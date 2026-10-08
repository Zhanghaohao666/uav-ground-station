QT += core gui network testlib qml quick
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = payload_tests
SOURCES += payload_tests.cpp ../../xsrc/XModule/XTCP/XTCPClient.cc ../../xsrc/XModule/XTCP/XGimbalTcpController.cc
HEADERS += ../../xsrc/XModule/XTCP/XTCPClient.h ../../xsrc/XModule/XTCP/XGimbalTcpController.h ../../xsrc/XModule/XTCP/XAlgorithmTcpController.h
INCLUDEPATH += ../../xsrc/XModule/XTCP
