import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: dialog
    signal maintenanceRequested()
    property var controller
    property var selectedKeys: []
    readonly property var snapshot: controller ? controller.status : ({})
    readonly property var streams: snapshot.streams || []
    readonly property var lidar: snapshot.lidar || ({})
    readonly property bool linked: controller && controller.connected
    readonly property bool working: controller && controller.busy
    readonly property bool lidarSupported: linked && lidar.supported === true
    readonly property bool lidarRunning: lidarSupported && lidar.active === true
    readonly property bool lidarCanStart: lidarSupported && lidar.available === true && !lidarRunning &&
                                         ["idle", "stopped", "error"].indexOf(lidar.phase) >= 0
    readonly property var startKeys: selectedKeys.filter(function(key) {
        return streams.some(function(stream) { return stream.key === key && stream.available })
    })
    parent: Overlay.overlay
    width: Math.min(parent ? parent.width - 24 : 720, 760)
    height: Math.min(parent ? parent.height - 24 : 680, 680)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    modal: true
    palette.windowText: "#dde7ef"
    closePolicy: Popup.CloseOnEscape
    padding: 16
    background: Rectangle { color: "#202830"; border.color: "#51616f"; radius: 8 }
    header: Label { text: qsTr("板端数据录制"); color: "white"; font.pixelSize: 22; padding: 16 }
    onOpened: {
        addressField.text = controller.address
        controller.configure(addressField.text)
    }
    function choose(key, checked) {
        var keys = selectedKeys.slice()
        var at = keys.indexOf(key)
        if (checked && at < 0) keys.push(key)
        if (!checked && at >= 0) keys.splice(at, 1)
        selectedKeys = keys
    }
    function lidarStateText() {
        if (!linked) return qsTr("状态未确认")
        if (lidar.malformed) return qsTr("雷达状态异常，请刷新或更新板端服务")
        if (!lidarSupported) return qsTr("主控尚不支持雷达录制，请更新板端服务")
        switch (lidar.phase) {
        case "starting": return qsTr("正在启动，等待雷达数据…")
        case "recording": return qsTr("正在录制雷达")
        case "stopping": return qsTr("正在停止并保存…")
        case "error": return qsTr("录制异常")
        case "stopped": return lidar.available ? qsTr("已停止") : qsTr("已停止 · 雷达未连接或未供电")
        default: return lidar.available ? qsTr("待录制") : qsTr("雷达未连接或未供电")
        }
    }
    function formatBytes(bytes) {
        if (typeof bytes !== "number" || !isFinite(bytes) || bytes < 0) return ""
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(2) + " GiB"
        return (bytes / 1048576).toFixed(1) + " MiB"
    }
    contentItem: ColumnLayout {
        spacing: 8
        Label { text: qsTr("数据保存在主控数据盘。关闭窗口或地面站后，已启动的录制继续。"); color: "#dde7ef"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            TextField { id: addressField; objectName: "recordingAddress"; placeholderText: qsTr("主控 IP"); Layout.fillWidth: true; selectByMouse: true; enabled: !dialog.working }
            Button { objectName: "connectRecording"; text: qsTr("连接"); enabled: !dialog.working; onClicked: controller.configure(addressField.text) }
        }
        RowLayout {
            BusyIndicator { running: dialog.working; implicitWidth: 24; implicitHeight: 24 }
            Label { text: dialog.working ? qsTr("正在请求主控…") : (dialog.linked ? qsTr("已连接主控 · 自动使用 dev / dev") : qsTr("未连接 / 状态未确认")); color: dialog.linked ? "#65d7a1" : "#e0b570"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Button { text: qsTr("刷新"); enabled: !dialog.working; onClicked: controller.configure(addressField.text) }
        }
        Label { objectName: "recordingError"; visible: text.length > 0; text: controller ? controller.errorText : ""; color: "#ffbe85"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        ScrollView {
            id: recordingScroll
            objectName: "recordingScroll"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            rightPadding: 12
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ColumnLayout {
                width: recordingScroll.availableWidth
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: lidarContent.implicitHeight + 20
                    radius: 5; color: "#26343e"; border.color: "#405562"
                    ColumnLayout {
                        id: lidarContent
                        anchors.fill: parent; anchors.margins: 10
                        spacing: 6
                        RowLayout {
                            Label { text: qsTr("E1X 车载激光雷达"); color: "white"; font.bold: true; Layout.fillWidth: true }
                            Label { objectName: "lidarRecordingSize"; text: dialog.linked && dialog.lidarSupported ? dialog.formatBytes(dialog.lidar.bytes) : ""; color: "#adbbc8" }
                        }
                        Label {
                            objectName: "lidarRecordingState"
                            text: dialog.lidarStateText()
                            color: dialog.lidarRunning && dialog.lidar.phase === "recording" ? "#65d7a1" : "#e0b570"
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        Label {
                            objectName: "lidarRecordingDetail"
                            text: dialog.lidarSupported ? (dialog.lidar.error || dialog.lidar.detail || "") : ""
                            visible: text.length > 0; color: dialog.lidar.error ? "#ffbe85" : "#adbbc8"
                            wrapMode: Text.WordWrap; Layout.fillWidth: true
                        }
                        TextField {
                            objectName: "lidarRecordingPath"
                            Layout.fillWidth: true; readOnly: true; selectByMouse: true
                            text: dialog.linked && dialog.lidarSupported && dialog.lidar.path ? dialog.lidar.path : "/data/uav-lidar"
                        }
                        RowLayout {
                            Button { objectName: "startLidarRecording"; text: qsTr("开始雷达录制"); enabled: dialog.lidarCanStart && !dialog.working; onClicked: controller.startLidar() }
                            Button { objectName: "stopLidarRecording"; text: qsTr("停止雷达录制"); enabled: dialog.lidarRunning && !dialog.working && dialog.lidar.phase !== "stopping"; onClicked: controller.stopLidar() }
                            Label { text: qsTr("保存原始点云数据"); color: "#adbbc8"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }
                }
                RowLayout {
                    Label { text: qsTr("视频录像"); color: "white"; font.bold: true; Layout.fillWidth: true }
                    Button { objectName: "selectAllRecording"; text: qsTr("全选可用视频"); enabled: dialog.linked && !dialog.working; onClicked: dialog.selectedKeys = dialog.streams.filter(function(s) { return s.available }).map(function(s) { return s.key }) }
                }
                RowLayout {
                    Button { objectName: "startBoardRecording"; text: qsTr("开始 / 添加录像"); enabled: dialog.linked && !dialog.working && dialog.startKeys.length > 0 && snapshot.storage && !snapshot.storage.error; onClicked: controller.startSelected(dialog.startKeys) }
                    Button { objectName: "stopSelectedRecording"; text: qsTr("停止所选视频"); enabled: dialog.linked && !dialog.working && dialog.selectedKeys.length > 0; onClicked: controller.stopSelected(dialog.selectedKeys) }
                    Button { objectName: "stopAllRecording"; text: qsTr("停止全部视频"); enabled: dialog.linked && !dialog.working && !!snapshot.session; onClicked: controller.stopAll() }
                }
                Label { text: qsTr("视频与雷达分别开始、停止。停止全部视频不会停止雷达录制。"); color: "#adbbc8"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                ListView {
                    objectName: "recordingStreams"
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Math.max(count * 49, 60), 245)
                    clip: true
                    model: dialog.streams
                    spacing: 4
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 45
                        color: index % 2 ? "#26323c" : "#2d3a45"
                        radius: 4
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            CheckBox {
                                objectName: "recordSelect_" + modelData.key
                                text: modelData.label
                                checked: dialog.selectedKeys.indexOf(modelData.key) >= 0
                                enabled: !dialog.working && dialog.linked && !!(modelData.available || modelData.requested || modelData.active)
                                Layout.preferredWidth: 185
                                onToggled: dialog.choose(modelData.key, checked)
                            }
                            Label {
                                text: dialog.linked ? (modelData.available || modelData.active || modelData.requested ? modelData.state : qsTr("当前方案未启用")) : qsTr("状态未确认")
                                color: dialog.linked && modelData.phase === "recording" ? "#65d7a1" : "#c8d5df"
                                Layout.preferredWidth: 135
                            }
                            Label {
                                text: dialog.linked && modelData.phase === "recording" ? modelData.detail : ""
                                color: "#adbbc8"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                TextField { objectName: "recordingPath"; Layout.fillWidth: true; readOnly: true; selectByMouse: true; text: dialog.linked && snapshot.session ? snapshot.session.path : "/data/uav-recordings" }
                Label { text: qsTr("录像与预览相互独立；自定义预览地址不改变录像源。"); color: "#adbbc8"; Layout.fillWidth: true; wrapMode: Text.WordWrap }

            }
        }
        RowLayout {
            Label {
                Layout.fillWidth: true; color: "#c8d5df"; wrapMode: Text.WordWrap
                text: dialog.linked && snapshot.storage ? (snapshot.storage.error || qsTr("数据盘剩余 %1 GiB，保留 %2 GiB").arg((snapshot.storage.free_bytes / 1073741824).toFixed(1)).arg((snapshot.storage.reserve_bytes / 1073741824).toFixed(0))) : ""
            }
            Button { objectName: "closeRecording"; text: qsTr("关闭"); onClicked: dialog.close() }
        }
    }
}
