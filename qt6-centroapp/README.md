# CentroApp Qt6 (Nativo, Offline-First)

Implementación base de aplicación de escritorio en **C++ + Qt6**, sin Electron ni webview.

## Objetivo

Esta versión crea una base funcional para migrar el flujo actual a una app nativa con:

- SQLite local como fuente principal.
- Cola de sincronización local para operaciones pendientes.
- Roles (`admin`, `recepcionista`, `laboratorista`, `medico`) con permisos por módulo.
- Módulos de Pacientes, Órdenes/Citas, Resultados, Facturación y Reportes.

## Requisitos cubiertos

- ✅ Datos mínimos del paciente (nombre, cédula/ID, nacimiento, contacto, dirección, médico).
- ✅ Identificación de resultados con 3 claves: `folio`, `codigo_estudio`, `codigo_muestra`.
- ✅ Login usuario/contraseña con rol.
- ✅ Soporte conceptual para +5 PCs: cada estación trabaja local y sincroniza luego.
- ✅ Indicador online/offline y contador de pendientes.

## Estructura

- `src/core/DatabaseManager.*`: SQLite + schema + cola de sync.
- `src/core/SyncEngine.*`: ping cada 10s y ciclo de sync cada 30s.
- `src/core/AuthService.*`: autenticación inicial por rol.
- `src/ui/MainWindow.*`: UI principal con tabs por módulo y permisos por rol.
- `src/main.cpp`: arranque de app, login, DB local, sync.

## Compilar

```bash
cd qt6-centroapp
cmake -S . -B build
cmake --build build
```

## Siguiente fase recomendada

1. Cambiar `AuthService` para autenticar contra usuarios locales cifrados + refresh con servidor.
2. Implementar repositorios CRUD reales por módulo.
3. Implementar `SyncEngine::processQueue()` con lotes REST y control de conflictos.
4. Integrar ingestión de máquinas (serial/HL7/DICOM/file watcher) al módulo de resultados.
5. Añadir auditoría por usuario/acción y cifrado local sensible.
