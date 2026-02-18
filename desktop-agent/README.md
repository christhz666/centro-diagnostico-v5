# Desktop Agent - Integración de Equipos Médicos

Agente Python para integración de equipos médicos de laboratorio con el servidor central del Centro Diagnóstico.

## Descripción

Este agente se instala en las PCs de laboratorio donde están conectados los equipos médicos (hematología, química, sonografía, rayos X, etc.) y se encarga de:

1. **Recolectar datos** de múltiples fuentes:
   - Puertos seriales (RS-232/USB) para equipos de laboratorio
   - Carpetas monitoreadas para archivos HL7/DICOM
   - Red DICOM para imágenes médicas

2. **Parsear y transformar** los datos recibidos a un formato estándar

3. **Enviar automáticamente** los resultados al servidor central vía API REST

## Requisitos

- Python 3.8 o superior
- Windows 10/11, Linux o macOS
- Acceso de red al servidor central (`192.9.135.84:5000`)
- Permisos de administrador (para acceso a puertos seriales)

## Instalación

### 1. Instalar Python
Descargar e instalar Python desde https://www.python.org/downloads/

### 2. Clonar o copiar el agente
```bash
git clone <repositorio>
cd desktop-agent
```

O simplemente copiar la carpeta `desktop-agent/` a la PC de laboratorio.

### 3. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 4. Configurar el agente
Copiar el archivo de ejemplo y editarlo:
```bash
cp config.example.json config.json
```

Editar `config.json` con los parámetros de tu estación:
- `server_url`: URL del servidor central
- `station_name`: Nombre identificativo de esta PC
- `api_key`: Clave de autenticación (si aplica)
- Configurar los collectors según los equipos conectados

### 5. Ejecutar el agente
```bash
python agent.py
```

O para ejecutar en segundo plano:
```bash
# Windows
pythonw agent.py

# Linux/macOS
nohup python agent.py &
```

## Configuración

### Ejemplo básico (config.json)

```json
{
  "server_url": "http://192.9.135.84:5000/api",
  "station_name": "PC-LABORATORIO-01",
  "api_key": "",
  "collectors": {
    "serial": {
      "enabled": true,
      "ports": [
        {
          "port": "COM3",
          "baud_rate": 9600,
          "equipment_type": "hematologia",
          "equipment_name": "Sysmex XN-1000"
        }
      ]
    },
    "file_watcher": {
      "enabled": true,
      "watch_dirs": [
        {
          "path": "C:/EquiposExport/hematologia",
          "file_type": "hl7",
          "equipment_type": "hematologia"
        }
      ]
    },
    "dicom_listener": {
      "enabled": false,
      "ae_title": "CENTRO_DIAG",
      "port": 11112
    }
  },
  "upload_interval_seconds": 10,
  "retry_on_failure": true,
  "max_retries": 3
}
```

### Collectors disponibles

#### Serial Collector
Lee datos de equipos conectados por puerto serial (RS-232/USB).

Parámetros:
- `port`: Nombre del puerto (COM1, COM2, /dev/ttyUSB0, etc.)
- `baud_rate`: Velocidad de comunicación (típicamente 9600, 19200, 38400)
- `equipment_type`: Tipo de equipo (hematologia, quimica, orina, etc.)
- `equipment_name`: Nombre descriptivo del equipo

#### File Watcher
Monitorea carpetas para detectar archivos nuevos exportados por los equipos.

Parámetros:
- `path`: Ruta de la carpeta a monitorear
- `file_type`: Tipo de archivo (hl7, dicom, pdf)
- `equipment_type`: Tipo de equipo que genera los archivos

#### DICOM Listener
Actúa como servidor DICOM para recibir imágenes de sonografía/rayos X.

Parámetros:
- `ae_title`: Application Entity Title del receptor
- `port`: Puerto de escucha DICOM (típicamente 11112)

## Tipos de equipos soportados

