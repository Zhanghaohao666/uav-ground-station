QT += core network testlib
CONFIG += console c++17
CONFIG -= app_bundle
TEMPLATE = app
TARGET = live_recording_smoke
SOURCES += live_recording_smoke.cpp ../../xsrc/XModule/XTCP/XBoardRecordingController.cc
HEADERS += ../../xsrc/XModule/XTCP/XBoardRecordingController.h
INCLUDEPATH += ../../xsrc/XModule/XTCP

SOURCES += ../../xsrc/XModule/XMaintenance/BoardSsh.cc
HEADERS += ../../xsrc/XModule/XMaintenance/BoardSsh.h
INCLUDEPATH += ../../xsrc/XModule/XMaintenance
