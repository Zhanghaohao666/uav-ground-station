import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs  1.2    //StandardButton

import QtGraphicalEffects   1.0

import QGroundControl.FlightMap     1.0
import QGroundControl.Vehicle       1.0

import QGroundControl               1.0

//import QtQuick 2.3
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0

//ValuesController 注入QGroundControl.Controllers中
import QGroundControl.Controllers   1.0
//fact
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.PX4           1.0

//import ZHControls 1.0
//import QGroundControl.SSTopToolBar  1.0
import ZHSingletonControl  1.0
import ZHControls          1.0
import ZHTop          1.0
import ZHSetting      1.0


ZHButton1 {
    id:                     ellipsisBtn
    property    int         _idx:                      0
    //内部使用
    property real imageWidth: 30

    anchors.verticalCenter:         parent.verticalCenter
    autoExclusive:                  true
    width:                          height
    _imageSize:                     height *0.9
    imageSource:                    "/image/XSetting.png"
    _defaultC:                      "black"

    property color divideCrl:       ZHGlobalColor.topDivideCrl
    property color fillCrl:         "#ffffff"   //ZHGlobalColor.topFillCrl

//    property string _mapProvider:               QGroundControl.settingsManager.flightMapSettings.mapProvider.value
//    property string _mapType:                   QGroundControl.settingsManager.flightMapSettings.mapType.value
//    Component.onCompleted: {
////        QGroundControl.settingsManager.flightMapSettings.mapProvider.value
//        console.log("_mapProvider1, _mapType1:", _mapProvider, _mapType)
////        QGroundControl.settingsManager.flightMapSettings.mapProvider.value = "天地图"
////        QGroundControl.settingsManager.flightMapSettings.mapType.value = "卫星地图"
////        console.log("_mapProvider2, _mapType2:", _mapProvider, _mapType)
//    }

    onClicked: {
        //mainWindow.zhShowPopup(ellipsisListview, null, 2) //2: 右侧弹出
        // console.log("点击设置按钮")
        mainWindow.showRightDraw(0)
    }

    Component {
        id:     ellipsisListview
        Rectangle {
            id:                     _root
            width:                  mainWindow.width * 0.5
            height:                 mainWindow.height - 2 -ScreenTool.toolbarHeight
            color:                  fillCrl
            border.width:           4
            border.color:           divideCrl

            signal listIndex(int idx);

            Item {
                id:                         row
                width:                      parent.width
                height:                     parent.height

                ListView {
                    id:                     leftListView
                    height:                 parent.height*0.98//contentItem.childrenRect.height  //parent.height
                    width:                  contentItem.childrenRect.width   //parent.width
                    model:                  toolStripActionList.model
                    anchors.verticalCenter: parent.verticalCenter
                    orientation:            ListView.Vertical
                    spacing :               0//20  //(width - contentItem.children[0].width*3)/2
                    delegate: Item {
                        width:                      btn1.width + 18
                        height:                     modelData.visible ? (btn1.height+ 32) : 0
                        anchors.horizontalCenter:   parent.horizontalCenter
                        visible:                    modelData.visible

                        //每一个都有这个信号
                        Connections{
                            target:                   _root
                            onListIndex:              {
//                                 console.log("index", index, "idx", idx)
                                modelData.checked = (idx===index)
//                                console.log("modelData.checked", modelData.checked)

                            }
                        }

                        ZHButton4 {
                            id:                     btn1
                            anchors.centerIn:       parent
                            radius:                 8
                            _buttonAction:          modelData

                            onClicked: {
                                _root.listIndex(index)
                                 modelData.triggered(this, modelData.checked)
                            }
                        }
                    }
                }

                Rectangle {
                    id:                 divide
                    width:              3
                    height:             parent.height *0.98
                    anchors.left:       leftListView.right
                    anchors.leftMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color:              divideCrl
                }

                Item {
                    width:          mainWindow.width * 0.65 - leftListView.width - divide.width -10////parent.width  //_contentWidth - leftListView.width - divide.width
                    height:         parent.height     //parent.height - leftListView.height - divide.height - row.spacing*2  //parent.height
                    anchors.left:   divide.right
                    anchors.leftMargin: 5

                    Loader {
                        width:              parent.width
                        height:             parent.height
                        sourceComponent:    getComponent()
                    }
                }
            }

//            //外框勾勒
//            Canvas {
//                width:          rect.width
//                height:         rect.height
//                anchors.right:  parent.right
//                anchors.bottom: parent.bottom

//                onPaint: {
//                    var ctx = getContext("2d");         //画师
//                    ctx.strokeStyle =               "#d0d0d0"//qgcPal.sgTheme
//                    ctx.lineWidth =                 6
//                    ctx.moveTo(0, height*0.01)
//                    ctx.lineTo(0, height*0.99);
//                    ctx.moveTo(width, height*0.01)
//                    ctx.lineTo(width,height*0.99);
//                    ctx.stroke();                       //外框勾勒
//                }
//            }
        }
    }

    function getComponent() {
        switch(_idx) {
        case 0: return generalComponent//generalComponent//linkComponent
        case 1: return linkComponent//linkComponent//videoComponentzhbutton
        case 2: return visibleProgressPct ? parameterComponent : emptyComponent
        // case 3: return colorChartComponent
        case 3: return rtkBlueToothComponent
        case 4: return versionComponent
        case 5: return undefined
        case 99: return "qrc:/qml/QGroundControl/Controls/AppMessages.qml"
        }
    }

    property real   _progressPct:     _controllerValid ? _planMasterController.missionController.progressPct : 0
    property bool visibleProgressPct:  false
    on_ProgressPctChanged: {
        if(_progressPct >=0.98) visibleProgressPct = true
    }
//    //连接进度条
//    Rectangle {
//        id:                     progressBar
//        width:                  _controllerProgressPct *  parent.width
//        height:                 XScreenTool.base * 0.5
//        anchors.bottom:         parent.bottom
//        color:                  ZHGlobalColor.highlightCrl
//        visible:                (_controllerProgressPct!==1 && _controllerProgressPct !== 0)
//    }
//    //0
    Component {
        id: generalComponent
        Item {
            ZHGeneralSetting {
                 anchors.fill: parent
            }
        }
    }

    Component {
        id: parameterComponent
        Item {
            ZHParameter {
                 anchors.fill: parent
            }
        }
    }

    //1
    Component {
        id: linkComponent
        Item {
            ZHLinkSettings {
                 anchors.fill: parent
                 anchors.margins: 10
            }
        }
    }

    //2
    Component {
        id: hkwsComponent
        Item {
              ZHVideoSetting {
                 anchors.fill: parent
                 anchors.margins: 10
            }
        }
    }

    // // 色表设置
    // Component {
    //     id: colorChartComponent
    //     Item {
    //         CustomColorChart {
    //              anchors.fill: parent
    //              anchors.margins: 10
    //         }
    //     }
    // }

    // 蓝牙设置
    Component {
        id: rtkBlueToothComponent
        Item {
            Loader {
                anchors.fill: parent
                anchors.margins: 10
                source: "RTKBlueTooth.qml"
            }
        }
    }

    //版本信息
    Component {
        id: versionComponent
        Item {
            ZHVersion {
                anchors.centerIn: parent
            }
        }
    }

    //2
    Component {
        id: saftlyComponent
        Item {
              ZHSafetyComponent {
                 anchors.fill: parent
//                 anchors.margins: 10
            }
        }
    }

    ///~
    Component {
        id: emptyComponent
        Item {
            Rectangle {
               // width:   lab1.width * 1.2
                width:      lab1.width * 1.2
                height:     lab1.height * 1.2
                radius:     height*0.2
                color:      "#aa000000"
                anchors.centerIn:  parent
                ZHLabel {
                    id:                 lab1
                    anchors.centerIn:   parent
                    wrapMode :Text.Wrap
                    text:               qsTr("Waiting for the connection...")//等待连接中
                    color:              "white"
                    big:             true
                }
            }
        }
    }

    //"/image/Video.svg"
    //"/image/Setting.png"
    ToolStripActionList {
        id: toolStripActionList
        model: [
            ToolStripAction {
                text:               qsTr("General")//"设置"//
                iconSource:         "/image/set.svg"
                enabled:            true//_missionController.flyThroughCommandsAllowed
                checkable:          true
                height:             30
                checked:            true
                onTriggered:        {
                    _idx = 0
                }
            },

            ToolStripAction {
                text:               qsTr("Link   ")//"链路"
                iconSource:         "/image/Link.svg"
                enabled:            true//_missionController.flyThroughCommandsAllowed
                checkable:          true
                height:             imageWidth
                visible:            true
                checked:            false

                onTriggered:        {
                    _idx = 1
                }
            },
            ToolStripAction {
                text:               qsTr("Safety   ")//
                iconSource:         "/image/Safety.svg"
                enabled:            true//_missionController.flyThroughCommandsAllowed
                checkable:          true
                height:             imageWidth
                checked:            false

                onTriggered:        {
                    _idx = 2
                }
            },
            // ToolStripAction {
            //     text:               globals.isChinese ? "色表" : "ColorChart" //"色表"
            //     iconSource:         "/InstrumentValueIcons/chart.svg"
            //     enabled:            true
            //     checkable:          true
            //     visible:            true
            //     height:             imageWidth
            //     checked:            false
            //     onTriggered:        {
            //         _idx = 3
            //     }
            // },
            ToolStripAction {
                text:               "GNSS"
                iconSource:         "/InstrumentValueIcons/RTK.svg"
                enabled:            true
                checkable:          true
                visible:            true
                height:             imageWidth
                checked:            false
                onTriggered:        {
                    _idx = 3
                }
            },
            ToolStripAction {
                text:               qsTr("Version")//"版本"//
                iconSource:         "/image/Help.svg"
                enabled:            true
                checkable:          true
                visible:            true
                height:             imageWidth
                checked:            false
                onTriggered:        {
                    _idx = 4
                }
            },
            ToolStripAction {
                text:               qsTr("控制台")
                iconSource:         "/image/Help.svg"
                enabled:            true
                checkable:          true
                visible:            false
                height:             imageWidth
                checked:            false
                onTriggered:        {
                    _idx = 99
                }
            }
        ]
    }
}




