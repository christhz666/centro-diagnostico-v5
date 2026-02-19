#pragma once

#include <QMainWindow>

class QLabel;
class QTabWidget;
class SyncEngine;

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(const QString& role, SyncEngine* syncEngine, QWidget* parent = nullptr);

private slots:
    void onConnectivityChanged(bool online);
    void onPendingCountChanged(int count);

private:
    void applyRolePermissions(const QString& role);

    QLabel* connectivityLabel;
    QLabel* pendingLabel;
    QTabWidget* tabs;
};
