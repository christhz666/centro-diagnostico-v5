#pragma once

#include <QObject>

class DatabaseManager;
class ConnectivityService;
class QTimer;

class SyncEngine : public QObject {
    Q_OBJECT
public:
    explicit SyncEngine(DatabaseManager* db, ConnectivityService* connectivity, QObject* parent = nullptr);
    void start();

signals:
    void pendingCountChanged(int count);

private:
    void processQueue();

    DatabaseManager* m_db;
    ConnectivityService* m_connectivity;
    QTimer* m_syncTimer;
};
