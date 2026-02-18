# Desktop App - Centro Diagnóstico v5

## Descripción

Aplicación de escritorio basada en Electron que envuelve el frontend React del sistema Centro Diagnóstico v5.

## Características

- **Aplicación nativa de escritorio** para Windows, macOS y Linux
- **Acceso directo desde el escritorio** sin necesidad de abrir navegador
- **Menú de aplicación** con atajos de teclado
- **Pantalla completa** (F11)
- **Zoom** (Ctrl +/-)
- **DevTools** integrados (F12)
- **Página de error personalizada** cuando no hay conexión al servidor
- **Prevención de múltiples instancias**
- **Auto-actualización** (puede implementarse en futuras versiones)

## Instalación para Usuarios

1. Descargar el instalador apropiado:
   - **Windows**: `Centro Diagnóstico Setup 5.0.0.exe`
   - **macOS**: `Centro Diagnóstico-5.0.0.dmg`
   - **Linux**: `Centro Diagnóstico-5.0.0.AppImage`

2. Ejecutar el instalador y seguir las instrucciones

3. La aplicación estará disponible en:
   - Menú Inicio (Windows)
   - Carpeta de Aplicaciones (macOS)
   - Menú de aplicaciones (Linux)

## Configuración

La aplicación se conecta al servidor en `http://192.9.135.84:5000` por defecto.

Para cambiar la URL del servidor, editar el archivo `main.js` y modificar:

```javascript
const SERVER_URL = 'http://TU_SERVIDOR:5000';
```

## Desarrollo

### Prerrequisitos

- Node.js 16 o superior
- npm 8 o superior

### Instalación de Dependencias

```bash
npm install
```

### Ejecutar en Modo Desarrollo

```bash
npm start
```

Esto abrirá la aplicación Electron conectándose al servidor configurado.

### Compilar para Producción

#### Windows

```bash
npm run build:win
```

o ejecutar `build.bat`

Genera: `dist/Centro Diagnóstico Setup 5.0.0.exe`

#### macOS

```bash
npm run build:mac
```

Genera: `dist/Centro Diagnóstico-5.0.0.dmg`

#### Linux

```bash
npm run build:linux
```

Genera: `dist/Centro Diagnóstico-5.0.0.AppImage`

#### Todas las Plataformas

```bash
npm run build
```

### Estructura de Archivos

```
desktop-app/
├── main.js           # Proceso principal de Electron
├── preload.js        # Script de precarga (bridge seguro)
├── package.json      # Configuración de npm y electron-builder
├── build.bat         # Script de build para Windows
├── assets/           # Iconos y recursos
│   ├── icon.ico      # Icono para Windows
│   ├── icon.icns     # Icono para macOS
│   └── icon.png      # Icono para Linux
└── README.md         # Este archivo
```

## Características Técnicas

### Seguridad

- **Context Isolation**: Habilitado para mayor seguridad
- **Node Integration**: Deshabilitado en el renderer process
- **Preload Script**: Bridge seguro entre main y renderer

### Menú de Aplicación

- **Archivo**
  - Recargar (F5)
  - Salir (Alt+F4)

- **Ver**
  - Pantalla Completa (F11)
  - Minimizar (Ctrl+M)
  - Zoom In (Ctrl++)
  - Zoom Out (Ctrl+-)
  - Zoom Reset (Ctrl+0)

- **Ayuda**
  - Acerca de
  - DevTools (F12)

### Manejo de Errores

Si la aplicación no puede conectarse al servidor, muestra una página de error personalizada con:
- Información del error
- URL del servidor
- Opciones para reintentar o cerrar
- Sugerencias de solución

## Distribución

Los instaladores pueden distribuirse de varias formas:

1. **Red Local**: Copiar a una carpeta compartida en la red
2. **Servidor Web**: Descargar desde intranet
3. **USB**: Copiar a dispositivos USB para instalación offline
4. **Deploy Remoto**: Usar el sistema de deploy remoto (ver componente DeployAgentes)

## Actualizaciones

Para actualizar la aplicación:

1. Los usuarios deben descargar e instalar la nueva versión
2. El instalador sobrescribirá la versión anterior
3. Los datos y configuración se mantienen

### Auto-actualización (Futuro)

Se puede implementar auto-actualización usando:
- `electron-updater`
- Servidor de actualizaciones interno
- Notificaciones de nueva versión disponible

## Personalización

### Cambiar Icono

Reemplazar los archivos en `assets/`:
- `icon.ico` - Windows (256x256)
- `icon.icns` - macOS (1024x1024)
- `icon.png` - Linux (512x512)

### Cambiar Nombre de Aplicación

Editar `package.json`:

```json
{
  "name": "tu-app",
  "productName": "Tu Aplicación",
  "build": {
    "appId": "com.tuempresa.tuapp"
  }
}
```

## Troubleshooting

### Error: "No se puede conectar al servidor"

- Verificar que el servidor backend esté ejecutándose
- Verificar la URL en `main.js`
- Verificar la conexión de red
- Verificar el firewall

### Error: "electron-builder no encontrado"

```bash
npm install --save-dev electron-builder
```

### Error: "electron no encontrado"

```bash
npm install --save-dev electron
```

## Soporte

Para problemas o preguntas, contactar al equipo de desarrollo.
