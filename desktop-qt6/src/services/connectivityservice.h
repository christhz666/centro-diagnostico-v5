#pragma once

#include <QObject>

class QNetworkAccessManager;
class QTimer;

class ConnectivityService : public QObject {
    Q_OBJECT
public:
    explicit ConnectivityService(QObject* parent = nullptr);

    bool isOnline() const;

signals:
    void connectivityChanged(bool online);

private:
    void checkConnectivity();

    bool m_online = false;
    QNetworkAccessManager* m_net;
    QTimer* m_timer;
};
