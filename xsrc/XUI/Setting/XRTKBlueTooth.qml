import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
    id: rtkBlueToothRoot

    property real  _margin:         XScreenTool.base
    property real  _labelWidth:     _margin * 8
    property real  _buttonHeight:   _margin * 3.5
    property color _theme2:          XGlobalColor.theme
    property color _sub:            XGlobalColor.sub

    // width: parent.width * 0.7
    width: parent.width * 1
    height: parent.height * 0.9
    anchors.centerIn: parent

    property real scaleFactor: 0.7
    property var bluetoothController: QGroundControl.bluetoothController

    property bool isReceivingData: true
    property var displayedDataList: []
    property bool isConnected: false
    property bool hasEverConnected: false
    property double lastReceivedDataTimestamp: 0
    property int maxDisplayedLines: 100  //最大保存信息条数
    property bool isConnecting: false
    property var displayedDevices: []

    // 添加一个函数来安全地访问 bluetoothController 的属性
    function safeGetProperty(propertyName, defaultValue) {
        return bluetoothController && bluetoothController[propertyName] !== undefined
               ? bluetoothController[propertyName]
               : defaultValue
    }

    // 添加一个函数来安全地调用 bluetoothController 的方法
    function safeCallMethod(methodName, ...args) {
        if (bluetoothController && typeof bluetoothController[methodName] === 'function') {
            return bluetoothController[methodName](...args)
        } else {
            console.log("Method not available:", methodName)
        }
    }

    function updateDataListView() {
        dataListView.model = displayedDataList
    }

    function clearAllData() {
        console.log("Clearing all data")
        displayedDataList = []
        safeCallMethod('clearReceivedDataList')
        updateDataListView()
    }

    function logMessage(message) {
        console.log(new Date().toLocaleTimeString() + ": " + message)
    }

    function getCurrentTimestamp() {
        return new Date().getTime()
    }


    // 清空设备列表
    function clearDeviceList() {
        displayedDevices = []
        console.log("Device list display cleared")
    }

    //清除文本框
    function resetFields() {
        ipCombo.editText = ""
        portCombo.editText = ""
        sourceNodeCombo.editText = ""
        accountField.text = ""
        passwordField.text = ""
        expirationField.text = ""
    }

    Component.onDestruction: {
        if (bluetoothController) {
            bluetoothController.ip = ""
            bluetoothController.port = ""
            bluetoothController.mp = ""
            bluetoothController.account = ""
            bluetoothController.setPassword("")
            bluetoothController.exp = ""
            // 断开蓝牙连接
            if (isConnected) {
                console.log("Disconnecting Bluetooth on component destruction")
                safeCallMethod('disconnectDevice')
                isConnected = false
                hasEverConnected = false
                isConnecting = false
            }
            // 清空设备列表
            clearDeviceList()
        }
    }

    Connections {
        target: bluetoothController
        function onConnectionSucceeded() {
            logMessage("Connection succeeded")
            isConnected = true
            isConnecting = false
            lastReceivedDataTimestamp = getCurrentTimestamp()
        }
        function onConnectionFailed() {
            logMessage("Connection failed")
            isConnected = false
            isConnecting = false
            hasEverConnected = true
        }
        function onReceivedDataListChanged() {
            var newDataList = safeGetProperty('receivedDataList', [])
            for (var i = 0; i < newDataList.length; i++) {
                var newData = newDataList[i]
                var lines = newData.split('\r\n')
                for (var j = 0; j < lines.length; j++) {
                    var line = lines[j].trim()
                    if (line && isReceivingData) {
                        displayedDataList.push(line)
                        if (displayedDataList.length > maxDisplayedLines) {
                            displayedDataList.shift()
                        }
                    }
                }
            }
            if (isReceivingData) {
                updateDataListView()
            }
        }
        function onLogMessageReceived(message) {
            if (message.trim().startsWith("$")) {
                lastReceivedDataTimestamp = getCurrentTimestamp()
                isConnected = true
                hasEverConnected = true
            }
        }
    }

    Timer {
        id: connectionCheckTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var currentTime = getCurrentTimestamp()
            if (currentTime - lastReceivedDataTimestamp > 8000) {
                if (isConnected || isConnecting) {
                    logMessage("No valid data received for 8 seconds, considering disconnected")
                    isConnected = false
                    isConnecting = false
                    hasEverConnected = true
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        TabBar {
            id: topBar
            Layout.fillWidth: true
            TabButton {
                text: qsTr("Account")
                background: Rectangle {
                    color: parent.checked ? _sub: _theme2  // 深灰色: #4A4A4A
                }
                contentItem: XLabel {
                    text:   parent.text
                    color:  parent.checked ? "black" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    small: true
                }
            }
            TabButton {
                text: qsTr("RTK Setting")
                background: Rectangle {
                    color: parent.checked ? _sub: _theme2  // 深灰色: #4A4A4A
                }
                contentItem: XLabel {
                    text:   parent.text
                    color:  parent.checked ? "black" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    small: true
                }
            }
        }

        StackLayout {
            currentIndex: topBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: _margin   // 增加整体间距

                    GroupBox {
                            Layout.fillWidth: true
                            title: qsTr("Device list")
                            label: XLabel {
                                text:   parent.text
                                color:  "black"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                small: true
                            }
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                XButtonLabel {
                                    text: qsTr("Scan Bluetooth Devices")
                                    onClicked: {
                                        safeCallMethod('disconnectDevice')
                                        hasEverConnected = false
                                        isConnecting = false
                                        isConnected = false
                                        logMessage("Starting device scan")
                                        clearDeviceList()  // 在开始新的扫描之前清空设备列表
                                        safeCallMethod('startDeviceDiscovery')
                                    }
                                    Layout.fillWidth: true
                                }
                                ListView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: _margin * 10
                                    clip: true
                                    // model: safeGetProperty('devices', [])
                                    model: displayedDevices
                                    delegate: ItemDelegate {
                                        width: parent.width
                                        height: _margin * 3
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: _margin / 2
                                            XLabel {
                                                text: modelData
                                                Layout.fillWidth: true
                                                small: true
                                            }
                                            XButtonLabel {
                                                id: connectButton
                                                _small: true
                                                text: {
                                                    if (isConnected) return qsTr("Connected")
                                                    if (isConnecting) return  qsTr("Connecting")
                                                    if (hasEverConnected) return  qsTr("Disconnected")
                                                    return qsTr("Connect")
                                                }
                                                onClicked: {
                                                    if (isConnected) {
                                                        logMessage("Disconnecting from: " + modelData)
                                                        safeCallMethod('disconnectDevice')
                                                        isConnected = false
                                                        hasEverConnected = true
                                                    } else {
                                                        logMessage("Attempting to connect to: " + modelData)
                                                        safeCallMethod('connectToDevice', index)
                                                        isConnecting = true
                                                    }
                                                }
                                                background: Rectangle {
                                                    color: {
                                                        if (isConnected) return "green"
                                                        if (isConnecting) return "yellow"
                                                        if (hasEverConnected) return "red"
                                                        return "gray"
                                                    }
                                                    border.color: connectButton.down ? "#17a81a" : "#21be2b"
                                                    border.width: 1
                                                    radius: 2
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: _margin/2

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter  // 左对齐和垂直居中
                            XLabel {
                                text: qsTr("IP:");
                                Layout.preferredWidth: _labelWidth
                                small: true
                            }
                            ComboBox {
                                id: ipCombo
                                Layout.minimumWidth: 200
                                Layout.fillWidth: true
                                editable: true
                                model: ListModel {
                                    id: ipModel
                                    ListElement { text: "rtk.ntrip.qxwz.com" }
                                    ListElement { text: "106.55.71.75 " }
                                    ListElement { text: "203.107.45.154" }
                                    ListElement { text: "60.205.8.49" }
                                    ListElement { text: "120.253.226.97" }
                                    ListElement { text: "119.9.136.126" }
                                    ListElement { text: "121.46.29.109" }
                                }
                                height: 40  // 增加高度
                                contentItem: XTextField {
                                    text: ipCombo.editText
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 12
                                    rightPadding: ipCombo.indicator.width + ipCombo.spacing
                                    topPadding: 8
                                    bottomPadding: 8
                                }
                                onAccepted: {
                                    if (find(editText) === -1)
                                        ipModel.append({text: editText})
                                }
                                Component.onCompleted: {
                                    currentIndex = -1  // 设置为-1，使ComboBox不选择任何预设值
                                    if (bluetoothController) {
                                        editText = bluetoothController.ip
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onIpChanged() {
                                        ipCombo.editText = bluetoothController.ip
                                        ipCombo.currentIndex = ipCombo.find(bluetoothController.ip)
                                    }
                                }
                                onEditTextChanged: {
                                    if (editText !== "" && find(editText) === -1) {
                                        currentIndex = -1  // 如果输入的文本不在预设列表中，将currentIndex设为-1
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            XLabel {
                                text: qsTr("Port:")
                                Layout.preferredWidth: _labelWidth
                            }
                            ComboBox {
                                id: portCombo
                                Layout.minimumWidth: 100
                                Layout.fillWidth: true
                                editable: true
                                model: ListModel {
                                    id: portModel
                                    ListElement { text: "8001" }
                                    ListElement { text: "8002" }
                                    ListElement { text: "8003" }
                                    ListElement { text: "2101" }
                                    ListElement { text: "2102" }
                                    ListElement { text: "2103" }
                                }
                                height: 40  // 增加高度
                                contentItem: XTextField {
                                    text: portCombo.editText
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 12
                                    rightPadding: portCombo.indicator.width + portCombo.spacing
                                    topPadding: 8
                                    bottomPadding: 8
                                }
                                onAccepted: {
                                    if (find(editText) === -1)
                                        portModel.append({text: editText})
                                }
                                Component.onCompleted: {
                                    currentIndex = -1  // 设置为-1，使ComboBox不选择任何预设值
                                    if (bluetoothController) {
                                        editText = bluetoothController.port
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onPortChanged() {
                                        portCombo.editText = bluetoothController.port
                                        portCombo.currentIndex = portCombo.find(bluetoothController.port)
                                    }
                                }
                                onEditTextChanged: {
                                    if (editText !== "" && find(editText) === -1) {
                                        currentIndex = -1  // 如果输入的文本不在预设列表中，将currentIndex设为-1
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            XLabel {
                                text:  qsTr("Node:")
                                Layout.preferredWidth: _labelWidth
                            }
                            ComboBox {
                                id: sourceNodeCombo
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                editable: true
                                model: ListModel {
                                    id: sourceNodeModel
                                    ListElement { text: "RTCM30_GG" }
                                    ListElement { text: "RTCM32_GGB" }
                                    ListElement { text: "RTCM30_GR" }
                                    ListElement { text: "RTCM33" }
                                    ListElement { text: "RTCM33_GRC" }
                                    ListElement { text: "RTCM33_GRCE" }
                                    ListElement { text: "RTCM33_GRCE_411 " }
                                    ListElement { text: "RTCM33_GRCEJ" }
                                    ListElement { text: "RTCM33_GRCEJ_516" }
                                    ListElement { text: "RTCM411" }
                                    ListElement { text: "NETRTK32" }
                                    ListElement { text: "NETRTK32_BD3" }
                                }
                                height: 40  // 增加高度
                                contentItem: XTextField {
                                    text: sourceNodeCombo.editText
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 12
                                    rightPadding: sourceNodeCombo.indicator.width + sourceNodeCombo.spacing
                                    topPadding: 8
                                    bottomPadding: 8
                                }
                                onAccepted: {
                                    if (find(editText) === -1)
                                        sourceNodeModel.append({text: editText})
                                }
                                Component.onCompleted: {
                                    currentIndex = -1  // 设置为-1，使ComboBox不选择任何预设值
                                    if (bluetoothController) {
                                        editText = bluetoothController.mp
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onMpChanged() {
                                        sourceNodeCombo.editText = bluetoothController.mp
                                        sourceNodeCombo.currentIndex = sourceNodeCombo.find(bluetoothController.mp)
                                    }
                                }
                                onEditTextChanged: {
                                    if (editText !== "" && find(editText) === -1) {
                                        currentIndex = -1  // 如果输入的文本不在预设列表中，将currentIndex设为-1
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            XLabel {
                                // font.pixelSize: parent.width * 0.06
                                text:  qsTr("User:")
                                Layout.preferredWidth: _labelWidth
                            }
                            XTextField {
                                id: accountField
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                Component.onCompleted: {
                                    if (bluetoothController) {
                                        text = bluetoothController.account
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onAccountChanged() { accountField.text = bluetoothController.account }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            XLabel {
                                // font.pixelSize: parent.width * 0.05
                                text:  qsTr("Password:")
                                Layout.preferredWidth: _labelWidth
                            }
                            XTextField {
                                id: passwordField
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                property bool isDevicePassword: false
                                echoMode: isDevicePassword ? TextField.Password : TextField.Normal
                                passwordCharacter: "●"
                                onTextChanged: {
                                    if (bluetoothController) {
                                        bluetoothController.setPassword(text)
                                    }
                                }
                                Component.onCompleted: {
                                    if (bluetoothController) {
                                        text = bluetoothController.password
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onPasswordChanged() { passwordField.text = bluetoothController.password }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            XLabel {
                                // font.pixelSize: parent.width * 0.04
                                text: qsTr("Time:")
                                Layout.preferredWidth: _labelWidth
                            }
                            XTextField {
                                id: expirationField
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                placeholderText: qsTr("YYYYMMDD For Example：20241231")
                                Component.onCompleted: {
                                    if (bluetoothController) {
                                        text = bluetoothController.exp
                                    }
                                }
                                Connections {
                                    target: bluetoothController
                                    function onExpChanged() { expirationField.text = bluetoothController.exp }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40  // 添加一些额外的空间
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        XButtonLabel {
                            text:  qsTr("Setting")
                            Layout.fillWidth: true
                            font.pixelSize: parent.width * 0.04
                            onClicked: {
                                console.log("Configuring CORS info")
                                var missingFields = []
                                if (!ipCombo.editText.trim()) missingFields.push("IP")
                                if (!portCombo.editText.trim()) missingFields.push( qsTr("Port"))
                                if (!sourceNodeCombo.editText.trim()) missingFields.push(qsTr("Node"))
                                if (!accountField.text.trim()) missingFields.push( qsTr("User"))
                                if (!passwordField.text.trim()) missingFields.push(qsTr("Password"))
                                if (!expirationField.text.trim()) missingFields.push(qsTr("Time"))

                                if (missingFields.length > 0) {
                                    console.log("Missing fields: " + missingFields.join(", "))
                                    validationPopup.missingFields = missingFields
                                    validationPopup.open()
                                    return
                                }

                                bluetoothController.setIp(ipCombo.editText)
                                bluetoothController.setPort(portCombo.editText)
                                bluetoothController.setSourceNode(sourceNodeCombo.editText)
                                bluetoothController.setAccount(accountField.text)
                                bluetoothController.setPassword(passwordField.text)
                                bluetoothController.setExp(expirationField.text)

                                var commandWithoutCRC = "$SET,CORS," + ipCombo.editText + "," + portCombo.editText + "," +
                                                        sourceNodeCombo.editText + "," + accountField.text + "," +
                                                        passwordField.text + "," + expirationField.text + "*";
                                var crc = bluetoothController.calculateCRC(commandWithoutCRC);
                                var fullCommand = commandWithoutCRC + crc;
                                console.log("Sending CORS config command: " + fullCommand)
                                bluetoothController.sendData(fullCommand)

                                corsConfigTimer.start()
                            }
                        }

                        XButtonLabel {
                            text: qsTr("Query Account")
                            Layout.fillWidth: true
                            font.pixelSize: parent.width * 0.04
                            onClicked: {
                                console.log("Querying device CORS info")
                                passwordField.isDevicePassword = true
                                passwordField.echoMode = TextField.Password
                                bluetoothController.queryCorsInfo()
                            }
                        }

                        XButtonLabel {
                            text: qsTr("Delete Account")
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "red"  // 将背景色改为红色
                                // radius: 5
                            }
                            onClicked: {
                                console.log("Opening CORS clear confirmation popup")
                                corsConfigClearConfirmPopup.open()
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true  // 填充剩余空间
                    }
                }
            }
            }
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: dataListView
                            model: displayedDataList
                            delegate: XLabel {
                                text: modelData
                                width: dataListView.width
                                wrapMode: Text.Wrap
                            }
                            onCountChanged: positionViewAtEnd()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        XButtonLabel {
                            id: receiveDataButton
                            text: isReceivingData ? qsTr("Suspend receiving") :  qsTr("Start receiving")
                            onClicked: {
                                isReceivingData = !isReceivingData
                                console.log(isReceivingData ? "Starting to receive data" : "Pausing data reception")
                            }
                        }
                        XButtonLabel {
                            text: qsTr("Clear data")
                            onClicked: {
                                clearAllData()
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true

                        ComboBox {
                            id: commandCombo
                            Layout.fillWidth: true
                            editable: true
                            model: [ "GPGGA COM2 0.2", "GPRMC COM2 0.5", "GPVTG COM2 0.2","$CSHOW", "saveconfig"]
                            currentIndex: -1
                            displayText: editText

                            onAccepted: {
                                if (find(editText) === -1 && editText !== "") {
                                    model.append(editText)
                                }
                            }

                            onActivated: {
                                if (currentIndex >= 0) {
                                    editText = currentText
                                }
                            }
                        }

                        XButtonLabel {
                            text:qsTr("Send command")
                            onClicked: {
                                if (commandCombo.editText !== "") {
                                    console.log("Sending data: " + commandCombo.editText)
                                    bluetoothController.sendData(commandCombo.editText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: corsConfigPopup
        width:  _margin * 20
        height: _margin * 12
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        background: Rectangle {
            color: "white"
            radius: 10
        }

        property bool configSuccess: false

        contentItem: Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: _margin
                Item { Layout.fillHeight: true }
                XLabel {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 360
                    text: corsConfigPopup.configSuccess ? qsTr("Account configuration succeeded") :  qsTr("Account configuration failed")
                    color: "black"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Item { Layout.fillHeight: true }
                XButtonLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text:  qsTr("YES")
                    _small: true
                    background: Rectangle {
                        implicitWidth: 160
                        implicitHeight: 60
                        color: parent.down ? "#d6d6d6" : "#f39c12"
                        radius: 5
                    }
                    onClicked: {
                        console.log("Closing CORS config popup")
                        corsConfigPopup.close()
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    Popup {
        id: validationPopup
        width: 400
        height: 300
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        background: Rectangle {
            color: "white"
            radius: 10
        }

        property var missingFields: []

        contentItem: Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: 20
                Item { Layout.fillHeight: true }
                ScrollView {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 360
                    Layout.preferredHeight: 120
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    XLabel {
                        width: 360
                        // text: "请填写以下信息：\n" + validationPopup.missingFields.join("、")
                        text: globals.isChinese
                                ? ("请填写以下信息：\n" + validationPopup.missingFields.join("、"))
                                : (qsTr("Please fill in the following information:\n") + validationPopup.missingFields.join(", "))
                        font.pixelSize: 26  // 增大字体
                        color: "black"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 5
                        elide: Text.ElideRight
                    }
                }
                Item { Layout.fillHeight: true }
                XButtonLabel {
                    Layout.alignment: Qt.AlignHCenter
                    _small:  true
                    text: qsTr("YES")
                    onClicked: {
                        console.log("Closing validation popup")
                        validationPopup.close()
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    Popup {
        id: corsConfigClearConfirmPopup
        width: 400
        height: 300
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        background: Rectangle {
            color: "white"
            radius: 10
        }

        contentItem: Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: 20
                Item { Layout.fillHeight: true }
                XLabel {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 360
                    text: globals.isChinese ? "确认清除CORS信息，\n清除后不可恢复！" : qsTr("Confirm clearing CORS info,\nThis action cannot be undone!")
                    font.pixelSize: 26  // 增大字体
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 40
                    XButtonLabel {
                        _small:  true
                        text:  qsTr("YES")
                        onClicked: {
                            console.log("Confirming CORS info clear")
                            var commandWithoutCRC = "$SET,CORS,Null,Null,Null,Null,Null,Null,*";
                            var crc = bluetoothController.calculateCRC(commandWithoutCRC);
                            var fullCommand = commandWithoutCRC + crc;
                            console.log("Sending CORS clear command: " + fullCommand)
                            bluetoothController.sendData(fullCommand);
                            corsConfigClearConfirmPopup.close()
                        }
                    }
                    XButtonLabel {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 60
                        text:  qsTr("NO")
                        onClicked: {
                            console.log("Cancelling CORS info clear")
                            corsConfigClearConfirmPopup.close()
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    Timer {
        id: corsConfigTimer
        interval: 5000
        repeat: false
        onTriggered: {
            console.log("CORS config timer triggered")
            corsConfigPopup.configSuccess = false
            corsConfigPopup.open()
        }
    }

    Connections {
        target: bluetoothController
        function onLogMessageReceived(message) {
            if (message.includes("#SET,CORS,INFO,FLASH,OK*15")) {
                corsConfigTimer.stop()
                corsConfigPopup.configSuccess = true
                corsConfigPopup.open()
            }
            lastReceivedDataTimestamp = Date.now()
        }

        function onDevicesChanged() {
            displayedDevices = bluetoothController.devices
        }
    }

    onIsConnectedChanged: {
        logMessage("Connection status changed to: " + isConnected)
    }

    Component.onCompleted: {

        displayedDevices = bluetoothController.devices
        console.log("QGCApplication available:", QGroundControl !== undefined)
        console.log("BluetoothController available:", bluetoothController !== undefined)
        if (bluetoothController) {
            console.log("BluetoothController properties:",
                "deviceNames -", safeGetProperty('deviceNames', 'undefined'),
                "receivedData -", safeGetProperty('receivedData', 'undefined'))
        }
        resetFields()  // 重置所有字段
        clearDeviceList()  // 初始化时清空设备列表
    }
}
