# 防止被多次 include
!contains(INCLUDED_PRI, xui) {
    INCLUDED_PRI += xui

    INCLUDEPATH +=  $$PWD \
                    $$PWD/XSingletons \
                    $$PWD/XUI \
                    $$PWD/XControls \
                    $$PWD/XImages \
                    $$PWD/XModule/XTCP

    # QML_IMPORT_PATH += xqmlui

    WindowsBuild {
        QMAKE_CXXFLAGS += /wd4819
    }

    RESOURCES +=  $$PWD/xui.qrc

    HEADERS += \
    $$PWD/XSingletons/XScreenToolsController.h \
    $$PWD/XModule/XTCP/CcTcpClient.h \
    $$PWD/XModule/XTCP/XTCPClient.h \
    $$PWD/XModule/XTCP/XGimbalTcpController.h \
    $$PWD/XModule/XTCP/XAlgorithmTcpController.h \
    $$PWD/XModule/XTCP/XScriptTcpController.h \
    $$PWD/XModule/XTCP/XBoardRecordingController.h

    SOURCES += \
    $$PWD/XSingletons/XScreenToolsController.cc \
    $$PWD/XModule/XTCP/XTCPClient.cc \
    $$PWD/XModule/XTCP/XGimbalTcpController.cc \
    $$PWD/XModule/XTCP/XScriptTcpController.cc \
    $$PWD/XModule/XTCP/XBoardRecordingController.cc
}
