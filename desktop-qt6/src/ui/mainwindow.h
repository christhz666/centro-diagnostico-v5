#pragma once

#include <QMainWindow>

class QLabel;
class AppContext;

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(AppContext* context, QWidget* parent = nullptr);

private:
    void setupUi();

    AppContext* m_context;
    QLabel* m_statusLabel;
    QLabel* m_pendingLabel;
};
