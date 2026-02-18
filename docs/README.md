# Sistema de Gestión para Centro Diagnóstico
## Documentación Técnica Completa

---

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Instalación y Configuración](#instalación-y-configuración)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Base de Datos](#base-de-datos)
6. [API Endpoints](#api-endpoints)
7. [Módulo de Facturación](#módulo-de-facturación)
8. [Integración con Equipos Médicos](#integración-con-equipos-médicos)
9. [Sincronización con Nube](#sincronización-con-nube)
10. [Roadmap de Desarrollo](#roadmap-de-desarrollo)

---

## 📖 Descripción General

Sistema híbrido de gestión para centros diagnósticos que integra:
- ✅ Facturación con NCF (República Dominicana)
- ✅ Gestión de pacientes y órdenes
- ✅ Integración automática con equipos médicos (DICOM, HL7, PDF)
- ✅ Sincronización con nube para respaldo
- ✅ Reportes y estadísticas
- ✅ Control de inventario (opcional)

### Características Principales

#### ✅ FASE 1 - IMPLEMENTADA
- Base de datos PostgreSQL completa
- Sistema de facturación con NCF
- Autenticación JWT
- Modelos y servicios base
- API REST para facturación

#### 🔄 FASE 2 - EN DESARROLLO
- Gestión completa de pacientes
- Creación y seguimiento de órdenes
- Integración con equipos (monitor de archivos)

#### 📅 FASE 3 - PLANIFICADA
- Parser HL7 para hematología
- Visor DICOM integrado
- Asociación automática de resultados

#### 📅 FASE 4 - FUTURA
- Sincronización con AWS/Azure
- Dashboard de reportes
- Aplicación móvil

---

## 🏗️ Arquitectura del Sistema

### Stack Tecnológico

**Backend:**
```
- Python 3.9+
- Flask (Framework web)
- PostgreSQL (Base de datos)
- SQLAlchemy (ORM)
- Celery + Redis (Tareas asíncronas)
- JWT (Autenticación)
```

**Frontend (Próxima fase):**
```
- React 18
- TypeScript
- Tailwind CSS
- Axios para API calls
- React Query para estado
```

**Infraestructura:**
```
- Servidor local (aplicación principal)
- AWS S3 / Azure Blob (respaldo de archivos)
- Redis (caché y cola de tareas)
- Nginx (proxy reverso en producción)
```

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (React)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Facturación│ │Pacientes │  │Órdenes   │  │Resultados│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↕ HTTP/REST API
┌─────────────────────────────────────────────────────────────┐
│                 BACKEND (Flask + Python)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  API REST Endpoints                                   │  │
│  │  /api/auth  /api/facturas  /api/pacientes ...       │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Servicios de Negocio                                 │  │
│  │  - FacturacionService                                 │  │
│  │  - IntegracionEquiposService                         │  │
│  │  - SyncService                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Modelos SQLAlchemy (ORM)                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────────┐
│              BASE DE DATOS (PostgreSQL)                      │
│  Pacientes | Órdenes | Facturas | Resultados | ...         │
└─────────────────────────────────────────────────────────────┘
      ↕                                          ↕
┌─────────────────┐                    ┌─────────────────────┐
│  File Watcher   │                    │  Cloud Sync Worker  │
│  (Celery Task)  │                    │  (Celery Task)      │
│                 │                    │                     │
│  Monitorea:     │                    │  Sincroniza con:    │
│  /mnt/equipos/  │                    │  AWS S3 / Azure     │
└─────────────────┘                    └─────────────────────┘
```

---

## 🚀 Instalación y Configuración

### Requisitos Previos

```bash
# Sistema operativo
- Ubuntu 20.04+ / Windows 10+ / macOS 10.15+

# Software
- Python 3.9+
- PostgreSQL 13+
- Redis 6+
- Node.js 16+ (para frontend)
```

### Paso 1: Clonar el Repositorio

```bash
git clone <tu-repositorio>
cd centro-diagnostico
```

### Paso 2: Configurar Base de Datos

```bash
# Crear base de datos PostgreSQL
sudo -u postgres psql

postgres=# CREATE DATABASE centro_diagnostico;
postgres=# CREATE USER centro_user WITH PASSWORD 'tu_password_seguro';
postgres=# GRANT ALL PRIVILEGES ON DATABASE centro_diagnostico TO centro_user;
postgres=# \q

# Ejecutar el schema
psql -U centro_user -d centro_diagnostico -f database/schema.sql
```

### Paso 3: Instalar Dependencias Python

```bash
cd backend

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt
```

### Paso 4: Configurar Variables de Entorno

Crear archivo `.env` en `/backend/`:

```bash
# Base de datos
DATABASE_URL=postgresql://centro_user:tu_password@localhost:5432/centro_diagnostico

# Seguridad
SECRET_KEY=tu-secret-key-muy-seguro-aqui
JWT_SECRET_KEY=otro-secret-key-para-jwt

# Rutas
UPLOAD_FOLDER=./uploads
EQUIPOS_EXPORT_PATH=/mnt/equipos/export

# Redis
REDIS_URL=redis://localhost:6379/0

# Nube (opcional)
CLOUD_SYNC_ENABLED=false
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_S3_BUCKET=centro-diagnostico-backup

# Email (opcional)
MAIL_USERNAME=tu-email@gmail.com
MAIL_PASSWORD=tu-app-password

# Entorno
FLASK_ENV=development
```

### Paso 5: Inicializar la Base de Datos

```bash
# Ejecutar migraciones (si usas Flask-Migrate)
flask db upgrade

# O ejecutar el schema directamente como en Paso 2
```

### Paso 6: Ejecutar el Backend

```bash
# Desarrollo
python app.py

# El servidor estará disponible en http://localhost:5000
```

### Paso 7: Ejecutar Workers de Celery (Opcional)

```bash
# Terminal 1: Worker principal
celery -A app.celery worker --loglevel=info

# Terminal 2: Beat scheduler (para tareas programadas)
celery -A app.celery beat --loglevel=info
```

---

## 📁 Estructura del Proyecto

```
centro-diagnostico/
│
├── backend/
│   ├── app/
│   │   ├── models/           # Modelos de base de datos
│   │   │   └── __init__.py   # Todos los modelos SQLAlchemy
│   │   ├── routes/           # Endpoints de API
│   │   │   ├── auth.py       # Autenticación
│   │   │   ├── facturas.py   # Facturación ✅
│   │   │   ├── pacientes.py  # Gestión de pacientes
│   │   │   ├── ordenes.py    # Órdenes de servicio
│   │   │   ├── estudios.py   # Catálogo de estudios
│   │   │   ├── resultados.py # Manejo de resultados
│   │   │   └── reportes.py   # Reportes y estadísticas
│   │   ├── services/         # Lógica de negocio
│   │   │   ├── facturacion.py ✅
│   │   │   ├── integracion_equipos.py
│   │   │   ├── sync_cloud.py
│   │   │   └── reportes.py
│   │   └── utils/            # Utilidades
│   │       ├── parsers.py    # Parsers HL7, DICOM, PDF
│   │       ├── validators.py # Validaciones
│   │       └── helpers.py    # Funciones auxiliares
│   ├── uploads/              # Archivos subidos
│   │   ├── resultados/       # Resultados de estudios
│   │   └── temp/             # Archivos temporales
│   ├── app.py               # Aplicación Flask principal
│   ├── config.py            # Configuraciones ✅
│   └── requirements.txt     # Dependencias ✅
│
├── database/
│   ├── schema.sql           # Schema completo ✅
│   ├── migrations/          # Migraciones
│   └── seeds/               # Datos de prueba
│
├── frontend/                # (Próxima fase)
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── utils/
│   └── package.json
│
├── docs/
│   ├── README.md           # Este archivo ✅
│   ├── API.md              # Documentación de API
│   ├── DEPLOYMENT.md       # Guía de despliegue
│   └── USER_MANUAL.md      # Manual de usuario
│
└── docker/                 # (Futuro)
    ├── Dockerfile
    └── docker-compose.yml
```

---

## 🗄️ Base de Datos

### Tablas Principales

#### 1. **pacientes**
Información de los pacientes del centro.

**Campos principales:**
- `cedula` (único, indexado)
- `nombre`, `apellido`
- `fecha_nacimiento`, `sexo`
- `telefono`, `celular`, `email`
- `seguro_medico`, `numero_poliza`
- `alergias`, `notas_medicas`

#### 2. **estudios**
Catálogo de estudios/servicios ofrecidos.

**Campos principales:**
- `codigo` (único, ej: HEM001)
- `nombre` (ej: Hemograma Completo)
- `categoria_id`
- `precio`, `costo`
- `tipo_resultado` (pdf, dicom, hl7)
- `equipo_asignado`

#### 3. **ordenes**
Órdenes de servicio generadas.

**Campos principales:**
- `numero_orden` (formato: ORD-YYMM-00001)
- `paciente_id`
- `medico_referente`
- `fecha_orden`, `fecha_cita`
- `estado` (pendiente, en_proceso, completada, cancelada)
- `prioridad` (normal, urgente, stat)

#### 4. **orden_detalles**
Estudios solicitados en cada orden.

**Relación:** orden -> orden_detalles -> estudio

#### 5. **facturas** ⭐
Facturas emitidas con NCF.

**Campos principales:**
- `numero_factura` (FAC-YYYY-000001)
- `ncf` (B01-001-00000001)
- `tipo_comprobante` (B01, B02, B14, B15)
- `paciente_id`, `orden_id`
- `subtotal`, `descuento`, `itbis`, `total`
- `estado` (pendiente, pagada, parcial, anulada)
- `forma_pago`

#### 6. **pagos**
Pagos registrados para facturas.

**Campos principales:**
- `factura_id`
- `monto`, `metodo_pago`
- `referencia`, `banco`
- `usuario_recibe_id`

#### 7. **resultados**
Resultados de estudios importados.

**Campos principales:**
- `orden_detalle_id`
- `tipo_archivo` (pdf, dicom, hl7)
- `ruta_archivo`, `ruta_nube`
- `hash_archivo` (integridad)
- `datos_hl7`, `datos_dicom` (JSON)
- `estado_validacion`

#### 8. **ncf_secuencias**
Control de secuencias de NCF según DGII.

**Campos principales:**
- `tipo_comprobante`
- `serie`
- `secuencia_inicio`, `secuencia_fin`, `secuencia_actual`
- `fecha_vencimiento`

### Relaciones Principales

```
pacientes
    ↓ (1:N)
ordenes
    ↓ (1:N)
orden_detalles
    ↓ (1:N)
resultados

pacientes
    ↓ (1:N)
facturas
    ↓ (1:N)
factura_detalles

facturas
    ↓ (1:N)
pagos
```

### Índices Importantes

```sql
-- Búsquedas rápidas de pacientes
CREATE INDEX idx_pacientes_cedula ON pacientes(cedula);
CREATE INDEX idx_pacientes_nombre ON pacientes(nombre, apellido);

-- Búsquedas de órdenes
CREATE INDEX idx_ordenes_fecha ON ordenes(fecha_orden);
CREATE INDEX idx_ordenes_estado ON ordenes(estado);

-- Búsquedas de facturas
CREATE INDEX idx_facturas_ncf ON facturas(ncf);
CREATE INDEX idx_facturas_fecha ON facturas(fecha_factura);
CREATE INDEX idx_facturas_estado ON facturas(estado);
```

---

## 🔌 API Endpoints

### Base URL
```
http://localhost:5000/api
```

### Autenticación

Todos los endpoints (excepto `/auth/login`) requieren token JWT en el header:
```
Authorization: Bearer <token>
```

#### POST `/auth/login`
Autenticar usuario y obtener tokens.

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "usuario": {
    "id": 1,
    "username": "admin",
    "nombre": "Administrador",
    "rol": "admin"
  }
}
```

---

### Facturas

#### GET `/facturas/`
Listar facturas con filtros opcionales.

**Query params:**
- `page` (default: 1)
- `per_page` (default: 20)
- `estado` (pendiente, pagada, parcial, anulada)
- `paciente_id`
- `fecha_desde` (ISO format)
- `fecha_hasta` (ISO format)

**Response:**
```json
{
  "facturas": [...],
  "total": 150,
  "pages": 8,
  "current_page": 1
}
```

#### GET `/facturas/<id>`
Obtener detalles completos de una factura.

**Response:**
```json
{
  "id": 1,
  "numero_factura": "FAC-2025-000001",
  "ncf": "B02-001-00000001",
  "fecha_factura": "2025-02-14T10:30:00",
  "total": 2500.00,
  "estado": "pagada",
  "paciente": {...},
  "detalles": [...],
  "pagos": [...],
  "saldo": 0
}
```

#### POST `/facturas/crear-desde-orden/<orden_id>`
Crear factura desde una orden existente.

**Request:**
```json
{
  "tipo_comprobante": "B02",
  "forma_pago": "efectivo",
  "incluir_itbis": false,
  "descuento_global": 0,
  "notas": "Pago inmediato"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Factura creada exitosamente",
  "factura": {...}
}
```

#### POST `/facturas/<id>/pagar`
Registrar un pago para una factura.

**Request:**
```json
{
  "monto": 1500.00,
  "metodo_pago": "tarjeta",
  "referencia": "VISA-1234",
  "banco": "Banco Popular",
  "notas": "Pago parcial"
}
```

#### POST `/facturas/<id>/anular`
Anular una factura.

**Request:**
```json
{
  "motivo": "Error en monto, se emitirá nueva factura"
}
```

#### GET `/facturas/estado-cuenta/<paciente_id>`
Obtener estado de cuenta de un paciente.

**Response:**
```json
{
  "total_facturado": 15000.00,
  "total_pagado": 12000.00,
  "saldo_pendiente": 3000.00,
  "facturas_pendientes": [...]
}
```

#### GET `/facturas/reporte-ventas`
Generar reporte de ventas.

**Query params:**
- `fecha_inicio` (required, ISO format)
- `fecha_fin` (required, ISO format)

**Response:**
```json
{
  "fecha_inicio": "2025-02-01",
  "fecha_fin": "2025-02-14",
  "total_ventas": 45000.00,
  "total_itbis": 8100.00,
  "cantidad_facturas": 85,
  "ventas_por_metodo": {
    "efectivo": 20000.00,
    "tarjeta": 15000.00,
    "transferencia": 10000.00
  }
}
```

---

## 💰 Módulo de Facturación

### Características Implementadas

✅ **Generación automática de NCF**
- Maneja secuencias múltiples
- Valida fechas de vencimiento
- Incremento automático

✅ **Cálculo automático de ITBIS**
- Configurable desde base de datos
- Aplicación proporcional por item

✅ **Múltiples métodos de pago**
- Efectivo, tarjeta, transferencia, cheque, seguro
- Pagos parciales
- Historial completo

✅ **Control de estados**
- Pendiente → Parcial → Pagada
- Anulación con motivo
- Validaciones de integridad

✅ **Reportes financieros**
- Ventas por período
- Estado de cuenta por paciente
- Cuentas por cobrar

### Flujo de Facturación

```
1. Crear Orden de Servicio
   ↓
2. Agregar Estudios a la Orden
   ↓
3. Completar Estudios
   ↓
4. Generar Factura desde Orden
   - Se obtiene NCF automáticamente
   - Se calculan totales e impuestos
   - Se crea factura en estado "pendiente"
   ↓
5. Registrar Pago(s)
   - Pago total → estado "pagada"
   - Pago parcial → estado "parcial"
   ↓
6. Imprimir/Enviar Factura
```

### Ejemplo de Uso

```python
from app.services.facturacion import FacturacionService

# Crear factura desde orden
factura = FacturacionService.crear_factura_desde_orden(
    orden_id=123,
    datos_factura={
        'tipo_comprobante': 'B02',  # Factura de consumo
        'forma_pago': 'tarjeta',
        'incluir_itbis': False,     # No incluir impuesto
        'descuento_global': 0,
        'notas': 'Cliente frecuente',
        'usuario_id': 1
    }
)

# Registrar pago
pago = FacturacionService.registrar_pago(
    factura_id=factura.id,
    datos_pago={
        'monto': 2500.00,
        'metodo_pago': 'efectivo',
        'referencia': '',
        'usuario_id': 1
    }
)
```

### NCF (Números de Comprobante Fiscal)

El sistema maneja los siguientes tipos de NCF según la DGII:

| Tipo | Descripción | Uso |
|------|-------------|-----|
| B01  | Facturas de Crédito Fiscal | Con derecho a crédito fiscal |
| B02  | Facturas de Consumo | Sin derecho a crédito |
| B14  | Nota de Crédito | Devoluciones o descuentos |
| B15  | Nota de Débito | Cargos adicionales |
| B16  | Comprobante de Compras | Compras a proveedores |

**Formato:** `B02-001-00000001`
- `B02`: Tipo de comprobante
- `001`: Serie
- `00000001`: Secuencia (8 dígitos)

---

## 🔧 Integración con Equipos Médicos

### Tipos de Archivos Soportados

#### 1. **HL7 (Health Level 7)**
Usado por equipos de laboratorio (hematología, química).

**Ejemplo de mensaje HL7:**
```
MSH|^~\&|LAB|HOSPITAL|RESULTS|LIS|20250214103000||ORU^R01|123456|P|2.5
PID|1||12345678||DOE^JOHN||19800101|M
OBR|1||987654|WBC|||20250214103000
OBX|1|NM|WBC||8.5|10^3/uL|4.0-11.0|N|||F
OBX|2|NM|RBC||4.8|10^6/uL|4.2-5.9|N|||F
```

**Campos principales:**
- PID: Información del paciente
- OBR: Información de la orden
- OBX: Resultados de pruebas individuales

#### 2. **DICOM (Digital Imaging and Communications in Medicine)**
Usado por equipos de imagen (rayos X, sonografía).

**Metadatos importantes:**
- Patient ID
- Study Date
- Modality (XR, US, CT, MRI)
- Series Description
- Image data (píxeles)

#### 3. **PDF**
Reportes generados por equipos que no exportan en formatos estándar.

### Configuración de Carpetas

El sistema monitorea carpetas específicas donde los equipos exportan:

```
/mnt/equipos/export/
├── hematologia/     # Archivos HL7
├── quimica/         # Archivos HL7
├── rayos-x/         # Archivos DICOM
├── sonografia/      # Archivos DICOM
└── otros/           # PDFs y otros formatos
```

### Proceso de Integración (Próxima Fase)

```python
# Servicio de integración (a implementar)
class IntegracionEquiposService:
    
    @staticmethod
    def iniciar_monitor():
        """Inicia el monitoreo de carpetas"""
        observer = Observer()
        handler = EquipoFileHandler()
        observer.schedule(handler, EQUIPOS_PATH, recursive=True)
        observer.start()
    
    @staticmethod
    def procesar_archivo_hl7(ruta):
        """Parsea y procesa archivo HL7"""
        with open(ruta, 'r') as f:
            mensaje = hl7.parse(f.read())
        
        # Extraer datos del paciente
        cedula = mensaje.segment('PID')[3]
        
        # Buscar orden correspondiente
        orden = buscar_orden_por_cedula(cedula)
        
        # Crear resultado
        resultado = crear_resultado_desde_hl7(mensaje, orden)
        
        return resultado
    
    @staticmethod
    def procesar_archivo_dicom(ruta):
        """Procesa archivo DICOM"""
        ds = pydicom.dcmread(ruta)
        
        # Extraer metadatos
        patient_id = ds.PatientID
        study_date = ds.StudyDate
        modality = ds.Modality
        
        # Asociar con orden
        # ...
```

---

## ☁️ Sincronización con Nube

### Configuración

El sistema puede sincronizar archivos con AWS S3 o Azure Blob Storage.

**Activar en `.env`:**
```bash
CLOUD_SYNC_ENABLED=true
CLOUD_PROVIDER=aws
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_S3_BUCKET=centro-diagnostico-backup
AWS_REGION=us-east-1
```

### Estrategia de Sincronización

#### Archivos a Sincronizar
- ✅ Resultados de estudios (PDF, DICOM)
- ✅ Imágenes de documentos
- ❌ Base de datos (respaldo separado)
- ❌ Archivos temporales

#### Frecuencia
- **Tiempo real:** Archivos críticos (resultados)
- **Cada 5 minutos:** Archivos no críticos
- **Nightly:** Respaldo completo de base de datos

### Implementación (Celery Task)

```python
@celery.task
def sync_archivo_a_nube(archivo_id):
    """Sincroniza un archivo con la nube"""
    resultado = Resultado.query.get(archivo_id)
    
    if not resultado or not resultado.ruta_archivo:
        return
    
    # Subir a S3
    s3_client = boto3.client('s3')
    
    with open(resultado.ruta_archivo, 'rb') as f:
        s3_key = f"resultados/{resultado.uuid}/{resultado.nombre_archivo}"
        
        s3_client.upload_fileobj(
            f,
            AWS_S3_BUCKET,
            s3_key,
            ExtraArgs={'ServerSideEncryption': 'AES256'}
        )
    
    # Actualizar registro
    resultado.ruta_nube = f"s3://{AWS_S3_BUCKET}/{s3_key}"
    db.session.commit()
    
    return resultado.id
```

---

## 🗓️ Roadmap de Desarrollo

### ✅ FASE 1 - COMPLETADA (Semanas 1-2)
- [x] Diseño de base de datos
- [x] Schema PostgreSQL con funciones
- [x] Modelos SQLAlchemy
- [x] Configuración del proyecto
- [x] Sistema de autenticación JWT
- [x] **Módulo de facturación completo**
  - [x] Generación de NCF
  - [x] Cálculo de impuestos
  - [x] Registro de pagos
  - [x] API endpoints

### 🔄 FASE 2 - EN DESARROLLO (Semanas 3-4)
- [ ] Rutas API completas
  - [ ] Gestión de pacientes (CRUD)
  - [ ] Gestión de estudios (CRUD)
  - [ ] Gestión de órdenes (CRUD)
- [ ] Monitor básico de archivos
  - [ ] Watchdog para carpetas
  - [ ] Detección de nuevos archivos
  - [ ] Asociación manual con órdenes
- [ ] Frontend básico (React)
  - [ ] Dashboard principal
  - [ ] Módulo de facturación
  - [ ] Registro de pacientes
  - [ ] Creación de órdenes

### 📅 FASE 3 - PLANIFICADA (Semanas 5-7)
- [ ] Parsers automáticos
  - [ ] Parser HL7 completo
  - [ ] Extractor de datos PDF
  - [ ] Metadatos DICOM
- [ ] Visor de resultados
  - [ ] Visor DICOM integrado
  - [ ] Vista previa de PDFs
  - [ ] Interpretación de HL7
- [ ] Asociación automática
  - [ ] Match por cédula/ID
  - [ ] Match por fecha y estudio
  - [ ] Notificaciones automáticas
- [ ] Sistema de reportes
  - [ ] Dashboard estadístico
  - [ ] Exportación a Excel
  - [ ] Gráficos de tendencias

### 📅 FASE 4 - FUTURA (Semanas 8+)
- [ ] Sincronización con nube
  - [ ] Worker de sincronización
  - [ ] Respaldo automático
  - [ ] Recuperación de desastres
- [ ] Optimizaciones
  - [ ] Caché con Redis
  - [ ] Búsqueda full-text
  - [ ] Indexación mejorada
- [ ] Características avanzadas
  - [ ] Aplicación móvil (React Native)
  - [ ] Portal para pacientes
  - [ ] Integración con seguros
  - [ ] Inventario automatizado
  - [ ] Citas en línea

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Instalar dependencias de testing
pip install pytest pytest-flask

# Ejecutar todos los tests
pytest

# Con coverage
pytest --cov=app

# Tests específicos
pytest tests/test_facturacion.py
```

### Ejemplo de Test

```python
def test_crear_factura_desde_orden(client, auth_header):
    """Test de creación de factura"""
    
    # Crear orden de prueba
    orden = crear_orden_prueba()
    
    # Crear factura
    response = client.post(
        f'/api/facturas/crear-desde-orden/{orden.id}',
        headers=auth_header,
        json={
            'tipo_comprobante': 'B02',
            'forma_pago': 'efectivo'
        }
    )
    
    assert response.status_code == 201
    assert 'factura' in response.json
    assert response.json['factura']['numero_factura'].startswith('FAC-')
```

---

## 🚀 Despliegue en Producción

### Usando Docker (Recomendado)

```bash
# Build
docker-compose build

# Run
docker-compose up -d
```

### Usando Servidor Tradicional

```bash
# Instalar Nginx
sudo apt install nginx

# Configurar Nginx como proxy reverso
# /etc/nginx/sites-available/centro-diagnostico

server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Ejecutar con Gunicorn
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Configuración de Producción

```bash
# Variables de entorno de producción
FLASK_ENV=production
DATABASE_URL=postgresql://user:pass@prod-db:5432/centro_diagnostico
CLOUD_SYNC_ENABLED=true

# Desactivar debug
DEBUG=False
```

---

## 📞 Soporte y Contacto

Para dudas, sugerencias o reportar problemas:

- **Email:** soporte@centrodiagnostico.com
- **Documentación:** https://docs.centrodiagnostico.com
- **Issues:** GitHub Issues

---

## 📄 Licencia

Propietario - Todos los derechos reservados.
Este sistema es propietario y confidencial.

---

## 🎯 Próximos Pasos Inmediatos

1. **Implementar rutas de pacientes y órdenes**
2. **Crear el frontend básico en React**
3. **Configurar el monitor de archivos (Watchdog)**
4. **Probar el flujo completo: Orden → Factura → Pago**

¿Por dónde te gustaría continuar?
