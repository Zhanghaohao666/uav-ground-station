/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs  1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controllers   1.0

/// Base view control for all Setup pages
Item {
    id:             setupView

    property alias  pageComponent:          pageLoader.sourceComponent
    property real   availableWidth:         width - pageLoader.x
    property real   availableHeight:        height - pageLoader.y
    property bool   showAdvanced:           false

    property bool   _vehicleIsRover:        globals.activeVehicle ? globals.activeVehicle.rover : false
    property bool   _vehicleArmed:          globals.activeVehicle ? globals.activeVehicle.armed : false
    property bool   _vehicleFlying:         globals.activeVehicle ? globals.activeVehicle.flying : false
    // FIXME: The _vehicleIsRover checkl is a hack to work around https://github.com/PX4/Firmware/issues/10969
    property real   _margins:               ScreenTools.defaultFontPixelHeight * 0.5

    Component.onCompleted: {
        if(pageLoader.item && pageLoader.item.setupPageCompleted) {
            pageLoader.item.setupPageCompleted()
        }
    }

    QGCFlickable {
        anchors.fill:   parent
        contentWidth:   Math.max(availableWidth,    pageLoader.x + pageLoader.item.width)
        contentHeight:  Math.max(availableHeight,    pageLoader.y + pageLoader.item.height)
        clip:           true

        Loader {
            id:                 pageLoader
            anchors.topMargin:  _margins
            //start_cch_20220324 加了则会报错重复 绑定contentWidth
//            anchors.horizontalCenter: parent.horizontalCenter
        }
        // Overlay to display when vehicle is armed and this setup page needs
        // to be disabled
        Rectangle {
            visible:            !setupView.enabled
            anchors.fill:       parent
            color:              "black"
            opacity:            0.5
        }
    }
}
