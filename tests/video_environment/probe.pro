QT = core
CONFIG += console c++11
CONFIG -= app_bundle
TEMPLATE = app
TARGET = environment_probe
SOURCES += environment_probe.cpp
HEADERS += ../../src/VideoReceiver/PortableGStreamerEnvironment.h
win32:QMAKE_CXXFLAGS += /utf-8
