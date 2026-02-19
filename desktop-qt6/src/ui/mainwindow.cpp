#include "mainwindow.h"

#include "core/appcontext.h"
#include "services/connectivityservice.h"
#include "services/syncengine.h"

#include <QHBoxLayout>
#include <QLabel>
#include <QStatusBar>
#include <QTabWidget>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(AppContext* context, QWidget* parent)
    : QMainWindow(parent), m_context(context), m_statusLabel(nullptr), m_pendingLabel(nullptr) {
    setupUi();

    auto* connectivity = m_context->connectivity();
    auto* sync = m_context->sync();

    connect(connectivity, &ConnectivityService::connectivityChanged, this, [this](bool online) {
        m_statusLabel->setText(online ? "🟢 En línea" : "🔴 Sin conexión");
    });

    connect(sync, &SyncEngine::pendingCountChanged, this, [this](int count) {
        m_pendingLabel->setText(QString("Pendientes sync: %1").arg(count));
    });

    m_statusLabel->setText(connectivity->isOnline() ? "🟢 En línea" : "🔴 Sin conexión");
}

void MainWindow::setupUi() {
    setWindowTitle("CentroApp Qt6 - Offline First");
    resize(1200, 760);

    QWidget* root = new QWidget(this);
    QVBoxLayout* layout = new QVBoxLayout(root);

    auto* tabs = new QTabWidget(root);
    tabs->addTab(new QLabel("Dashboard"), "Dashboard");
    tabs->addTab(new QLabel("Pacientes"), "Pacientes");
    tabs->addTab(new QLabel("Órdenes / Citas"), "Órdenes");
    tabs->addTab(new QLabel("Resultados"), "Resultados");
    tabs->addTab(new QLabel("Facturación"), "Facturación");
    tabs->addTab(new QLabel("Reportes"), "Reportes");

    layout->addWidget(tabs);
    setCentralWidget(root);

    m_statusLabel = new QLabel("Estado", this);
    m_pendingLabel = new QLabel("Pendientes sync: 0", this);
    statusBar()->addPermanentWidget(m_statusLabel);
    statusBar()->addPermanentWidget(m_pendingLabel);
}
