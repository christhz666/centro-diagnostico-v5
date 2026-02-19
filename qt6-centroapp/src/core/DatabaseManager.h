#pragma once

#include <QSqlDatabase>
#include <QString>

class DatabaseManager {
public:
    bool open(const QString& path);
    bool initializeSchema();
    bool enqueueSync(const QString& entity, const QString& action, const QString& payload);
    int pendingSyncCount() const;

private:
    QSqlDatabase db;
};
