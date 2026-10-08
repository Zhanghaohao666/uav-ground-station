import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: panel
    property var controller
    property bool gimbalControls: false
    property int trackingInputMode: 0
    signal inputModeRequested(int mode)
    property bool moving: false
    readonly property string defaultIP: "192.168.2.36"
    readonly property int defaultPort: gimbalControls ? 9000 : 9001
    readonly property color foreground: "#eff4f3"

    function stopMotion() {
        if (moving) {
            moving = false
            controller.stopGimbalSpeed()
        }
    }
    onVisibleChanged: if (!visible) stopMotion()

    Flickable {
        id: scroll
        anchors.fill: parent
        anchors.margins: 8
        contentWidth: width
        contentHeight: controls.height
        clip: true
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: controls
            width: scroll.width
            height: implicitHeight
            spacing: 8

            Label {
                text: panel.gimbalControls ? qsTr("云台控制") : qsTr("算法板控制")
                color: panel.foreground
                font.bold: true
                font.pixelSize: 18
            }
            Label {
                Layout.fillWidth: true
                text: panel.gimbalControls ? qsTr("云台可见光 /gimbal · 默认端口 9000") :
                                             qsTr("前视检测跟踪 /algorithm · 默认端口 9001")
                color: "#b9c9c3"
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: ipField
                    objectName: "controlIP"
                    Layout.fillWidth: true
                    text: controller.tcpServerIP
                    placeholderText: qsTr("主控 IP")
                    selectByMouse: true
                }
                TextField {
                    id: portField
                    objectName: "controlPort"
                    Layout.preferredWidth: 76
                    text: controller.tcpServerPort.toString()
                    validator: IntValidator { bottom: 1; top: 65535 }
                    inputMethodHints: Qt.ImhDigitsOnly
                    selectByMouse: true
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    objectName: "connectControl"
                    Layout.fillWidth: true
                    text: controller.isConnected ? qsTr("断开") : qsTr("连接")
                    enabled: controller.isConnected || (ipField.text.trim().length > 0 && portField.acceptableInput)
                    onClicked: {
                        if (controller.isConnected) {
                            panel.stopMotion()
                            controller.disConnectQml()
                        } else {
                            controller.tcpServerIP = ipField.text.trim()
                            controller.tcpServerPort = parseInt(portField.text)
                            controller.connectQml(controller.tcpServerIP, controller.tcpServerPort)
                        }
                    }
                }
                Button {
                    objectName: "resetControlEndpoint"
                    Layout.fillWidth: true
                    text: qsTr("恢复默认")
                    onClicked: {
                        panel.stopMotion()
                        controller.disConnectQml()
                        controller.tcpServerIP = panel.defaultIP
                        controller.tcpServerPort = panel.defaultPort
                        ipField.text = panel.defaultIP
                        portField.text = panel.defaultPort.toString()
                    }
                }
            }
            Label {
                objectName: "controlConnectionState"
                text: controller.isConnected ? qsTr("控制已连接") : qsTr("控制未连接")
                color: controller.isConnected ? "#66d5a9" : "#ed8a87"
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    objectName: "enableDetection"
                    Layout.fillWidth: true
                    text: qsTr("开启检测")
                    enabled: controller.isConnected
                    onClicked: controller.setDetectionEnabled(true)
                }
                Button {
                    objectName: "disableDetection"
                    Layout.fillWidth: true
                    text: qsTr("关闭检测")
                    enabled: controller.isConnected
                    onClicked: controller.setDetectionEnabled(false)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: [qsTr("点选"), qsTr("框选"), qsTr("目标 ID")]
                    Button {
                        Layout.fillWidth: true
                        text: modelData
                        highlighted: panel.trackingInputMode === index
                        onClicked: panel.inputModeRequested(index)
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                text: panel.trackingInputMode === 0 ? qsTr("在对应算法画面双击检测框") :
                      (panel.trackingInputMode === 1 ? qsTr("在对应算法画面拖出目标框") : qsTr("输入当前检测列表中的目标 ID"))
                color: "#b9c9c3"
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                visible: panel.trackingInputMode === 2
                TextField {
                    id: targetField
                    objectName: "trackingTargetID"
                    Layout.fillWidth: true
                    text: "0"
                    validator: IntValidator { bottom: 0; top: 2147483647 }
                    placeholderText: qsTr("目标 ID")
                }
                Button {
                    objectName: "trackTargetID"
                    text: qsTr("跟踪")
                    enabled: controller.isConnected && targetField.acceptableInput
                    onClicked: controller.trackId(parseInt(targetField.text))
                }
            }
            Button {
                objectName: "stopTracking"
                Layout.fillWidth: true
                text: qsTr("停止跟踪")
                enabled: controller.isConnected
                onClicked: controller.unlockTracking()
            }

            ColumnLayout {
                objectName: "gimbalMotionControls"
                Layout.fillWidth: true
                visible: panel.gimbalControls
                enabled: controller.isConnected
                RowLayout {
                    Layout.fillWidth: true
                    Button { Layout.fillWidth: true; text: qsTr("回中"); onClicked: controller.gimbalCenter() }
                    Button { Layout.fillWidth: true; text: qsTr("下视 90°"); onClicked: controller.gimbalDown90() }
                }
                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: pitch; Layout.fillWidth: true; text: "0"; placeholderText: qsTr("俯仰角"); validator: IntValidator { bottom: -90; top: 30 } }
                    TextField { id: yaw; Layout.fillWidth: true; text: "0"; placeholderText: qsTr("偏航角"); validator: IntValidator { bottom: -180; top: 180 } }
                    Button { text: qsTr("设置"); enabled: pitch.acceptableInput && yaw.acceptableInput; onClicked: controller.setGimbalAngle(parseInt(pitch.text), parseInt(yaw.text)) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Button { Layout.fillWidth: true; text: qsTr("锁定云台"); onClicked: controller.setGimbalLocked(true) }
                    Button { Layout.fillWidth: true; text: qsTr("解锁云台"); onClicked: controller.setGimbalLocked(false) }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    Repeater {
                        model: [{label: qsTr("上"), yaw: 128, pitch: 180},
                                {label: qsTr("左"), yaw: 76, pitch: 128},
                                {label: qsTr("右"), yaw: 180, pitch: 128},
                                {label: qsTr("下"), yaw: 128, pitch: 76}]
                        Button {
                            Layout.fillWidth: true
                            text: modelData.label
                            onPressed: { panel.moving = true; controller.sendGimbalSpeed(modelData.yaw, modelData.pitch) }
                            onReleased: panel.stopMotion()
                            onCanceled: panel.stopMotion()
                        }
                    }
                }
                Button { Layout.fillWidth: true; text: qsTr("停止云台运动"); onClicked: { panel.moving = false; controller.stopGimbalSpeed() } }
            }

            Label {
                objectName: "trackingFeedback"
                Layout.fillWidth: true
                text: qsTr("跟踪状态：") + controller.trackerStatusText + " · " + qsTr("目标数：") + controller.targetCount
                color: panel.foreground
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: qsTr("跟踪框：") + controller.trackX + "," + controller.trackY + "," + controller.trackW + "," + controller.trackH
                color: "#b9c9c3"
                wrapMode: Text.WordWrap
            }
            Label {
                visible: panel.gimbalControls
                text: qsTr("偏航：") + controller.yawDeg.toFixed(2) + " · " + qsTr("俯仰：") + controller.pitchDeg.toFixed(2)
                color: "#b9c9c3"
            }
            Label {
                objectName: "currentTargetIDs"
                Layout.fillWidth: true
                text: qsTr("当前目标 ID：") + controller.targets.map(function(target) { return target.id }).join(", ")
                color: "#b9c9c3"
                wrapMode: Text.WordWrap
            }
            ScrollView {
                id: logView
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                Layout.minimumHeight: 100
                Layout.maximumHeight: 180
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                TextArea {
                    objectName: "controlLog"
                    width: logView.availableWidth
                    text: controller.logText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    color: panel.foreground
                    onTextChanged: cursorPosition = length
                    background: Rectangle { color: "#16221e"; radius: 4 }
                }
            }
            Button { Layout.fillWidth: true; text: qsTr("清空日志"); onClicked: controller.clearLog() }
        }
    }
}
