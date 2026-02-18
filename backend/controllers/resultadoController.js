const Resultado = require('../models/Resultado');
const Cita = require('../models/Cita');
const Paciente = require('../models/Paciente');

// @desc    Obtener resultados (con filtros)
// @route   GET /api/resultados
exports.getResultados = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        let filter = {};

        if (req.query.paciente) filter.paciente = req.query.paciente;
        if (req.query.cita) filter.cita = req.query.cita;
        if (req.query.estado) filter.estado = req.query.estado;
        if (req.query.estudio) filter.estudio = req.query.estudio;

        const [resultados, total] = await Promise.all([
            Resultado.find(filter)
                .populate('paciente', 'nombre apellido cedula')
                .populate('estudio', 'nombre codigo categoria')
                .populate('medico', 'nombre apellido especialidad')
                .populate('realizadoPor', 'nombre apellido')
                .populate('validadoPor', 'nombre apellido')
                .sort('-createdAt')
                .skip(skip)
                .limit(limit),
            Resultado.countDocuments(filter)
        ]);

        res.json({
            success: true,
            count: resultados.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: resultados
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Obtener resultados por paciente
// @route   GET /api/resultados/paciente/:pacienteId
exports.getResultadosPorPaciente = async (req, res, next) => {
    try {
        const resultados = await Resultado.find({ 
            paciente: req.params.pacienteId,
            estado: { $ne: 'anulado' }
        })
            .populate('estudio', 'nombre codigo categoria')
            .populate('medico', 'nombre apellido especialidad')
            .populate('validadoPor', 'nombre apellido')
            .sort('-createdAt');

        res.json({
            success: true,
            count: resultados.length,
            data: resultados
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Obtener resultados por cédula (para QR)
// @route   GET /api/resultados/cedula/:cedula
exports.getResultadosPorCedula = async (req, res, next) => {
    try {
        const paciente = await Paciente.findOne({ cedula: req.params.cedula });
        
        if (!paciente) {
            return res.status(404).json({
                success: false,
                message: 'Paciente no encontrado'
            });
        }

        const resultados = await Resultado.find({ 
            paciente: paciente._id,
            estado: { $in: ['completado', 'entregado'] }
        })
            .populate('estudio', 'nombre codigo categoria')
            .populate('medico', 'nombre apellido especialidad')
            .populate('validadoPor', 'nombre apellido')
            .sort('-createdAt');

        res.json({
            success: true,
            paciente: {
                _id: paciente._id,
                nombre: paciente.nombre,
                apellido: paciente.apellido,
                cedula: paciente.cedula,
                fechaNacimiento: paciente.fechaNacimiento,
                sexo: paciente.sexo,
                nacionalidad: paciente.nacionalidad
            },
            count: resultados.length,
            data: resultados
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Obtener un resultado
// @route   GET /api/resultados/:id
exports.getResultado = async (req, res, next) => {
    try {
        const resultado = await Resultado.findById(req.params.id)
            .populate('paciente')
            .populate('estudio')
            .populate('medico', 'nombre apellido especialidad licenciaMedica')
            .populate('realizadoPor', 'nombre apellido')
            .populate('validadoPor', 'nombre apellido');

        if (!resultado) {
            return res.status(404).json({
                success: false,
                message: 'Resultado no encontrado'
            });
        }

        res.json({ success: true, data: resultado });
    } catch (error) {
        next(error);
    }
};

// @desc    Crear resultado
// @route   POST /api/resultados
exports.createResultado = async (req, res, next) => {
    try {
        req.body.realizadoPor = req.user?._id;

        const resultado = await Resultado.create(req.body);

        await resultado.populate('paciente', 'nombre apellido');
        await resultado.populate('estudio', 'nombre codigo');

        res.status(201).json({
            success: true,
            message: 'Resultado creado exitosamente',
            data: resultado
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Actualizar resultado
// @route   PUT /api/resultados/:id
exports.updateResultado = async (req, res, next) => {
    try {
        const resultado = await Resultado.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, runValidators: true }
        )
            .populate('paciente', 'nombre apellido')
            .populate('estudio', 'nombre codigo');

        if (!resultado) {
            return res.status(404).json({
                success: false,
                message: 'Resultado no encontrado'
            });
        }

        res.json({
            success: true,
            message: 'Resultado actualizado',
            data: resultado
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Validar resultado
// @route   PUT /api/resultados/:id/validar
exports.validarResultado = async (req, res, next) => {
    try {
        const resultado = await Resultado.findByIdAndUpdate(
            req.params.id,
            {
                estado: 'completado',
                validadoPor: req.user?._id,
                fechaValidacion: new Date(),
                interpretacion: req.body.interpretacion,
                conclusion: req.body.conclusion
            },
            { new: true }
        )
            .populate('paciente')
            .populate('estudio')
            .populate('validadoPor', 'nombre apellido');

        if (!resultado) {
            return res.status(404).json({
                success: false,
                message: 'Resultado no encontrado'
            });
        }

        res.json({
            success: true,
            message: 'Resultado validado exitosamente',
            data: resultado
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Eliminar resultado
// @route   DELETE /api/resultados/:id
exports.deleteResultado = async (req, res, next) => {
    try {
        const resultado = await Resultado.findByIdAndDelete(req.params.id);

        if (!resultado) {
            return res.status(404).json({
                success: false,
                message: 'Resultado no encontrado'
            });
        }

        res.json({
            success: true,
            message: 'Resultado eliminado'
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Marcar como impreso
// @route   PUT /api/resultados/:id/imprimir
exports.marcarImpreso = async (req, res, next) => {
    try {
        const resultado = await Resultado.findByIdAndUpdate(
            req.params.id,
            {
                impreso: true,
                $inc: { vecesImpreso: 1 }
            },
            { new: true }
        );

        res.json({ success: true, data: resultado });
    } catch (error) {
        next(error);
    }
};

// @desc    Verificar estado de pago antes de imprimir
// @route   GET /api/resultados/:id/verificar-pago
exports.verificarPago = async (req, res, next) => {
    try {
        const Factura = require('../models/Factura');
        
        // Obtener el resultado con la cita y paciente poblados
        const resultado = await Resultado.findById(req.params.id)
            .populate('cita')
            .populate('paciente', 'nombre apellido');

        if (!resultado) {
            return res.status(404).json({
                success: false,
                message: 'Resultado no encontrado'
            });
        }

        // Buscar facturas asociadas al paciente que estén pendientes de pago
        const facturasPendientes = await Factura.find({
            paciente: resultado.paciente._id,
            $or: [
                { pagado: false },
                { estado: { $in: ['borrador', 'emitida'] } }
            ]
        }).select('numero total montoPagado estado');

        // Calcular el total pendiente
        let montoPendiente = 0;
        facturasPendientes.forEach(factura => {
            const pendiente = factura.total - (factura.montoPagado || 0);
            if (pendiente > 0) {
                montoPendiente += pendiente;
            }
        });

        const puedeImprimir = montoPendiente === 0;

        res.json({
            success: true,
            puede_imprimir: puedeImprimir,
            monto_pendiente: montoPendiente,
            facturas_pendientes: facturasPendientes.map(f => ({
                id: f._id,
                numero: f.numero,
                total: f.total,
                pagado: f.montoPagado || 0,
                pendiente: f.total - (f.montoPagado || 0),
                estado: f.estado
            })),
            paciente: {
                nombre: resultado.paciente.nombre,
                apellido: resultado.paciente.apellido
            }
        });
    } catch (error) {
        next(error);
    }
};
