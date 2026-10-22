QT += core network testlib
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = recording_tests
SOURCES += recording_tests.cpp ../../xsrc/XModule/XTCP/XBoardRecordingController.cc
HEADERS += ../../xsrc/XModule/XTCP/XBoardRecordingController.h
INCLUDEPATH += ../../xsrc/XModule/XTCP

SOURCES += ../../xsrc/XModule/XMaintenance/BoardSsh.cc
HEADERS += ../../xsrc/XModule/XMaintenance/BoardSsh.h
INCLUDEPATH += ../../xsrc/XModule/XMaintenance

HEADERS += test_controller.h
win32-msvc*:QMAKE_CXXFLAGS += /utf-8
