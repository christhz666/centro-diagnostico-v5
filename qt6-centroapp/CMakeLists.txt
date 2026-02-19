cmake_minimum_required(VERSION 3.21)
project(CentroAppQt6 VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets Sql Network)

qt_standard_project_setup()

qt_add_executable(centroapp
    src/main.cpp
    src/ui/MainWindow.h
    src/ui/MainWindow.cpp
    src/core/DatabaseManager.h
    src/core/DatabaseManager.cpp
    src/core/SyncEngine.h
    src/core/SyncEngine.cpp
    src/core/AuthService.h
    src/core/AuthService.cpp
)

target_link_libraries(centroapp PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Sql
    Qt6::Network
)

install(TARGETS centroapp)
