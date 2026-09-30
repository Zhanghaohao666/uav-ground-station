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
import QGroundControl.SettingsManager        1.0

import ZHControls           1.0
import ZHSingletonControl   1.0

import XUI 1.0
//-------------------------------------------------------------------------
//-- GPS Indicator
Item {
    id:             _root
    width:          (rfValuesColumn.x + rfValuesColumn.width) * 1.01
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property real _margin : XScreenTool.base

    property string _rangeFinder: {
        if (!_activeVehicle || !_activeVehicle.rangeFinder) {
            return "None"
        }
        var rawValue = _activeVehicle.rangeFinder.rawValue
        return (rawValue === null || isNaN(rawValue)) ? "None" : rawValue.toFixed(2)
    }

    // 新增属性：水面高程和水底高程
    property string _elevation: {
        if (!_activeVehicle || !_activeVehicle.gps) {
            return "None"
        }
        var rawValue = _activeVehicle.gps.altEllipsoid.value - _appSettings.antennaHeight.value + _appSettings.elevationCorrection.value
        return (rawValue === null || isNaN(rawValue)) ? "None" : rawValue.toFixed(2)
    }
    property string water_bottom_elevation: {
        if (!_activeVehicle || !_activeVehicle.gps || !_activeVehicle.rangeFinder) {
            return "None"
        }
        var rawValue = _elevation - _activeVehicle.rangeFinder.rawValue
        return (rawValue === null || isNaN(rawValue)) ? "None" : rawValue.toFixed(2)
    }

    property color  _bgCrl :     ZHGlobalColor.topBackgroundCrl
    property color  _textCrl :   "white"//ZHGlobalColor.topTextCrl

    // 优化后的 Rangefinder 信息组件，使用 GridLayout 划分 XLabel
    Component {
        id:     rangefinderInfo

        Item {
            width:  elevationGrid.width + ScreenTools.defaultFontPixelWidth * 4
            height: elevationGrid.height + ScreenTools.defaultFontPixelHeight * 2
            // radius: ScreenTools.defaultFontPixelHeight * 0.5
            // color:  "#88000000"//_bgCrl
            // border.color:   _textCrl
            // border.width: 1
            // anchors.top: parent.top
            // // anchors.left: toolStrip.left
            // anchors.topMargin: _margin * -8   //高程显示框位置

            // 添加阴影效果（可选）
            // layer.enabled: true
            // layer.effect: DropShadow {
            //     color: "black"
            //     radius: 8
            //     samples: 16
            //     xOffset: 2
            //     yOffset: 2
            // }

            GridLayout {
                id:                 elevationGrid
                columns:            2
                rowSpacing:         ScreenTools.defaultFontPixelHeight * 0.3
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                anchors.centerIn:   parent
                anchors.margins:    ScreenTools.defaultFontPixelHeight

                // 水面高程标题
                XLabel {
                    Layout.alignment:   Qt.AlignCenter
                    text:               qsTr("水深参数")
                    Layout.columnSpan: 2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:  1
                    color:  XGlobalColor.sub
                    Layout.columnSpan: 2

                }

                XLabel {
                    text:           qsTr("水面高程：")
                    color: _textCrl
                    small:  true
                }

                // 水面高程值
                XLabel {
                    text: _activeVehicle ? _elevation : "0.00"
                    color: _textCrl
                    small:  true

                }

                // 水底高程标题
                XLabel {
                    text:           qsTr("水底高程：")
                    small:  true
                    color: _textCrl
                }

                // 水底高程值
                XLabel {
                    text: _activeVehicle ? water_bottom_elevation : "0.00"
                    color: _textCrl
                    small:  true
                }
            }
        }
    }

    Image {
        id:                 rfIcon
        width:              height * 0.85
        height:             parent.height
        source:             "qrc:/image/XHeight.png"
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        id:                     rfValuesColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
        anchors.left:           rfIcon.right
        spacing:                rfIcon.height * 0.2
        XLabel {
            text:                   _activeVehicle ? _rangeFinder : "0.00"
            color:                  _textCrl
            height:                 rfIcon.height * 0.4
            // 水深参数
            onTextChanged: {
                if(!_activeVehicle)
                    return
                var _targetIndex = QGroundControl.settingsManager.appSettings.colorLineParamIndex.value
                if(_targetIndex === 10) {
                    console.log("_targetIndex 等于10是水深参数")
                    globals._colorLineValue = _rangeFinder
                }
                // 用于设备数据csv文件保存
                globals.csvParamArray[10] = _rangeFinder
            }
            small: true
        }
        XLabel {
            text:                   "m"
            height:                 rfIcon.height * 0.4
            color:                  _textCrl
            small: true
        }
    }


    MouseArea {
        anchors.fill: parent
        property bool isPopupVisible: false  // 添加一个状态标志，跟踪弹窗显示状态

        onClicked: {
            if(XGlobalProperty.vhcnull) {
                mainWindow.xShowPopup(rangefinderInfo, _root, 3)
            }
            else {
                mainWindow.xShowPopup(noVehicleComponent, parent, 3)
            }
            // if (!isPopupVisible) {
            //     mainWindow.showIndicatorPopup(_root, rangefinderInfo)  // 显示弹窗
            //     isPopupVisible = true  // 设置状态为“显示”
            // } else {
            //     mainWindow.hideIndicatorPopup()  // 隐藏弹窗
            //     isPopupVisible = false  // 设置状态为“隐藏”
            // }
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
                    text:   "请连接无人机！"
                    small:  true
                }
            }
        }
    }
}
