import QtQuick          2.12

//import QtQuick.Window 2.12
//import QtQuick.Controls 2.5
//import QtQuick.Layouts  1.11
//import QtQuick.Dialogs  1.3
//import Qt.labs.qmlmodels 1.0

//import QtQuick.Controls 2.4
//import QtQuick.Layouts  1.11
import QtQuick              2.3
import QtLocation           5.3
import QtPositioning        5.3
import QtGraphicalEffects   1.0
import QtQuick.Layouts          1.2


import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0

import QGroundControl.SGControls        1.0
import SGLibs.feiyu                   1.0

Rectangle {
    width:  20
    height: 20
    color: "red"
}
//Item {
//    id:                         content
//    width:                      rootCol.implicitWidth + _margin*2
//    height:                     rootCol.implicitHeight + _margin*4

//    property real   _margin:            5
//    property int    _bordW:             2
//    property color  _black:             "#88000000"
//    property color  _arrows:            "yellow"
//    property real   textFeildWidth:      30
//    property real   size:               ScreenTools.defaultFontPixelHeight * 4
//    property var    _sanHang:            globalSanHang
//    property var    _baseValue:         _sanHang.baseValue  //
//    property var    _baseName:          _sanHang.baseName
//    property var    _baseUnit:          _sanHang.baseUnit
//    property var    _baseZoom:          _sanHang.baseZoom
//    property bool   _boxFlag:           true
//    Column {
//        id:                     rootCol
//        width:                  Math.max(row1,row2)
//        anchors.centerIn:       parent
//        spacing:                _margin
//        Row {
//            id:                   row1
//            spacing:              _margin
//            //检测框控制
//            SGHoverHoriButton {
//                text:                      _boxFlag ?  qsTr("关闭检测框") : qsTr("打开检测框")
//                imageSource:                "/qmlimages/SG/Shoot.svg"
//                onClicked: {
//                    //int SanHangCtr::set_detect_model(unsigned char devno, unsigned char box_flag, bool output_parameters_flag)
//                    if(_boxFlag) {
//                        _sanHang.set_detect_model(0x01, false, true)
//                        _sanHang.set_detect_model(0x02, false, true)
//                    }
//                    else {
//                        _sanHang.set_detect_model(0x01, true, true)
//                        _sanHang.set_detect_model(0x02, true, true)
//                    }
//                    _boxFlag =!_boxFlag
//                }
//            }
//            //取消追踪模式
//            SGHoverHoriButton {
//                text:                       qsTr("停止追踪")
//                imageSource:                "/qmlimages/SG/Shoot.svg"
//                visible:                    _sanHang.trackMode === 2
//                onClicked: {
//                    _sanHang.set_track_mode(0x01, 0x00, 0x00, 1, 1, 2, 2)
//                    _sanHang.set_track_mode(0x02, 0x00, 0x00, 1, 1, 2, 2)
//                }
//            }
//            //复位按钮
//            SGHoverHoriButton {
//                text:                       qsTr("复位")
//                imageSource:                "/qmlimages/SG/Shoot.svg"
//                onClicked: {
//                    _sanHang.set_ptz(0xC1, 0x00, 0, 200)
//                }
//            }
//        }
//        Row {
//            id:                   row2
//            spacing:              _margin
//            Repeater {
//                id:     statusNameRepeater
//                model:  _baseValue
//                Row{
//                    id: _row
//                    SGLabel {
//                        color:                            "white"//"#424200"
//                        horizontalAlignment:              Text.AlignHCenter
//                        text:                             _baseName[index]
//                    }
//                    SGLabel {
//                        color:                            "#CCFF80"//qgcPal.sgButton//"#336666"
//                        horizontalAlignment:              Text.AlignHCenter
//                        text:                             modelData  + _baseUnit[index]
//                    }
//                }
//            }
//        }

////            Row {
////                Layout.columnSpan:  2
////                QGCLabel {
////                    color:                            "white"//"#424200"
////                    horizontalAlignment:              Text.AlignHCenter
////                    font.pointSize:                   12//ScreenTools.mediumFontPointSize * 1.0
////                    text:                             qsTr("镜头变焦")
////                    font.bold:                        true
////                }
////                Repeater {
////                    model:    _baseZoom
////                    QGCLabel {
////                        color:                            "#CCFF80"//qgcPal.sgButton//"#336666"
////                        horizontalAlignment:              Text.AlignHCenter
////                        font.pointSize:                   12//ScreenTools.mediumFontPointSize *1.0
////                        text:                             "  " + modelData
////                        font.bold:                        true
////                    }
////                }
////            }
////            RowLayout {
////                Layout.columnSpan:  2
////                Layout.alignment:   Qt.AlignHCenter
////                Layout.fillWidth:            true
////                SGHoverHoriButton {
////                    id: sitl
////                    text:                   _tsSITL ? qsTr("使用SITL") : qsTr("使用DYT")
////                    enabled:                true
////                    imageSource:            "/qmlimages/SG/Shoot.svg"
////                    Layout.fillWidth:            true
////                    onClicked: {
////                        _tsSITL = !_tsSITL
////                        if(_isTsCMD)        sanHang.setTsSITL(_tsSITL);
////                    }
////                }
////                Item {
////                    Layout.fillWidth:       true            //textFeildWidth*1.5
////                    height: 1
////                }
////                QGCComboBox {
////                    model:   _tsState
////                    font.pointSize:             14
////                    Layout.fillWidth:           true
////                    onActivated: {
////                        if(_isTsCMD)  sanHang.setTargetState(index)
////                    }
////                }
////            }

////            //start_cch_20230206
////            RowLayout {
////                Layout.columnSpan:  2
////                Layout.alignment:   Qt.AlignHCenter
////                Layout.fillWidth:            true

////                QGCComboBox {
////                    id:                         tsControl
////                    model:                      _tsSetParam
////                    font.pointSize:             14
////                    Layout.fillWidth:           true
////                    onActivated: {
////                        switch(currentIndex){
////                            case 1: _postfix = " m"
////                                  break;
////                            case 2: _postfix = " m/s"
////                                  break;
////                            case 3: _postfix = " "
////                                  break;
////                            case 4: _postfix = " m/s"
////                                  break;
////                            case 5: _postfix = " "
////                                  break;
////                        }
////                        if(currentIndex===0) {
////                            _isTsCMD = true
////                        }
////                        else {
////                            _isTsCMD = false
////                        }
////                    }
////                }
////                Item {
////                    Layout.fillWidth:       true            //textFeildWidth*1.5
////                    height: 1
////                }
////                Item {
////                    Layout.preferredWidth:              45 //textFeildWidth*1.5
////                    Layout.fillHeight   :               true
////                    QGCTextField {
////                        id:                                 tsControlValue
////                        anchors.centerIn:                   parent
////                        width:                              parent.width*0.9
////                        height:                             parent.height*0.9
////                        text:                               "0 "
////                        pointSize:                          13
////                    }
////                }
////                SGHoverHoriButton {
////                    text:                       "发送"
////                    enabled:                    !_isTsCMD
////                    imageSource:                "/qmlimages/SG/Shoot.svg"
////                    Layout.fillWidth:            true
////                    onClicked: {
////                        console.log("index", tsControl.currentIndex, "text", tsControlValue.text)
////                        sanHang.setTsControl(tsControl.currentIndex, tsControlValue.text);
////                    }
////                }
////            }

////        Item {
////            width: 1
////            height: 1
////            Layout.columnSpan:  2
////        }
//    }
//}



