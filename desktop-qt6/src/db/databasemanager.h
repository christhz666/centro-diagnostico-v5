#pragma once

#include <QSqlDatabase>
#include <QVariantMap>

class DatabaseManager {
public:
    bool open();
    int pendingSyncCount() const;
    bool enqueueSync(const QString& entityType, const QString& action, const QVariantMap& payload);

private:
    bool ensureSchema();
    QSqlDatabase m_db;
};
