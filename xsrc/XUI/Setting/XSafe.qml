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
import XUI                   1.0

QGCFlickable {
    id:                 _root
    clip:               true
    anchors.fill:       parent
    contentHeight:      outerItem.height + _margins * 4
    contentWidth:       width

    property var    _appSettings:           QGroundControl.settingsManager.appSettings
    property real   _textFieldItemHeight:   ScreenTools.implicitTextFieldHeight
    property color  _borderColor:           globals.divideColor
    property real   _spacing:               _margins

    property real   _margins:                   XScreenTool.base//ScreenTools.defaultFontPixelWidth
    property real   _labelWidth:                ScreenTools.defaultFontPixelWidth * 10
    property real   _comboFieldWidth:           ScreenTools.defaultFontPixelWidth * 25 //10
    property string _mapProvider:               QGroundControl.settingsManager.flightMapSettings.mapProvider.value
    property string _mapType:                   QGroundControl.settingsManager.flightMapSettings.mapType.value
    property real   _switchButtonHeight:        outerItem.width * 0.11  //开关大小
    // property real   _contentHeight:         outerItem.width * 0.1   //输入框大小

    readonly property color themeC:               XGlobalColor.theme//    "#a0FFFFFF"
    readonly property color textColor:                 "white"
    readonly property real _contentHeight:              _margins * 3.5
    readonly property real _contentHeightAdd:           _margins * 3.5
    readonly property real _contentWidth:               _margins * 12
    property color        marginsC :                     ZHGlobalColor.topDivideCrl

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property Fact _virtualJoystick:                     QGroundControl.settingsManager.appSettings.virtualJoystick

    /// ******************* CRUISE_SPEED 水文模式速度参数 *******************
    property Fact _CRUISE_SPEED_fact:   _activeVehicle ?    controller.getParameterFact(-1, "CRUISE_SPEED") : null
    property real _CRUISE_SPEED_sliderValue
    property Fact _CRUISE_SPEED_userFact:  _CRUISE_SPEED_fact

    ///fact speed
    FactPanelController { id: controller; }
    property Fact _speedfact:            _activeVehicle ?    controller.getParameterFact(-1, "WP_SPEED") : null
    property real _sliderValue//speedValue

    property Fact _failsafeThrEnable:           controller.getParameterFact(-1, "FS_THR_ENABLE")        //遥控器失控
    property Fact _failsafeAction:              controller.getParameterFact(-1, "FS_ACTION")            //失控动作
    property Fact _failsafeBatt1CritVoltage:    controller.getParameterFact(-1, "BATT_CRT_VOLT", false /* reportMissing */)
    property Fact _userFact:                    _speedfact

    property Fact _failsafeBatt1LowVoltage:         controller.getParameterFact(-1, "BATT_LOW_VOLT", false /* reportMissing */)
    property Fact _FSTimeout:                       controller.getParameterFact(-1, "FS_TIMEOUT", false /* reportMissing */)

    //低于电压持续时间
    property Fact _lowVoltageTime:         controller.getParameterFact(-1, "BATT_LOW_TIMER", false /* reportMissing */)
   property Fact _failsafeBatt1CritAct:    controller.getParameterFact(-1, "BATT_FS_CRT_ACT", false /* reportMissing */)

    //PWM门限（错误油门值）
    property Fact _failsafeThrValue:   controller.getParameterFact(-1, "FS_THR_VALUE")

    //推进器通道值
    property Fact _right_ThrTrimValue:   controller.getParameterFact(-1, "SERVO1_MAX")  //左推进器最大油门值
    property Fact _right_ThrMaxValue:   controller.getParameterFact(-1, "SERVO1_TRIM")  //左推进器油门中位值
    property Fact _left_ThrMaxValue:   controller.getParameterFact(-1, "SERVO3_MAX")  //右推进器最大油门值
    property Fact _left_ThrTrimValue:   controller.getParameterFact(-1, "SERVO3_TRIM")  //右推进器油门中位值

    //采样参数值
    // property Fact _samplingInitialValue:   controller.getParameterFact(-1, "SAMPLING_INITIAL")  //采样初始值
    // property Fact _samplingSample1Value:   controller.getParameterFact(-1, "SAMPLING_SAMPLE1")
    // property Fact _samplingSample2Value:   controller.getParameterFact(-1, "SAMPLING_SAMPLE2")
    // property Fact _samplingSample3Value:   controller.getParameterFact(-1, "SAMPLING_SAMPLE3")
    // property Fact _samplingSample4Value:   controller.getParameterFact(-1, "SAMPLING_SAMPLE4")


    property Fact _batt1Monitor:                    controller.getParameterFact(-1, "BATT_MONITOR")
    property Fact _batt2Monitor:                    controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
    property bool _batt2MonitorAvailable:           controller.parameterExists(-1, "BATT2_MONITOR")
    property bool _batt1MonitorEnabled:             _batt1Monitor.rawValue !== 0
    property bool _batt2MonitorEnabled:             _batt2MonitorAvailable ? _batt2Monitor.rawValue !== 0 : false
    property bool _batt1ParamsAvailable:            controller.parameterExists(-1, "BATT_CAPACITY")
    property bool _batt2ParamsAvailable:            controller.parameterExists(-1, "BATT2_CAPACITY")

    property Fact _failsafeBatt1LowAct:             controller.getParameterFact(-1, "BATT_FS_LOW_ACT", false /* reportMissing */)
    property Fact _failsafeBatt2LowAct:             controller.getParameterFact(-1, "BATT2_FS_LOW_ACT", false /* reportMissing */)
    property Fact _failsafeBatt2CritAct:            controller.getParameterFact(-1, "BATT2_FS_CRT_ACT", false /* reportMissing */)
    property Fact _failsafeBatt1LowMah:             controller.getParameterFact(-1, "BATT_LOW_MAH", false /* reportMissing */)
    property Fact _failsafeBatt2LowMah:             controller.getParameterFact(-1, "BATT2_LOW_MAH", false /* reportMissing */)
    property Fact _failsafeBatt1CritMah:            controller.getParameterFact(-1, "BATT_CRT_MAH", false /* reportMissing */)
    property Fact _failsafeBatt2CritMah:            controller.getParameterFact(-1, "BATT2_CRT_MAH", false /* reportMissing */)
    property Fact _failsafeBatt2LowVoltage:         controller.getParameterFact(-1, "BATT2_LOW_VOLT", false /* reportMissing */)
    property Fact _failsafeBatt2CritVoltage:        controller.getParameterFact(-1, "BATT2_CRT_VOLT", false /* reportMissing */)

    property Fact _armingCheck: controller.getParameterFact(-1, "ARMING_CHECK")

    //避障距离
    property Fact _oaMarginMax: controller.getParameterFact(-1, "OA_MARGIN_MAX")
    //避障开关
    property Fact _oaType: controller.getParameterFact(-1, "OA_TYPE")

    //rtsp地址设置
    property var    _videoSettings:             QGroundControl.settingsManager.videoSettings
    Component.onCompleted: {
        console.log(" ************* ZHGeneralSetting.qml onCompleted ************* ")
        if(_videoSettings.useRtspIndex.value === 1) {
            _videoSettings.rtspUrl.value = _videoSettings.rtspUrl1.value
            console.log("[RTSP图传]默认使用rtsp1 ", _videoSettings.rtspUrl1.value )
        }
        else {
            _videoSettings.rtspUrl.value = _videoSettings.rtspUrl2.value
            console.log("[RTSP图传]默认使用rtsp2 ", _videoSettings.rtspUrl2.value )
        }
    }

    // XTextFieldFact {
    //     fact:        _videoSettings.rtspUrl
    //     visible:    false
    // }


    Item {
        id:         outerItem
        width:      parent.width * 0.95
        height:     settingsColumn.height
        anchors.horizontalCenter:   parent.horizontalCenter

        Column {

            id:                         settingsColumn
            anchors.horizontalCenter:   parent.horizontalCenter
            spacing:                    _margins / 2
            width:                      parent.width

            Item {
                height:     _spacing
                width: 1
            }

            Rectangle {
                visible: _batt1MonitorEnabled
                width:   parent.width
                height: battery1FailsafeLoader.y + battery1FailsafeLoader.height + _margins
                color:  "transparent"
                anchors.horizontalCenter: parent.horizontalCenter

                Loader {
                    id:                 battery1FailsafeLoader
                    anchors.margins:    _margins
                    anchors.top:        parent.top
                    anchors.left:       parent.left
                    width:              parent.width
                    sourceComponent:    batteryFailsafeComponent

                    property Fact battMonitor:              _batt1Monitor
                    property bool battParamsAvailable:      _batt1ParamsAvailable
                    property Fact failsafeBattLowAct:       _failsafeBatt1LowAct
                    property Fact failsafeBattCritAct:      _failsafeBatt1CritAct
                    property Fact failsafeBattLowMah:       _failsafeBatt1LowMah
                    property Fact failsafeBattCritMah:      _failsafeBatt1CritMah
                    property Fact failsafeBattLowVoltage:   _failsafeBatt1LowVoltage
                    property Fact failsafeBattCritVoltage:  _failsafeBatt1CritVoltage
                    property Fact lowVoltageTime          : _lowVoltageTime
                    property Fact failsafeThrEnable:        _failsafeThrEnable
                    property Fact fsTimeout:               _FSTimeout
                    property Fact failsafeThrValue:        _failsafeThrValue
                }
            } // Rectangle
            Rectangle {width: parent.width;height: 1;anchors.horizontalCenter: parent.horizontalCenter}

            ///--qsTr("5.speed Setting")
            XSliderSwitch {
                width:                      parent.width * 0.9
                anchors.horizontalCenter:   parent.horizontalCenter
                _unit:                      "m/s"
                _name:                      qsTr("航线速度")  //qsTr("Speed")航线速度
                _valueMin:                  0.1
                _valueMax:                  3.0
                presion:                    1
                _defaultValue:              _activeVehicle ?  (_speedfact ? _speedfact.rawValue.toFixed(1): 1.0) : 1.0
                onUpValue:            {
                    speed.restart();
                    _sliderValue = value
                    _userFact = _speedfact
                    console.log("ZHSliderSwitch speed1: ", _sliderValue)
                }
            }

            XSliderSwitch {
                width:                      parent.width * 0.9
                anchors.horizontalCenter:   parent.horizontalCenter
                _unit:                      "m/s"
                _name:                      qsTr("定速巡航速度")  // 水文模式速度//qsTr("Steering speed")  // 水文模式速度
                _valueMin:                  0.1

                _valueMax:                  3.0
                presion:                    1
                _defaultValue:              _activeVehicle ?  (_CRUISE_SPEED_fact ? _CRUISE_SPEED_fact.rawValue.toFixed(1) : 2.0 ) : 2.0
                onUpValue:            {
                    _CRUISE_SPEED_Timer.restart();
                    _CRUISE_SPEED_sliderValue = value
                    _CRUISE_SPEED_userFact = _CRUISE_SPEED_fact
                    console.log("ZHSliderSwitch 水文模式速度: ", _CRUISE_SPEED_sliderValue)
                }
            }

            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter }
            // 预留空间
            Item { height: _spacing;  width: 1 }

            //2. 浅水报警开关
            XSwitchLabelFact {
                id:                     useCompassCheckBox
                width:                  parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:                 _contentHeight
                desc:                   qsTr("浅水报警开关")//浅水报警开关//qsTr("Shallow water alarm")//浅水报警开关
                lineVisible:            false
                fact:                   QGroundControl.settingsManager.appSettings.rangefinder
            }

            Item {
                width:      parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:     _contentHeight
                visible:    useCompassCheckBox.checked

                XLabel {
                    text:                   "水深" //"浅水水深" : "Depth"
                    color:                  textColor
                    anchors.left:           parent.left
                    anchors.leftMargin:     _margins
                    anchors.verticalCenter: parent.verticalCenter
                }
                Row {
                    spacing:                _margins / 2
                    anchors.right:          parent.right
                    anchors.rightMargin:   _margins
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height:             _contentHeightAdd
                        width:              height
                        color:              "transparent"
                        border.color:       _borderColor
                        radius:             5
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.lowAlarmDepth.value = _appSettings.lowAlarmDepth.value - 0.1
                            }
                        }
                    }

                    XTextFieldFact {
                        height:                 _contentHeight
                        width:                  _contentWidth
                        fact:                   QGroundControl.settingsManager.appSettings.lowAlarmDepth
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height:         _contentHeightAdd
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         5
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.lowAlarmDepth.value = _appSettings.lowAlarmDepth.value + 0.1
                            }
                        }
                    }
                }
            }

            // 预留空间
            Item { height: _spacing;  width: 1 }

            //3. 低电压返航
            // FactCustomCheckBox {
            //     id:                     lowBatteryCheckBox
            //     fact:                   QGroundControl.settingsManager.appSettings.lowBattery
            //     height:                 _switchButtonHeight
            //     width:                  parent.width
            //     XLabel {
            //         text:                   globals.isChinese ? "低电量返航" : "Return with low battery"
            //         color:                  textColor
            //         anchors.left:           parent.left
            //         anchors.verticalCenter: parent.verticalCenter
            //     }
            //     onCheckedChanged: {
            //         if(checked) {
            //             _failsafeBatt1CritAct.value = _failsafeBatt1CritAct.enumValues[1]               //RTL
            //             console.log("_failsafeBatt1CritVoltage.value", _failsafeBatt1CritVoltage.value)
            //         }
            //         else {
            //             _failsafeBatt1CritAct.value = _failsafeBatt1CritAct.enumValues[0]               //没有动作
            //             console.log("_failsafeBatt1CritVoltage.value", _failsafeBatt1CritVoltage.value)
            //         }
            //     }
            // }

            // 预留空间
            Item { height: _spacing;  width: 1 }

            //4. 失联返航
            // FactCustomCheckBox {
            //     id:                 lossLink
            //     fact:               QGroundControl.settingsManager.appSettings.lossLink
            //     height:             _switchButtonHeight
            //     width:              parent.width
            //     XLabel {
            //         text:                   qsTr("Lost and returned home")//失联返航
            //         color:                  textColor
            //         anchors.left:           parent.left
            //         anchors.verticalCenter: parent.verticalCenter
            //     }
            //     onCheckedChanged: {
            //         if(checked) {
            //             _failsafeThrEnable.value =  _failsafeThrEnable.enumValues[1]
            //             _failsafeAction.value = _failsafeAction.enumValues[1]
            //         }
            //         else {
            //             _failsafeThrEnable.value =  _failsafeThrEnable.enumValues[0]
            //             _failsafeAction.value = _failsafeAction.enumValues[0]

            //         }
            //     }
            // }

            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter }
            // 预留空间
            Item { height: _spacing;  width: 1 }

            XSwitchLabelFact {
                id:                     radarMap
                width:                  parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:                 _contentHeight
                desc:                   qsTr("避障雷达图")//"避障雷达图" : "Radar map"
                lineVisible:            false
                fact:                   QGroundControl.settingsManager.appSettings.radarMap
            }

            XSwitchLabel {
                id:                     evade
                width:                  parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:                 _contentHeight
                desc:                   qsTr("避障开关")//"避障开关" : "Obstacle avoidance"
                lineVisible:            false
                valDefalule:            _oaType.value
                onValChanged: {
                    console.log("val: ", val)
                    if(val === 3) {
                        _oaType.value = 3
                    }
                    else {
                        _oaType.value = 0
                    }
                }
            }

            ///--避障距离
            Item {
                width:                          parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:                         _rowHeight
                visible:                        _oaType.value === 3
                XLabel {
                    text:                       "避障距离"//globals.isChinese ? "避障距离" : "Distance"
                    color:                      textColor
                    anchors.left:               parent.left
                    anchors.leftMargin:         _margins
                    anchors.verticalCenter:     parent.verticalCenter
                }

                Row {
                    height:                 _textFieldItemHeight
                    spacing:                _margins / 2
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height:         _contentHeightAdd
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         1
                        anchors.verticalCenter: parent.verticalCenter
                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // var avoidanceDis = _appSettings.avoidanceDis
                                // _appSettings.avoidanceDis.value = avoidanceDis.value - 0.1
                                _oaMarginMax.value = _oaMarginMax.value - 0.1
                            }
                        }
                    }

                    XTextFieldFact {
                        height:                 _contentHeight
                        width:                  height * 2.5
                        fact:                   _oaMarginMax //QGroundControl.settingsManager.appSettings.avoidanceDis
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        height:         _contentHeightAdd
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _oaMarginMax.value = _oaMarginMax.value + 0.1
                                // _appSettings.avoidanceDis.value = _appSettings.avoidanceDis.value + 0.1
                            }
                        }
                    }
                }
            }

            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter }
            // 预留空间
            Item { height: _spacing;  width: 1 }

            // FactCustomCheckBox {
            //     id:                     elevationDisplay
            //     fact:                   QGroundControl.settingsManager.appSettings.elevationDisplay
            //     height:                 _checkboxHeight
            //     width:                  parent.width
            //     XLabel {
            //         text:                   "高程显示"
            //         color:                  textColor
            //         anchors.left:           parent.left
            //         anchors.verticalCenter: parent.verticalCenter
            //     }
            // }

            //---天线高
            Item {
                width:      parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                height:     _rowHeight
                // visible:    elevationDisplay.checked

                XLabel {
                    text:                   "天线高"  //globals.isChinese ? "天线高" : "GPS antenna height"
                    color:                  textColor
                    x:                      _margins
                    anchors.verticalCenter: parent.verticalCenter
                }
                Row {
                    height:                 _textFieldItemHeight
                    spacing:                _margins / 2
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        height:         _contentHeight
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         1
                        anchors.verticalCenter: parent.verticalCenter
                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.antennaHeight.value = _appSettings.antennaHeight.value - 0.01
                            }
                        }
                    }

                    XTextFieldFact {
                        height:                 _contentHeight
                        width:                  height * 3
                        fact:                   QGroundControl.settingsManager.appSettings.antennaHeight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height:         _contentHeightAdd
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.antennaHeight.value = _appSettings.antennaHeight.value + 0.01
                            }
                        }
                    }
                }
            }

            //---高程改正
            Item {
                width:      parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                height:     _rowHeight
                // visible:    elevationDisplay.checked

                XLabel {
                    text:                   "高程改正"//globals.isChinese ? "高程改正" : "Elevation correction"
                    color:                  textColor
                    x:                      _margins
                    anchors.verticalCenter: parent.verticalCenter
                }
                Row {
                    height:                 _textFieldItemHeight
                    spacing:                _margins / 2
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height:         _contentHeight
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         1
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.elevationCorrection.value = _appSettings.elevationCorrection.value - 0.01
                            }
                        }
                    }

                    XTextFieldFact {
                        height:                 _contentHeight
                        width:                  height * 3
                        fact:                   QGroundControl.settingsManager.appSettings.elevationCorrection
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height:         _contentHeightAdd
                        width:          height
                        color:          "transparent"
                        border.color:   _borderColor
                        radius:         2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _appSettings.elevationCorrection.value = _appSettings.elevationCorrection.value + 0.01
                            }
                        }
                    }
                }
            }

            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter }
            // 预留空间
            Item { height: _spacing;  width: 1 }

            //---高级参数
            XSwitchLabelFact {
                id:                     advancedParameter
                width:                  parent.width * 0.95
                anchors.horizontalCenter:       parent.horizontalCenter
                height:                 _contentHeight
                desc:                   qsTr("高级参数")//"高级参数" : "Advanced parameter"
                lineVisible:            false
                fact:                   QGroundControl.settingsManager.appSettings.advancedParameter
            }

            XLabel {
                color:      textColor
                font.bold:  true
                visible: advancedParameter.checked
                text:       "推进器调参" //: "Throttle tuning"
                anchors.horizontalCenter: parent.horizontalCenter  // 将文本水平居中
            }

            //---左推进器最大油门值
            Item {
                width: parent.width
                height: _rowHeight
                visible: advancedParameter.checked

                XLabel {
                    text: "左推进器最大油门" //: "Left maximum throttle"  // 左推进器最大油门值
                    color: textColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    height: _textFieldItemHeight
                    spacing: _margins / 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _right_ThrTrimValue.value = _right_ThrTrimValue.value - 3
                            }
                        }
                    }

                    XTextFieldFact {
                        height: _contentHeight
                        width: height * 2.2
                        fact: _right_ThrTrimValue  // 绑定左推进器最大油门值

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height:     _contentHeightAdd
                        width:   height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _right_ThrTrimValue.value = _right_ThrTrimValue.value + 3
                            }
                        }
                    }
                }
            }

            //---左推进器油门中位值
            Item {
                width: parent.width
                height: _rowHeight
                visible: advancedParameter.checked

                XLabel {
                    text:  "左推进器中位油门"// : "Left median throttle"  // 左推进器油门中位值
                    color: textColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    height: _textFieldItemHeight
                    spacing: _margins / 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _right_ThrMaxValue.value = _right_ThrMaxValue.value - 3
                            }
                        }
                    }

                    XTextFieldFact {
                        height: _contentHeight
                        width: height * 2.2
                        fact: _right_ThrMaxValue  // 绑定左推进器油门中位值

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _right_ThrMaxValue.value = _right_ThrMaxValue.value + 3
                            }
                        }
                    }
                }
            }

            //---右推进器最大油门值
            Item {
                width: parent.width
                height: _rowHeight
                visible: advancedParameter.checked

                XLabel {
                    text:  "右推进器最大油门" //: "Right maximum throttle"  // 右推进器最大油门值
                    color: textColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    height: _textFieldItemHeight
                    spacing: _margins / 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _left_ThrMaxValue.value = _left_ThrMaxValue.value - 3
                            }
                        }
                    }

                    XTextFieldFact {
                        height: _contentHeight
                        width: height * 2.2
                        fact: _left_ThrMaxValue  // 绑定右推进器最大油门值

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _left_ThrMaxValue.value = _left_ThrMaxValue.value + 3
                            }
                        }
                    }
                }
            }

            //---右推进器油门中位值
            Item {
                width: parent.width
                height: _rowHeight
                visible: advancedParameter.checked

                XLabel {
                    text: "右推进器中位油门" //: "Right median throttle"  // 右推进器油门中位值
                    color: textColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    height: _textFieldItemHeight
                    spacing: _margins / 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "-"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _left_ThrTrimValue.value = _left_ThrTrimValue.value - 3
                            }
                        }
                    }

                    XTextFieldFact {
                        height: _contentHeight
                        width: height * 2.2
                        fact: _left_ThrTrimValue  // 绑定右推进器油门中位值

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height: _contentHeightAdd
                        width: height
                        color: "transparent"
                        border.color: _borderColor
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter

                        XLabel {
                            text:               "+"
                            anchors.centerIn:   parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _left_ThrTrimValue.value = _left_ThrTrimValue.value + 3
                            }
                        }
                    }
                }
            }

            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter; visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible}
            Item { height: _spacing;  width: 1 ; visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible}

            //关闭采样
            // XLabel {
            //     color:      textColor
            //     font.bold:  true
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible
            //     text:       globals.isChinese ? "采样瓶通道值" : "Bottle position"
            //     anchors.horizontalCenter: parent.horizontalCenter  // 将文本水平居中
            // }

            // //---关闭---采样初始值设置模块
            // Item {
            //     width: parent.width
            //     height: _rowHeight
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible  // 控制可见性

            //     XLabel {
            //         text: globals.isChinese ? "排水位置" : "Drainage position"  // 显示“采样初始值”标签
            //         color: textColor
            //         anchors.verticalCenter: parent.verticalCenter
            //     }

            //     Row {
            //         height: _textFieldItemHeight
            //         spacing: _margins / 2
            //         anchors.right: parent.right
            //         anchors.verticalCenter: parent.verticalCenter

            //         // 减号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 1
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "-"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingInitialValue.value = _samplingInitialValue.value - 4
            //                 }
            //             }
            //         }

            //         // 显示当前采样初始值的文本框
            //         XTextFieldFact {
            //             height: _contentHeight
            //             width: height * 2.2
            //             fact: _samplingInitialValue  // 绑定采样初始值的 Fact
            //             anchors.verticalCenter: parent.verticalCenter
            //         }

            //         // 加号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 2
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "+"
            //                 color:              qgcPal.colorBlue
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingInitialValue.value = _samplingInitialValue.value + 4
            //                 }
            //             }
            //         }
            //     }
            // }
            // // 采样1
            // Item {
            //     width: parent.width
            //     height: _rowHeight
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible  // 控制可见性

            //     XLabel {
            //         text: globals.isChinese ? "采样瓶一" : "Sample bottle 1"
            //         color: textColor
            //         anchors.verticalCenter: parent.verticalCenter
            //     }

            //     Row {
            //         height: _textFieldItemHeight
            //         spacing: _margins / 2
            //         anchors.right: parent.right
            //         anchors.verticalCenter: parent.verticalCenter

            //         // 减号按钮
            //         Rectangle {
            //             height: _contentHeightAdd
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 1
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "-"
            //                 color:              qgcPal.colorBlue
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample1Value.value = _samplingSample1Value.value - 4
            //                 }
            //             }
            //         }

            //         // 显示当前采样初始值的文本框
            //         XTextFieldFact {
            //             height: _contentHeight
            //             width: height * 2.2
            //             fact: _samplingSample1Value  // 绑定采样初始值的 Fact
            //             anchors.verticalCenter: parent.verticalCenter
            //         }

            //         // 加号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 2
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "+"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample1Value.value = _samplingSample1Value.value + 4
            //                 }
            //             }
            //         }
            //     }
            // }
            // // 采样2
            // Item {
            //     width: parent.width
            //     height: _rowHeight
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible  // 控制可见性

            //     XLabel {
            //         text: globals.isChinese ? "采样瓶二" : "Sample bottle 2"
            //         color: textColor
            //         anchors.verticalCenter: parent.verticalCenter
            //     }

            //     Row {
            //         height: _textFieldItemHeight
            //         spacing: _margins / 2
            //         anchors.right: parent.right
            //         anchors.verticalCenter: parent.verticalCenter

            //         // 减号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 1
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "-"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample2Value.value = _samplingSample2Value.value - 4
            //                 }
            //             }
            //         }

            //         // 显示当前采样初始值的文本框
            //         XTextFieldFact {
            //             height: _contentHeight
            //             width: height * 2.2
            //             fact: _samplingSample2Value  // 绑定采样初始值的 Fact
            //             anchors.verticalCenter: parent.verticalCenter
            //         }

            //         // 加号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 2
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "+"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample2Value.value = _samplingSample2Value.value + 4
            //                 }
            //             }
            //         }
            //     }
            // }
            // // 采样3
            // Item {
            //     width: parent.width
            //     height: _rowHeight
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible  // 控制可见性

            //     XLabel {
            //         text: globals.isChinese ? "采样瓶三" : "Sample bottle 3"
            //         color: textColor
            //         anchors.verticalCenter: parent.verticalCenter
            //     }

            //     Row {
            //         height: _textFieldItemHeight
            //         spacing: _margins / 2
            //         anchors.right: parent.right
            //         anchors.verticalCenter: parent.verticalCenter

            //         // 减号按钮
            //         Rectangle {
            //             height: _contentHeightAdd
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 1
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "-"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample3Value.value = _samplingSample3Value.value - 4
            //                 }
            //             }
            //         }

            //         // 显示当前采样初始值的文本框
            //         XTextFieldFact {
            //             height: _contentHeight
            //             width: height * 2.2
            //             fact: _samplingSample3Value  // 绑定采样初始值的 Fact
            //             anchors.verticalCenter: parent.verticalCenter
            //         }

            //         // 加号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 2
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "+"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample3Value.value = _samplingSample3Value.value + 4
            //                 }
            //             }
            //         }
            //     }
            // }
            // // 采样4
            // Item {
            //     width: parent.width
            //     height: _rowHeight
            //     visible: advancedParameter.checked & ZHGlobalProperty.dataSampleVisible  // 控制可见性

            //     XLabel {
            //         text: globals.isChinese ? "采样瓶四" : "Sample bottle 4"
            //         color: textColor
            //         anchors.verticalCenter: parent.verticalCenter
            //     }

            //     Row {
            //         height: _textFieldItemHeight
            //         spacing: _margins / 2
            //         anchors.right: parent.right
            //         anchors.verticalCenter: parent.verticalCenter

            //         // 减号按钮
            //         Rectangle {
            //             height: _contentHeight
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 1
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "-"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample4Value.value = _samplingSample4Value.value - 4
            //                 }
            //             }
            //         }

            //         // 显示当前采样初始值的文本框
            //         XTextFieldFact {
            //             height: _contentHeight
            //             width: height * 2.2
            //             fact: _samplingSample4Value  // 绑定采样初始值的 Fact

            //             anchors.verticalCenter: parent.verticalCenter
            //             anchors.topMargin: 10
            //         }

            //         // 加号按钮
            //         Rectangle {
            //             height: _contentHeightAdd
            //             width: height
            //             color: "transparent"
            //             border.color: _borderColor
            //             radius: 2
            //             anchors.verticalCenter: parent.verticalCenter

            //             XLabel {
            //                 text:               "+"
            //                 anchors.centerIn:   parent
            //             }
            //             MouseArea {
            //                 anchors.fill: parent
            //                 onClicked: {
            //                     _samplingSample4Value.value = _samplingSample4Value.value + 4
            //                 }
            //             }
            //         }
            //     }
            // }

            // // 预留空间
            // Item { height: _spacing;  width: 1 ; visible: advancedParameter.checked && ZHGlobalProperty.lifterVisible}
            // // 分割线
            // Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter; visible: advancedParameter.checked && ZHGlobalProperty.lifterVisible }
            // // 预留空间
            // Item { height: _spacing;  width: 1 }

            // XLabel {
            //     id:         lifterConfigure
            //     color:      textColor
            //     font.bold:  true
            //     visible: advancedParameter.checked && ZHGlobalProperty.lifterVisible
            //     text:       globals.isChinese ? "升级支架设置" : "Lifting support"
            //     anchors.horizontalCenter: parent.horizontalCenter  // 将文本水平居中
            // }

            // //升降支架反转
            // FactCustomCheckBox {
            //     id:                     lifterReversal
            //     fact:                   QGroundControl.settingsManager.appSettings.lifterReversal
            //     visible:                advancedParameter.checked && ZHGlobalProperty.lifterVisible
            //     height:                 _switchButtonHeight
            //     width:                  parent.width
            //     XLabel {
            //         text:                   globals.isChinese ? "升降支架反向" : "Lifting support reversal"
            //         color:                  textColor
            //         anchors.left:           parent.left
            //         anchors.verticalCenter: parent.verticalCenter
            //     }
            // }

            // // 分割线
            // // Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter; visible: advancedParameter.checked }

            // 预留空间
            Item { height: _spacing;  width: 1 ; visible: advancedParameter.checked}
            // 分割线
            Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter; visible: advancedParameter.checked }
            // 预留空间
            Item { height: _spacing;  width: 1 }

            // // ********************** 图传设置 **********************
            // XLabel {
            //     id:         videoConfigure
            //     color:      textColor
            //     font.bold:  true
            //     visible: advancedParameter.checked
            //     text:     "视频地址" // "Video Address"
            //     anchors.horizontalCenter: parent.horizontalCenter  // 将文本水平居中
            // }

            // //< rtspUrl1
            // Row {
            //     width:  parent.width
            //     height: _rowHeight
            //     spacing: _margins
            //     visible: advancedParameter.checked

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
            //                     var _tipsString =  "切换至视频流1" //: "Switch to Video 1"
            //                     mainWindow.$qmlBottomMessage(_tipsString)
            //                 }
            //             }
            //         }
            //     }

            //     XTextFieldFact {
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
            //     visible: advancedParameter.checked

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
            //                     var _tipsString = "切换至视频流2" //: "Switch to Video 2"
            //                     mainWindow.$qmlBottomMessage(_tipsString)
            //                 }
            //             }
            //         }
            //     }

            //     XTextFieldFact {
            //         width:                      parent.width - ScreenTools.implicitTextFieldHeight - _margins
            //         fact:                       _videoSettings.rtspUrl2
            //         anchors.verticalCenter:     parent.verticalCenter
            //     }
            // }

    // 预留空间
    Item { height: _spacing;  width: 1 ; visible: advancedParameter.checked}
    // 分割线
    Rectangle { width:  parent.width;  height: 1;  color:  globals.divideColor;  anchors.horizontalCenter: parent.horizontalCenter; visible: advancedParameter.checked }
    // 预留空间
    Item { height: _spacing;  width: 1 }

        }
    }

    Timer {
        id:         speed
        interval:   300;
        running:    false;
        repeat:     false
        onTriggered:    {
            if(_activeVehicle) {
                _userFact.rawValue = _sliderValue
                console.log("_userFact.rawValue",  _userFact.rawValue)
            }
        }
    }

    //  水文模式速度定时器
    Timer {
        id:         _CRUISE_SPEED_Timer
        interval:   300;
        running:    false;
        repeat:     false
        onTriggered:    {
            if(_activeVehicle) {
                _CRUISE_SPEED_fact.rawValue = _CRUISE_SPEED_sliderValue
                console.log("_userFact.rawValue",  _CRUISE_SPEED_fact.rawValue)
            }
        }
    }


    Component {
        id: batteryFailsafeComponent

        Column {
            spacing: _margins

            XComboBoxLabelFact {
                desc:               qsTr("低电压保护")
                fact:               failsafeBattLowAct
                width:              parent.width * 0.95
                height:             _contentHeight
                box.width:          1/4 * width   //_margin * 40
                box.height:         _buttonHeight * 0.8
                anchors.horizontalCenter: parent.horizontalCenter
                _line:              false
                // indexModel:         false
            }
            Item {
                height:         _contentHeight
                width:          parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                XLabel { //"Low voltage threshold:") }
                    text: qsTr("低电压阈值")
                    anchors.left: parent.left
                    anchors.leftMargin: _margins
                }
                XTextFieldFact {
                    fact:               failsafeBattLowVoltage
                    height:         _contentHeight
                    width:          1/4 * parent.width
                    anchors.right:  parent.right
                    anchors.rightMargin: _margins
                //   _failsafeBatt1LowVoltage.value = _failsafeBatt1LowVoltage.value - 0.1

                }
            } // GridLayout
            Item {
                height:         _contentHeight
                width:          parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                XLabel { //"Low voltage threshold:") }
                    text: qsTr("低电压时间")
                    anchors.left: parent.left
                    anchors.leftMargin: _margins
                }
                XTextFieldFact {
                    fact:               lowVoltageTime
                    height:             _contentHeight
                    width:              1/4 * parent.width
                    anchors.right:      parent.right
                    anchors.rightMargin: _margins
                }
            }

            ///
            XComboBoxLabelFact {
                desc:               qsTr("失联返航")
                fact:               failsafeThrEnable
                width:              parent.width * 0.95
                height:             _contentHeight
                box.width:          1/3 * width   //_margin * 40
                box.height:         _buttonHeight * 0.8
                anchors.horizontalCenter: parent.horizontalCenter
                _line:              false
                // indexModel:         false
            }

            Item {
                height:         _contentHeight
                width:          parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                XLabel { //"Low voltage threshold:") }
                    text: qsTr("失联时间")
                    anchors.left: parent.left
                    anchors.leftMargin: _margins
                }
                XTextFieldFact {
                    fact:               fsTimeout
                    height:             _contentHeight
                    width:              1/4 * parent.width
                    anchors.right:      parent.right
                    anchors.rightMargin: _margins
                }
            }

            Item {
                height:         _contentHeight
                width:          parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                XLabel { //"Low voltage threshold:") }
                    text: qsTr("油门值")
                    anchors.left: parent.left
                    anchors.leftMargin: _margins
                }
                XTextFieldFact {
                    fact:               failsafeThrValue
                    height:             _contentHeight
                    width:              1/4 * parent.width
                    anchors.right:      parent.right
                    anchors.rightMargin: _margins
                }
            }
        } // Column
    }

}
