#include "databasemanager.h"

#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QDebug>

bool DatabaseManager::open() {
    const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appData);

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(appData + "/centroapp.db");

    if (!m_db.open()) {
        qCritical() << "No se pudo abrir SQLite:" << m_db.lastError().text();
        return false;
    }

    return ensureSchema();
}

bool DatabaseManager::ensureSchema() {
    QSqlQuery q(m_db);

    if (!q.exec(R"(
        CREATE TABLE IF NOT EXISTS pacientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre_completo TEXT NOT NULL,
            cedula_id TEXT NOT NULL UNIQUE,
            fecha_nacimiento TEXT NOT NULL,
            telefono TEXT,
            email TEXT,
            direccion TEXT,
            medico_cabecera TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    )")) return false;

    if (!q.exec(R"(
        CREATE TABLE IF NOT EXISTS resultados (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folio TEXT NOT NULL,
            codigo_estudio TEXT NOT NULL,
            codigo_muestra TEXT NOT NULL,
            estado TEXT NOT NULL DEFAULT 'pendiente',
            resultado_json TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(folio, codigo_estudio, codigo_muestra)
        )
    )")) return false;

    if (!q.exec(R"(
        CREATE TABLE IF NOT EXISTS sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    )")) return false;

    return true;
}

int DatabaseManager::pendingSyncCount() const {
    QSqlQuery q(m_db);
    q.prepare("SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'");
    if (!q.exec() || !q.next()) return 0;
    return q.value(0).toInt();
}

bool DatabaseManager::enqueueSync(const QString& entityType, const QString& action, const QVariantMap& payload) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO sync_queue(entity_type, action, payload)
        VALUES(:entity_type, :action, :payload)
    )");

    q.bindValue(":entity_type", entityType);
    q.bindValue(":action", action);
    q.bindValue(":payload", QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(payload)).toJson(QJsonDocument::Compact)));

    return q.exec();
}
