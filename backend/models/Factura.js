const mongoose = require('mongoose');

const facturaSchema = new mongoose.Schema({
    numero: {
        type: String,
        unique: true
    },
    tipo: {
        type: String,
        enum: ['fiscal', 'consumidor_final', 'credito_fiscal', 'nota_credito'],
        default: 'consumidor_final'
    },
    paciente: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Paciente',
        required: true
    },
    cita: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Cita'
    },
    datosCliente: {
        nombre: String,
        cedula: String,
        rnc: String,
        direccion: String,
        telefono: String,
        email: String
    },
    items: [{
        descripcion: String,
        estudio: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Estudio'
        },
        cantidad: { type: Number, default: 1 },
        precioUnitario: Number,
        descuento: { type: Number, default: 0 },
        subtotal: Number
    }],
    subtotal: { type: Number, required: true, default: 0 },
    descuento: { type: Number, default: 0 },
    itbis: { type: Number, default: 0 },
    total: { type: Number, required: true, default: 0 },
    metodoPago: {
        type: String,
        enum: ['efectivo', 'tarjeta', 'transferencia', 'cheque', 'seguro', 'mixto'],
        default: 'efectivo'
    },
    pagado: { type: Boolean, default: false },
    montoPagado: { type: Number, default: 0 },
    estado: {
        type: String,
        enum: ['borrador', 'emitida', 'pagada', 'anulada'],
        default: 'emitida'
    },
    creadoPor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    anuladoPor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    motivoAnulacion: String,
    fechaAnulacion: Date,
    notas: String
}, {
    timestamps: true
});

// Auto-generar número de factura ANTES de validar
facturaSchema.pre('validate', async function(next) {
    if (!this.numero) {
        const count = await mongoose.model('Factura').countDocuments();
        const year = new Date().getFullYear();
        const month = String(new Date().getMonth() + 1).padStart(2, '0');
        this.numero = `FAC-${year}${month}-${String(count + 1).padStart(5, '0')}`;
    }
    next();
});

facturaSchema.index({ numero: 1 });
facturaSchema.index({ paciente: 1 });
facturaSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Factura', facturaSchema);
