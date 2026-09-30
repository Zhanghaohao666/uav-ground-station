QT += core testlib quick
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = demand_tests
DEFINES += QGC_GST_STREAMING
SOURCES += demand_tests.cpp
HEADERS += ../../src/VideoReceiver/VideoReceiver.h
