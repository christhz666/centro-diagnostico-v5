# ?? Sistema de Gestión para Centro Diagnóstico Médico

![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)
![Flask](https://img.shields.io/badge/Flask-3.0-green.svg)
![React](https://img.shields.io/badge/React-18-61dafb.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13-336791.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)
![Status](https://img.shields.io/badge/Status-Production-success.svg)
![Value](https://img.shields.io/badge/Value-$20k+-gold.svg)

Sistema completo de gestión hospitalaria para centros de diagnóstico médico, desarrollado con Flask (Backend) y React (Frontend).

[El resto del README actual...]


## 🖥️ Nueva base nativa de escritorio (Qt6, sin Electron)

Se agregó el módulo `desktop-qt6/` como punto de partida para migrar la app de escritorio a una implementación nativa en C++/Qt6 con enfoque offline-first (SQLite local + cola de sincronización).

- Ver guía: `desktop-qt6/README.md`
- Compilación: `cmake -S desktop-qt6 -B desktop-qt6/build && cmake --build desktop-qt6/build`

## 🧪 Test Sistema Completo

### Descripción

`test_sistema_completo.sh` es un script exhaustivo de verificación que prueba **absolutamente todo el sistema** y guarda los resultados en un archivo de log detallado.

### Características

- ✅ **Verificación de estructura de archivos**: Verifica que TODOS los archivos del backend, frontend, modelos, controllers, rutas y componentes existan
- 🔍 **Detección de archivos problemáticos**: Identifica archivos que pueden tener contenido incompleto
- 📦 **Verificación de dependencias**: Comprueba Node.js (node_modules) y Python (venv) con paquetes clave
- 🔗 **Consistencia de imports**: Valida que todos los `require()` en server.js apunten a archivos reales
- 🎮 **Controllers**: Verifica que cada controller importado desde las rutas exista y exporte funciones
- 💾 **Conexión a bases de datos**: Test de conexión a MongoDB y PostgreSQL
- 🌐 **Test de API endpoints**: Prueba todos los endpoints REST (health, auth, pacientes, citas, estudios, etc.)
- 🔄 **Mapeo frontend ↔ backend**: Verifica que las rutas que el frontend llama existan en el backend
- ⚙️ **Variables de entorno**: Verifica .env y variables necesarias (MONGODB_URI, JWT_SECRET, PORT, etc.)
- 📊 **Resumen final**: Conteo de tests pasados, fallidos y advertencias con porcentaje de salud del sistema

### Uso

```bash
# Ejecutar el script de test completo
./test_sistema_completo.sh
```

### Salida

El script genera:
- **Salida en terminal**: Con colores para fácil visualización
  - 🟢 Verde: Tests pasados
  - 🟡 Amarillo: Advertencias
  - 🔴 Rojo: Tests fallidos
- **Log detallado**: En `logs/test_sistema_YYYYMMDD_HHMMSS.log`

### Ejemplo de Salida

```
╔════════════════════════════════════════════════════════════════════════════╗
║   TEST SISTEMA COMPLETO - CENTRO DIAGNÓSTICO MI ESPERANZA                 ║
╚════════════════════════════════════════════════════════════════════════════╝

📅 Fecha: 2026-02-18 12:41:57
🖥️  Servidor: server-name
📝 Log: /path/to/logs/test_sistema_20260218_124157.log

================================================================================
1️⃣  VERIFICACIÓN DE ESTRUCTURA DE ARCHIVOS
================================================================================
✅ Servidor principal existe: /path/to/backend/server.js
✅ Package.json existe: /path/to/backend/package.json
...

================================================================================
📊 RESUMEN FINAL
================================================================================

Total de verificaciones: 114
✅ Pasadas: 106
⚠️  Advertencias: 6
❌ Fallidas: 2

Nivel de salud del sistema: 92%
🎉 Sistema en excelente estado
```

### Secciones de Verificación

1. **Estructura de Archivos**: Backend (Node.js + Python), Frontend (React), Database, Scripts
2. **Contenido de Archivos de Rutas**: Detecta archivos rotos o incompletos
3. **Dependencias**: node_modules (backend y frontend), venv (Python)
4. **Consistencia de Imports**: Valida require() en server.js
5. **Controllers**: Verifica existencia y exports
6. **Conexión a BD**: MongoDB y PostgreSQL
7. **Variables de Entorno**: .env y .env.example
8. **API Endpoints**: Tests de todos los endpoints REST
9. **Mapeo Frontend ↔ Backend**: Rutas llamadas por api.js vs rutas del servidor

### Notas Importantes

- El script es **idempotente**: Se puede ejecutar múltiples veces sin efectos secundarios
- **No requiere que el servidor esté corriendo** para verificar estructura de archivos
- Para tests de API completos, el servidor debe estar ejecutándose en el puerto 5000
- Los logs NO se commitean al repositorio (están en .gitignore)

### Logs

Todos los logs se guardan en el directorio `logs/` con timestamp único. Los archivos de log contienen:
- Toda la información mostrada en terminal (sin códigos de color)
- Detalles adicionales de rutas encontradas
- Historial completo de verificaciones

### Scripts Relacionados

- `diagnostico_completo.sh`: Diagnóstico del sistema en producción
- `test_final.sh`: Test rápido de funcionalidad básica
- `verificar_todo.sh`: Verificación general del sistema

## 🖥️ Cliente nativo Qt6 (sin Electron)

Se agregó una base de cliente de escritorio nativo offline-first en `qt6-centroapp/` para iniciar la migración de webview a app C++/Qt6.

Ver guía en: `qt6-centroapp/README.md`.
