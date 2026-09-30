/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Window   2.11

// import QGroundControl.FactSystem    1.0
// import QGroundControl               1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
// import QGroundControl.FlightDisplay 1.0
// import QGroundControl.FlightMap     1.0


import XUI 1.0
/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:         splash
    visible:    true
    flags: Qt.Window | Qt.FramelessWindowHint

    minimumWidth:   ScreenTools.isMobile ? Screen.width  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? Screen.height : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120) {
            splash.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? Screen.width  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? Screen.height : Math.min(150 * Screen.pixelDensity, Screen.height)
        }
    }

    Image {
        anchors.fill:           parent
        source:                 "qrc:/image/Theme"
        fillMode:               Image.Stretch
    }

}

