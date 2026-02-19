#pragma once

#include <QObject>
#include <QTimer>

class DatabaseManager;

class SyncEngine : public QObject {
    Q_OBJECT
public:
    explicit SyncEngine(DatabaseManager* db, QObject* parent = nullptr);
    void start();

signals:
    void connectivityChanged(bool online);
    void pendingCountChanged(int count);

private slots:
    void checkConnectivity();
    void processQueue();

private:
    DatabaseManager* db;
    QTimer pingTimer;
    QTimer syncTimer;
    bool online = false;
};
