const express = require('express');
const cors = require('cors');
const path = require('path');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');

// Cargar variables de entorno
dotenv.config();

// Importar conexión DB
const connectDB = require('./config/db');

// Importar middleware de errores
const { errorHandler, notFound } = require('./middleware/errorHandler');

// Inicializar Express
const app = express();

// ==========================================
// MIDDLEWARE DE SEGURIDAD
// ==========================================

// Helmet - headers de seguridad
app.use(helmet({
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false
}));

// Rate limiting - prevenir ataques de fuerza bruta
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 10000, // máximo 200 requests por ventana
    message: {
        success: false,
        message: 'Demasiadas peticiones desde esta IP. Intente en 15 minutos.'
    }
});
app.use('/api/', limiter);

// Rate limit más estricto para login
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    message: {
        success: false,
        message: 'Demasiados intentos de login. Intente en 15 minutos.'
    }
});
app.use('/api/auth/login', loginLimiter);

// ==========================================
// MIDDLEWARE GENERAL
// ==========================================

// CORS - Permitir comunicación frontend ? backend
app.use(cors({
    origin: [
        'http://192.9.135.84',
        'http://192.9.135.84:3000',
        'http://localhost:3000',
        'http://localhost:5000',
        process.env.FRONTEND_URL
    ].filter(Boolean),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
}

// Archivos estáticos
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ==========================================
// RUTAS DE LA API
// ==========================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: '?? Centro Diagnóstico Mi Esperanza - API funcionando',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
        uptime: process.uptime()
    });
});


// ========================================== 
// RUTA DE PRUEBA DIRECTA
// ==========================================
// app.get('/api/equipos', async (req, res) => {
//   console.log('?? TEST: /api/test-equipos');
//   try {
//     const Equipo = require('./models/Equipo');
//     const equipos = await Equipo.find().sort({ nombre: 1 });
//     console.log('?? TEST: Encontrados', equipos.length, 'equipos');
//     res.json({ 
//       success: true, 
//       count: equipos.length, 
//       equipos: equipos.map(e => ({ 
//         id: e._id, 
//         nombre: e.nombre, 
//         tipo: e.tipo 
//       }))
//     });
//   } catch (error) {
//     console.error('?? TEST ERROR:', error.message);
//     res.status(500).json({ success: false, error: error.message });
//   }
// });

// Rutas principales
app.use('/api/auth', require('./routes/auth'));
app.use('/api/pacientes', require('./routes/pacientes'));
app.use('/api/citas', require('./routes/citas'));
app.use('/api/ordenes', require('./routes/citas'));
app.use('/api/estudios', require('./routes/estudios'));
app.use('/api/resultados', require('./routes/resultados'));
app.use('/api/facturas', require('./routes/facturas'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/reportes', require('./routes/dashboard'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/equipos', require('./routes/equipoRoutes'));
app.use('/api/contabilidad', require('./routes/contabilidad'));
app.use('/api/configuracion', require('./routes/configuracion'));

// ==========================================
// SERVIR FRONTEND (React build)
// ==========================================

// Si existe el build de React, servirlo
const frontendBuild = path.join(__dirname, '../frontend/build');
const fs = require('fs');

if (fs.existsSync(frontendBuild)) {
    app.use(express.static(frontendBuild));
    
    // Cualquier ruta que no sea /api, servir el index.html de React
    app.get('*', (req, res) => {
        if (!req.originalUrl.startsWith('/api')) {
            res.sendFile(path.join(frontendBuild, 'index.html'));
        }
    });
}

// ==========================================
// MANEJO DE ERRORES
// ==========================================

app.use(notFound);
app.use(errorHandler);

// ==========================================
// INICIAR SERVIDOR
// ==========================================

const PORT = process.env.PORT || 5000;

// Conectar a la base de datos y luego iniciar el servidor
const startServer = async () => {
    try {
        await connectDB();
        
        app.listen(PORT, '0.0.0.0', () => {
            console.log('');
            console.log('+---------------------------------------------------+');
            console.log('¦  ?? Centro Diagnóstico Mi Esperanza              ¦');
            console.log('¦  ?? API Server                                    ¦');
            console.log(`¦  ?? Puerto: ${PORT}                                  ¦`);
            console.log(`¦  ?? Entorno: ${process.env.NODE_ENV || 'development'}                        ¦`);
            console.log(`¦  ?? API: http://192.9.135.84:${PORT}/api             ¦`);
            console.log(`¦  ??  Health: http://192.9.135.84:${PORT}/api/health  ¦`);
            console.log('+---------------------------------------------------+');
            console.log('');
        });
    } catch (error) {
        console.error('? Error fatal al iniciar:', error.message);
        process.exit(1);
    }
};

startServer();

// Manejo de errores no capturados
process.on('unhandledRejection', (err) => {
    console.error('? UNHANDLED REJECTION:', err.message);
    console.error(err.stack);
});

process.on('uncaughtException', (err) => {
    console.error('? UNCAUGHT EXCEPTION:', err.message);
    console.error(err.stack);
    process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('?? SIGTERM recibido. Cerrando servidor...');
    process.exit(0);
});

module.exports = app;

// ==========================================
// INICIAR SERVICIO DE EQUIPOS
// ==========================================
const equipoService = require('./services/equipoService');

// Iniciar equipos automáticamente cuando el servidor esté listo
setTimeout(() => {
  equipoService.iniciarTodos()
    .then(() => console.log('? Servicio de equipos iniciado'))
    .catch(err => console.error('??  Error iniciando equipos:', err.message));
}, 3000); // Esperar 3 segundos después de que MongoDB conecte
