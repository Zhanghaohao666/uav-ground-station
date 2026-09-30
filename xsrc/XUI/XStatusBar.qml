import QtQuick 2.15
import QtQuick.Controls 2.15

import QGroundControl               1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controls          1.0
import QtQuick.Layouts                  1.11
import QGroundControl.FactSystem    1.0

import XUI 1.0

Item {
    id: root

    property Vehicle activeVehicle: XGlobalProperty.vhcnull

    property bool   _armed:         activeVehicle ? activeVehicle.armed : false


    property bool           connected: activeVehicle && !activeVehicle.vehicleLinkManager.communicationLost
    property int            gpsNum: activeVehicle ? activeVehicle.gps.count.rawValue : 0
    property real           hdop: activeVehicle ? activeVehicle.gps.hdop.value : 0
    property real           batteryPercentRemaining: activeVehicle && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0).percentRemaining.rawValue : 100

    property bool           flying: activeVehicle ? activeVehicle.flying : false

    property var   battery0:    activeVehicle && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0) : null//undefined
    property var    _batteryValue:                  battery0 ? battery0.percentRemaining.value : 0
    property var    _batPercentRemaining:           isNaN(_batteryValue) ? 0 : _batteryValue


    //start_cch_20230917
    property bool   _communicationLost:  activeVehicle ? activeVehicle.vehicleLinkManager.communicationLost : false
    property real   _factor:              0.55//0.7
    property real   _factorItem:          1.05

    property bool   uploadClicked:    false  // 跟踪上传按钮是否被点击

    property real _margin:          XScreenTool.base
    property real _r1Width:         (parent.width - _m1Width - _topMargin*2)/2
    property real _m1Width:         parent.width * 0.13   //0.2
    property real _topMargin:       _margin/2

    // objectName : XUIManagerZOrder.nameStatusBar
    // z: XUIManagerZOrder.zFor(this)

    height:         _margin * 5
    width:          parent.width
    // color:          XGlobalColor.background//"transparent" //"#88000000"//"transparent"   //"#44000000"   //"transparent" //ZHGlobalColor.topBackgroundCrl
    y:              XGlobalProperty.videoFull ? - height : 0
    Behavior on y { PropertyAnimation{duration: 300}}
    property color themeC :         XGlobalColor.theme
    property color themeC2 :         XGlobalColor.theme2

    // //效果更好
    // Rectangle {
    //     width: parent.width
    //     height: parent.height * 1.0
    //     gradient: Gradient {
    //         GradientStop { position: 0.0; color: "#bb000000" }
    //         GradientStop { position: 1.0; color: "#77000000" }
    //     }
    // }

    ///=================== flyview =================
    Rectangle {
        id:         flyview
        width:      parent.width
        height:     parent.height - 1
        color:      XGlobalColor.background
    }

    Rectangle {
        width:      parent.width
        height:     1
        y:          flyview.height
        color:      XGlobalColor.line
    }

    Row {
        id:                     leftRow
        anchors.verticalCenter: flyview.verticalCenter
        height:                 parent.height * 0.8
        x:                      _margin
        spacing:                _margin //XGlobalProperty.getSpacing(this, parent.width - 4 * _margin)
        visible:                !XGlobalProperty.isPlanView

        //LOGO
        XColoredImage {
            id:                 logo
            height:              parent.height * 0.5
            width:               height * 3.5
            // sourceSize.height:   height
            anchors.verticalCenter: parent.verticalCenter
            source:             "qrc:/image/xlogo"
            // asynchronous:       true
            // smooth:             true
            // mipmap:             true
            // antialiasing:       true
            // fillMode:           Image.PreserveAspectFit
            color:              XGlobalColor.theme
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    XGlobalProperty.isPlanView = true
                }
            }
        }

        XLabel {
            text:   "无人机指控平台"
            color:  themeC
            big:  true
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: 1
            height: 1
        }

        XButtonColoredImageLabelRow {
            id:                     mainButton
            // width:                  _margin * 7
            // height:                 parent.height * 0.66
            anchors.verticalCenter: parent.verticalCenter
            source:                 "qrc:/image/XOther"
            text:                   "主界面"
            checked:                !XGlobalProperty.isPlanView
            enabled:                XGlobalProperty.isPlanView
            _small:                 true
            _imageRatio:            1.0
            _backDefault:           "transparent"
            _backChecked:           XGlobalColor.theme
            _imageDefault:          XGlobalColor.label2
            _imageChecked:          XGlobalColor.label
            backRect.radius:        4
            onClicked:              XGlobalProperty.isPlanView = false
        }

        XButtonColoredImageLabelRow {
            id:                     planButton
            // width:                  _margin * 8
            // height:                 parent.height * 0.66
            anchors.verticalCenter: parent.verticalCenter
            source:                 "qrc:/image/XDistance"
            text:                   "航线规划"
            checked:                XGlobalProperty.isPlanView
            enabled:                !XGlobalProperty.isPlanView
            _small:                 true
            _imageRatio:            1.0
            _backDefault:           "transparent"
            _backChecked:           XGlobalColor.theme
            _imageDefault:          XGlobalColor.label2
            _imageChecked:          XGlobalColor.label
            backRect.radius:        4
            onClicked:              XGlobalProperty.isPlanView = true
        }
    }

    XButtonColoredImageLabelRow {
        id:                     armBtn
        anchors.right:          rightRowRectangle.left
        anchors.rightMargin:    _margin
        anchors.verticalCenter: parent.verticalCenter
        source:                 _armed ? "qrc:/image/Unlock" : (forceArm ? "qrc:/image/Unlock" : "qrc:/image/Lock")
        text:                   _armed ? "已解锁" : "未解锁"
        _small:                 true
        _imageRatio:            1.0
        _backDefault:           _armed ? XGlobalColor.theme : XGlobalColor.background2
        _backChecked:           _backDefault
        _imageDefault:          _armed ? XGlobalColor.label : XGlobalColor.label2
        _imageChecked:          _imageDefault
        backRect.radius:        4
        property bool forceArm: false
        property string lastImageSource: ""
        hoverEnabled: true
        onPressAndHold: forceArm = true
        onClicked: {
            if (_armed) {
                mainWindow.disarmVehicleRequest()
            } else {
                if (forceArm) {
                    mainWindow.forceArmVehicleRequest()
                } else {
                    mainWindow.armVehicleRequest()
                }
            }
            forceArm = false
        }
    }

    Rectangle {
        id:                     rightRowRectangle
        width:                  rightRowRow.width + _margin * 1
        height:                 rightRowRow.height * 0.8
        radius:                 4
        anchors.verticalCenter: parent.verticalCenter
        color:                  XGlobalColor.background3
        border.color:           XGlobalColor.line
        border.width:           1
        anchors.right:          parent.right
        anchors.rightMargin:    _margin
    }

    Row {
        id:                     rightRowRow
        anchors.centerIn:       rightRowRectangle
        height:                 parent.height * 0.8
        spacing:                _margin //XGlobalProperty.getSpacing(this, parent.width - 4 * _margin)
        visible:                !XGlobalProperty.isPlanView

        //状态
        XLabel {
            id:                 mainStatusLabel
            anchors.verticalCenter: parent.verticalCenter
            height:             parent.height
            width:              Math.max(_margin * 8, implicitWidth + _margin * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            color:              "white"                 //"#E69941"
            text:               mainStatusText()        //"N/"
            property string _flightMode:        activeVehicle ? activeVehicle.flightMode : qsTr("N/A")
            property string _commLostText:      qsTr("Communication Lost")
            property string _readyToFlyText:    qsTr("Ready To Fly")
            property string _notReadyToFlyText: qsTr("Not Ready")
            property string _disconnectedText:  qsTr("Disconnected")
            property string _armedText:         qsTr("Armed")
            property string _flyingText:        qsTr("Flying")
            property string _landingText:       qsTr("Landing")

            function mainStatusText() {
                var statusText
                if (activeVehicle) {
                    mainStatusLabel.color = "white"
                    if (_communicationLost) {
                        gradientSet = allGradients[3]
                        // abnormalAnimation.restart()
                        return mainStatusLabel._commLostText

                    }
                    if (activeVehicle.armed) {
                        gradientSet = allGradients[1]
                        // abnormalAnimation.stop()
                        if (activeVehicle.flying) {
                            return mainStatusLabel._flyingText
                        } else if (activeVehicle.landing) {
                            return mainStatusLabel._landingText
                        } else {
                            return mainStatusLabel._armedText
                        }
                    } else {
                        if (activeVehicle.readyToFlyAvailable) {
                            if (activeVehicle.readyToFly) {
                                gradientSet = allGradients[1]
                                // abnormalAnimation.stop()
                                return mainStatusLabel._readyToFlyText
                            } else {
                                gradientSet = allGradients[2]
                                // abnormalAnimation.restart()
                                return mainStatusLabel._notReadyToFlyText
                            }
                        } else {
                            // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                            if (activeVehicle.allSensorsHealthy && activeVehicle.autopilot.setupComplete) {
                                gradientSet = allGradients[1]
                                // abnormalAnimation.stop()
                                return mainStatusLabel._readyToFlyText
                            } else {
                                gradientSet = allGradients[2]
                                // abnormalAnimation.restart()
                                return mainStatusLabel._notReadyToFlyText
                            }
                        }
                    }
                } else {
                    gradientSet = allGradients[0]
                    // abnormalAnimation.restart()
                    return mainStatusLabel._disconnectedText
                }
            }
        }

        Rectangle {
            width:  1
            height: 1
            color:  XGlobalColor.sub
        }

        FlightModeMenuIndicator {
            id:                     flightModeMenu2
            height:                 parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter
        }
        XBatteryIndicator {
            id:                     batteryLdr
            anchors.verticalCenter: parent.verticalCenter
            height:                 parent.parent.height * 0.8
        }


        XButtonImage {
            id:                     ii_setting
            anchors.verticalCenter:     parent.verticalCenter
            height:                 parent.height *    _factor
            width:                  height
            source:                 "qrc:/image/xsetting"
            color:                  XGlobalColor.sub2
            // imageColor:             XGlobalColor.sub
            onClicked: {
                // XGlobalProperty.settingViewVisible = true
                mainWindow.showToolSelectDialog()
            }
        }

    }

    // 当前颜色组
    property var gradientSet: allGradients[4]
    // // 所有预设颜色组
    // property var allGradients: [
    //     //["#01008000", "#44008000", "#77008000", "#aa008000", "#77008000", "#44008000", "#01008000"], // 绿色
    //     ["#01101010", "#44303030", "#77606060", "#cc909090", "#77606060", "#44303030", "#01101010"],   // 灰色
    //     ["#01008080", "#44008080", "#77008080", "#cc008080", "#77008080", "#44008080", "#01008080"],   // 青色系 正常
    //     ["#01808000", "#44808000", "#77808000", "#cc808000", "#77808000", "#44808000", "#01808000"],   // 灰绿系 告警
    //     ["#01800000", "#44800000", "#77800000", "#cc800000", "#77800000", "#44800000", "#01800000"],   // 红色系 危险
    //     ["#01000080", "#44000080", "#77000080", "#aa000080", "#77000080", "#44000080", "#01000080"]    // 蓝色系
    // ]

    // 所有预设颜色组
    property var allGradients: [
        //["#01008000", "#44008000", "#77008000", "#aa008000", "#77008000", "#44008000", "#01008000"], // 绿色
        [ XGlobalColor.background, "#88606060", "#bb8c8a55", "#88606060", XGlobalColor.background],   // 灰色
        [ XGlobalColor.background, "#88008080", "#bb008080", "#88008080", XGlobalColor.background ],   // 青色系 正常
        [ XGlobalColor.background, "#88808000", "#bb808000", "#88808000", XGlobalColor.background ],   // 灰绿系 告警
        [ XGlobalColor.background, "#88800000", "#bb800000", "#88800000", XGlobalColor.background],   // 红色系 危险
        [ XGlobalColor.background, "#88000080", "#bb000080", "#88000080", XGlobalColor.background]    // 蓝色系
    ]

    //丢失后自动关闭
    Timer {
        id:         closeTimer
        running:    false
        interval:   4000
        onTriggered:  {
            activeVehicle.closeVehicle()
        }
    }
    on_CommunicationLostChanged: {
        if(activeVehicle && _communicationLost) {
            closeTimer.start()
        }
    }

    // SequentialAnimation {
    //     id: abnormalAnimation
    //     loops: 1000
    //     PauseAnimation {
    //         duration: 500
    //     }
    //     PropertyAnimation {
    //         target: abnormalBox
    //         property: "opacity"
    //         from: 1
    //         to: 0.5
    //         duration: 2000
    //     }
    //     PropertyAnimation {
    //         target: abnormalBox
    //         property: "opacity"
    //         from:0.5
    //         to: 1
    //         duration: 2000
    //     }
    // }

    //参数加载完成标志
    property bool _loadParameters:     XGlobalProperty.loadParameters
    //进度条
    property real   _loadProgress:      XGlobalProperty.loadProgress

    ///--连接进度条, 最优先显示，【优先级最高】
    Rectangle {
        id:                             loadProgressRectangle
        visible:                        _loadProgress !== 0
        width:                          parent.width * _loadProgress
        height:                         2
        anchors.bottomMargin:           -2
        anchors.bottom:                 parent.bottom
        color:                          "black"
        Rectangle {
            anchors.fill:               parent
            color:                      XGlobalColor.sub
        }
    }

    //========================== 二级菜单 =================================
    //二级菜单：等待参数加载
    Component {
        id:             waitLoaderComponent
        Item {
            width:    waitLoaderColumn.implicitWidth + ScreenTool.baseSize * 4
            height:   waitLoaderColumn.implicitHeight + ScreenTool.baseSize * 3
            Column {
                id:        waitLoaderColumn
                anchors.centerIn:   parent
                XLabel {
                    text:   "等待参数加载..."
                    small:  true
                }
            }
        }
    }

    //二级菜单：无人机未连接
    Component {
        id:             noVehicleComponent
        Item {
            width:    noVehicleColumn.implicitWidth + _margin * 4
            height:   noVehicleColumn.implicitHeight + _margin * 3
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

    //二级菜单：电量相关
    Component {
        id:             voltageComponent
        Item {
            id:         voltageItem
            width:      voltageGrid.width   + _margin * 4
            height:     voltageGrid.height  + _margin * 4
            property real _voltage :               activeVehicle ? activeVehicle.myVoltage.rawValue : 0

            FactPanelController{
                id: controller
            }

            property Fact _batt_cell_count:       controller.getParameterFact(-1, "BATT_CELL_COUNT")

            GridLayout {
                id:                 voltageGrid
                anchors.margins:    _margin
                columnSpacing:      _margin * 3
                rowSpacing:         _margin
                anchors.centerIn:   parent
                columns: 2

                XLabel { text: qsTr("电池信息")    ;
                    Layout.columnSpan:      2
                }
                Rectangle {
                    height:  1.5
                    Layout.fillWidth:       true
                    Layout.columnSpan:      2     // 占据 2 列
                    color:                  themeC
                }

                XLabel { text: qsTr("Total Voltage")    ;
                    small : true}
                XLabel {
                    id: total_voltage;
                    text: voltageItem._voltage.toFixed(2) + "v" ;
                    small : true;
                }
                XLabel { text: qsTr("Number of battery cells")   ;
                    small : true}
                XLabel {
                    id: cells
                    text: _batt_cell_count.value //QGroundControl.settingsManager.flyViewSettings.batteryCells.value;
                    small : true
                }
                XLabel { text: qsTr("Average single")    ;
                    small : true
                }
                XLabel {
                    id: singleVol;
                    text: (voltageItem._voltage/(cells.text===0 ? 1 : cells.text)).toFixed(2) + "v" ;
                    small : true
                }

                XLabel { text: qsTr("Percent Remaining")     ; small : true}
                XLabel {
                    text: battery0?battery0.percentRemaining.rawValue.toFixed(1) + "%": "0%"
                    small : true
                }
                XLabel { text: qsTr("Current")    ; small : true}
                XLabel {
                    text: battery0 ? battery0.current.rawValue.toFixed(1) + "A":"N/A"
                    small : true
                }
            }
        }
    }

    //二级菜单：gnss
    Component {
        id:         gnssComponent
        Item {
            width:      gnssColunm.width   + _margin * 4
            height:     gnssColunm.height  + _margin * 4

            Column {
                id:                 gnssColunm
                anchors.margins:    _margin
                spacing:            _margin
                anchors.centerIn:   parent

                XLabel {
                    text: (activeVehicle && activeVehicle.gps.count.value >= 0) ? qsTr("GPS Status") : qsTr("GPS data not available")
                    Layout.columnSpan:    2
                    small:  !(activeVehicle && activeVehicle.gps.count.value >= 0)
                }

                Rectangle {
                    height:                 1.5
                    width:                  parent.width
                    color:                  themeC
                }

                GridLayout {
                    id:                 gpsGrid
                    visible:            (activeVehicle && activeVehicle.gps.count.value >= 0)
                    anchors.margins:    _margin
                    columnSpacing:      _margin * 3
                    columns:            2
                    XLabel { text: qsTr("GPS Number"); small: true;  }
                    XLabel { text: activeVehicle ? activeVehicle.gps.count.valueString : qsTr("N/A", "No data") ; small: true ;}
                    XLabel { text: qsTr("GPS Type") ; small: true;}
                    XLabel { text: activeVehicle ? activeVehicle.gps.lock.enumStringValue : qsTr("N/A", "No data") ; small: true; }
                    XLabel { text: qsTr("Horizontal Accuracy") ; small: true ; }
                    XLabel { text: activeVehicle ? activeVehicle.gps.hdop.valueString : qsTr("--.--", "No data") ; small: true; }
                    XLabel { text: qsTr("Vertical Accuracy") ; small: true; }
                    XLabel { text: activeVehicle ? activeVehicle.gps.vdop.valueString : qsTr("--.--", "No data") ; small: true; }
                }
            }
        }
    }

    //         //GPS
    //         Item {
    //             width:                      gpsLdr.width * 1.1//_factorItem
    //             height:                     parent.height *  (_factor-0.1)
    //             anchors.verticalCenter:     parent.verticalCenter
    //             ZHGPSIndicator {
    //                 id:                     gpsLdr
    //                 anchors.centerIn:       parent
    //                 height:                 parent.height
    // //                source:                 "qrc:/ZHUI/ZHTop//*ZHGPSIndicator*/.qml"
    //             }
    //         }


//     //        Loader {
//     //            sourceComponent:            spaComponent
//     //            anchors.verticalCenter:     parent.verticalCenter
//     //        }


//     //        Loader {
//     //            sourceComponent:            spaComponent
//     //            anchors.verticalCenter:     parent.verticalCenter
//     //        }
//     //        Item {
//     //            width:                      messageLdr.width * _factorItem
//     //            height:                     parent.height *  _factor
//     //            anchors.verticalCenter:     parent.verticalCenter
//     //            Loader {
//     //                id:                     messageLdr
//     //                anchors.centerIn:       parent
//     //                height:                 parent.height
//     //                source:                 "qrc:/toolbar/MessageIndicator.qml"
//     //            }
//     //        }
//     //        Loader {
//     //            sourceComponent:    spaComponent
//     //            anchors.verticalCenter:     parent.verticalCenter
//     //        }
//         }


//     //中间状态
//     Item {
//         x:      _l1Width + _l2Width
//         height:  parent.height * 0.75
//         anchors.bottomMargin: _margin / 2
//         anchors.bottom:     parent.bottom
//         width:  _l3Width
// //            color:  ZHGlobalColor.topFillCrl
//         // gradient: Gradient {
//         //     orientation: Qt.Horizontal
//         //     GradientStop { position: 0.0; color: "#88F1AA4B" }
//         //     GradientStop { position: 1.0; color: "#88F1AA4B" }
//         // }
//         Row {
//             id:                 statusRect
//             height:             parent.height
//             anchors.centerIn:   parent
//             spacing:            _margin
//             Image {
//                 id:                     statusImage
//                 anchors.verticalCenter: parent.verticalCenter
//                 height:                 parent.height * 0.6
//                 width:                  height
//                 source:                 "qrc:/image/XBoat.png"
//                 asynchronous:           true
//                 smooth:                 true
//                 mipmap:                 true
//                 antialiasing:           true
//                 fillMode:               Image.PreserveAspectFit
//             }
//             XLabelOutline {
//                 id:                     mainStatusLabel
//                 text:                   mainStatusText()
//                 anchors.verticalCenter: parent.verticalCenter
//                 color:                  "WHITE"//gradientSet

//                 property string _commLostText:      qsTr("通讯丢失")//qsTr("Communication Lost")  "/image/XBoat.png" //
//                 property string _readyToFlyText:    globals.isChinese ? "未解锁" : "准备飞行"//"Ready To Fly" //qsTr("Sailing")
//                 property string _notReadyToFlyText: qsTr("未就绪")
//                 property string _disconnectedText:  qsTr("离线...")
//                 property string _armedText:         qsTr("解锁")
//                 property string _flyingText:        qsTr("航行中")//qsTr("Sailing")
//                 property string _landingText:       qsTr("Landing")

//                 function mainStatusText() {
//                     var statusText
//                     if (activeVehicle) {
//                         if (_communicationLost) {
//                             _mainStatusBGColor = "red"
//                             return mainStatusLabel._commLostText
//                         }
//                         if (activeVehicle.armed) {
//                             _mainStatusBGColor = "green"
//                             if (activeVehicle.flying) {
//                                 return mainStatusLabel._flyingText
//                             } else if (activeVehicle.landing) {
//                                 return mainStatusLabel._landingText
//                             } else {
//                                 return mainStatusLabel._armedText
//                             }
//                         } else {
//                             if (activeVehicle.readyToFlyAvailable) {
//                                 if (activeVehicle.readyToFly) {
//                                     _mainStatusBGColor = "green"
//                                     return mainStatusLabel._readyToFlyText
//                                 } else {
//                                     _mainStatusBGColor = "yellow"
//                                     return mainStatusLabel._notReadyToFlyText
//                                 }
//                             } else {
//                                 // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
//                                 if (activeVehicle.allSensorsHealthy && activeVehicle.autopilot.setupComplete) {
//                                     _mainStatusBGColor = "green"
//                                     return mainStatusLabel._readyToFlyText
//                                 } else {
//                                     _mainStatusBGColor = "yellow"
//                                     return mainStatusLabel._notReadyToFlyText
//                                 }
//                             }
//                         }
//                     } else {
//                         _mainStatusBGColor = "balck"//qgcPal.brandingPurple
//                         return mainStatusLabel._disconnectedText
//                     }
//                 }
//                 MouseArea {
//                     anchors.left:           parent.left
//                     anchors.right:          parent.right
//                     anchors.verticalCenter: parent.verticalCenter
//                     height:                 root.height
//                     enabled:                activeVehicle
//                     onClicked: {
//                         console.log("模式文本")
//                         //mainWindow.showPopup(mainStatusLabel, sensorStatusInfoComponent)
//                     }
//                 }
//             }
//         }
//     }
//     //右边状态
//     Item {
//         x:                          _l1Width + _l2Width + _l3Width
//         y:                          _margin * 0.66
//         width:                      _l2Width
//         height:                     parent.height * 0.8
//         anchors.verticalCenter:     parent.verticalCenter
//         visible:                    !ZHGlobalProperty.inAirway
//         Row {
//             anchors.centerIn:       parent
//             height:                 parent.height
//             //Speed
//             Item {
//                 width:                      speedLdr.width * 1.1//_factorItem
//                 height:                     parent.height *  _factor
//                 anchors.verticalCenter:     parent.verticalCenter
//     //             ZHSpeedIndicator {
//     //                 id:                     speedLdr
//     //                 anchors.centerIn:       parent
//     //                 height:                 parent.height
//     // //                source:                 "qrc:/ZHUI/ZHTop/ZHSpeedIndicator.qml"
//     //             }
//             }
//             Item {
//                 width: _margin/2
//                 height: 1
//             }
//             //Distance
//             Item {
//                 width:                      distanceLdr.width * _factorItem
//                 height:                     parent.height *  _factor
//                 anchors.verticalCenter:     parent.verticalCenter
//                 // ZHDistanceIndicator {
//                 //     id:                     distanceLdr
//                 //     anchors.centerIn:       parent
//                 //     height:                 parent.height
//                 // }
//             }

//             Item {
//                 width: _margin/3
//                 height: 1
//             }

//             Item {
//                 width:                      setting.width * 1.1//_factorItem
//                 height:                     parent.height *  _factor
//                 anchors.verticalCenter:     parent.verticalCenter
//                 // ZHSetting {
//                 //     id:                     setting
//                 //     anchors.centerIn:       parent
//                 //     height:                 parent.height
//                 // }
//             }
//         }
//     }
//     Component {
//         id:                 spaComponent
//         Rectangle {
//             width:          5
//             height:         root.height * 0.8
//             color:          _color
//             property color  _color: ZHGlobalColor.topDivideCrl
//         }
//     }
// //    ZHImageButton {
// //        height: parent.height - _margin * 0.3
// //        width: height * 2.5
// //        source: "qrc:/image/Left.png"
// //        visible: ZHGlobalProperty.inAirway
// //        onClicked: {
// //            ZHGlobalProperty.inAirway = false
// //        }
// //    }

    //============================================================================//
    ///规划界面的参数等

    property var    _planMasterController:      XGlobalProperty.planMasterPlan//globals.planMasterControllerPlanView
    property var    _currentMissionItem:        XGlobalProperty.currentPlanMissionItem          ///< Mission item to display status for

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property bool   _missionValid:              missionItems !== undefined

    property real   _distance:                  _currentMissionItemValid ? _currentMissionItem.distance : NaN
    property bool   _currentMissionItemValid:   _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
    property string _distanceText:              isNaN(_distance) ?              "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0

    property real   _missionTime:               _missionValid ? missionTime : 0

    property real   missionMaxTelemetry:        _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
    property real   _missionMaxTelemetry:       _missionValid ? missionMaxTelemetry : NaN
    property string _missionMaxTelemetryText:   isNaN(_missionMaxTelemetry) ?   "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    property real   missionDistance:            _controllerValid ? _planMasterController.missionController.missionDistance : NaN
    property real   _missionDistance:           _missionValid ? missionDistance : NaN
    property string _missionDistanceText:       isNaN(_missionDistance) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    // property real _vehicleSpeed:                mainWindow._vehicleSpeed
    property real   _newTimer:                60//     isNaN(_missionDistance) ? " " :     (Number(_missionDistance) / (_vehicleSpeed > 0 ? _vehicleSpeed : 1.5)).toFixed(0)
    property int    _offset:                        _margin

    Component.onCompleted:  {
        getNewTimer()
    }

    function getNewTimer() {

       console.log("_newTimer",_newTimer)
//        console.log("_missionDistance",_missionDistance)

        if (!_newTimer) {
            return "00:00:00"
        }

        // console.log("更新预估规划时间:", _newTimer, ", 设备速度:", _vehicleSpeed)

        var t = new Date(2024, 0, 0, 0, 0, Number(_newTimer))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }


    Row {
        id:             planStatusBar
        height:         parent.height * 0.8
        anchors.verticalCenter: flyview.verticalCenter
        spacing:         XGlobalProperty.getSpacing(planStatusBar, parent.width - planStatusBar.x)
        x:                      _margin
        visible:         XGlobalProperty.isPlanView
        XButtonColoredImageLabelRow {
            source:   "qrc:/image/XBack"
            text:         qsTr("主页")
            height:       parent.height
            x:            _margin
            width:        _margin * 6
            backRect.border.width:     0
            backRect.radius: 0
            anchors.verticalCenter:     parent.verticalCenter
            onClicked: {
                // if (uploadClicked) {
                //     _planMasterController.loadFromVehicle()
                //     uploadClicked = false  // 重置标志
                // }
                XGlobalProperty.isPlanView = false
            }
        }
        //Time
        // XSingleValue {
        //     height:                     parent.height *  _factor
        //     anchors.verticalCenter:     parent.verticalCenter
        //     labelName:                  qsTr("航点距离")
        //     labelValue:                 _distanceText
        //     imageSource:                "qrc:/image/XMaxDistance"
        // }
        // XSingleValue {
        //     height:                     parent.height *  _factor
        //     anchors.verticalCenter:     parent.verticalCenter
        //     labelName:                  qsTr("总路程")
        //     labelValue:                 _missionDistanceText
        //     imageSource:                "qrc:/image/XFlightDistance"
        // }
        // //总路程
        // XSingleValue {
        //     height:                     parent.height *  _factor
        //     anchors.verticalCenter:     parent.verticalCenter
        //     labelName:                  qsTr("最远距离")
        //     labelValue:                 _missionMaxTelemetryText
        //     imageSource:                "qrc:/image/XDistanceToHome"
        // }
        //Time
        // XSingleValue {
        //     height:                     parent.height *  _factor
        //     anchors.verticalCenter:     parent.verticalCenter
        //     labelName:                  qsTr("时间")
        //     labelValue:                 getMissionTime()//getNewTimer()
        //     imageSource:                "qrc:/image/XTime"
        // }

        // Row {
        //     anchors.verticalCenter:     parent.verticalCenter
        //     height:       parent.height
        //     spacing:  _margin
        //     XButtonColoredImageLabelRow {
        //         text:       qsTr("下载")
        //         source:     "qrc:/image/XDownload"
        //         backRect.border.width:  0
        //         backRect.radius: 0
        //         anchors.verticalCenter: parent.verticalCenter
        //         height:       parent.height
        //         _rotation:          180
        //         onClicked: {
        //             _planMasterController.loadFromVehicle()
        //         }
        //     }
        //     XButtonColoredImageLabelRow {
        //         text:       qsTr("上传")
        //         backRect.radius: 0
        //         height:       parent.height
        //         source:     "qrc:/image/XUpdate"
        //         backRect.border.width:  0
        //         anchors.verticalCenter: parent.verticalCenter
        //         onClicked: {
        //             _planMasterController.upload()
        //             uploadClicked = true  // 设置标志为真
        //         }
        //     }
        // }
    }

    // ///电池的下划线
    // Rectangle {
    //     width: parent.width
    //     height: _margin * 0.5
    //     anchors.bottom: parent.bottom
    //     // visible:           false// !progressBar.visible
    //     gradient: Gradient {
    //         orientation: Qt.Horizontal
    //         GradientStop { position: 0.0; color: "red" }
    //         GradientStop { position: 1.0; color: "#80ff00" }
    //     }
    //     Rectangle {
    //         height: parent.height
    //         width: parent.width * (1 - (batteryPercentRemaining / 100))
    //         anchors.right: parent.right
    //     }
    //     Rectangle {
    //         height: _margin * 2
    //         anchors.verticalCenter: parent.verticalCenter
    //         width: _margin * 4
    //         radius: height * 0.5
    //         visible: false
    //         x:  (parent.width - width) * batteryPercentRemaining / 100
    //         XLabel {
    //             anchors.centerIn: parent
    //             color:  "black"
    //             text:   "N/A"
    //             font.pixelSize: _margin * 1.2
    //         }
    //     }
    // }

    // //连接进度条
    // on_ActiveVehicleChanged: {
    //     // 连接上设备，并且设备处于解锁情况
    //     if(_activeVehicle) {

    //     } else {
    //         console.log(" ZHStatusBar.qml >>> 设备已断开, 将进度重置为0")
    //         if(_controllerValid)
    //             _planMasterController.missionController.resetProgressPct(0)
    //     }
    // }
    // //property real   _controllerProgressPct:    _controllerValid ? _planMasterController.missionController.progressPct : 0
    // property real   _controllerProgressPct:   globals.activeVehicle && _controllerValid ? _planMasterController.missionController.progressPct : 0
    // on_ControllerProgressPctChanged: {
    //     console.log(" >>> 参数加载进度:", _controllerProgressPct)

    //     // 飞控加载参数完成状态参数（进度>=0.98）
    //     if(_controllerProgressPct >= 0.98) {
    //         console.log("飞控加载参数完成状态参数（进度>=0.98）, 将loadVehicleParamFinished设置为true")
    //         globals.loadVehicleParamFinished = true
    //     }
    // }
    // Rectangle {
    //     id:                     progressBar
    //     width:                  _controllerProgressPct *  parent.width
    //     height:                 _margin * 0.5
    //     anchors.bottom:         parent.bottom
    //     color:                  "green"//ZHGlobalColor.highlightCrl
    //     visible:                _controllerProgressPct > 0 && _controllerProgressPct !==1
    // }

    Component {
        id: sensorStatusInfoComponent

        Rectangle {
            width:          flickable.width + (_margin * 2)
            height:         flickable.height + (_margin * 2)
            radius:         5
            color:          qgcPal.window
            border.color:   qgcPal.text

            QGCFlickable {
                id:                 flickable
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                width:              mainLayout.width
                height:             mainWindow.contentItem.height - (indicatorPopup.padding * 2) - (_margin * 2)
                flickableDirection: Flickable.VerticalFlick
                contentHeight:      mainLayout.height
                contentWidth:       mainLayout.width

                ColumnLayout {
                    id:         mainLayout
                    spacing:    _spacing

                    QGCButton {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               _armed ?  qsTr("Disarm") : (forceArm ? qsTr("Force Arm") : qsTr("Arm"))

                        property bool forceArm: false

                        onPressAndHold: forceArm = true

                        onClicked: {
                            if (_armed) {
                                mainWindow.disarmVehicleRequest()
                            } else {
                                if (forceArm) {
                                    mainWindow.forceArmVehicleRequest()
                                } else {
                                    mainWindow.armVehicleRequest()
                                }
                            }
                            forceArm = false
                            mainWindow.hideIndicatorPopup()
                        }
                    }

                    XLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("Sensor Status")
                    }

                    GridLayout {
                        rowSpacing:     _spacing
                        columnSpacing:  _spacing
                        rows:           activeVehicle.sysStatusSensorInfo.sensorNames.length
                        flow:           GridLayout.TopToBottom

                        Repeater {
                            model: activeVehicle.sysStatusSensorInfo.sensorNames

                            XLabel {
                                text: modelData
                            }
                        }

                        Repeater {
                            model: activeVehicle.sysStatusSensorInfo.sensorStatus

                            XLabel {
                                text: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