- **hematologia**: Contadores hematológicos (ej: Sysmex, Mindray)
- **quimica**: Analizadores de química clínica (ej: Roche Cobas, Beckman)
- **orina**: Analizadores de orina
- **coagulacion**: Equipos de coagulación
- **inmunologia**: Analizadores inmunológicos
- **microbiologia**: Equipos de microbiología
- **sonografia**: Equipos de ultrasonido (DICOM)
- **rayos_x**: Equipos de rayos X (DICOM)

## Formatos soportados

### HL7 v2.5
Protocolo estándar para intercambio de información en laboratorios clínicos.

El parser extrae:
- Identificación del paciente (segmento PID)
- Datos de la orden (segmento ORC/OBR)
- Resultados (segmentos OBX)

### DICOM
Protocolo estándar para imágenes médicas.

El parser extrae:
- Patient ID
- Patient Name
- Study Date
- Modality
- Series Description

## Logs

El agente genera logs en el archivo `agent.log` en el mismo directorio.

Niveles de log:
- `INFO`: Operaciones normales
- `WARNING`: Advertencias (ej: reintento de envío)
- `ERROR`: Errores (ej: equipo desconectado, servidor no disponible)

## Solución de problemas

### El agente no detecta el puerto serial
- Verificar que el equipo esté conectado y encendido
- Verificar el nombre del puerto en el Administrador de Dispositivos (Windows) o `ls /dev/tty*` (Linux)
- Verificar que ningún otro programa esté usando el puerto
- Ejecutar el agente con permisos de administrador

### No se reciben datos del equipo
- Verificar la configuración del equipo (protocolo, velocidad, formato de salida)
- Revisar el log del agente para ver si hay errores de comunicación
- Probar con un monitor de puerto serial (ej: PuTTY, RealTerm) para verificar que el equipo envía datos

### Error al enviar al servidor
- Verificar la conectividad de red: `ping 192.9.135.84`
- Verificar que el servidor esté en ejecución
- Revisar la configuración de firewall (debe permitir tráfico al puerto 5000)
- Verificar el `server_url` en config.json

### Archivos DICOM no se procesan
- Verificar que los archivos sean DICOM válidos
- Verificar permisos de lectura en la carpeta
- Revisar el log para errores de parseo

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Desktop Agent                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────┐    ┌────────────────┐          │
│  │ Serial         │    │ File           │          │
│  │ Collector      │    │ Watcher        │          │
│  └────────┬───────┘    └────────┬───────┘          │
│           │                     │                   │
│           └──────────┬──────────┘                   │
│                      │                              │
│              ┌───────▼───────┐                      │
│              │  Queue        │                      │
│              └───────┬───────┘                      │
│                      │                              │
│              ┌───────▼───────┐                      │
│              │  Parsers      │                      │
│              │  (HL7/DICOM)  │                      │
│              └───────┬───────┘                      │
│                      │                              │
│              ┌───────▼───────┐                      │
│              │  Uploader     │                      │
│              └───────┬───────┘                      │
└──────────────────────┼──────────────────────────────┘
                       │
                       │ HTTPS/API
                       │
              ┌────────▼─────────┐
              │  Servidor        │
              │  Central         │
              │  (192.9.135.84)  │
              └──────────────────┘
```

## Seguridad

- Los datos se envían al servidor vía HTTPS (cuando está configurado)
- Autenticación por API key
- Los archivos procesados se mueven a una carpeta `procesados/` para evitar reprocesamiento
- Los datos sensibles no se guardan en logs

## Mantenimiento

### Actualizar el agente
```bash
git pull
pip install -r requirements.txt --upgrade
```

### Ver logs en tiempo real
```bash
# Windows
type agent.log

# Linux/macOS
tail -f agent.log
```

### Reiniciar el agente
```bash
# Detener el proceso actual (Ctrl+C o buscar el PID)
# Luego reiniciar
python agent.py
```

## Soporte

Para soporte técnico, contactar al administrador del sistema o revisar la documentación del servidor en `docs/INTEGRACION_MAQUINAS.md`.
