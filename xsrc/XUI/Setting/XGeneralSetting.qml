import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0
import QGroundControl.Controllers           1.0
import QGroundControl.SettingsManager       1.0

import ZHControls            1.0
import ZHSingletonControl    1.0

import XUI 1.0

QGCFlickable {
    id:                 _root
    clip:               true
    anchors.fill:       parent

    contentHeight:      outerItem.height + _margins * 4
    contentWidth:       width

    property real   _labelWidth:                ScreenTools.defaultFontPixelWidth * 10
    property real   _comboFieldWidth:           ScreenTools.defaultFontPixelWidth * 25 //10
    property string _mapProvider:               QGroundControl.settingsManager.flightMapSettings.mapProvider.value
    property string _mapType:                   QGroundControl.settingsManager.flightMapSettings.mapType.value


    readonly property color themeC:               "#a0FFFFFF"
    readonly property color textColor:             "white"
    // property var    _videoSettings:             QGroundControl.settingsManager.videoSettings

    property real   _margin:            XScreenTool.base
    property color       marginsC :                     ZHGlobalColor.topDivideCrl

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property Fact _virtualJoystick:                     QGroundControl.settingsManager.appSettings.virtualJoystick
    property Fact _hkwsjoystick:                        QGroundControl.settingsManager.appSettings.hkwsjoystick

    property Fact _ptzJoystick:                    QGroundControl.settingsManager.appSettings.ptzJoystick
    property Fact _dataSample:                     QGroundControl.settingsManager.appSettings.dataSample
    property Fact _dataSampleAuto:                 QGroundControl.settingsManager.appSettings.dataSampleAuto
    property Fact _waterData:                     QGroundControl.settingsManager.appSettings.waterData
    property Fact _lifter: QGroundControl.settingsManager.appSettings.lifter //升降支架
    property Fact _hidbutton: QGroundControl.settingsManager.appSettings.hidbutton //HID控制开关

    // //hkws zhihui
    // property string _ipValue:        "192.168.144.64"
    // property string _portValue:      "8000"
    // property string _userValue:      "admin"
    // property string _passwordValue:  "njzh123456789"

    //hkws zhihui
    property string _ipValue:        "192.168.144.64"
    property string _portValue:      "8000"
    property string _userValue:      "admin"
    property string _passwordValue:  "zhd192168"

    property real   _switchButtonHeight:        outerItem.width * 0.11  //开关大小
    property real   _contentHeight:             _buttonHeight * 1.2
    property real   _contentWidht:              width * 0.95


    // Component.onCompleted: {
    //     console.log(" ************* ZHGeneralSetting.qml onCompleted ************* ")
    //     if(_videoSettings.useRtspIndex.value === 1) {
    //         _videoSettings.rtspUrl.value = _videoSettings.rtspUrl1.value
    //         console.log("[RTSP图传]默认使用rtsp1 ", _videoSettings.rtspUrl1.value )
    //     }
    //     else {
    //         _videoSettings.rtspUrl.value = _videoSettings.rtspUrl2.value
    //         console.log("[RTSP图传]默认使用rtsp2 ", _videoSettings.rtspUrl2.value )
    //     }
    // }
    // FactTextField {
    //     fact:        _videoSettings.rtspUrl
    //     visible:    false
    // }

    Item {
        id:         outerItem
        width:      parent.width
        height:     settingsColumn.height
        anchors.horizontalCenter:   parent.horizontalCenter

        Column {
            id:                         settingsColumn
            anchors.horizontalCenter:   parent.horizontalCenter
            spacing:                    0//_margins / 2
            width:                      parent.width

            //1.语言
            XComboBoxLabelFact {
                width:                          _contentWidht
                height:                         _contentHeight
                anchors.horizontalCenter:       parent.horizontalCenter
                desc:                           qsTr("Language")
                box.width:                      1/3 * width//_margin * 40
                box.height:                     _buttonHeight * 0.8
                fact:                           QGroundControl.settingsManager.appSettings.qLocaleLanguage
                box.indexModel: false
            }

            //2.地图源
            XComboBoxLabelFact {
                width:                          _contentWidht
                height:                         _contentHeight
                anchors.horizontalCenter:       parent.horizontalCenter
                desc:                           qsTr("地图源")
                box.width:                      1/3 * width//_margin * 40
                box.height:                     _buttonHeight * 0.8
                model:       QGroundControl.mapEngineManager.mapProviderList
                box.indexModel: false
                onActivated: {
                    _mapProvider = mapProviderCombo.box.textAt(index)
                    QGroundControl.settingsManager.flightMapSettings.mapProvider.value =  mapProviderCombo.box.textAt(index)
                    QGroundControl.settingsManager.flightMapSettings.mapType.value=QGroundControl.mapEngineManager.mapTypeList(mapProviderCombo.box.textAt(index))[0]
                }
                Component.onCompleted: {
                    var index = box.find(_mapProvider)
                    if(index < 0) {
                        index = 0
                    }
                    box.currentIndex = index
                }
            }
            //3.地图源
            XComboBoxLabelFact {
                id:                             mapTypeCombo
                width:                          _contentWidht
                height:                         _contentHeight
                anchors.horizontalCenter:       parent.horizontalCenter
                desc:                           qsTr("Map Type")
                box.width:                      1/3 * width//_margin * 40
                box.height:                     _buttonHeight * 0.8
                model:                          QGroundControl.mapEngineManager.mapTypeList(_mapProvider)
                box.indexModel: false
                onActivated: {
                    _mapType =  mapTypeCombo.box.textAt(index)
                    QGroundControl.settingsManager.flightMapSettings.mapType.value=mapTypeCombo.box.textAt(index)
                }
                Component.onCompleted: {
                    var index =  mapTypeCombo.box.find(_mapType)
                    if(index < 0)  {
                        index = 0
                    }
                    mapTypeCombo.currentIndex = index
                }
            }

            //4. 虚拟遥杆开关
            XSwitchLabelFact {
                width:      _contentWidht
                height:     _contentHeight
                desc:       qsTr("Virtual Joystick")//虚拟遥杆开关
                lineVisible: true
                fact:       _virtualJoystick
                visible:    _virtualJoystick.visible
                anchors.horizontalCenter:       parent.horizontalCenter
            }

            //5.云台开关
            XSwitchLabelFact {
                id:         _ptzJoySwitch
                width:      _contentWidht
                height:     _contentHeight
                desc:       qsTr("PTZ Switch")
                lineVisible: true
                checked:    XGlobalProperty.gimbal
                // fact:       _ptzJoystick
                // visible:    _ptzJoystick.visible
                anchors.horizontalCenter:    parent.horizontalCenter
                onCheckedChanged:  {
                // onClicked: {
                    console.log("checked:", _ptzJoySwitch.checked, QGroundControl.settingsManager.appSettings.ptzJoystick.value)
                    XGlobalProperty.gimbal = checked
                    if(_ptzJoySwitch.checked) {
                        //start_cch_20240313 [win]
                        console.log("onClickedLogin")
                        gloalHKWS.onClickedLogin(_ipValue, _portValue, _userValue, _passwordValue)
                    }
                    else {
                    }
                }
            }

            // //6.水体采样开关
            // XSwitchLabelFact {
            //     width:      _contentWidht
            //     height:     _contentHeight
            //     desc:       qsTr("Water sampling") // 水体采样开关
            //     lineVisible: true
            //     visible:            _dataSample.visible
            //     fact:               _dataSample
            //     anchors.horizontalCenter:       parent.horizontalCenter
            // }

            //8.水质参数开关
            XSwitchLabelFact {
                width:      _contentWidht
                height:     _contentHeight
                desc:       qsTr("Water quality panel") // 水质参数开关
                lineVisible: true
                visible: _waterData.visible
                fact: _waterData
                anchors.horizontalCenter:       parent.horizontalCenter
            }

            //8.语音开关
            XSwitchLabelFact {
                width:      _contentWidht
                height:     _contentHeight
                desc:       qsTr("Voice Announcement") // 水质参数开关
                lineVisible: true
                visible: _audioMuted.visible
                fact: _audioMuted
                anchors.horizontalCenter:       parent.horizontalCenter
                property Fact _audioMuted: QGroundControl.settingsManager.appSettings.audioMuted
            }

            // //10.升降支架开关
            // XSwitchLabelFact {
            //     width:      _contentWidht
            //     height:     _contentHeight
            //     desc:       qsTr("Lifting Support")     //升降支架开关
            //     lineVisible: true
            //     visible:            _lifter.visible
            //     fact:               _lifter
            //     anchors.horizontalCenter:       parent.horizontalCenter
            // }

            //11. HID控制开关
            XSwitchLabelFact {
                width:                      _contentWidht
                anchors.horizontalCenter:   parent.horizontalCenter
                height:                     _contentHeight
                desc:                       qsTr("Switch Camera")
                lineVisible:                true
                visible:                    _hidbutton.visible
                fact:                       _hidbutton
            }

            // // ********************** 图传设置 **********************
            // XLabel {
            //     id:         videoConfigure
            //     color:      textColor
            //     font.bold:  true
            //     visible: advancedParameter.checked
            //     text:     "视频地址" // "Video Address"
            //     anchors.horizontalCenter: parent.horizontalCenter  // 将文本水平居中
            // }

            //< rtspUrl1
            // Row {
            //     width:  parent.width
            //     height: _rowHeight
            //     spacing: _margins
            //     visible: advancedParameter.checked

                // Rectangle {
                //     id:                         rtsp1CheckBox
                //     height:                     ScreenTools.implicitTextFieldHeight
                //     width:                      height
                //     color:                      _checked ? qgcPal.colorBlue : "transparent"
                //     border.color:               "black"
                //     anchors.verticalCenter:     parent.verticalCenter
                //     property bool _checked: _videoSettings.useRtspIndex.value === 1

                    // QGCColoredImage {
                    //     source:     "/qmlimages/checkbox-check.svg"
                    //     color:      "white"
                    //     mipmap:     true
                    //     fillMode:   Image.PreserveAspectFit
                    //     width:      parent.width * 0.75
                    //     height:     width
                    //     sourceSize.height: height
                    //     anchors.centerIn:  parent
                    //     visible:    parent._checked
                    // }
                //     MouseArea {
                //         anchors.fill: parent
                //         onClicked: {
                //             if (!rtsp1CheckBox._checked) {
                //                 rtsp1CheckBox._checked = true
                //                 _videoSettings.useRtspIndex.value = 1
                //                 // 设置rtsp流
                //                 _videoSettings.rtspUrl.value = _videoSettings.rtspUrl1.value
                //                 var _tipsString =  "切换至视频流1" //: "Switch to Video 1"
                //                 mainWindow.$qmlBottomMessage(_tipsString)
                //             }
                //         }
                //     }
                // }

            Item {
                width: 1
                height: _margin * 2
            }

            XTextFieldFact {
                width:                      _contentWidht
                anchors.horizontalCenter:   parent.horizontalCenter
                height:                     _contentHeight * 0.8
                fact:                       QGroundControl.settingsManager.videoSettings.rtspUrl1
            }
            // }


            // //12.风动开关
            // XSwitchLabelFact {
            //     id:                 windBox
            //     width:              _contentWidht
            //     height:             _contentHeight
            //     desc:               globals.isChinese ? "风动" : qsTr("Wind power switch") // 风动开关
            //     lineVisible:        true
            //     visible:            _activeVehicle && mainWindow._Use_WindPower && globals.loadVehicleParamFinished
            //     checked:            visible ? globals.windPowerSwitch : false
            //     anchors.horizontalCenter:       parent.horizontalCenter
            //     MouseArea {
            //         anchors.fill: parent
            //         onClicked: {
            //             _setWindPower(checked)
            //         }
            //         function _setWindPower(isOpen) {
            //             // 在解锁状态下打开风动开关时跳出弹窗“请先将无人船加锁”
            //             if(globals.vehicleArmed) {
            //                 checked = false
            //                 armedConfirmation.open()
            //                 return
            //             }

            //             // 风动开关仅在解锁状态下可用
            //             if(mainWindow.fact_SERVO1_FUNCTION === null) {
            //                 console.log("fact_SERVO1_FUNCTION is null")
            //                 return
            //             }

            //             if(isOpen) {
            //                 console.log(" >>> 风动开关开启")
            //                 mainWindow.fact_SERVO1_FUNCTION.value = 0
            //                 mainWindow.fact_SERVO2_FUNCTION.value = 0
            //                 mainWindow.fact_SERVO3_FUNCTION.value = 73
            //                 mainWindow.fact_SERVO4_FUNCTION.value = 74

            //                 globals.windPowerSwitch = true
            //             } else {
            //                 console.log(" >>> 风动开关关闭")
            //                 mainWindow.fact_SERVO1_FUNCTION.value = 73
            //                 mainWindow.fact_SERVO2_FUNCTION.value = 74
            //                 mainWindow.fact_SERVO3_FUNCTION.value = 0
            //                 mainWindow.fact_SERVO4_FUNCTION.value = 0

            //                 globals.windPowerSwitch = false
            //             }
            //         }
            //         MessageDialog {
            //             id:                 armedConfirmation
            //             //title:              ""
            //             text:               globals.isChinese ? "请先将无人船加锁" : qsTr("Please arm the vehicle first")
            //             standardButtons:    StandardButton.Ok
            //         }
            //     }
            // }

            // 分割线
            // Rectangle { visible: windBox.visible;  width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter }

            // Item { width: 1; height: _margins;}

            // // ********************** 图传设置 **********************
            // XLabel {
            //     id:         videoConfigure
            //     color:      textColor
            //     font.bold:  true
            //     text:       qsTr("Video Address: ")
            // }

            // //< rtspUrl1
            // Row {
            //     width:  parent.width
            //     height: _rowHeight
            //     spacing: _margins

            //     Rectangle {
            //         id:                         rtsp1CheckBox
            //         height:                     ScreenTools.implicitTextFieldHeight
            //         width:                      height
            //         color:                      _checked ? qgcPal.colorBlue : "transparent"
            //         border.color:               "black"
            //         anchors.verticalCenter:     parent.verticalCenter
            //         property bool _checked: _videoSettings.useRtspIndex.value === 1

            //         QGCColoredImage {
            //             source:     "/qmlimages/checkbox-check.svg"
            //             color:      "white"
            //             mipmap:     true
            //             fillMode:   Image.PreserveAspectFit
            //             width:      parent.width * 0.75
            //             height:     width
            //             sourceSize.height: height
            //             anchors.centerIn:  parent
            //             visible:    parent._checked
            //         }
            //         MouseArea {
            //             anchors.fill: parent
            //             onClicked: {
            //                 if (!rtsp1CheckBox._checked) {
            //                     rtsp2CheckBox._checked = false
            //                     rtsp1CheckBox._checked = true
            //                     _videoSettings.useRtspIndex.value = 1
            //                     // 设置rtsp流
            //                     _videoSettings.rtspUrl.value = _videoSettings.rtspUrl1.value
            //                     var _tipsString = globals.isChinese ? "切换至视频流1" : "Switch to Video 1"
            //                     mainWindow.$qmlBottomMessage(_tipsString)
            //                 }
            //             }
            //         }
            //     }

            //     FactTextField {
            //         width:                      parent.width - ScreenTools.implicitTextFieldHeight - _margins
            //         fact:                       _videoSettings.rtspUrl1
            //         anchors.verticalCenter:     parent.verticalCenter
            //     }
            // }

            // //< rtspUrl2
            // Row {
            //     width:  parent.width
            //     height: _rowHeight
            //     spacing: _margins

            //     Rectangle {
            //         id:                         rtsp2CheckBox
            //         height:                     ScreenTools.implicitTextFieldHeight
            //         width:                      height
            //         color:                      _checked ? qgcPal.colorBlue : "transparent"
            //         border.color:               "black"
            //         anchors.verticalCenter:     parent.verticalCenter
            //         property bool _checked: _videoSettings.useRtspIndex.value === 2

            //         QGCColoredImage {
            //             source:     "/qmlimages/checkbox-check.svg"
            //             color:      "white"
            //             mipmap:     true
            //             fillMode:   Image.PreserveAspectFit
            //             width:      parent.width * 0.75
            //             height:     width
            //             sourceSize.height: height
            //             anchors.centerIn:  parent
            //             visible:    parent._checked
            //         }
            //         MouseArea {
            //             anchors.fill: parent
            //             onClicked: {
            //                 if (!rtsp2CheckBox._checked) {
            //                     rtsp1CheckBox._checked = false
            //                     rtsp2CheckBox._checked = true
            //                     _videoSettings.useRtspIndex.value = 2
            //                     // 设置rtsp流
            //                     _videoSettings.rtspUrl.value = _videoSettings.rtspUrl2.value
            //                     var _tipsString = globals.isChinese ? "切换至视频流2" : "Switch to Video 2"
            //                     mainWindow.$qmlBottomMessage(_tipsString)
            //                 }
            //             }
            //         }
            //     }

            //     FactTextField {
            //         width:                      parent.width - ScreenTools.implicitTextFieldHeight - _margins
            //         fact:                       _videoSettings.rtspUrl2
            //         anchors.verticalCenter:     parent.verticalCenter
            //     }
            // }
        }
    }
}
