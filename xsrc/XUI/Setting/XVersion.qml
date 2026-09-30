import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import QGroundControl.FlightMap 1.0
import QGroundControl.Vehicle 1.0
import QGroundControl 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Controllers 1.0

import ZHControls 1.0

import XUI 1.0

Item {

    property string appVersion: XGlobalProperty.version

    // ****** 返回编译代码时间 根据每次编译代码时间自动更新 ******
    property string appDatenum: QGroundControl.buildDateTime()
    property real _margin:  XScreenTool.base
    Column {
        spacing:    _margin
        width:      parent.width

        Item {
            height:  _margin
            width: 1
        }

        Item {
            width:   parent.width
            height:  versionLabel.height
            XLabel {
               id:               versionLabel
               x:               _margin * 4
               text:            qsTr("系统版本")
            }
            XLabel {  // 导引头状态
                text:           appVersion
                anchors.right: parent.right
                anchors.rightMargin: _margin * 4
            }
        }

        Rectangle {
            height: 1;
            width: parent.width * 0.95
            color: "#aaaaaa"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width:   parent.width
            height:  versionLabel.height
            XLabel {
               x:       _margin * 4
               text:    qsTr("日期")
            }
            XLabel {   // 飞控状态
                text: appDatenum
                anchors.right: parent.right
                anchors.rightMargin: _margin * 4
            }
        }

        Rectangle {
            height: 1;
            width: parent.width * 0.95
            color: "#aaaaaa"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width:   parent.width
            height:  versionLabel.height
            XLabel {
               x:       _margin * 4
               text:    qsTr("序列号")
            }
            XLabel {   // 飞控状态
                text:   "H5D865ASF3"
                anchors.right: parent.right
                anchors.rightMargin: _margin * 4
            }
        }
    }

    // MouseArea {
    //     id: mouseArea
    //     anchors.fill: parent
    //     onClicked: {
    //         _clickCount++
    //         eggTimer.restart()
    //         if (_clickCount == 5) {
    //             advancedModeConfirmation.open()
    //         }
    //     }

    //     property int _clickCount: 0

    //     Timer {
    //         id: eggTimer
    //         interval: 1000
    //         repeat: false
    //         onTriggered: parent._clickCount = 0
    //     }
    // }


    CustomButton {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "检查版本更新"
        visible:    false
        onClicked: {
            console.log("检查版本更新按钮被点击")
            checkForUpdates()
        }
    }

    CustomDialog {
        id: advancedModeConfirmation
        dialogTitle: globals.isChinese ? "高级模式" : "Advanced Mode"
        dialogText: globals.isChinese ? "是否进入高级模式？" : "Whether to enter the advanced mode？"
        onAccepted: {
            mainWindow.showSetupTool()
            advancedModeConfirmation.close()
        }
    }

    CustomDialog {
        id: updateDialog
        dialogTitle: qsTr("版本更新")
        dialogText: ""
    }

    CustomDialog {
        id: loadingDialog
        dialogTitle: qsTr("请稍候")
        dialogText: qsTr("正在检查更新...")
        showButtons: false
    }

    CustomDialog {
        id: newVersionDialog
        property string downloadUrl: ""
        dialogTitle: qsTr("新版本可用")
        dialogText: ""
        onAccepted: {
            Qt.openUrlExternally(downloadUrl)
        }
    }

    function checkForUpdates() {
        console.log("开始检查更新...")
        loadingDialog.open()
        var url = "http://175.24.139.88/version/version.php"
        var request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                loadingDialog.close()
                if (request.status === 200) {
                    var newVersion = request.responseText.trim()
                    console.log("收到新版本号: " + newVersion)
                    if (compareVersions(newVersion, appVersion) > 0) {
                        var downloadUrl = "http://175.24.139.88/apk/zhwrc" + newVersion + ".apk"
                        console.log("有新版本，提示用户下载: " + downloadUrl)
                        newVersionDialog.dialogText = "发现新版本 " + newVersion + "，是否下载更新？"
                        newVersionDialog.downloadUrl = downloadUrl
                        newVersionDialog.open()
                    } else {
                        console.log("当前版本已是最新")
                        updateDialog.dialogText = "当前版本已是最新"
                        updateDialog.open()
                    }
                } else {
                    console.log("检查更新失败，状态码: " + request.status)
                    updateDialog.dialogText = "检查更新失败"
                    updateDialog.open()
                }
            }
        }
        request.onerror = function() {
            loadingDialog.close()
            console.log("网络错误")
            updateDialog.dialogText = "网络错误，请稍后再试"
            updateDialog.open()
        }
        request.open("GET", url)
        request.send()
    }

    function compareVersions(v1, v2) {
        var v1Parts = v1.split('.')
        var v2Parts = v2.split('.')
        var len = Math.max(v1Parts.length, v2Parts.length)
        for (var i = 0; i < len; ++i) {
            var v1Part = parseInt(v1Parts[i] || 0, 10)
            var v2Part = parseInt(v2Parts[i] || 0, 10)
            if (v1Part > v2Part) return 1
            if (v1Part < v2Part) return -1
        }
        return 0
    }

    // Custom Button Component
    component CustomButton: Button {
        // width: commonWidth
        height: 80  // Increased height
        background: Rectangle {
            // color: parent.down ? Qt.darker(buttonColor, 1.1) : buttonColor
            radius: 15
        }
        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 40  // Increased font size
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Custom Dialog Component
    component CustomDialog: Popup {
        id: root
        width: 400  // Increased width
        height: 300  // Increased height
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: Overlay.overlay

        property string dialogTitle: ""
        property string dialogText: ""
        property bool showButtons: true

        signal accepted()
        signal rejected()

        background: Rectangle {
            color: "#000000"
            radius: 15
            border.color: Qt.darker("#000000", 1.1)
            border.width: 1
        }

        contentItem: Item {
            Column {
                anchors.fill: parent
                spacing: 15  // Increased spacing

                Text {
                    width: parent.width
                    height: 50  // Increased height
                    text: root.dialogTitle
                    font.pixelSize: 22  // Increased font size
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#333333"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.darker("#000000", 1.1)
                }

                Text {
                    width: parent.width
                    height: 100  // Increased height
                    text: root.dialogText
                    font.pixelSize: 25  // Increased font size
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#666666"
                }

                Row {
                    visible: root.showButtons
                    spacing: 20  // Increased spacing
                    anchors.horizontalCenter: parent.horizontalCenter

                    CustomButton {
                        width: 130  // Increased width
                        height: 60  // Increased height
                        text: "确定"
                        onClicked: {
                            root.accepted()
                            root.close()
                        }
                    }

                    CustomButton {
                        width: 130  // Increased width
                        height: 60  // Increased height
                        text: "取消"
                        onClicked: {
                            root.rejected()
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
