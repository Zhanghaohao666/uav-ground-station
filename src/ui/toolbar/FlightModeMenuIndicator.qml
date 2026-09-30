/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.11
import QtQuick.Layouts 1.11

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0

import XUI 1.0

Item {
    id:                     _root
    // Layout.preferredWidth:  rowLayout.width
    implicitWidth:              rowLayout.width
    property real _margin:      XScreenTool.base
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    Row {
        id:         rowLayout
        spacing:     _margin / 8
        height:     parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        Image {
            id:                     flightModeIcon
            width:                  height
            height:                 parent.height * 0.65
            fillMode:               Image.PreserveAspectFit
            mipmap:                 true
            source:                 "/image/xmode"
            anchors.verticalCenter:     parent.verticalCenter
        }
        Item {
            width:                  Math.max(flightMode.width, flightModeValue.width)
            height:                 parent.height
            anchors.verticalCenter:     parent.verticalCenter
            XLabel {
                id:                 flightMode
                text:               qsTr("Flight Mode")
                minmin:                true
                font.bold:          false
                anchors.top:        parent.top
            }
            XLabel {
                id:                 flightModeValue
                text:               activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
                minmin:               true
                font.bold:          false
                anchors.bottom:     parent.bottom
            }
        }
        XColoredImage {
            height:                 parent.height * 0.4
            sourceSize.height:      height
            width:                  height
            anchors.verticalCenter: parent.verticalCenter
            fillMode:               Image.PreserveAspectFit
            color:                  "white"
            source:                 "/image/xleft"
            cusrotation:            90
        }
    }


    property real fontPointSize: ScreenTools.largeFontPointSize

    Component {
        id: flightModeMenu

        Rectangle {
            width: flickable.width + (_margin * 2)
            height: flickable.height + (_margin * 2)
            radius:         _margin * 0.5
            color:      "transparent"

            QGCFlickable {
                id: flickable
                anchors.centerIn: parent
                width: mainLayout.width
                height: _fullWindowHeight <= mainLayout.height ? _fullWindowHeight : mainLayout.height
                flickableDirection: Flickable.VerticalFlick
                contentHeight: mainLayout.height
                contentWidth: mainLayout.width

                property real _fullWindowHeight: mainWindow.contentItem.height - (indicatorPopup.padding * 2) - (ScreenTools.defaultFontPixelWidth * 2)

                ColumnLayout {
                    id: mainLayout
                    spacing: _margin / 2

                    Repeater {
                        model: activeVehicle ? activeVehicle.flightModes : []

                        QGCButton {
                            text: modelData
                            Layout.fillWidth: true
                            onClicked: {
                                activeVehicle.flightMode = text
                                mainWindow.xClosePopup()
                            }
                        }
                    }
                }
            }
        }
    }


    QGCMouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.xShowPopup(flightModeMenu, _root, 3)
    }
}
