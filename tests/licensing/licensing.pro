QT += core gui widgets testlib
CONFIG += console c++14 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = licensing_tests
win32-msvc*: QMAKE_CXXFLAGS += /utf-8
include(../../src/Licensing/licensing.pri)
SOURCES += licensing_tests.cpp
