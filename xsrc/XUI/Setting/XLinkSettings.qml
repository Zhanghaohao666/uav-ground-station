import QtQuick          2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs  1.3
import QtQuick.Layouts  1.3

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

import ZHControls           1.0
import ZHSingletonControl   1.0
import ZHComponets          1.0

import XUI 1.0

Item {
    id: _linkRoot
    anchors.fill: parent
    anchors.margins: ScreenTools.defaultFontPixelWidth * scaleFactor

    // 定义比例因子
    property real scaleFactor: ScreenTools.defaultFontPixelWidth / 12  // 示例比例因子，根据您的需求调整
    property real _margin:  XScreenTool.base
    property color _themeC : XGlobalColor.theme

    // 保持使用比例控制的尺寸属性
    property var _currentSelection: null
    property int _firstColumn: ScreenTools.defaultFontPixelWidth * 6 * scaleFactor
    property int _secondColumn: ScreenTools.defaultFontPixelWidth * 15 * scaleFactor

    property color backgroundColor: "black"
    property color contentColor: ZHGlobalColor.topDivideCrl
    property color themeColor: ZHGlobalColor.themeCrl


    property int _rowSpacing: XScreenTool.base * 2 * scaleFactor
    property int _secondColumnWidth: XScreenTool.base * 20 * scaleFactor
    property int _colSpacing: XScreenTool.base * 0.5 * scaleFactor

    readonly property string _G20_Name:  "G20遥控器" //qsTr("G20-Control")
    // readonly property string _H20_Name: globals.isChinese ?   "H20遥控器": qsTr("H20-Control")
    // readonly property string _H16SW_Name: globals.isChinese ? "H16-水文" : qsTr("H16-Type2")
    readonly property string _4g_Name:  "4G网络" //qsTr("4G-Network")

    function isSpecialConnection(linkName) {
        return linkName === _G20_Name ;
    }

    function is4GConnection(linkName) {
        return linkName === _4g_Name;
    }

    function shouldShowAddButton(linkName) {
        return linkName !== _G20_Name ;
    }

    function updateButtonVisibility() {
        var editButton = buttonRow.children[0]
        var connectButton = buttonRow.children[1]
        var disconnectButton = buttonRow.children[2]
        var addButton = buttonRow.children[3]
        var deleteButton = buttonRow.children[4]

        if (_currentSelection) {
            var isSpecial = isSpecialConnection(_currentSelection.name);
            var is4G = is4GConnection(_currentSelection.name);
            var showAddForThis = shouldShowAddButton(_currentSelection.name);

            // 只有在非预设连接（包括4G）时才显示删除按钮
            deleteButton.visible = !isSpecial && !is4G;
            editButton.visible = true //!isSpecial || is4G;
            addButton.visible = true //showAddForThis;
            connectButton.visible = true;
            disconnectButton.visible = true;
        } else {
            deleteButton.visible = false;
            editButton.visible = false;
            addButton.visible = true;
            connectButton.visible = false;
            disconnectButton.visible = false;
        }

        // 更新按钮的启用状态
        connectButton.enabled = _currentSelection ? !_currentSelection.link : false;
        disconnectButton.enabled = _currentSelection ? _currentSelection.link : false;
        editButton.enabled = _currentSelection && (!_currentSelection.link || !isSpecialConnection(_currentSelection.name));
    }

    function _link_EnableEdit(linkName) {
        if(linkName === _G20_Name ) {
            return false
        }
        return true
    }

    function _set_AutoConnectLink(link) {
        var presetLinks = [_G20_Name, /*_H20_Name, _H16SW_Name,*/ _4g_Name];
        var configChanged = false;

        // 开始配置编辑
        var editingConfig = QGroundControl.linkManager.startConfigurationEditing(link);

        // 如果连接的是预设连接之一
        if (presetLinks.includes(link.name)) {
            for (var i = 0; i < linkManager.linkConfigurations.count; i++) {
                var config = linkManager.linkConfigurations.get(i);
                if (config) {
                    if (config.name === link.name) {
                        console.log(config.name, "设置为自动连接");
                        editingConfig.autoConnect = true;
                        configChanged = true;
                    } else if (presetLinks.includes(config.name)) {
                        console.log(config.name, "取消自动连接");
                        var otherEditingConfig = QGroundControl.linkManager.startConfigurationEditing(config);
                        otherEditingConfig.autoConnect = false;
                        QGroundControl.linkManager.endConfigurationEditing(config, otherEditingConfig);
                        configChanged = true;
                    }
                }
            }
        } else {
            // 如果不是预设连接，只更改当前连接
            editingConfig.autoConnect = true;
            configChanged = true;

            // 取消其他非预设连接的自动连接
            for (var j = 0; j < linkManager.linkConfigurations.count; j++) {
                var otherConfig = linkManager.linkConfigurations.get(j);
                if (otherConfig && otherConfig !== link && !presetLinks.includes(otherConfig.name)) {
                    var otherEditingConfig = QGroundControl.linkManager.startConfigurationEditing(otherConfig);
                    otherEditingConfig.autoConnect = false;
                    QGroundControl.linkManager.endConfigurationEditing(otherConfig, otherEditingConfig);
                }
            }
        }

        // 如果配置有变化，保存设置
        if (configChanged) {
            QGroundControl.linkManager.endConfigurationEditing(link, editingConfig);
            console.log("自动连接设置已保存");
        } else {
            QGroundControl.linkManager.cancelConfigurationEditing(editingConfig);
        }

        return configChanged;
    }

    MessageDialog {
        id: deleteDialog
        visible: false
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Yes | StandardButton.No
        title: qsTr("Remove Link Configuration")
        text: _currentSelection ? qsTr("Remove %1. Is this really what you want?").arg(_currentSelection.name) : ""
        onYes: {
            if (_currentSelection)
                QGroundControl.linkManager.removeConfiguration(_currentSelection)
            _currentSelection = null
            deleteDialog.visible = false
        }
        onNo: {
            deleteDialog.visible = false
        }
    }

    Component.onCompleted: {
        var isFound_G20 = false
        // var isFound_H20 = false
        // var isFound_H16SW = false
        var is4g = false

        updateButtonVisibility()

        console.log("QGroundControl.linkManager:", linkManager)
        if (linkManager && linkManager.linkConfigurations) {
            console.log("linkConfigurations count:", linkManager.linkConfigurations.count)
            for (var i = 0; i < linkManager.linkConfigurations.count; i++) {
                var config = linkManager.linkConfigurations.get(i)
                if (config) {
                    console.log("Configuration", i, ":", config.name)
                    if (config.name === _G20_Name) isFound_G20 = true
                    // if (config.name === _H20_Name) isFound_H20 = true
                    // if (config.name === _H16SW_Name) isFound_H16SW = true
                    if (config.name === _4g_Name) is4g = true
                } else {
                    console.log("Configuration", i, ": undefined")
                }
            }
        } else {
            console.log("linkManager or linkConfigurations is not available")
        }

        var _udp_object
        if (!isFound_G20) {
            _udp_object = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeUdp, _G20_Name)
            _udp_object.localPort = 14550
            var _defaultHost = "192.168.144.11:14550"
            _udp_object.addHost(_defaultHost)
            QGroundControl.linkManager.endCreateConfiguration(_udp_object)
            console.log("创建G20连接", _udp_object, _udp_object.localPort)
        }
        // if(!isFound_H20) {
        //     _udp_object = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeUdp, _H20_Name)
        //     _udp_object.localPort = 14550
        //     var _defaultHost = "192.168.144.101:14550"
        //     _udp_object.addHost(_defaultHost)
        //     QGroundControl.linkManager.endCreateConfiguration(_udp_object)
        //     console.log("创建H20连接", _udp_object, _udp_object.localPort)
        // }
        // if(!isFound_H16SW) {
        //     _udp_object = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeUdp, _H16SW_Name)
        //     _udp_object.localPort = 13551
        //     QGroundControl.linkManager.endCreateConfiguration(_udp_object)
        //     console.log("创建H16SW连接", _udp_object, _udp_object.localPort)
        // }
        var _4g_object
        if(!is4g) {
            _4g_object = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeTcp, _4g_Name)
            _4g_object.host = ""//"106.54.48.192"
            _4g_object.port = 5760
            QGroundControl.linkManager.endCreateConfiguration(_4g_object)
            console.log("创建找到4G连接", _4g_object, _4g_object.host, _4g_object.port)
        }
        //在所有创建操作完成后，重新加载连接列表
        if (linkManager && linkManager.linkConfigurations) {
            console.log("更新后的linkConfigurations count:", linkManager.linkConfigurations.count)
            for (var j = 0; j < linkManager.linkConfigurations.count; j++) {
                var updatedConfig = linkManager.linkConfigurations.get(j)
                console.log("Updated Configuration", j, ":", updatedConfig ? updatedConfig.name : "undefined")
            }
        }
    }

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  enabled
    }

    function openCommSettings(originalLinkConfig) {
        if (originalLinkConfig) {
            console.log("Opening settings for:", originalLinkConfig.name)
            settingsLoader.originalLinkConfig = originalLinkConfig
            settingsLoader.editingConfig = QGroundControl.linkManager.startConfigurationEditing(originalLinkConfig)
        } else {
            console.log("Creating new link configuration")
            settingsLoader.originalLinkConfig = null
            settingsLoader.editingConfig = QGroundControl.linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
        }
        settingsLoader.sourceComponent = commSettings
    }

    Component.onDestruction: {
        if (settingsLoader.sourceComponent) {
            settingsLoader.sourceComponent = null
            QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
        }
    }

    // property var _currentSelection: null
    property var linkManager: QGroundControl.linkManager

    // 添加 Flickable 组件来使内容可滚动
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: Math.max(mainColumn.height, height)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: mainColumn
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: _rowSpacing

            Item { width: parent.width; height: ScreenTools.defaultFontPixelHeight * 0.05 * scaleFactor } // 选择遥控器下方空白

            Item {
                id: linkGridContainer
                width: parent.width
                height: linkGrid.height
                anchors.horizontalCenter: parent.horizontalCenter

                Grid {
                    id: linkGrid
                    columns: 1
                    spacing: _margin
                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)

                    Repeater {
                        id: listRepeater
                        model: linkManager ? linkManager.linkConfigurations : null
                        delegate: Rectangle {
                            width:  linkGridContainer.width * 0.6
                            height: _margin * 4
                            color: _currentSelection === linkConfig ?  _themeC : "white" //"#fdebd0" : "white"
                            border.color: _themeC     //"#f5b041"
                            border.width: 1
                            radius: height / 8
                            property var linkConfig: linkManager.linkConfigurations.get(index)
                            XLabel {
                                id:         linkText
                                anchors.centerIn: parent
                                verticalAlignment: Text.AlignVCenter
                                // horizontalAlignment: Text.AlignLeft
                                text: linkConfig ? (linkConfig.name || "Unnamed Link") : "Invalid Link"
                                color: "black"
                                elide: Text.ElideRight
                                fontSizeMode: Text.Fit
                                minimumPixelSize: ScreenTools.defaultFontPixelSize * scaleFactor
                                maximumLineCount: 1
                                wrapMode: Text.NoWrap
                            }


                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    _currentSelection = linkConfig
                                    console.log("Selected:", linkConfig ? linkConfig.name : "undefined")
                                    updateButtonVisibility()
                                }
                            }
                        }
                    }
                }
            }

            // Item { width: parent.width; height: ScreenTools.defaultFontPixelHeight * 0.7 * scaleFactor } // 连接区域上方空白

            // 自定义按钮组件定义
            Component {
                id: customButtonComponent
                Item {
                    id: root
                    width: buttonRect.width
                    height: buttonRect.height
                    property string text: ""
                    property bool enabled: true
                    signal clicked()

                    Rectangle {
                        id: buttonRect
                        width: buttonRow.width + ScreenTools.defaultFontPixelWidth * 3 * scaleFactor  // 使用比例因子
                        height: ScreenTools.defaultFontPixelHeight * 2 * scaleFactor  // 使用比例因子
                        color: mouseArea.pressed ?  "#AA00CBFF" :   "#8800CBFF" //"#fad7a0" : "#fdebd0"
                        border.color:               "#AA00CBFF"//"#f5b041"
                        border.width: 1 * scaleFactor
                        radius: height / 4

                        Row {
                            id: buttonRow
                            anchors.centerIn: parent
                            spacing: ScreenTools.defaultFontPixelWidth * scaleFactor

                            Label {
                                text: root.text
                                // color: "#d35400"
                                color: "black"
                                font.bold: true
                                font.pixelSize: ScreenTools.defaultFontPixelSize * 0.9 * scaleFactor  // 减小字体大小
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.color = "#faebd7"
                            onExited: parent.color = "#fdebd0"
                            onClicked: {
                                if (root.enabled) {
                                    root.clicked()
                                }
                            }
                        }
                    }

                    states: [
                        State {
                            name: "disabled"
                            when: !root.enabled
                            PropertyChanges {
                                target: buttonRect
                                opacity: 0.5
                            }
                        }
                    ]
                }
            }

            Item {
                height: 1
                width: 1
            }

            Rectangle {
                width:  parent.width * 0.95
                height: 1
                color:  "#aaaaaa"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                height: 1
                width: 1
            }

            // 更新按钮行布局
            Item {
                id: buttonContainer
                width: parent.width *0.9
                height: ScreenTools.defaultFontPixelHeight * 2 * scaleFactor  // 动态高度
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    spacing: ScreenTools.defaultFontPixelHeight * 0.7 * scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter

                    // 第一排按钮
                    Row {
                    id: buttonRow
                    spacing: ScreenTools.defaultFontPixelWidth * 1.3 * scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter

                    XButtonLabel {
                        id:         editButtonLoader
                        text:       qsTr("Edit")
                        enabled:    _currentSelection && !_currentSelection.link
                        onClicked: {
                            _linkRoot.openCommSettings(_currentSelection)
                        }
                    }

                    XButtonLabel {
                        id:         connectButtonLoader
                        text:       qsTr("Link")
                        enabled:    _currentSelection && !_currentSelection.link
                        onClicked: {
                            if (_currentSelection) {
                                var configChanged = _set_AutoConnectLink(_currentSelection);
                                if (configChanged) {
                                    console.log("自动连接设置已更改并保存");
                                }
                                updateButtonVisibility();
                                QGroundControl.linkManager.createConnectedLink(_currentSelection);
                            }
                        }
                    }

                    XButtonLabel {
                        id:         disconnectButtonLoader
                        text:       qsTr("Disconnect")
                        enabled:    _currentSelection && !_currentSelection.link
                        onClicked: {
                            _currentSelection.link.disconnect()
                        }
                    }

                    XButtonLabel {
                        id:         addButtonLoader
                        text:       qsTr("Add")
                        // enabled:    _currentSelection && !_currentSelection.link
                        visible:    true//_currentSelection ? shouldShowAddButton(_currentSelection.name) : false
                        onClicked: {
                            _linkRoot.openCommSettings(null)
                        }
                    }

                    XButtonLabel {
                        id:         deleteButtonLoader
                        text:       qsTr("Del")
                        visible:    _currentSelection ? shouldShowAddButton(_currentSelection.name) : false
                        onClicked: {
                            if (_currentSelection)
                                deleteDialog.visible = true
                        }
                    }
                }
                }

                Item { width: parent.width; height: ScreenTools.defaultFontPixelHeight * 1 * scaleFactor } // 分隔空白
        }
    }

        Connections {
            target: _linkRoot
            function onCurrentSelectionChanged() {
                updateButtonVisibility()
            }
        }

        // 添加滚动条
        ScrollBar.vertical: ScrollBar {
            active: flickable.contentHeight > flickable.height
            visible: active
        }

        Loader {
            id: settingsLoader
            anchors.fill: parent
            visible: sourceComponent ? true : false

            property var originalLinkConfig: null
            property var editingConfig: null
        }

        Component {
            id: commSettings
            Rectangle {
                id: settingsRect
                color: qgcPal.window
                anchors.fill: parent
                property real _panelWidth: width * 0.8

                QGCFlickable {
                    id: settingsFlick
                    clip: true
                    anchors.fill: parent
                    anchors.margins: ScreenTools.defaultFontPixelWidth * scaleFactor
                    contentHeight: mainLayout.height
                    contentWidth: mainLayout.width

                    ColumnLayout {
                        id: mainLayout
                        spacing: _rowSpacing

                        QGCGroupBox {
                            title: originalLinkConfig ? qsTr("Edit Link Configuration Settings") : qsTr("Create New Link Configuration")

                            ColumnLayout {
                                spacing: _rowSpacing

                                GridLayout {
                                    columns: 2
                                    columnSpacing: _colSpacing
                                    rowSpacing: _rowSpacing

                                    XLabel { text: qsTr("Name") }
                                    QGCTextField {
                                        id: nameField
                                        Layout.preferredWidth: _secondColumnWidth
                                        Layout.fillWidth: true
                                        text: editingConfig.name
                                        placeholderText: qsTr("Enter name")
                                    }

                                    QGCCheckBox {
                                        Layout.columnSpan: 2
                                        text: qsTr("Automatically Connect on Start")
                                        checked: editingConfig.autoConnect
                                        onCheckedChanged: editingConfig.autoConnect = checked
                                    }

                                    QGCCheckBox {
                                        Layout.columnSpan: 2
                                        text: qsTr("High Latency")
                                        checked: editingConfig.highLatency
                                        onCheckedChanged: editingConfig.highLatency = checked
                                    }

                                    XLabel { text: qsTr("Type") }
                                    QGCComboBox {
                                        Layout.preferredWidth: _secondColumnWidth
                                        Layout.fillWidth: true
                                        enabled: originalLinkConfig == null
                                        model: QGroundControl.linkManager.linkTypeStrings
                                        currentIndex: editingConfig.linkType

                                        onActivated: {
                                            if (index !== editingConfig.linkType) {
                                                // Save current name
                                                var name = nameField.text
                                                // 创建新的链接配置
                                                editingConfig = QGroundControl.linkManager.createConfiguration(index, name)
                                            }
                                        }
                                    }
                                }

                                Loader {
                                    id: linksettingsLoader
                                    source: subEditConfig.settingsURL

                                    property var subEditConfig: editingConfig
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: _colSpacing

                            QGCButton {
                                width: ScreenTools.defaultFontPixelWidth * 10 * scaleFactor
                                text: qsTr("OK")
                                enabled: nameField.text !== ""

                                onClicked: {
                                    // 保存编辑
                                    linksettingsLoader.item.saveSettings()
                                    editingConfig.name = nameField.text
                                    settingsLoader.sourceComponent = null
                                    if (originalLinkConfig) {
                                        QGroundControl.linkManager.endConfigurationEditing(originalLinkConfig, editingConfig)
                                    } else {
                                        // 如果已编辑，则不再是“动态”的
                                        editingConfig.dynamic = false
                                        QGroundControl.linkManager.endCreateConfiguration(editingConfig)
                                    }
                                }
                            }

                            QGCButton {
                                width: ScreenTools.defaultFontPixelWidth * 10 * scaleFactor
                                text: qsTr("Cancel")
                                onClicked: {
                                    settingsLoader.sourceComponent = null
                                    QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
