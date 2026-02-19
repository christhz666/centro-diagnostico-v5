#include "SyncEngine.h"
#include "DatabaseManager.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QEventLoop>
#include <QUrl>

SyncEngine::SyncEngine(DatabaseManager* db, QObject* parent)
    : QObject(parent), db(db) {
    pingTimer.setInterval(10000);
    syncTimer.setInterval(30000);

    connect(&pingTimer, &QTimer::timeout, this, &SyncEngine::checkConnectivity);
    connect(&syncTimer, &QTimer::timeout, this, &SyncEngine::processQueue);
}

void SyncEngine::start() {
    checkConnectivity();
    pingTimer.start();
    syncTimer.start();
}

void SyncEngine::checkConnectivity() {
    QNetworkAccessManager manager;
    QNetworkRequest request(QUrl("https://example.com/health"));

    QEventLoop loop;
    QNetworkReply* reply = manager.get(request);
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    const bool nowOnline = reply->error() == QNetworkReply::NoError;
    reply->deleteLater();

    if (nowOnline != online) {
        online = nowOnline;
        emit connectivityChanged(online);
    }
}

void SyncEngine::processQueue() {
    if (!online || !db) {
        emit pendingCountChanged(db ? db->pendingSyncCount() : 0);
        return;
    }

    // Aquí iría envío por lotes a REST API y marcación de items sincronizados.
    emit pendingCountChanged(db->pendingSyncCount());
}
