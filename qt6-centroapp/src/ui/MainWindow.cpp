#include "MainWindow.h"
#include "../core/SyncEngine.h"

#include <QLabel>
#include <QTabWidget>
#include <QToolBar>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(const QString& role, SyncEngine* syncEngine, QWidget* parent)
    : QMainWindow(parent), connectivityLabel(new QLabel("🟢 Online")), pendingLabel(new QLabel("Pendientes: 0")), tabs(new QTabWidget) {
    setWindowTitle("CentroApp Qt6 - Offline First");
    resize(1200, 700);

    auto* topBar = addToolBar("Estado");
    topBar->setMovable(false);
    topBar->addWidget(connectivityLabel);
    topBar->addSeparator();
    topBar->addWidget(pendingLabel);

    tabs->addTab(new QLabel("Dashboard y estadísticas en tiempo real"), "Dashboard");
    tabs->addTab(new QLabel("Registro y edición de pacientes"), "Pacientes");
    tabs->addTab(new QLabel("Órdenes de estudios y citas"), "Órdenes/Citas");
    tabs->addTab(new QLabel("Resultados de laboratorio manuales y máquinas"), "Resultados");
    tabs->addTab(new QLabel("Facturación, pagos y facturas"), "Facturación");
    tabs->addTab(new QLabel("Reportes y estadísticas"), "Reportes");

    auto* central = new QWidget;
    auto* layout = new QVBoxLayout(central);
    layout->addWidget(tabs);
    setCentralWidget(central);

    applyRolePermissions(role);

    connect(syncEngine, &SyncEngine::connectivityChanged, this, &MainWindow::onConnectivityChanged);
    connect(syncEngine, &SyncEngine::pendingCountChanged, this, &MainWindow::onPendingCountChanged);
}

void MainWindow::applyRolePermissions(const QString& role) {
    if (role == "admin") return;

    if (role == "recepcionista") {
        tabs->setTabEnabled(5, false); // Reportes
    } else if (role == "laboratorista") {
        tabs->setTabEnabled(1, false); // Pacientes edición
        tabs->setTabEnabled(4, false); // Facturación
        tabs->setTabEnabled(5, false); // Reportes
    } else if (role == "medico") {
        tabs->setTabEnabled(4, false);
        tabs->setTabEnabled(5, false);
    }
}

void MainWindow::onConnectivityChanged(bool online) {
    connectivityLabel->setText(online ? "🟢 Online" : "🔴 Sin conexión");
}

void MainWindow::onPendingCountChanged(int count) {
    pendingLabel->setText(QString("Pendientes: %1").arg(count));
}
