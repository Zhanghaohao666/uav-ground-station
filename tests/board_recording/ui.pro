QT += core gui network testlib qml quick
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = recording_ui_tests
SOURCES += ui_tests.cpp ../../xsrc/XModule/XTCP/XBoardRecordingController.cc
HEADERS += ../../xsrc/XModule/XTCP/XBoardRecordingController.h
INCLUDEPATH += ../../xsrc/XModule/XTCP
