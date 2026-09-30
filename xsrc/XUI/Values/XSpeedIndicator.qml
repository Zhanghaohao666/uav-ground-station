/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0


import XUI 1.0
//-------------------------------------------------------------------------
//-- GPS Indicator
Item {
    id:             _root
    width:          (speedValuesColumn.x + speedValuesColumn.width) * 1.01
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _speed:  _activeVehicle ? _activeVehicle.groundSpeed.rawValue.toFixed(1) : 0
    property color _bgCrl :      ZHGlobalColor.topBackgroundCrl
    property color _textCrl :    ZHGlobalColor.topTextCrl

    Component {
        id: rangefinderInfo

        Item {
            width:  gpsCol.width   + ScreenTools.defaultFontPixelWidth  * 3
            height: gpsCol.height  + ScreenTools.defaultFontPixelHeight * 2

            Column {
                id:                 gpsCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(gpsGrid.width, gpsLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                XLabel {
                    id:             gpsLabel
                    text:           (_activeVehicle) ? qsTr("Speed Status") : qsTr("Speed Unavailable")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    width: parent.width
                    height:  1
                    color:  XGlobalColor.sub
                }
                GridLayout {
                    id:                 gpsGrid
                    visible:            _activeVehicle
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    XLabel {small: true  ; text: qsTr("Speed:") }
                    XLabel { small: true  ;text: _activeVehicle ? _speed + "m/s" : qsTr("N/A") }
                }
            }
        }
    }

    Image {
        id:                 speedIcon
        width:              height * 0.9
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source:             "/image/XSpeed.png"
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height * 0.9
        asynchronous : true
    }

    Column {
        id:                     speedValuesColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
        anchors.left:           speedIcon.right
        spacing:                ScreenTools.defaultFontPixelWidth / 2
        XLabel {
            color:                  "white"
            text:                   _activeVehicle ? _speed : "0.0"
            small:                  true
            height:                 speedIcon.height * 0.4
        }
        XLabel {
            color:                  "white"
            text:                   "m/s"
            small:                  true
            height:                 speedIcon.height * 0.4
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            if(XGlobalProperty.vhcnull) {
                mainWindow.xShowPopup(rangefinderInfo, parent, 3)
            }
            else {
                mainWindow.xShowPopup(noVehicleComponent, parent, 3)
            }
        }
    }

    //二级菜单：无人机未连接
    Component {
        id:             noVehicleComponent
        Item {
            width:    noVehicleColumn.implicitWidth + XScreenTool.base * 4
            height:   noVehicleColumn.implicitHeight + XScreenTool.base * 3
            Column {
                id:        noVehicleColumn
                anchors.centerIn:   parent
                XLabel {
                    text:   qsTr("Please connect the drone!")
                    small:  true
                }
            }
        }
    }
}
