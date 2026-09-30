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

//-------------------------------------------------------------------------
//-- GPS Indicator
import XUI 1.0

Item {
    id:             _root
    width:          (gpsValuesColumn.x + gpsValuesColumn.width) * 1.01
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    property alias source:  gpsIcon.source

    property bool showIndicator: true
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Component {
        id: gpsInfo

        Item {
            width:  gpsCol.width   + XScreenTool.base  * 3
            height: gpsCol.height  + XScreenTool.base * 2

            Column {
                id:                 gpsCol
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                width:              Math.max(gpsGrid.width, gpsLabel.width)
                anchors.margins:    ScreenTools.defaultFontPixelHeight
                anchors.centerIn:   parent

                XLabel {
                    id:             gpsLabel
                    text:           (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? qsTr("GPS Status") : qsTr("GPS Data Unavailable")
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: parent.width
                    height:  1
                    color:  XGlobalColor.sub
                }

                GridLayout {
                    id:                 gpsGrid
                    visible:            (_activeVehicle && _activeVehicle.gps.count.value >= 0)
                    anchors.margins:    ScreenTools.defaultFontPixelHeight
                    columnSpacing:      ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    XLabel { small: true  ; text: qsTr("GPS Count:")   }
                    XLabel { small: true  ;text: _activeVehicle ? _activeVehicle.gps.count.valueString : qsTr("N/A", "No data to display") }
                    XLabel { small: true  ;text: qsTr("GPS Lock:") }
                    XLabel { small: true  ;text: _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : qsTr("N/A", "No data to display") }
                    XLabel { small: true  ;text: qsTr("HDOP:") }
                    XLabel { small: true  ;text: _activeVehicle ? _activeVehicle.gps.hdop.valueString : qsTr("--.--", "No data to display") }
                    XLabel { small: true  ;text: qsTr("VDOP:") }
                    XLabel { small: true  ;text: _activeVehicle ? _activeVehicle.gps.vdop.valueString : qsTr("--.--", "No data to display") }
                }
            }
        }
    }

    Image {
        id:                 gpsIcon
        width:              height
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source:             "/image/XSat.png"//"/qmlimages/Gps.svg"
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height
        asynchronous : true
        // color:              _textCrl
    }

    Column {
        id:                     gpsValuesColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
        anchors.left:           gpsIcon.right
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        XLabel {
            color:                      "white"
            text:                       _activeVehicle ? _activeVehicle.gps.count.valueString : "0"
            height:                     gpsIcon.height * 0.5
            small:              true
        }

        XLabel {
            id:         hdopValue
            color:      "white"
            text:       _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : "N/A"
            small:              true
            height:                     gpsIcon.height * 0.5
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            if(XGlobalProperty.vhcnull) {
                mainWindow.xShowPopup(gpsInfo, parent, 3)
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
