const express = require('express');
const router = express.Router();
const Configuracion = require('../models/Configuracion');
const { protect, authorize } = require('../middleware/auth');

const MAX_CONFIG_VALUE_LENGTH = 1000000;

// GET /api/configuracion/ - Get all configuration (requires auth)
router.get('/', protect, async (req, res) => {
    try {
        const configs = await Configuracion.find({});
        const configuracion = {};
        configs.forEach(c => {
            configuracion[c.clave] = c.valor;
        });
        res.json({ configuracion });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// PUT /api/configuracion/ - Update configuration (admin only)
router.put('/', protect, authorize('admin'), async (req, res) => {
    try {
        const datos = req.body;
        if (!datos || typeof datos !== 'object') {
            return res.status(400).json({ error: 'Datos requeridos' });
        }

        const actualizados = [];
        for (const [clave, valor] of Object.entries(datos)) {
            if (typeof clave !== 'string' || clave.length > 100) continue;
            const valorStr = String(valor).substring(0, MAX_CONFIG_VALUE_LENGTH);

            await Configuracion.findOneAndUpdate(
                { clave },
                { clave, valor: valorStr, tipo: clave.startsWith('logo_') ? 'imagen' : 'texto' },
                { upsert: true, new: true }
            );
            actualizados.push(clave);
        }

        res.json({
            success: true,
            message: `${actualizados.length} configuraciones actualizadas`,
            actualizados
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// GET /api/configuracion/empresa - Public company info (no auth required)
router.get('/empresa', async (req, res) => {
    try {
        const claves = ['empresa_nombre', 'empresa_rnc', 'empresa_telefono', 'empresa_direccion', 'empresa_email', 'logo_login', 'logo_factura', 'logo_resultados'];
        const configs = await Configuracion.find({ clave: { $in: claves } });

        const info = {};
        configs.forEach(c => {
            if (c.clave.startsWith('empresa_')) {
                info[c.clave.replace('empresa_', '')] = c.valor;
            } else {
                info[c.clave] = c.valor;
            }
        });
        res.json(info);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
