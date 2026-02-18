# ?? Integración con Máquinas de Laboratorio

## Configuración de Máquinas para Enviar Resultados al VPS

### ?? URL Base del Servidor
```
http://192.9.135.84:5000/api/maquinas
```

### ?? Endpoints Disponibles

#### 1. Recibir Resultados HL7
**URL:** `POST http://192.9.135.84:5000/api/maquinas/recibir-hl7`

**Body (JSON):**
```json
{
  "paciente_id": 123,
  "orden_id": 456,
  "mensaje_hl7": "MSH|^~\\&|LAB|HOSPITAL|...",
  "valores": {
    "hemoglobina": {
      "valor": 14.5,
      "unidad": "g/dL",
      "referencia": "12-16 g/dL"
    }
  }
}
```

#### 2. Recibir Imágenes DICOM
**URL:** `POST http://192.9.135.84:5000/api/maquinas/recibir-dicom`

**Body (multipart/form-data):**
```
archivo: [archivo DICOM]
paciente_id: 123
orden_id: 456
```

#### 3. Recibir Resultados JSON (Genérico)
**URL:** `POST http://192.9.135.84:5000/api/maquinas/recibir-json`

**Body (JSON):**
```json
{
  "paciente_id": 123,
  "orden_id": 456,
  "tipo_estudio": "hemograma",
  "valores": {
    "hemoglobina": {"valor": 14.5, "unidad": "g/dL"},
    "leucocitos": {"valor": 7500, "unidad": "cel/µL"}
  }
}
```

### ?? Configuración en las Máquinas

#### Sysmex (Hematología)
1. Ir a Settings ? Network ? HTTP POST
2. URL: `http://192.9.135.84:5000/api/maquinas/recibir-json`
3. Format: JSON
4. Enable: Yes

#### Roche Cobas (Química Clínica)
1. Menu ? Configuration ? Interfaces
2. Type: HTTP
3. URL: `http://192.9.135.84:5000/api/maquinas/recibir-hl7`
4. Protocol: HL7 v2.5

#### GE RAD (Radiología - DICOM)
1. PACS Configuration
2. DICOM Destination:
   - AE Title: CENTRO_DIAG
   - IP: 192.9.135.84
   - Port: 11112 (usar servicio DICOM separado)

### ?? Probar Integración
```bash
# Probar endpoint desde la máquina de laboratorio
curl -X POST http://192.9.135.84:5000/api/maquinas/recibir-json \
  -H "Content-Type: application/json" \
  -d '{
    "paciente_id": 1,
    "orden_id": 1,
    "tipo_estudio": "hemograma",
    "valores": {
      "hemoglobina": {"valor": 14.5, "unidad": "g/dL"}
    }
  }'
```

### ?? Seguridad
- Firewall: Abrir puerto 5000 solo para IPs del laboratorio
- VPN: Conectar máquinas vía VPN si están en otra ubicación
- API Key: Agregar autenticación por clave API (próxima versión)

