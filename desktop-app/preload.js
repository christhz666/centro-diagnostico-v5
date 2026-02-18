// preload.js - Script de precarga para Electron
// Este script se ejecuta antes de que se cargue la página web
// y tiene acceso tanto a las APIs de Node.js como al DOM

const { contextBridge, ipcRenderer } = require('electron');

// Exponer APIs seguras al renderer process
contextBridge.exposeInMainWorld('electronAPI', {
  // Información de la plataforma
  platform: process.platform,
  
  // Versión de la aplicación
  getAppVersion: () => {
    return require('./package.json').version;
  },
  
  // Aquí se pueden agregar más APIs según sea necesario
  // Por ejemplo, para acceso a funcionalidades nativas del SO
});

// Indicar que estamos en Electron
contextBridge.exposeInMainWorld('isElectron', true);

console.log('Preload script loaded');
