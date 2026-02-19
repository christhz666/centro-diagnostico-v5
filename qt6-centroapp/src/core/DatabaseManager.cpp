#include "DatabaseManager.h"

#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QDebug>

bool DatabaseManager::open(const QString& path) {
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(path);

    if (!db.open()) {
        qWarning() << "No se pudo abrir SQLite:" << db.lastError().text();
        return false;
    }

    return true;
}

bool DatabaseManager::initializeSchema() {
    QSqlQuery q(db);

    const QString schema = R"(
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('admin', 'recepcionista', 'laboratorista', 'medico'))
        );

        CREATE TABLE IF NOT EXISTS pacientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre_completo TEXT NOT NULL,
            cedula_id TEXT UNIQUE NOT NULL,
            fecha_nacimiento TEXT NOT NULL,
            telefono_email TEXT,
            direccion TEXT,
            medico_cabecera TEXT,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS ordenes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folio TEXT UNIQUE NOT NULL,
            paciente_id INTEGER NOT NULL,
            prioridad TEXT DEFAULT 'normal',
            estado TEXT DEFAULT 'pendiente',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        );

        CREATE TABLE IF NOT EXISTS resultados (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folio TEXT NOT NULL,
            codigo_estudio TEXT NOT NULL,
            codigo_muestra TEXT NOT NULL,
            valor TEXT,
            validado_por INTEGER,
            validado_at TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(folio, codigo_estudio, codigo_muestra)
        );

        CREATE TABLE IF NOT EXISTS sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INTEGER DEFAULT 0,
            last_error TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
    )";

    if (!q.exec(schema)) {
        qWarning() << "Error creando schema:" << q.lastError().text();
        return false;
    }

    return true;
}

bool DatabaseManager::enqueueSync(const QString& entity, const QString& action, const QString& payload) {
    QSqlQuery q(db);
    q.prepare("INSERT INTO sync_queue(entity, action, payload) VALUES(?, ?, ?)");
    q.addBindValue(entity);
    q.addBindValue(action);
    q.addBindValue(payload);
    return q.exec();
}

int DatabaseManager::pendingSyncCount() const {
    QSqlQuery q(db);
    if (!q.exec("SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'")) {
        return 0;
    }

    if (!q.next()) {
        return 0;
    }

    return q.value(0).toInt();
}
