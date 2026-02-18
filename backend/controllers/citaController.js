const Cita = require('../models/Cita');
const Paciente = require('../models/Paciente');
const Estudio = require('../models/Estudio');
const { AppError } = require('../middleware/errorHandler');

// @desc    Obtener todas las citas
// @route   GET /api/citas
exports.getCitas = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        let filter = {};

        // Filtrar por fecha
        if (req.query.fecha) {
            const fecha = new Date(req.query.fecha);
            const inicio = new Date(fecha.setHours(0, 0, 0, 0));
            const fin = new Date(fecha.setHours(23, 59, 59, 999));
            filter.fecha = { $gte: inicio, $lte: fin };
        }

        // Filtrar por rango de fechas
        if (req.query.fechaInicio && req.query.fechaFin) {
            filter.fecha = {
                $gte: new Date(req.query.fechaInicio),
                $lte: new Date(req.query.fechaFin)
            };
        }

        // Filtrar por estado
        if (req.query.estado) {
            filter.estado = req.query.estado;
        }

        // Filtrar por paciente
        if (req.query.paciente) {
            filter.paciente = req.query.paciente;
        }

        // Filtrar por médico
        if (req.query.medico) {
            filter.medico = req.query.medico;
        }

        // Solo citas del día (shortcut)
        if (req.query.hoy === 'true') {
            const hoy = new Date();
            filter.fecha = {
                $gte: new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate()),
                $lte: new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate(), 23, 59, 59)
            };
        }

        const [citas, total] = await Promise.all([
            Cita.find(filter)
                .populate('paciente', 'nombre apellido cedula telefono email')
                .populate('medico', 'nombre apellido especialidad')
                .populate('estudios.estudio', 'nombre codigo categoria precio')
                .populate('creadoPor', 'nombre apellido')
                .sort(req.query.sort || 'fecha horaInicio')
                .skip(skip)
                .limit(limit),
            Cita.countDocuments(filter)
        ]);

        res.json({
            success: true,
            count: citas.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: citas
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Obtener una cita
// @route   GET /api/citas/:id
exports.getCita = async (req, res, next) => {
    try {
        const cita = await Cita.findById(req.params.id)
            .populate('paciente')
            .populate('medico', 'nombre apellido especialidad')
            .populate('estudios.estudio')
            .populate('creadoPor', 'nombre apellido');

        if (!cita) {
            return res.status(404).json({
                success: false,
                message: 'Cita no encontrada'
            });
        }

        res.json({
            success: true,
            data: cita
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Crear cita
// @route   POST /api/citas
exports.createCita = async (req, res, next) => {
    try {
        // Verificar que el paciente existe
        const paciente = await Paciente.findById(req.body.paciente);
        if (!paciente) {
            return res.status(404).json({
                success: false,
                message: 'Paciente no encontrado'
            });
        }

        // Si vienen IDs de estudios, obtener precios
        if (req.body.estudios && req.body.estudios.length > 0) {
            const estudiosCompletos = [];
            for (const item of req.body.estudios) {
                const estudioId = item.estudio || item;
                const estudio = await Estudio.findById(estudioId);
                if (estudio) {
                    estudiosCompletos.push({
                        estudio: estudio._id,
                        precio: item.precio || estudio.precio,
                        descuento: item.descuento || 0
                    });
                }
            }
            req.body.estudios = estudiosCompletos;
        }

        req.body.creadoPor = req.user._id;

        const cita = await Cita.create(req.body);

        // Populate para la respuesta
        await cita.populate('paciente', 'nombre apellido cedula');
        await cita.populate('estudios.estudio', 'nombre codigo precio');

        res.status(201).json({
            success: true,
            message: 'Cita creada exitosamente',
            data: cita
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Actualizar cita
// @route   PUT /api/citas/:id
exports.updateCita = async (req, res, next) => {
    try {
        req.body.modificadoPor = req.user._id;

        const cita = await Cita.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, runValidators: true }
        )
        .populate('paciente', 'nombre apellido cedula')
        .populate('estudios.estudio', 'nombre codigo precio');

        if (!cita) {
            return res.status(404).json({
                success: false,
                message: 'Cita no encontrada'
            });
        }

        res.json({
            success: true,
            message: 'Cita actualizada exitosamente',
            data: cita
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Cambiar estado de cita
// @route   PATCH /api/citas/:id/estado
exports.cambiarEstado = async (req, res, next) => {
    try {
        const { estado, motivo } = req.body;

        const updateData = {
            estado,
            modificadoPor: req.user._id
        };

        if (estado === 'cancelada') {
            updateData.canceladoPor = req.user._id;
            updateData.motivoCancelacion = motivo || 'Sin motivo especificado';
        }

        if (estado === 'completada') {
            updateData.horaFin = new Date().toLocaleTimeString('es-DO', { hour: '2-digit', minute: '2-digit' });
        }

        const cita = await Cita.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        )
        .populate('paciente', 'nombre apellido cedula')
        .populate('estudios.estudio', 'nombre');

        if (!cita) {
            return res.status(404).json({
                success: false,
                message: 'Cita no encontrada'
            });
        }

        res.json({
            success: true,
            message: `Cita ${estado} exitosamente`,
            data: cita
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Citas del día
// @route   GET /api/citas/hoy
exports.citasHoy = async (req, res, next) => {
    try {
        const hoy = new Date();
        const inicio = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());
        const fin = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate(), 23, 59, 59);

        const citas = await Cita.find({
            fecha: { $gte: inicio, $lte: fin }
        })
        .populate('paciente', 'nombre apellido cedula telefono')
        .populate('medico', 'nombre apellido')
        .populate('estudios.estudio', 'nombre codigo')
        .sort('horaInicio');

        res.json({
            success: true,
            count: citas.length,
            data: citas
        });
    } catch (error) {
        next(error);
    }
};
