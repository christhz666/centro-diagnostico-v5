-- ============================================
-- SISTEMA DE GESTIÓN PARA CENTRO DIAGNÓSTICO
-- Base de Datos PostgreSQL
-- ============================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABLA: PACIENTES
-- ============================================
CREATE TABLE pacientes (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    cedula VARCHAR(20) UNIQUE,
    pasaporte VARCHAR(30),
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    telefono VARCHAR(20),
    celular VARCHAR(20),
    email VARCHAR(100),
    direccion TEXT,
    ciudad VARCHAR(100),
    seguro_medico VARCHAR(100),
    numero_poliza VARCHAR(50),
    tipo_sangre VARCHAR(5),
    alergias TEXT,
    notas_medicas TEXT,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pacientes_cedula ON pacientes(cedula);
CREATE INDEX idx_pacientes_nombre ON pacientes(nombre, apellido);

-- ============================================
-- TABLA: USUARIOS DEL SISTEMA
-- ============================================
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('admin', 'cajero', 'tecnico', 'medico', 'recepcion')),
    permisos JSONB,
    activo BOOLEAN DEFAULT true,
    ultimo_acceso TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: CATEGORÍAS DE ESTUDIOS
-- ============================================
CREATE TABLE categorias_estudios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    color VARCHAR(7), -- Código hex para UI
    icono VARCHAR(50),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: ESTUDIOS/SERVICIOS
