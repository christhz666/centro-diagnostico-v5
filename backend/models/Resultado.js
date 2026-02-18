const mongoose = require('mongoose');

const resultadoSchema = new mongoose.Schema({
    // Relaciones
    cita: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Cita',
        required: true
    },
    paciente: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Paciente',
        required: true
    },
    estudio: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Estudio',
        required: true
    },
    medico: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    
    // Resultado
    estado: {
        type: String,
        enum: ['pendiente', 'en_proceso', 'completado', 'entregado', 'anulado'],
        default: 'pendiente'
    },
    
    // Valores del resultado
    valores: [{
        parametro: String,
        valor: String,
        unidad: String,
        valorReferencia: String,
        estado: {
            type: String,
            enum: ['normal', 'alto', 'bajo', 'critico', ''],
            default: ''
        }
    }],
    
    // Interpretación
    interpretacion: {
        type: String,
        trim: true
    },
    observaciones: {
        type: String,
        trim: true
    },
    conclusion: {
        type: String,
        trim: true
    },
    
    // Archivos adjuntos (imágenes, PDFs)
    archivos: [{
        nombre: String,
        url: String,
        tipo: String,
        tamaño: Number
    }],
    
    // Control
    realizadoPor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    validadoPor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    fechaRealizacion: Date,
    fechaValidacion: Date,
    fechaEntrega: Date,
    
    // Para impresión
    impreso: {
        type: Boolean,
        default: false
    },
    vecesImpreso: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Índices
resultadoSchema.index({ paciente: 1, createdAt: -1 });
resultadoSchema.index({ cita: 1 });
resultadoSchema.index({ estado: 1 });

module.exports = mongoose.model('Resultado', resultadoSchema);
