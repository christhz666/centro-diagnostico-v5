const express = require('express');
const router = express.Router();
const resultadoController = require('../controllers/resultadoController');

// Rutas públicas (para QR)
router.get('/cedula/:cedula', resultadoController.getResultadosPorCedula);

// Rutas sin protección temporalmente para testing
router.get('/', resultadoController.getResultados);
router.get('/paciente/:pacienteId', resultadoController.getResultadosPorPaciente);
router.get('/:id', resultadoController.getResultado);
router.post('/', resultadoController.createResultado);
router.put('/:id', resultadoController.updateResultado);
router.put('/:id/validar', resultadoController.validarResultado);
router.patch('/:id/validar', resultadoController.validarResultado);
router.put('/:id/imprimir', resultadoController.marcarImpreso);
router.delete('/:id', resultadoController.deleteResultado);

module.exports = router;