-- ============================================
CREATE TABLE estudios (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    categoria_id INTEGER REFERENCES categorias_estudios(id),
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    costo DECIMAL(10,2),
    tiempo_estimado INTEGER, -- en minutos
    requiere_preparacion BOOLEAN DEFAULT false,
    instrucciones_preparacion TEXT,
    tipo_resultado VARCHAR(20) CHECK (tipo_resultado IN ('pdf', 'dicom', 'hl7', 'manual')),
    equipo_asignado VARCHAR(100),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_estudios_codigo ON estudios(codigo);
CREATE INDEX idx_estudios_categoria ON estudios(categoria_id);

-- ============================================
-- TABLA: ÓRDENES DE SERVICIO
-- ============================================
CREATE TABLE ordenes (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    numero_orden VARCHAR(20) UNIQUE NOT NULL,
    paciente_id INTEGER REFERENCES pacientes(id) NOT NULL,
    medico_referente VARCHAR(100),
    fecha_orden TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_cita TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_proceso', 'completada', 'cancelada', 'facturada')),
    prioridad VARCHAR(20) DEFAULT 'normal' CHECK (prioridad IN ('normal', 'urgente', 'stat')),
    observaciones TEXT,
    usuario_registro_id INTEGER REFERENCES usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ordenes_paciente ON ordenes(paciente_id);
CREATE INDEX idx_ordenes_fecha ON ordenes(fecha_orden);
CREATE INDEX idx_ordenes_estado ON ordenes(estado);

-- ============================================
-- TABLA: DETALLES DE ORDEN (Estudios solicitados)
-- ============================================
CREATE TABLE orden_detalles (
    id SERIAL PRIMARY KEY,
    orden_id INTEGER REFERENCES ordenes(id) ON DELETE CASCADE,
    estudio_id INTEGER REFERENCES estudios(id),
    precio DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0,
    precio_final DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_proceso', 'completado', 'cancelado')),
    resultado_disponible BOOLEAN DEFAULT false,
    fecha_resultado TIMESTAMP,
    tecnico_id INTEGER REFERENCES usuarios(id),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orden_detalles_orden ON orden_detalles(orden_id);

-- ============================================
-- TABLA: RESULTADOS
-- ============================================
CREATE TABLE resultados (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    orden_detalle_id INTEGER REFERENCES orden_detalles(id),
    tipo_archivo VARCHAR(10) CHECK (tipo_archivo IN ('pdf', 'dicom', 'hl7', 'jpg', 'png')),
    ruta_archivo VARCHAR(500),
    ruta_nube VARCHAR(500),
    nombre_archivo VARCHAR(255),
    tamano_bytes BIGINT,
    hash_archivo VARCHAR(64), -- Para verificar integridad
    datos_hl7 TEXT, -- Almacenar datos HL7 parseados
    datos_dicom JSONB, -- Metadatos DICOM
    interpretacion TEXT,
    valores_referencia TEXT,
    estado_validacion VARCHAR(20) DEFAULT 'pendiente' CHECK (estado_validacion IN ('pendiente', 'validado', 'rechazado')),
    validado_por_id INTEGER REFERENCES usuarios(id),
    fecha_validacion TIMESTAMP,
    impreso BOOLEAN DEFAULT false,
    enviado_email BOOLEAN DEFAULT false,
    fecha_importacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_resultados_orden_detalle ON resultados(orden_detalle_id);

-- ============================================
-- TABLA: SECUENCIAS NCF (Números Comprobantes Fiscales)
-- ============================================
CREATE TABLE ncf_secuencias (
    id SERIAL PRIMARY KEY,
    tipo_comprobante VARCHAR(20) NOT NULL CHECK (tipo_comprobante IN ('B01', 'B02', 'B14', 'B15', 'B16')),
    serie VARCHAR(3) NOT NULL,
    secuencia_inicio BIGINT NOT NULL,
    secuencia_fin BIGINT NOT NULL,
    secuencia_actual BIGINT NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tipo_comprobante, serie)
);

-- ============================================
-- TABLA: FACTURAS
-- ============================================
CREATE TABLE facturas (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    numero_factura VARCHAR(30) UNIQUE NOT NULL,
    ncf VARCHAR(19), -- Formato: B01-001-00000001
    tipo_comprobante VARCHAR(3),
    orden_id INTEGER REFERENCES ordenes(id),
    paciente_id INTEGER REFERENCES pacientes(id) NOT NULL,
    fecha_factura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATE,
    subtotal DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0,
    itbis DECIMAL(10,2) DEFAULT 0, -- 18% en RD
    otros_impuestos DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'pagada', 'parcial', 'anulada', 'vencida')),
    forma_pago VARCHAR(30),
    notas TEXT,
    usuario_emision_id INTEGER REFERENCES usuarios(id),
    anulada_por_id INTEGER REFERENCES usuarios(id),
    motivo_anulacion TEXT,
    fecha_anulacion TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facturas_paciente ON facturas(paciente_id);
CREATE INDEX idx_facturas_fecha ON facturas(fecha_factura);
CREATE INDEX idx_facturas_estado ON facturas(estado);
CREATE INDEX idx_facturas_ncf ON facturas(ncf);

-- ============================================
-- TABLA: DETALLES DE FACTURA
-- ============================================
CREATE TABLE factura_detalles (
    id SERIAL PRIMARY KEY,
    factura_id INTEGER REFERENCES facturas(id) ON DELETE CASCADE,
    orden_detalle_id INTEGER REFERENCES orden_detalles(id),
    descripcion VARCHAR(255) NOT NULL,
    cantidad INTEGER DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0,
    itbis DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: PAGOS
-- ============================================
CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    factura_id INTEGER REFERENCES facturas(id),
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL CHECK (metodo_pago IN ('efectivo', 'tarjeta', 'transferencia', 'cheque', 'seguro', 'mixto')),
    referencia VARCHAR(100), -- Número de transacción, cheque, etc.
    banco VARCHAR(100),
    notas TEXT,
    usuario_recibe_id INTEGER REFERENCES usuarios(id),
    caja_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pagos_factura ON pagos(factura_id);
CREATE INDEX idx_pagos_fecha ON pagos(fecha_pago);

-- ============================================
-- TABLA: CAJAS (Control de efectivo)
-- ============================================
CREATE TABLE cajas (
    id SERIAL PRIMARY KEY,
    numero_caja VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100),
    usuario_id INTEGER REFERENCES usuarios(id),
    fecha_apertura TIMESTAMP NOT NULL,
    fecha_cierre TIMESTAMP,
    monto_apertura DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_cierre DECIMAL(10,2),
    estado VARCHAR(20) DEFAULT 'abierta' CHECK (estado IN ('abierta', 'cerrada')),
    notas_apertura TEXT,
    notas_cierre TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: MOVIMIENTOS DE CAJA
-- ============================================
CREATE TABLE caja_movimientos (
    id SERIAL PRIMARY KEY,
    caja_id INTEGER REFERENCES cajas(id),
    tipo_movimiento VARCHAR(20) CHECK (tipo_movimiento IN ('ingreso', 'egreso', 'apertura', 'cierre')),
    concepto VARCHAR(255) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    pago_id INTEGER REFERENCES pagos(id),
    usuario_id INTEGER REFERENCES usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: INVENTARIO (Opcional, para futuro)
-- ============================================
CREATE TABLE inventario (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(50),
    unidad_medida VARCHAR(20),
    cantidad_actual INTEGER DEFAULT 0,
    cantidad_minima INTEGER,
    costo_unitario DECIMAL(10,2),
    proveedor VARCHAR(100),
    fecha_vencimiento DATE,
    lote VARCHAR(50),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: CONFIGURACIÓN DEL SISTEMA
-- ============================================
CREATE TABLE configuracion (
    id SERIAL PRIMARY KEY,
    clave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT,
    tipo VARCHAR(20) CHECK (tipo IN ('texto', 'numero', 'boolean', 'json')),
    descripcion TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: LOGS DE AUDITORÍA
-- ============================================
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    tabla VARCHAR(50) NOT NULL,
    registro_id INTEGER NOT NULL,
    accion VARCHAR(20) CHECK (accion IN ('crear', 'actualizar', 'eliminar', 'ver')),
    usuario_id INTEGER REFERENCES usuarios(id),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auditoria_tabla ON auditoria(tabla, registro_id);
CREATE INDEX idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX idx_auditoria_fecha ON auditoria(created_at);

-- ============================================
-- TABLA: SINCRONIZACIÓN CON NUBE
-- ============================================
CREATE TABLE sync_queue (
    id SERIAL PRIMARY KEY,
    tabla VARCHAR(50) NOT NULL,
    registro_id INTEGER NOT NULL,
    accion VARCHAR(20),
    datos JSONB,
    intentos INTEGER DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'procesando', 'completado', 'error')),
    error_mensaje TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- ============================================
-- TRIGGERS PARA UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pacientes_updated_at BEFORE UPDATE ON pacientes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_estudios_updated_at BEFORE UPDATE ON estudios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ordenes_updated_at BEFORE UPDATE ON ordenes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_facturas_updated_at BEFORE UPDATE ON facturas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCIÓN PARA GENERAR NÚMERO DE ORDEN
-- ============================================
CREATE OR REPLACE FUNCTION generar_numero_orden()
RETURNS VARCHAR AS $$
DECLARE
    nuevo_numero VARCHAR;
    anio VARCHAR;
    mes VARCHAR;
    contador INTEGER;
BEGIN
    anio := TO_CHAR(CURRENT_DATE, 'YY');
    mes := TO_CHAR(CURRENT_DATE, 'MM');
    
    SELECT COUNT(*) + 1 INTO contador
    FROM ordenes
    WHERE TO_CHAR(fecha_orden, 'YYMM') = anio || mes;
    
    nuevo_numero := 'ORD-' || anio || mes || '-' || LPAD(contador::TEXT, 5, '0');
    
    RETURN nuevo_numero;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN PARA GENERAR NÚMERO DE FACTURA
-- ============================================
CREATE OR REPLACE FUNCTION generar_numero_factura()
RETURNS VARCHAR AS $$
DECLARE
    nuevo_numero VARCHAR;
    anio VARCHAR;
    contador INTEGER;
BEGIN
    anio := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    SELECT COUNT(*) + 1 INTO contador
    FROM facturas
    WHERE TO_CHAR(fecha_factura, 'YYYY') = anio;
    
    nuevo_numero := 'FAC-' || anio || '-' || LPAD(contador::TEXT, 6, '0');
    
    RETURN nuevo_numero;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCIÓN PARA OBTENER SIGUIENTE NCF
-- ============================================
CREATE OR REPLACE FUNCTION obtener_siguiente_ncf(tipo VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    secuencia RECORD;
    ncf VARCHAR;
BEGIN
    SELECT * INTO secuencia
    FROM ncf_secuencias
    WHERE tipo_comprobante = tipo
    AND activo = true
    AND secuencia_actual < secuencia_fin
    AND fecha_vencimiento > CURRENT_DATE
    ORDER BY fecha_vencimiento DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No hay secuencia NCF disponible para tipo %', tipo;
    END IF;
    
    ncf := tipo || '-' || secuencia.serie || '-' || LPAD(secuencia.secuencia_actual::TEXT, 8, '0');
    
    UPDATE ncf_secuencias
    SET secuencia_actual = secuencia_actual + 1
    WHERE id = secuencia.id;
    
    RETURN ncf;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar categorías de estudios
INSERT INTO categorias_estudios (nombre, descripcion, color, icono) VALUES
('Laboratorio Clínico', 'Análisis de sangre, orina y otros fluidos', '#3B82F6', 'test-tube'),
('Imagenología', 'Rayos X, Ultrasonido, etc.', '#10B981', 'image'),
('Cardiología', 'Electrocardiogramas y estudios cardíacos', '#EF4444', 'heart'),
('Microbiología', 'Cultivos y estudios bacteriológicos', '#8B5CF6', 'microscope'),
('Hematología', 'Estudios de sangre especializados', '#F59E0B', 'droplet');

-- Insertar estudios comunes
INSERT INTO estudios (codigo, nombre, categoria_id, precio, tipo_resultado, activo) VALUES
('HEM001', 'Hemograma Completo', 5, 350.00, 'hl7', true),
('HEM002', 'Glicemia en Ayunas', 1, 200.00, 'hl7', true),
('HEM003', 'Perfil Lipídico', 1, 800.00, 'hl7', true),
('HEM004', 'Creatinina', 1, 250.00, 'hl7', true),
('HEM005', 'Ácido Úrico', 1, 250.00, 'hl7', true),
('IMG001', 'Rayos X de Tórax', 2, 600.00, 'dicom', true),
('IMG002', 'Sonografía Abdominal', 2, 1200.00, 'dicom', true),
('IMG003', 'Sonografía Pélvica', 2, 1200.00, 'dicom', true),
('IMG004', 'Sonografía Obstétrica', 2, 1500.00, 'dicom', true),
('CAR001', 'Electrocardiograma', 3, 500.00, 'pdf', true);

-- Insertar secuencias NCF (ejemplo)
INSERT INTO ncf_secuencias (tipo_comprobante, serie, secuencia_inicio, secuencia_fin, secuencia_actual, fecha_vencimiento, activo) VALUES
('B01', '001', 1, 10000, 1, '2025-12-31', true),
('B02', '001', 1, 5000, 1, '2025-12-31', true);

-- Insertar configuración inicial
INSERT INTO configuracion (clave, valor, tipo, descripcion) VALUES
('empresa_nombre', 'Centro de Diagnóstico Medical Plus', 'texto', 'Nombre del centro médico'),
('empresa_rnc', '000-00000-0', 'texto', 'RNC del centro'),
('empresa_telefono', '809-000-0000', 'texto', 'Teléfono principal'),
('empresa_direccion', 'Calle Principal #123, Santo Domingo', 'texto', 'Dirección física'),
('itbis_porcentaje', '18', 'numero', 'Porcentaje de ITBIS'),
('dias_vencimiento_factura', '30', 'numero', 'Días para vencimiento de facturas'),
('ruta_exportacion_equipos', '/mnt/equipos/export/', 'texto', 'Ruta donde los equipos exportan archivos'),
('sync_intervalo_minutos', '5', 'numero', 'Intervalo de sincronización con nube'),
('email_notificaciones', 'resultados@centrodiagnostico.com', 'texto', 'Email para notificaciones');

-- Crear usuario administrador por defecto (password: admin123)
INSERT INTO usuarios (username, password_hash, nombre, apellido, email, rol, activo) VALUES
('admin', crypt('admin123', gen_salt('bf')), 'Administrador', 'Sistema', 'admin@centrodiagnostico.com', 'admin', true);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de facturas con información completa
CREATE VIEW vista_facturas_completa AS
SELECT 
    f.id,
    f.uuid,
    f.numero_factura,
    f.ncf,
    f.fecha_factura,
    f.total,
    f.estado,
    p.cedula as paciente_cedula,
    CONCAT(p.nombre, ' ', p.apellido) as paciente_nombre,
    p.telefono as paciente_telefono,
    u.username as usuario_emision,
    COALESCE(SUM(pag.monto), 0) as monto_pagado,
    f.total - COALESCE(SUM(pag.monto), 0) as saldo_pendiente
FROM facturas f
JOIN pacientes p ON f.paciente_id = p.id
LEFT JOIN usuarios u ON f.usuario_emision_id = u.id
LEFT JOIN pagos pag ON pag.factura_id = f.id
GROUP BY f.id, p.id, u.id;

-- Vista de órdenes pendientes
CREATE VIEW vista_ordenes_pendientes AS
SELECT 
    o.id,
    o.numero_orden,
    o.fecha_orden,
    o.estado,
    CONCAT(p.nombre, ' ', p.apellido) as paciente,
    p.cedula,
    COUNT(od.id) as total_estudios,
    SUM(CASE WHEN od.resultado_disponible THEN 1 ELSE 0 END) as estudios_completados
FROM ordenes o
JOIN pacientes p ON o.paciente_id = p.id
JOIN orden_detalles od ON od.orden_id = o.id
WHERE o.estado != 'completada' AND o.estado != 'cancelada'
GROUP BY o.id, p.id;

-- ============================================
-- COMENTARIOS
-- ============================================
COMMENT ON TABLE pacientes IS 'Registro de pacientes del centro diagnóstico';
COMMENT ON TABLE estudios IS 'Catálogo de estudios y servicios ofrecidos';
COMMENT ON TABLE ordenes IS 'Órdenes de servicio generadas';
COMMENT ON TABLE facturas IS 'Facturas emitidas con NCF';
COMMENT ON TABLE resultados IS 'Resultados de estudios importados de equipos';
COMMENT ON TABLE ncf_secuencias IS 'Control de secuencias de NCF según DGII';
