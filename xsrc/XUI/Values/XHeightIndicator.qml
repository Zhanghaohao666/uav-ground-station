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

Item {
    id:             _root
    width:          (heightValuesColumn.x + heightValuesColumn.width) * 1.01
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    property alias source:  heightIcon.source
    property real _margin:  XScreenTool.base

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _altitudeRelative: _activeVehicle ? _activeVehicle.altitudeRelative.rawValue.toFixed(2): 0

    Component {
        id: heightInfo

        Item {

            width:  gpsCol.width   + _margin  * 3
            height: gpsCol.height  + _margin * 2


            Column {
                id:                 gpsCol
                spacing:            _margin * 0.5
                width:              Math.max(gpsGrid.width, gpsLabel.width)
                anchors.margins:    _margin
                anchors.centerIn:   parent

                XLabel {
                    id:             gpsLabel
                    text:           (_activeVehicle) ? qsTr("Distance") : qsTr("Distance Unavailable")
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
                    anchors.margins:    _margin
                    columnSpacing:      _margin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2


                    XLabel {
                        color:                  "white"
                        text:                   _activeVehicle ? _distanceToGCS : "0.0"
                        height:                 heightIcon.height * 0.4
                        small:                  true
                    }
                    XLabel {
                        color:                  "white"
                        text:                   "m"
                        height:                 heightIcon.height * 0.4
                        small:                  true
                    }
                }
            }
        }
    }

    Image {
        id:                 heightIcon
        width:              height
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source:             "qrc:/ii_resource/ii_attitude_logo.png"
        fillMode:           Image.PreserveAspectFit
        asynchronous:       true
        smooth:             true
        mipmap:             true
        antialiasing:       true
        sourceSize.height:  height
    }

    Column {
        id:                     heightValuesColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin:     _margin
        anchors.left:           heightIcon.right
        spacing:                _margin / 4
        XLabel {
            color:                  "white"
            text:                   _activeVehicle ? _altitudeRelative : "0.0"
            height:                 heightIcon.height * 0.4
            small:                  true
        }
        XLabel {
            color:                  "white"
            text:                   "m"
            height:                 heightIcon.height * 0.4
            small:                  true
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked: {
            if(XGlobalProperty.vhcnull) {
                mainWindow.xShowPopup(heightInfo, parent, 3)
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
