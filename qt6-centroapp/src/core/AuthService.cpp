#include "AuthService.h"

bool AuthService::login(const QString& username, const QString& password, QString& roleOut) const {
    if (username == "admin" && password == "admin123") {
        roleOut = "admin";
        return true;
    }
    if (username == "recep" && password == "recep123") {
        roleOut = "recepcionista";
        return true;
    }
    if (username == "lab" && password == "lab123") {
        roleOut = "laboratorista";
        return true;
    }
    if (username == "med" && password == "med123") {
        roleOut = "medico";
        return true;
    }
    return false;
}
