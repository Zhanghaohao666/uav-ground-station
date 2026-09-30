import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.5
import QtQuick.Dialogs 1.2

import QGroundControl 1.0
import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0

import ZHControls 1.0
import ZHSingletonControl 1.0
import XUI 1.0

Item {
    id: root
    width: parent.width
    height: column.height

    property real   _margin:        XScreenTool.base
    property var    _appSettings:   QGroundControl.settingsManager.appSettings

    function clearColorLineObject() {
        QGroundControl.settingsManager.appSettings.showColorLine.value = false
        globals.mapControl.clearColorLine()
    }

    Column {
        id:         column
        width:      parent.width
        spacing:    _margin

        Item { width: 1; height: _margin *2  }

        Column {
            id: contentColumn
            width: parent.width
            spacing: 8
            Item {
                width:  parent.width
                height: rowLayout.height
                RowLayout {
                    id:         rowLayout
                    spacing:    _margin
                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)

                    XComboBox {
                        id:         paramComboBox
                        Layout.preferredWidth:   _margin * 12
                        Layout.preferredHeight:  _margin * 4
                        model:          globals._colorLineArray
                        onActivated: {
                            clearColorLineObject()
                            QGroundControl.settingsManager.appSettings.colorLineParamIndex.value = index
                        }
                        Component.onCompleted: {
                            currentIndex = QGroundControl.settingsManager.appSettings.colorLineParamIndex.value
                        }
                    }

                    XLabel {
                        text:                   qsTr("范围")
                        color:                  "white"
                        Layout.preferredWidth:  _margin * 7
                        horizontalAlignment:    Text.AlignHCenter
                    }

                    XTextFieldFact {
                        id:                 _minValueText
                        // color:              "black"
                        fact: _appSettings.colorLineMinValue
                        Layout.preferredWidth: _margin * 8
                        Layout.preferredHeight: _margin * 4
                        onEditingFinished: clearColorLineObject()
                    }

                    Label {
                        text:   "-"
                        color:  "white"
                        Layout.preferredWidth: _margin * 2
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment:   Qt.AlignVCenter
                    }

                    XTextFieldFact {
                        id: _maxValueText
                        // color: "black"
                        fact: _appSettings.colorLineMaxValue
                        Layout.preferredWidth: _margin * 8
                        Layout.preferredHeight: _margin * 4
                        onEditingFinished: clearColorLineObject()
                    }
                }
            }

            Item { width: 1; height: _margin * 2 }

            Item {
                width: parent.width
                height: gradientRect.height + _margin * 5 + checkBox.height

                Rectangle {
                    id: gradientRect
                    width: parent.width * 0.85
                    height: _margin * 2
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: globals._minColor }
                        GradientStop { position: 0.33; color: globals._yellowColor }
                        GradientStop { position: 0.66; color: globals._cyanColor }
                        GradientStop { position: 1.0; color: globals._maxColor }
                    }
                    XLabel {
                        text: _minValueText.text
                        color:                  "white"
                        anchors.top: parent.bottom
                        anchors.topMargin: _margin * 0.3
                        anchors.left: parent.left
                    }
                    XLabel {
                        text: _maxValueText.text
                        color:                   "white"
                        anchors.top: parent.bottom
                        anchors.topMargin: _margin * 0.3
                        anchors.right: parent.right
                    }
                }



                XSwitchLabelFact {
                    id:                     checkBox
                    width:                  parent.width * 0.95
                    anchors.horizontalCenter:       parent.horizontalCenter
                    anchors.bottom:         parent.bottom
                    fact: QGroundControl.settingsManager.appSettings.showColorLine
                    height:                 _margins * 4
                    desc:                   qsTr("创建色表")//"创建色表" : "Create color chart"
                    lineVisible:            false
                    onClicked: {
                        if(checked) {
                            console.log("创建色表")
                        } else {
                            console.log("销毁色表对象")
                            globals.mapControl.clearColorLine()
                        }
                    }
                }


                // FactCustomCheckBox {
                //     id: checkBox
                //     anchors.bottom: parent.bottom
                //     anchors.horizontalCenter: parent.horizontalCenter
                //     fact: QGroundControl.settingsManager.appSettings.showColorLine
                //     width: parent.width * 0.85
                //     height:  root.width * 0.11
                //     XLabel {
                //         text:                   globals.isChinese ? "创建色表" : "Create color chart"
                //         color:                  textColor
                //         anchors.left:           parent.left
                //         anchors.verticalCenter: parent.verticalCenter
                //     }
                //     onClicked: {
                //         if(checked) {
                //             console.log("创建色表")
                //         } else {
                //             console.log("销毁色表对象")
                //             globals.mapControl.clearColorLine()
                //         }
                //     }
                // }
            }

            Item { width: 1; height: _margin * 1 }

            Item { width: 1; height: _margin * 1 }


            Rectangle {
                id:         csvButton
                width:      parent.width * 0.4
                height:     _margin * 4
                color:      "black"//mouseArea.pressed ? XGlobalColor.theme : XGlobalColor.theme2
                border.width: 1
                border.color:  "white"
                radius: height / 4
                anchors.horizontalCenter: parent.horizontalCenter

                XLabel {
                    text:   qsTr("读取本地设备数据CSV文件")//qsTr("Read local device data")
                    color:  XGlobalColor.theme//"#d35400"
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    // onEntered: parent.color = "#faebd7"
                    // onExited: parent.color = "#fdebd0"
                    onClicked: {
                        mainWindow.showCustomDraw(1)
                    }
                }
            }
        }

        XLabel {
            text: "（调试显示）色表轨迹对象个数：" + globals.mapControl.getColorLineObjectCount()
            color: "red"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: false
        }
    }
}
