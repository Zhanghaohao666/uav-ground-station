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
import MAVLink                              1.0


import XUI 1.0
//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             _root
    width:          batteryIndicatorRow.width

    property bool   showIndicator: true
    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var    _battery:     _activeVehicle && _activeVehicle.batteries.count ? _activeVehicle.batteries.get(0) : undefined
//    property var    battery:     globals.activeVehicle && globals.activeVehicle.batteries.count ? globals.activeVehicle.batteries.get(0) : undefined
    property color  _bgCrl :      XGlobalColor.background
    property color  _textCrl :    XGlobalColor.text

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceComponent:    batteryVisual
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            if(XGlobalProperty.vhcnull) {
                if(XGlobalProperty.loadParameters) {
                    //连接无人机 && 加载完参数
                    mainWindow.xShowPopup(batteryPopup, parent, 3) }
                else {
                    //等待参数加载...
                    mainWindow.xShowPopup(waitLoaderComponent, parent, 3)
                }
            }
            else {
                mainWindow.xShowPopup(noVehicleComponent, parent, 3)
            }
        }
    }

    //二级菜单：等待参数加载
    Component {
        id:             waitLoaderComponent
        Item {
            width:    waitLoaderColumn.implicitWidth +  XScreenTool.base * 4
            height:   waitLoaderColumn.implicitHeight + XScreenTool.base * 3
            Column {
                id:        waitLoaderColumn
                anchors.centerIn:   parent
                XLabel {
                    text:   qsTr("Waiting for parameters to load...")
                    small:  true
                }
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

    Component {
        id: batteryVisual

        Row {
            id:             rowBattery
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            function getBatteryColor() {
                if(_battery !== undefined) {
                    if (_battery.percentRemaining.valueString > 60) {
                        return "green"
                    }
                    if (_battery.percentRemaining.valueString > 20) {
                        return "#C6A300"
                    }
                    if (_battery.percentRemaining.valueString > -1) {
                        return "red"
                    }
                }
                return  "black"
            }
            function getBatteryPercentageText() {
                if(_battery !== undefined) {
                    return _battery.percentRemaining.valueString + "%"
                }
                else {
                    return "--%"
                }
            }
            function getBatteryVoltageText() {
                if(_battery !== undefined) {
                    return _battery.voltage.rawValue.toFixed(1) + "V"
                }
                else {
                    return "--.-V"
                }
            }

            function getBatteryCurrent() {
                if(_battery !== undefined) {
                    return _battery.current.rawValue.toFixed(1) + "A"
                }
                else {
                    return "--.-A"
                }
            }
            // property bool currentAvailable:         !isNaN(battery.current.rawValue)

            function getBatteryImage() {
//                if (!isNaN(_battery)) {  //加上有bug
//                if (!isNaN(_battery.percentRemaining.rawValue)) {
                if(_battery !== undefined) {
                    if (_battery.percentRemaining.valueString > 90) {    //  rawValue   valueString
                        return "qrc:/image/xpower4" //"qrc:/image/battery5.svg"
                    }
                    if (_battery.percentRemaining.valueString >75) {
                        return "qrc:/image/xpower3"//"qrc:/image/battery4.svg"
                    }
                    if (_battery.percentRemaining.valueString >50) {
                        return "qrc:/image/xpower2"
                    }
                    if (_battery.percentRemaining.valueString >20.0) {
                        return "qrc:/image/xpower1"//"qrc:/image/battery1.svg"
                    }
                    if (_battery.percentRemaining.valueString >= 0) {
                        return "qrc:/image/xpower1"
                    }
                }
                return  "qrc:/image/xpower4"
            }

            // ZHColoredImage {
            //     height:                 parent.height *0.8
            //     width:                  height
            //     sourceSize.width:       width
            //     source:                 rowBattery.getBatteryImage()
            //     fillMode:               Image.PreserveAspectFit
            //     color:                  rowBattery.getBatteryColor()
            //     anchors.verticalCenter: parent.verticalCenter
            // }
            // XLabel {
            //     text:                   rowBattery.getBatteryPercentageText()
            //     color:                  rowBattery.getBatteryColor()
            //     anchors.verticalCenter: parent.verticalCenter
            // }
            XColoredImage {
                id:                     image
                height:                 parent.height * 0.5
                width:                  height
                color:                  XGlobalColor.sub
                source:                 rowBattery.getBatteryImage()
                // fillMode:               Image.PreserveAspectFit
                // color:                  rowBattery.getBatteryColor()
                anchors.verticalCenter: parent.verticalCenter
            }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.max(batteryPercentag.width, batteryRow.width)
                height:                 parent.height * 0.7
                XLabel {
                    id:                 batteryPercentag
                    text:               rowBattery.getBatteryPercentageText()
                    color:              "white"//rowBattery.getBatteryColor()
                    height:              image.height * 0.6
                    min:                true
                    anchors.top:        parent.top
                }
                Row {
                    id:                 batteryRow
                    spacing:                5
                    anchors.bottom:     parent.bottom
                    XLabel {
                        text:               rowBattery.getBatteryVoltageText()
                        color:              "white"//rowBattery.getBatteryColor()
                        height:              image.height * 0.6
                        minmin:                true
                    }
                    XLabel {
                        text:               rowBattery.getBatteryCurrent()
                        color:              "white"//rowBattery.getBatteryColor()
                        height:              image.height * 0.6
                        minmin:             true
                    }
                }
            }
        }
    }

    Component {
        id: batteryValuesAvailableComponent

        QtObject {
            property bool timeRemainingAvailable:   _battery.timeRemaining.rawValue !== undefined//!isNaN(_battery.timeRemaining.rawValue)
        }
    }

    Component {
        id: batteryPopup
        Item {
            width:          mainLayout.width   + mainLayout.anchors.margins * 2
            height:         mainLayout.height  + mainLayout.anchors.margins * 2
            // radius:         ScreenTools.defaultFontPixelHeight / 2
            // color:          _bgCrl//qgcPal.window
            // border.color:   _textCrl//qgcPal.text

            ColumnLayout {
                id:                 mainLayout
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.top:        parent.top
                anchors.right:      parent.right
                spacing:            XScreenTool.base / 2//ScreenTools.defaultFontPixelHeight

                XLabel {
                    Layout.alignment:   Qt.AlignCenter
                    text:               qsTr("Battery Status")
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:  1
                    color:  XGlobalColor.sub
                }

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 5

                                property var batteryValuesAvailable: nameAvailableLoader.item

                                Loader {
                                    id:                 nameAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent
                                    property var _battery: object
                                }

                                XLabel { text: qsTr("Remaining") ; small: true}
                                XLabel { text: qsTr("Voltage")  ; small: true }
                                XLabel { text: qsTr("Current")  ; small: true }
                                XLabel { text: qsTr("Consumed")  ;  visible: batteryValuesAvailable.mahConsumedAvailable ;small: true }

                            }
                        }
                    }

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 5

                                property var batteryValuesAvailable: valueAvailableLoader.item

                                Loader {
                                    id:                 valueAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent
                                    property var _battery: object
                                }

                                XLabel { text: object.percentRemaining.valueString + " " + object.percentRemaining.units; small: true }
                                XLabel { text: object.voltage.valueString + " " + object.voltage.units; small: true }
                                XLabel { text: object.current.valueString + " " + object.current.units; small: true }
                                XLabel { text: object.mahConsumed.valueString + " " + object.mahConsumed.units;  visible: batteryValuesAvailable.mahConsumedAvailable;   small: true }
                            }
                        }
                    }
                }
            }
        }
    }
}




/*
//                if (!isNaN(_battery)) {
//                    if (!isNaN(_battery.percentRemaining.valueString)) {  // valueString   rawValue
//                        if (_battery.percentRemaining.valueString > 98.9) {
//                            return qsTr("100%")
//                        } else {
//                            return _battery.percentRemaining.valueString + _battery.percentRemaining.units
//                        }
//                    } else if (!isNaN(_battery.voltage.valueString)) {   //voltage.rawValue
//                        return _battery.voltage.valueString + _battery.voltage.units   //voltage.valueString
//                    }
//                }

//                return qsTr("100%")
*/

/*
//                if (!isNaN(_battery)) {
//                if(_battery!==undefined) {
//                    switch (_battery.chargeState.rawValue) {
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
//                        return _textCrl//qgcPal.text
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
//                        return "orange"   //qgcPal.colorOrange
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
//                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
//                        return "red"//qgcPal.colorRed
//                    default:
//                        return _textCrl//qgcPal.text
//                    }
//                }
//                else {
//                    return "black"  //qgcPal.text
//                }
*/

