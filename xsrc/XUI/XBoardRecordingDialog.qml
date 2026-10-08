import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: dialog
    property var controller
    property var selectedKeys: []
    readonly property var snapshot: controller ? controller.status : ({})
    readonly property var streams: snapshot.streams || []
    readonly property bool linked: controller && controller.connected
    readonly property bool working: controller && controller.busy
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
    header: Label { text: qsTr("板端录像"); color: "white"; font.pixelSize: 22; padding: 16 }
    onOpened: {
        addressField.text = controller.address
        codeField.text = controller.connectionCode
        rememberBox.checked = controller.rememberConnection
        controller.refresh()
    }
    function choose(key, checked) {
        var keys = selectedKeys.slice()
        var at = keys.indexOf(key)
        if (checked && at < 0) keys.push(key)
        if (!checked && at >= 0) keys.splice(at, 1)
        selectedKeys = keys
    }
    contentItem: ColumnLayout {
        spacing: 8
        Label { text: qsTr("视频保存在主控数据盘。关闭窗口或地面站后，录像继续。"); color: "#dde7ef"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            TextField { id: addressField; objectName: "recordingAddress"; placeholderText: qsTr("主控 IP"); Layout.preferredWidth: 190; enabled: !dialog.working }
            TextField { id: codeField; objectName: "recordingCode"; placeholderText: qsTr("连接码（首次粘贴）"); echoMode: TextInput.Password; Layout.fillWidth: true; enabled: !dialog.working }
            Button { objectName: "connectRecording"; text: qsTr("连接"); enabled: !dialog.working; onClicked: controller.configure(addressField.text, codeField.text, rememberBox.checked) }
        }
        RowLayout {
            CheckBox { id: rememberBox; text: qsTr("记住连接"); enabled: !dialog.working }
            BusyIndicator { running: dialog.working; implicitWidth: 24; implicitHeight: 24 }
            Label { text: dialog.working ? qsTr("正在请求主控…") : (dialog.linked ? qsTr("已连接主控") : qsTr("未连接 / 状态未确认")); color: dialog.linked ? "#65d7a1" : "#e0b570"; Layout.fillWidth: true }
            Button { text: qsTr("刷新"); enabled: !dialog.working; onClicked: controller.refresh() }
        }
        Label { objectName: "recordingError"; visible: text.length > 0; text: controller ? controller.errorText : ""; color: "#ffbe85"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            Button { objectName: "selectAllRecording"; text: qsTr("全选当前方案"); enabled: dialog.linked; onClicked: dialog.selectedKeys = dialog.streams.filter(function(s) { return s.available }).map(function(s) { return s.key }) }
            Label { text: qsTr("选择录像与打开预览相互独立"); color: "#adbbc8"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
        ListView {
            objectName: "recordingStreams"
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                        enabled: !dialog.working && dialog.linked && (modelData.available || modelData.requested || modelData.active)
                        Layout.preferredWidth: 185
                        onToggled: dialog.choose(modelData.key, checked)
                    }
                    Label {
                        text: dialog.linked ? (modelData.available || modelData.active || modelData.requested ? modelData.state : qsTr("当前方案未启用")) : qsTr("状态未确认")
                        color: dialog.linked && modelData.phase === "recording" ? "#65d7a1" : "#c8d5df"
                        Layout.preferredWidth: 135
                    }
                    Label {
                        text: modelData.phase === "recording" ? modelData.detail : ""
                        color: "#adbbc8"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
        Label {
            Layout.fillWidth: true
            color: "#c8d5df"
            wrapMode: Text.WordWrap
            text: snapshot.storage ? (snapshot.storage.error || qsTr("数据盘剩余 %1 GiB，保留 %2 GiB").arg((snapshot.storage.free_bytes / 1073741824).toFixed(1)).arg((snapshot.storage.reserve_bytes / 1073741824).toFixed(0))) : ""
        }
        TextField { objectName: "recordingPath"; Layout.fillWidth: true; readOnly: true; selectByMouse: true; text: snapshot.session ? snapshot.session.path : "/data/uav-recordings" }
        Label { text: qsTr("录制所连接主控的视频；自定义预览地址不改变录像源。"); color: "#adbbc8"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        RowLayout {
            Button { objectName: "startBoardRecording"; text: qsTr("开始 / 添加录像"); enabled: dialog.linked && !dialog.working && dialog.startKeys.length > 0 && snapshot.storage && !snapshot.storage.error; onClicked: controller.startSelected(dialog.startKeys) }
            Button { objectName: "stopSelectedRecording"; text: qsTr("停止所选"); enabled: dialog.linked && !dialog.working && dialog.selectedKeys.length > 0; onClicked: controller.stopSelected(dialog.selectedKeys) }
            Button { objectName: "stopAllRecording"; text: qsTr("停止全部"); enabled: dialog.linked && !dialog.working && !!snapshot.session; onClicked: controller.stopAll() }
            Item { Layout.fillWidth: true }
            Button { text: qsTr("关闭"); onClicked: dialog.close() }
        }
    }
}
