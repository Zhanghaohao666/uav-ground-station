QT = core testlib
CONFIG += console c++11 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = environment_tests
SOURCES += environment_tests.cpp
HEADERS += ../../src/VideoReceiver/PortableGStreamerEnvironment.h
win32:QMAKE_CXXFLAGS += /utf-8
