cmake_minimum_required(VERSION 3.16)
project(CentroApp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Sql Network)

qt_add_executable(CentroApp
    src/main.cpp
    src/core/appcontext.h
    src/core/appcontext.cpp
    src/db/databasemanager.h
    src/db/databasemanager.cpp
    src/services/syncengine.h
    src/services/syncengine.cpp
    src/services/connectivityservice.h
    src/services/connectivityservice.cpp
    src/ui/mainwindow.h
    src/ui/mainwindow.cpp
)

target_include_directories(CentroApp PRIVATE src)

target_link_libraries(CentroApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Sql
    Qt6::Network
)
