QT += core gui widgets testlib
CONFIG += console c++14 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = licensing_tests
win32-msvc* {
    contains(CONFIG, license_ansi_source_test) {
        QMAKE_CXXFLAGS += /source-charset:.1252 /execution-charset:.1252
    } else {
        QMAKE_CXXFLAGS += /utf-8
    }
    PRECOMPILED_HEADER = ../../src/stable_headers.h
}
include(../../src/Licensing/licensing.pri)
SOURCES += licensing_tests.cpp
