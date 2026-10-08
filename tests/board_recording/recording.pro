QT += core network testlib
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = recording_tests
SOURCES += recording_tests.cpp ../../xsrc/XModule/XTCP/XBoardRecordingController.cc
HEADERS += ../../xsrc/XModule/XTCP/XBoardRecordingController.h
INCLUDEPATH += ../../xsrc/XModule/XTCP
