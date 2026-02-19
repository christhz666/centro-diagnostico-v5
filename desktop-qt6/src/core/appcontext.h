#pragma once

#include <memory>

class DatabaseManager;
class ConnectivityService;
class SyncEngine;

class AppContext {
public:
    bool initialize();

    DatabaseManager* db() const;
    ConnectivityService* connectivity() const;
    SyncEngine* sync() const;

private:
    std::unique_ptr<DatabaseManager> m_db;
    std::unique_ptr<ConnectivityService> m_connectivity;
    std::unique_ptr<SyncEngine> m_sync;
};
