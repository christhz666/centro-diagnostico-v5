#include "core/AuthService.h"
#include "core/DatabaseManager.h"
#include "core/SyncEngine.h"
#include "ui/MainWindow.h"

#include <QApplication>
#include <QDir>
#include <QFormLayout>
#include <QLineEdit>
#include <QMessageBox>
#include <QPushButton>
#include <QDialog>

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);

    DatabaseManager db;
    const QString dbPath = QDir::homePath() + "/centroapp_local.sqlite";
    if (!db.open(dbPath) || !db.initializeSchema()) {
        QMessageBox::critical(nullptr, "Error", "No se pudo inicializar la base de datos local.");
        return 1;
    }

    QDialog loginDialog;
    loginDialog.setWindowTitle("CentroApp Login");

    QLineEdit username;
    QLineEdit password;
    password.setEchoMode(QLineEdit::Password);

    auto* submit = new QPushButton("Ingresar");
    auto* layout = new QFormLayout(&loginDialog);
    layout->addRow("Usuario", &username);
    layout->addRow("Contraseña", &password);
    layout->addWidget(submit);

    QObject::connect(submit, &QPushButton::clicked, &loginDialog, &QDialog::accept);

    if (loginDialog.exec() != QDialog::Accepted) {
        return 0;
    }

    AuthService auth;
    QString role;
    if (!auth.login(username.text(), password.text(), role)) {
        QMessageBox::warning(nullptr, "Login", "Credenciales inválidas.");
        return 0;
    }

    SyncEngine syncEngine(&db);
    MainWindow window(role, &syncEngine);
    window.show();

    syncEngine.start();

    return app.exec();
}
