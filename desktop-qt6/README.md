# CentroApp Qt6 (base nativa offline-first)

Este módulo reemplaza el enfoque Electron/WebView por una app **100% nativa en Qt 6 + C++17** con almacenamiento local en SQLite y sincronización diferida.

## Objetivo de esta iteración

- Dejar una base compilable para empezar la migración completa.
- Definir estructura de módulos y servicios offline-first.
- Implementar núcleo de persistencia local y cola de sincronización.

## Arquitectura inicial

- `src/db/DatabaseManager`: abre SQLite y crea tablas base:
  - `pacientes`
  - `resultados` (identificados por `folio + codigo_estudio + codigo_muestra`)
  - `sync_queue` para operaciones pendientes
- `src/services/ConnectivityService`: ping cada 10s para detectar conectividad.
- `src/services/SyncEngine`: ciclo de sync cada 30s, con contador de pendientes.
- `src/ui/MainWindow`: shell de módulos (tabs) + barra de estado de conexión y pendientes.

## Cobertura funcional ya modelada

- Pacientes con campos mínimos solicitados:
  - Nombre completo
  - Cédula / ID
  - Fecha nacimiento
  - Teléfono
  - Email
  - Dirección
  - Médico de cabecera
- Resultados de laboratorio por triple clave:
  - `folio`
  - `codigo_estudio`
  - `codigo_muestra`
- Cola local de sincronización para eventos offline.

## Próximos pasos (roadmap corto)

1. **Autenticación y autorización local**
   - Login usuario/contraseña
   - Roles: `admin`, `recepcionista`, `laboratorista`, `medico`
   - Guardas por módulo y acción.
2. **Módulos completos**
   - CRUD de pacientes
   - Órdenes/citas con prioridad
   - Resultados manuales + import de equipos
   - Facturación y reportes.
3. **Sync robusto multiestación (>5 PCs)**
   - GUID por operación
   - Reintentos exponenciales
   - Resolución de conflictos (last-write + auditoría)
   - Confirmación idempotente en API.
4. **Hardening para producción Windows**
   - Instalador
   - Servicio de auto-update (opcional)
   - Logs y auditoría.

## Build local

```bash
cmake -S desktop-qt6 -B desktop-qt6/build
cmake --build desktop-qt6/build
```

> Requiere Qt 6 con módulos: Core, Gui, Widgets, Sql, Network.
