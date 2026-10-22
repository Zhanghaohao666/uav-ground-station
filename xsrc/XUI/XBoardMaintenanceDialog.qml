import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: dialog
    property var controller
    readonly property string target: targetBox.currentIndex === 1 ? "algorithm" : "main"
    readonly property var entries: controller ? controller.actions(target) : []
    parent: Overlay.overlay
    width: Math.min(parent ? parent.width - 24 : 820, 840)
    height: Math.min(parent ? parent.height - 24 : 710, 710)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    modal: true
    padding: 16
    closePolicy: Popup.CloseOnEscape
    palette.windowText: "#dde7ef"
    background: Rectangle { color: "#202830"; border.color: "#51616f"; radius: 8 }
    header: Label { text: qsTr("板卡维护 / SSH 终端"); color: "white"; font.pixelSize: 22; padding: 16 }
    onOpened: {
        var c = controller.configuration
        mainHost.text = c.mainHost
        mainPort.value = c.mainPort
        mainUser.text = c.mainUser
        algorithmHost.text = c.algorithmHost
        algorithmPort.value = c.algorithmPort
        algorithmUser.text = c.algorithmUser
        viaMain.checked = c.viaMain
    }
    function saveConnection() {
        return controller.configure(mainHost.text, mainPort.value, mainUser.text,
                                    algorithmHost.text, algorithmPort.value, algorithmUser.text, viaMain.checked)
    }
    function launch(board, action) {
        if (saveConnection()) controller.openTerminal(board, action)
    }
    Dialog {
        id: restartPrompt
        objectName: "maintenanceRestartPrompt"
        property string board
        property string actionId
        property string actionLabel
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - 24, 560)
        modal: true
        title: qsTr("确认重启服务")
        standardButtons: Dialog.Ok | Dialog.Cancel
        Label { width: parent.width; wrapMode: Text.WordWrap; text: qsTr("%1\n对应视频会短暂中断。SSH 连接成功并在终端取得 sudo 权限后执行。").arg(restartPrompt.actionLabel) }
        onAccepted: dialog.launch(board, actionId)
    }
    contentItem: ColumnLayout {
        spacing: 8
        Label {
            text: qsTr("无需互联网；电脑与板卡仍需通过 MK22、网线或 Wi-Fi 局域网连通。终端在独立窗口中打开。")
            color: "#dde7ef"; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        GridLayout {
            columns: 4
            Layout.fillWidth: true
            Label { text: qsTr("板卡"); color: "#adbbc8" }
            Label { text: qsTr("IP / 主机名"); color: "#adbbc8" }
            Label { text: qsTr("SSH 端口"); color: "#adbbc8" }
            Label { text: qsTr("用户名"); color: "#adbbc8" }
            Label { text: qsTr("主控板"); color: "#dde7ef" }
            TextField { id: mainHost; objectName: "maintenanceMainHost"; Layout.fillWidth: true; selectByMouse: true }
            SpinBox { id: mainPort; objectName: "maintenanceMainPort"; from: 1; to: 65535; editable: true }
            TextField { id: mainUser; objectName: "maintenanceMainUser"; Layout.preferredWidth: 110; selectByMouse: true }
            Label { text: qsTr("算法板"); color: "#dde7ef" }
            TextField { id: algorithmHost; objectName: "maintenanceAlgorithmHost"; Layout.fillWidth: true; selectByMouse: true }
            SpinBox { id: algorithmPort; objectName: "maintenanceAlgorithmPort"; from: 1; to: 65535; editable: true }
            TextField { id: algorithmUser; objectName: "maintenanceAlgorithmUser"; Layout.preferredWidth: 110; selectByMouse: true }
        }
        CheckBox { id: viaMain; objectName: "maintenanceViaMain"; text: qsTr("算法板经主控 SSH 跳转（推荐，MK22 下无需单独连接算法板网段）") }
        RowLayout {
            Button { objectName: "openMainTerminal"; text: qsTr("打开主控终端"); onClicked: dialog.launch("main", "shell") }
            Button { objectName: "openAlgorithmTerminal"; text: qsTr("打开算法板终端"); onClicked: dialog.launch("algorithm", "shell") }
            Item { Layout.fillWidth: true }
            ComboBox { id: targetBox; objectName: "maintenanceTarget"; model: [qsTr("主控快捷操作"), qsTr("算法板快捷操作")]; Layout.preferredWidth: 190 }
        }
        Label {
            text: qsTr("密码在终端里输入，输入时不显示字符；地面站不保存 SSH 密码。首次连接请确认板卡指纹。跳转连接可能先后询问两块板的密码。")
            color: "#adbbc8"; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        Label { objectName: "maintenanceStatus"; text: controller ? controller.statusText : ""; visible: text.length > 0; color: "#e0b570"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        ListView {
            id: actionList
            objectName: "maintenanceActions"
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 5
            model: dialog.entries
            ScrollBar.vertical: ScrollBar {}
            delegate: Rectangle {
                width: actionList.width; height: 74
                color: index % 2 ? "#26323c" : "#2d3a45"; radius: 4
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 3
                    RowLayout {
                        Label { text: modelData.label; color: "#dde7ef"; Layout.fillWidth: true }
                        Button { objectName: "copyMaintenance_" + modelData.id; text: qsTr("复制命令"); onClicked: controller.copyCommand(dialog.target, modelData.id) }
                        Button {
                            objectName: "runMaintenance_" + modelData.id
                            text: qsTr("终端执行")
                            onClicked: {
                                if (modelData.restart) {
                                    restartPrompt.board = dialog.target
                                    restartPrompt.actionId = modelData.id
                                    restartPrompt.actionLabel = modelData.label
                                    restartPrompt.open()
                                } else dialog.launch(dialog.target, modelData.id)
                            }
                        }
                    }
                    Label { text: modelData.command; color: "#adbbc8"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }
        }
        Label { text: qsTr("uav-switch 是主控方案切换菜单。查看状态不会切换方案；重启只影响所选服务。关闭此面板不关闭已打开的 SSH 终端。"); color: "#adbbc8"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout { Item { Layout.fillWidth: true } Button { text: qsTr("关闭"); onClicked: dialog.close() } }
    }
}
