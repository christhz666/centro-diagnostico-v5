const express = require('express');
const router = express.Router();
const {
    getMovimientos, createMovimiento, getResumenContable,
    getFlujoCaja, deleteMovimiento
} = require('../controllers/contabilidadController');
const { protect, authorize } = require('../middleware/auth');
const { idValidation } = require('../middleware/validators');

router.use(protect);
router.use(authorize('admin'));

router.get('/resumen', getResumenContable);
router.get('/flujo-caja', getFlujoCaja);

router.route('/')
    .get(getMovimientos)
    .post(createMovimiento);

router.route('/:id')
    .delete(idValidation, deleteMovimiento);

module.exports = router;
