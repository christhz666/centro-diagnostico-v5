const express = require('express');
const router = express.Router();
const equipoController = require('../controllers/equipoController');

console.log('? Cargando rutas de equipos...');

// GET - Listar equipos
router.get('/', equipoController.getEquipos);
router.get('/estados', equipoController.getEstadoConexiones);

// CRUD
router.post('/', equipoController.createEquipo);
router.put('/:id', equipoController.updateEquipo);
router.delete('/:id', equipoController.deleteEquipo);

// Conexiones
router.post('/:id/conectar', equipoController.conectarEquipo);
router.post('/:id/desconectar', equipoController.desconectarEquipo);
router.post('/:id/probar', equipoController.probarConexion);

// ? SIMULACIÓN DE RESULTADO
router.post('/:id/simular-resultado', async (req, res) => {
  console.log('?? Simulación de resultado iniciada');
  
  const Equipo = require('../models/Equipo');
  const Resultado = require('../models/Resultado');
  const Paciente = require('../models/Paciente');
  const Estudio = require('../models/Estudio');
  const Cita = require('../models/Cita');
  
  try {
    // 1. Buscar equipo
    const equipo = await Equipo.findById(req.params.id);
    if (!equipo) {
      return res.status(404).json({ success: false, message: 'Equipo no encontrado' });
    }
    console.log('? Equipo:', equipo.nombre);
    
    // 2. Buscar paciente
    const paciente = await Paciente.findOne({ cedula: req.body.cedula });
    if (!paciente) {
      return res.status(404).json({ success: false, message: 'Paciente no encontrado con cédula: ' + req.body.cedula });
    }
    console.log('? Paciente:', paciente.nombre);
    
    // 3. Buscar estudio
    const estudio = await Estudio.findOne();
    if (!estudio) {
      return res.status(404).json({ success: false, message: 'No hay estudios registrados' });
    }
    console.log('? Estudio:', estudio.nombre);
    
    // 4. Buscar o crear cita
    let cita = await Cita.findOne({ 
      paciente: paciente._id, 
      estado: { $in: ['confirmada', 'completada'] }
    });
    
    if (!cita) {
      console.log('?? Creando cita automática...');
      const ahora = new Date();
      cita = await Cita.create({
        paciente: paciente._id,
        fecha: ahora,
        hora: ahora.toTimeString().slice(0, 5),
        horaInicio: ahora.toTimeString().slice(0, 5), // ? Campo requerido
        estudios: [{
          estudio: estudio._id, // ? Estructura correcta
          precio: estudio.precio || 0,
          estado: 'completado'
        }],
        estado: 'completada',
        motivo: 'Resultado automático - ' + equipo.nombre,
        tipoConsulta: 'laboratorio'
      });
      console.log('? Cita creada');
    } else {
      console.log('? Cita existente encontrada');
    }
    
    // 5. Generar valores según tipo de equipo
    let valores = [];
    
    if (equipo.tipo === 'hematologia') {
      valores = [
        { 
          parametro: 'Leucocitos (WBC)', 
          valor: (Math.random() * 5 + 5).toFixed(1), 
          unidad: '10³/µL', 
          valorReferencia: '4.0-10.0', 
          estado: 'normal' 
        },
        { 
          parametro: 'Eritrocitos (RBC)', 
          valor: (Math.random() * 1 + 4.5).toFixed(1), 
          unidad: '106/µL', 
          valorReferencia: '4.5-5.5', 
          estado: 'normal' 
        },
        { 
          parametro: 'Hemoglobina (HGB)', 
          valor: (Math.random() * 3 + 13).toFixed(1), 
          unidad: 'g/dL', 
          valorReferencia: '13.0-17.0', 
          estado: 'normal' 
        },
        { 
          parametro: 'Plaquetas (PLT)', 
          valor: (Math.random() * 200 + 200).toFixed(0), 
          unidad: '10³/µL', 
          valorReferencia: '150-400', 
          estado: 'normal' 
        }
      ];
    } else if (equipo.tipo === 'quimica') {
      valores = [
        { parametro: 'Glucosa', valor: (Math.random() * 20 + 80).toFixed(0), unidad: 'mg/dL', valorReferencia: '70-100', estado: 'normal' },
        { parametro: 'Urea', valor: (Math.random() * 15 + 20).toFixed(0), unidad: 'mg/dL', valorReferencia: '15-40', estado: 'normal' },
        { parametro: 'Creatinina', valor: (Math.random() * 0.5 + 0.7).toFixed(1), unidad: 'mg/dL', valorReferencia: '0.6-1.2', estado: 'normal' }
      ];
    } else {
      valores = [
        { parametro: 'Parámetro Test', valor: (Math.random() * 100).toFixed(1), unidad: 'U/L', valorReferencia: 'Normal', estado: 'normal' }
      ];
    }
    
    console.log('? Valores generados:', valores.length);
    
    // 6. Crear resultado
    const resultado = await Resultado.create({
      paciente: paciente._id,
      cita: cita._id,
      estudio: estudio._id,
      valores,
      estado: 'en_proceso',
      observaciones: `Resultado automático de ${equipo.nombre} - ${new Date().toLocaleString('es-DO')}`
    });
    
    console.log('? Resultado creado:', resultado._id);
    
    // 7. Actualizar estadísticas del equipo
    await Equipo.findByIdAndUpdate(equipo._id, {
      ultimaConexion: new Date(),
      $inc: { 'estadisticas.resultadosRecibidos': 1 },
      'estadisticas.ultimoResultado': new Date()
    });
    
    res.json({
      success: true,
      message: `? Resultado creado exitosamente desde ${equipo.nombre}`,
      data: {
        resultadoId: resultado._id,
        paciente: `${paciente.nombre} ${paciente.apellido}`,
        cedula: paciente.cedula,
        equipo: equipo.nombre,
        valores: valores.length,
        estado: 'en_proceso'
      }
    });
    
  } catch (error) {
    console.error('? Error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: error.message,
      details: error.toString()
    });
  }
});

