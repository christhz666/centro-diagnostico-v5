// main.js - Proceso principal de Electron
// Centro Diagnóstico v5

const { app, BrowserWindow, Menu, dialog } = require('electron');
const path = require('path');

// URL del servidor backend
const SERVER_URL = 'http://192.9.135.84:5000';

let mainWindow;

function createWindow() {
  // Crear la ventana del navegador
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 768,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    title: 'Centro Diagnóstico v5',
    backgroundColor: '#1a3a5c',
    show: false // No mostrar hasta que esté listo
  });

  // Cargar la aplicación desde el servidor
  // En producción, esto apunta al servidor backend que sirve el frontend
  mainWindow.loadURL(SERVER_URL);

  // Mostrar ventana cuando esté lista
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // Abrir DevTools en modo desarrollo
  // mainWindow.webContents.openDevTools();

  // Manejar cierre de ventana
  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Manejar errores de carga
  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    if (errorCode === -3) {
      // ERR_ABORTED - ignorar, es normal durante navegación
      return;
    }
    
    console.error('Error cargando página:', errorCode, errorDescription);
    
    // Mostrar página de error
    const errorHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Error de Conexión</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #1a3a5c 0%, #2c5a7a 100%);
            color: white;
          }
          .error-container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            backdrop-filter: blur(10px);
          }
          h1 {
            font-size: 48px;
            margin: 0 0 20px 0;
          }
          p {
            font-size: 18px;
            margin: 10px 0;
          }
          .error-code {
            font-family: monospace;
            background: rgba(0, 0, 0, 0.3);
            padding: 10px;
            border-radius: 5px;
            margin: 20px 0;
          }
          button {
            background: #87CEEB;
            color: #1a3a5c;
            border: none;
            padding: 15px 30px;
            font-size: 16px;
            font-weight: bold;
            border-radius: 5px;
            cursor: pointer;
            margin: 10px;
          }
          button:hover {
            background: #a0d8f0;
          }
        </style>
      </head>
      <body>
        <div class="error-container">
          <h1>⚠️ Error de Conexión</h1>
          <p>No se pudo conectar al servidor de Centro Diagnóstico</p>
          <div class="error-code">
            <strong>Servidor:</strong> ${SERVER_URL}<br>
            <strong>Error:</strong> ${errorDescription} (${errorCode})
          </div>
          <p>Por favor, verifique:</p>
          <ul style="text-align: left; display: inline-block;">
            <li>Que el servidor esté ejecutándose</li>
            <li>Que la conexión de red esté activa</li>
            <li>Que la URL del servidor sea correcta</li>
          </ul>
          <br><br>
          <button onclick="location.reload()">🔄 Reintentar</button>
          <button onclick="window.close()">✖ Cerrar</button>
        </div>
      </body>
      </html>
    `;
    
    mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(errorHtml));
  });

  // Crear menú de aplicación
  createMenu();
}

function createMenu() {
  const template = [
    {
      label: 'Archivo',
      submenu: [
        {
          label: 'Recargar',
          accelerator: 'F5',
          click: () => {
            if (mainWindow) {
              mainWindow.reload();
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Salir',
          accelerator: 'Alt+F4',
          click: () => {
            app.quit();
          }
        }
      ]
    },
    {
      label: 'Ver',
      submenu: [
        {
          label: 'Pantalla Completa',
          accelerator: 'F11',
          click: () => {
            if (mainWindow) {
              mainWindow.setFullScreen(!mainWindow.isFullScreen());
            }
          }
        },
        {
          label: 'Minimizar',
          accelerator: 'CmdOrCtrl+M',
          role: 'minimize'
        },
        { type: 'separator' },
        {
          label: 'Zoom In',
          accelerator: 'CmdOrCtrl+Plus',
          click: () => {
            if (mainWindow) {
              const currentZoom = mainWindow.webContents.getZoomFactor();
              mainWindow.webContents.setZoomFactor(currentZoom + 0.1);
            }
          }
        },
        {
          label: 'Zoom Out',
          accelerator: 'CmdOrCtrl+-',
          click: () => {
            if (mainWindow) {
              const currentZoom = mainWindow.webContents.getZoomFactor();
              mainWindow.webContents.setZoomFactor(currentZoom - 0.1);
            }
          }
        },
        {
          label: 'Zoom Reset',
          accelerator: 'CmdOrCtrl+0',
          click: () => {
            if (mainWindow) {
              mainWindow.webContents.setZoomFactor(1.0);
            }
          }
        }
      ]
    },
    {
      label: 'Ayuda',
      submenu: [
        {
          label: 'Acerca de',
          click: () => {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'Acerca de Centro Diagnóstico',
              message: 'Centro Diagnóstico v5.0',
              detail: 'Sistema de Gestión de Laboratorio Clínico\n\n' +
                      'Desarrollado por Centro Diagnóstico\n' +
                      '© 2024 Todos los derechos reservados',
              buttons: ['OK']
            });
          }
        },
        {
          label: 'DevTools',
          accelerator: 'F12',
          click: () => {
            if (mainWindow) {
              mainWindow.webContents.toggleDevTools();
            }
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// Cuando Electron haya terminado de inicializarse
app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    // En macOS, recrear ventana cuando se hace clic en el icono del dock
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// Salir cuando todas las ventanas estén cerradas (excepto en macOS)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Manejar segundo instance (evitar múltiples instancias)
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    // Si alguien intenta ejecutar otra instancia, enfocar nuestra ventana
    if (mainWindow) {
      if (mainWindow.isMinimized()) {
        mainWindow.restore();
      }
      mainWindow.focus();
    }
  });
}

// Manejo de errores no capturados
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
