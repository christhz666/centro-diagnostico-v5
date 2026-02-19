#include "appcontext.h"
#include "db/databasemanager.h"
#include "services/connectivityservice.h"
#include "services/syncengine.h"

bool AppContext::initialize() {
    m_db = std::make_unique<DatabaseManager>();
    if (!m_db->open()) {
        return false;
    }

    m_connectivity = std::make_unique<ConnectivityService>();
    m_sync = std::make_unique<SyncEngine>(m_db.get(), m_connectivity.get());
    m_sync->start();

    return true;
}

DatabaseManager* AppContext::db() const {
    return m_db.get();
}

ConnectivityService* AppContext::connectivity() const {
    return m_connectivity.get();
}

SyncEngine* AppContext::sync() const {
    return m_sync.get();
}