// GET individual - debe ir AL FINAL
router.get('/:id', equipoController.getEquipo);

// -----------------------------------------------------------
// ?? RECEPCIÓN DESDE AGENTE REMOTO
// -----------------------------------------------------------

router.post('/:id/recibir-resultado', async (req, res) => {
  console.log('?? Recibiendo resultado desde agente remoto');
  console.log('Equipo ID:', req.params.id);
  console.log('Datos:', JSON.stringify(req.body, null, 2));

  try {
    const Equipo = require('../models/Equipo');
    const Resultado = require('../models/Resultado');
    const Paciente = require('../models/Paciente');
    const Estudio = require('../models/Estudio');
    const Cita = require('../models/Cita');

    // Buscar equipo
    const equipo = await Equipo.findById(req.params.id);
    if (!equipo) {
      console.log('? Equipo no encontrado');
      return res.status(404).json({ 
        success: false, 
        message: 'Equipo no encontrado' 
      });
    }

    console.log('? Equipo encontrado:', equipo.nombre);

    const { cedula, valores, timestamp } = req.body;

    // Buscar paciente
    const paciente = await Paciente.findOne({ cedula });
    if (!paciente) {
      console.log('? Paciente no encontrado:', cedula);
      return res.status(404).json({ 
        success: false, 
        message: `Paciente con cédula ${cedula} no encontrado` 
      });
    }

    console.log('? Paciente encontrado:', paciente.nombre, paciente.apellido);

    // Buscar o crear estudio
    let estudio = await Estudio.findOne();
    if (!estudio) {
      estudio = await Estudio.create({
        nombre: 'Examen General',
        codigo: 'GEN-001',
        categoria: 'Laboratorio Clínico',
        precio: 0
      });
    }

    // Buscar o crear cita
    let cita = await Cita.findOne({ 
      paciente: paciente._id, 
      estado: 'completada' 
    }).sort({ createdAt: -1 });

    if (!cita) {
      const ahora = new Date();
      cita = await Cita.create({
        paciente: paciente._id,
        fecha: ahora,
        hora: ahora.toTimeString().slice(0, 5),
        horaInicio: ahora.toTimeString().slice(0, 5),
        estudios: [{
          estudio: estudio._id,
          precio: 0,
          estado: 'completado'
        }],
        estado: 'completada',
        motivo: `Auto - ${equipo.nombre}`
      });
      console.log('? Cita creada automáticamente');
    }

    // Mapear valores recibidos a parámetros del sistema
    const valoresMapeados = valores.map(v => {
      // Buscar mapeo en el equipo
      const mapeo = equipo.mapeoParametros.find(m => 
        m.codigoEquipo === v.codigo || 
        v.codigo.includes(m.codigoEquipo)
      );

      return {
        parametro: mapeo?.nombreParametro || v.codigo,
        valor: v.valor,
        unidad: mapeo?.unidad || v.unidad || '',
        valorReferencia: mapeo?.valorReferencia || '',
        estado: v.estado === 'N' ? 'normal' : 
                v.estado === 'H' ? 'alto' : 
                v.estado === 'L' ? 'bajo' : 'normal'
      };
    });

    console.log('? Valores mapeados:', valoresMapeados.length);

    // Crear resultado
    const resultado = await Resultado.create({
      paciente: paciente._id,
      cita: cita._id,
      estudio: estudio._id,
      valores: valoresMapeados,
      estado: 'en_proceso',
      observaciones: `Recibido desde ${equipo.nombre} - Agente remoto - ${timestamp || new Date().toISOString()}`
    });

    console.log('? Resultado creado:', resultado._id);

    // Actualizar estadísticas del equipo
    await Equipo.findByIdAndUpdate(equipo._id, {
      ultimaConexion: new Date(),
      $inc: { 'estadisticas.resultadosRecibidos': 1 }
    });

    res.json({
      success: true,
      message: `Resultado recibido desde ${equipo.nombre}`,
      data: {
        resultadoId: resultado._id,
        paciente: `${paciente.nombre} ${paciente.apellido}`,
        valores: valoresMapeados.length
      }
    });

  } catch (error) {
    console.error('? Error procesando resultado:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

module.exports = router;
