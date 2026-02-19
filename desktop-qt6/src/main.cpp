#include <QApplication>
#include "core/appcontext.h"
#include "ui/mainwindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    AppContext context;
    if (!context.initialize()) {
        return 1;
    }

    MainWindow window(&context);
    window.show();

    return app.exec();
}
