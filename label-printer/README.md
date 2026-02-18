# Label Printer - Centro Diagnóstico v5

## Descripción

Aplicación de escritorio para impresión de etiquetas adhesivas para frascos/tubos de laboratorio.

## Características

- **Interfaz gráfica bonita y fácil de usar**
- **Búsqueda automática** por ID de paciente
- **Auto-agrega prefijo L** para estudios de laboratorio
- **Impresión de etiquetas** con código de barras
- **Solo muestra estudios de laboratorio** (hematología, química, orina, etc.)
- **Timeout automático** de 30 segundos para volver a la pantalla de búsqueda
- **Configuración flexible** de impresora y tamaño de etiquetas

## Uso

### Instalación

1. Ejecutar `Setup_LabelPrinter.exe`
2. Seguir las instrucciones del instalador
3. Configurar la URL del servidor durante la instalación

### Operación

1. La aplicación se inicia automáticamente
2. Ingresar el **número del paciente** (solo números, ej: `1328`)
3. El sistema busca automáticamente con prefijo `L` (busca `L1328`)
4. Se muestran los estudios de laboratorio pendientes
5. Presionar:
   - **0** para imprimir TODAS las etiquetas
   - **1-9** para imprimir una etiqueta específica
6. Después de imprimir, regresa automáticamente en 30 segundos

### Configuración

Hacer clic en el ícono de engranaje (⚙) para configurar:

- **URL del Servidor**: Dirección del servidor backend
- **Modelo de Impresora**: Seleccionar de la lista de impresoras compatibles
  - Zebra GK420
  - Zebra ZD220
  - Zebra ZD420
  - Brother QL-800
  - Brother QL-820NWB
  - DYMO LabelWriter
  - TSC TTP-225
  - Godex G500
  - Impresora genérica térmica
  - Impresora genérica USB
- **Tamaño de Etiqueta**: Ancho y alto en milímetros

## Contenido de las Etiquetas

Cada etiqueta incluye:

- Nombre completo del paciente
- Cédula
- ID del resultado (ej: `L1328`)
- Nombre del estudio
- Fecha
- Código de barras con el ID

## Desarrollo

### Requisitos

```bash
pip install -r requirements.txt
```

### Ejecutar en modo desarrollo

```bash
python main.py
```

### Compilar a ejecutable

```bash
build.bat
```

Genera `dist\LabelPrinter.exe`

### Crear instalador

Usar Inno Setup con `installer.iss`

## Notas Técnicas

- **Solo estudios de laboratorio**: La aplicación filtra automáticamente y solo muestra estudios de las categorías:
  - Hematología
  - Química
  - Orina
  - Coagulación
  - Inmunología
  - Microbiología
  - Laboratorio Clínico

- **Estado pendiente**: Solo se muestran estudios con estado `pendiente`

- **Formato de ID**: 
  - El usuario ingresa: `1328`
  - El sistema busca: `L1328`
  - Compatible con formato antiguo: `MUE-20260218-00001`

## Soporte

Para problemas o preguntas, contactar al administrador del sistema.
