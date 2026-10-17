QT = core gui quick testlib
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = receiver_tests
SOURCES += receiver_tests.cpp ../../src/VideoReceiver/GstVideoReceiver.cc ../../src/QGCLoggingCategory.cc
HEADERS += ../../src/VideoReceiver/GstVideoReceiver.h ../../src/VideoReceiver/VideoReceiver.h ../../src/QGCLoggingCategory.h ../../src/VideoReceiver/VideoPlaybackPolicy.h
INCLUDEPATH += ../../src ../../src/VideoReceiver
win32 {
    GSTROOT = $$(GCS_GST_ROOT)
    INCLUDEPATH += $$GSTROOT/include/gstreamer-1.0 $$GSTROOT/include/glib-2.0 $$GSTROOT/lib/glib-2.0/include
    LIBS += -L$$GSTROOT/lib -lgstreamer-1.0 -lgstapp-1.0 -lgobject-2.0 -lglib-2.0
} else {
    CONFIG += link_pkgconfig
    PKGCONFIG += gstreamer-1.0 gstreamer-app-1.0
}
