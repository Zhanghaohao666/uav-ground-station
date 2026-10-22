QT += core gui network testlib qml quick
CONFIG += console c++14 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = maintenance_tests
win32-msvc*:QMAKE_CXXFLAGS += /utf-8
SOURCES += maintenance_tests.cpp ../../xsrc/XModule/XMaintenance/XBoardMaintenanceController.cc
HEADERS += ../../xsrc/XModule/XMaintenance/XBoardMaintenanceController.h
INCLUDEPATH += ../../xsrc/XModule/XMaintenance

RESOURCES += panel.qrc
