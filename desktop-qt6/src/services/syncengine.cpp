#include "syncengine.h"

#include "db/databasemanager.h"
#include "services/connectivityservice.h"
#include <QTimer>

SyncEngine::SyncEngine(DatabaseManager* db, ConnectivityService* connectivity, QObject* parent)
    : QObject(parent),
      m_db(db),
      m_connectivity(connectivity),
      m_syncTimer(new QTimer(this)) {
    connect(m_syncTimer, &QTimer::timeout, this, [this]() { processQueue(); });
    connect(m_connectivity, &ConnectivityService::connectivityChanged, this, [this](bool online) {
        if (online) processQueue();
    });
}

void SyncEngine::start() {
    m_syncTimer->start(30000);
    emit pendingCountChanged(m_db->pendingSyncCount());
}

void SyncEngine::processQueue() {
    emit pendingCountChanged(m_db->pendingSyncCount());

    if (!m_connectivity->isOnline()) {
        return;
    }

    // Placeholder: enviar lote al backend REST y marcar registros como enviados.
    // En esta iteración se deja la estructura lista para implementar reintentos,
    // conflictos de concurrencia (>5 estaciones) e idempotencia por GUID.
}
