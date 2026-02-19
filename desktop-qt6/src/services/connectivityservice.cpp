#include "connectivityservice.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>

ConnectivityService::ConnectivityService(QObject* parent)
    : QObject(parent),
      m_net(new QNetworkAccessManager(this)),
      m_timer(new QTimer(this)) {
    connect(m_timer, &QTimer::timeout, this, [this]() { checkConnectivity(); });
    m_timer->start(10000);
    checkConnectivity();
}

bool ConnectivityService::isOnline() const {
    return m_online;
}

void ConnectivityService::checkConnectivity() {
    QNetworkRequest req(QUrl("https://www.google.com/generate_204"));
    req.setTransferTimeout(4000);

    QNetworkReply* reply = m_net->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const bool online = reply->error() == QNetworkReply::NoError;
        if (online != m_online) {
            m_online = online;
            emit connectivityChanged(m_online);
        }
        reply->deleteLater();
    });
}
