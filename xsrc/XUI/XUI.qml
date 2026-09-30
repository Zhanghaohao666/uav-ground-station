import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl 1.0
import QGroundControl.Controllers 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap 1.0
import QGroundControl.ScreenTools 1.0

import XUI 1.0
import "XVideoCoordinateMapper.js" as VideoCoordinateMapper

Item {
    id: root

    property var activeVehicle:     XGlobalProperty.vhcnull
    property var _ext:              XGlobalProperty.ext
    property real   _margin:        XScreenTool.base
    property color  _themeC:		XGlobalColor.theme
    property color  _themeC2:       XGlobalColor.theme2
    property color  _backC:         XGlobalColor.background
    property color  _subC:          XGlobalColor.sub
    property real  _toolbarHeight:  XScreenTool.toolbarHeight
    property color  _greenC:        "#cc4fd6a2"//_themeC
    readonly property color outC:            "#ff0f3b2b"
    property var    guidedController:        guidedActionsController
    property var    _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property var    _guidedActionList:       guidedActionList
    property var    _guidedValueSlider:      guidedValueSlider
    property var    _widgetLayer:            root
    property real   _toolsMargin:            ScreenTools.defaultFontPixelWidth * 0.75
    property real   _margins:                ScreenTools.defaultFontPixelWidth / 2
    property alias  _gripperMenu:            gripperOptions
    property int _selectedNavIndex: 0
    property int _fullVideoStreamIndex: -1
    property int _trackingInputMode: 0   // 0: point select, 1: drag select, 2: target ID
    property real   _base:                      XScreenTool.base /21.2 * _sc
    readonly property real   _sc:               1.0
    property real   _dashWidth:                 _base * 230//220//220 //220  //219  //248



    property real   _rollAngle:         activeVehicle ? activeVehicle.roll.rawValue  : 0
    property real   _pitchAngle:        activeVehicle ? activeVehicle.pitch.rawValue : 0
    property real   _heading:                     activeVehicle ? activeVehicle.heading.rawValue : 0
    property real   _airSpeed:          activeVehicle ? activeVehicle.airSpeed.rawValue : 0
    property real   _altitudeRelative:  activeVehicle ? activeVehicle.altitudeRelative.rawValue : 0
    property real   _altitudeAMSL:      activeVehicle ? activeVehicle.altitudeAMSL.rawValue : 0
    property real   _groundSpeed:       activeVehicle ? activeVehicle.groundSpeed.rawValue : 0
    property real   _climbRate:         activeVehicle ? activeVehicle.climbRate.rawValue : 0
    property real   _distanceToHome:    activeVehicle ? activeVehicle.distanceToHome.rawValue : 0

    //飞行距离
    property real _flightDistance:      activeVehicle ? activeVehicle.flightDistance.rawValue : 0
    //油门
    property real _throttlePct:         activeVehicle ? activeVehicle.throttlePct.rawValue : 0
    //时间
    property var  _flightTime:   activeVehicle ? activeVehicle.flightTime.rawValue : 0
    readonly property var _navItems: [
        { "label": qsTr("Video Monitor"), "icon": "qrc:/image/xvideo.png" },
        { "label": qsTr("Map Monitor"), "icon": "qrc:/image/xmap.png" },
        { "label": qsTr("Swarm Control"), "icon": "qrc:/image/xswarm.png" },
        { "label": "RViz",     "icon": "qrc:/image/xrviz.png" },
        { "label": qsTr("Script Customization"), "icon": "qrc:/image/xscript.png" }
    ]
    readonly property var _videoItems: [
        qsTr("Downward global camera stream"),
        qsTr("Binocular camera stream"),
        qsTr("Forward short-focus camera stream"),
        qsTr("Forward long-focus camera stream"),
        qsTr("Infrared thermal stream")
    ]
    readonly property var _videoObjectNames: [
        "videoContent",
        "thermalVideo",
        "videoContent3",
        "videoContent4",
        "videoContent5"
    ]
    readonly property var _videoReceivers: [
        QGroundControl.videoManager.videoReceiver,
        QGroundControl.videoManager.thermalVideoReceiver,
        QGroundControl.videoManager.videoReceiver3,
        QGroundControl.videoManager.videoReceiver4,
        QGroundControl.videoManager.videoReceiver5
    ]
    readonly property var _videoRtspFacts: [
        QGroundControl.settingsManager.videoSettings.rtspUrl,
        QGroundControl.settingsManager.videoSettings.rtspUrl2,
        QGroundControl.settingsManager.videoSettings.rtspUrl3,
        QGroundControl.settingsManager.videoSettings.rtspUrl4,
        QGroundControl.settingsManager.videoSettings.rtspUrl5
    ]
    property string _videoConfigTitle: ""
    property var    _videoConfigFact:  null

    readonly property var _paramItems: [
        { "label": qsTr("Airspeed"),      "value": _airSpeed.toFixed(1),         "unit": "m/s" },
        { "label": qsTr("Altitude AMSL"), "value": _altitudeAMSL.toFixed(0),     "unit": "m" },
        { "label": qsTr("Climb Rate"),    "value": _climbRate.toFixed(1),        "unit": "m/s" },
        { "label": qsTr("Distance"),      "value": _distanceToHome.toFixed(0),   "unit": "m" },
        { "label": qsTr("Mileage"),       "value": _flightDistance.toFixed(0),   "unit": "m" },
        { "label": qsTr("Speed"),         "value": _groundSpeed.toFixed(1),      "unit": "m/s" },
        { "label": qsTr("Throttle"),      "value": _throttlePct.toFixed(0),      "unit": "%" },
        { "label": qsTr("Altitude"),      "value": _altitudeRelative.toFixed(0), "unit": "m" },
        { "label": qsTr("Flight Time"),   "value": getFlyTime(),                 "unit": "" }
    ]

    function getFlyTime() {
        if(_flightTime <= 0 || isNaN(_flightTime) ) {
            return "00:00"
        }
        // console.log("_flightTime:",_flightTime)

        var totalSec = Math.floor(_flightTime)
        var small = Math.floor(totalSec / 60)
        var sec = totalSec % 60
        return (small < 10 ? "0" + small : small) + ":" + (sec < 10 ? "0" + sec : sec)
    }

    function requestInitVideoSinks() {
        initVideoSinksTimer.restart()
    }

    on_SelectedNavIndexChanged: {
        if (_selectedNavIndex !== 0) {
            _fullVideoStreamIndex = -1
        }
    }

    on_FullVideoStreamIndexChanged: {
        if (_fullVideoStreamIndex < 0) {
            requestInitVideoSinks()
        }
    }

    Timer {
        id:       initVideoSinksTimer
        interval: 0
        repeat:   false
        onTriggered: QGroundControl.videoManager.initVideoSinks()
    }

    PlanMasterController {
        id:                     _homePlanController
        flyView:                true
        Component.onCompleted:  start()
    }

    QGCToolInsets {
        id: _homeMapInsets
    }

    GuidedActionsController {
        id:                 guidedActionsController
        missionController:  _homePlanController.missionController
        actionList:         _guidedActionList
        guidedValueSlider:  _guidedValueSlider
    }

    XScriptTcpController {
        id: scriptTcpController
    }

    XGimbalTcpController {
        id: gimbalTcpController
    }

    GuidedActionConfirm {
        id:                         guidedActionConfirm
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.topMargin:          _toolbarHeight + _toolsMargin
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           guidedActionsController
        guidedValueSlider:          guidedValueSlider
    }

    GuidedActionList {
        id:                         guidedActionList
        anchors.margins:            _toolsMargin
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           guidedActionsController
        guidedValueSlider:          guidedValueSlider
    }

    GuidedValueSlider {
        id:                         guidedValueSlider
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.topMargin:          _toolbarHeight + _toolsMargin
        anchors.right:              parent.right
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       _toolsMargin
        z:                          QGroundControl.zOrderTopMost
        radius:                     ScreenTools.defaultFontPixelWidth / 2
        width:                      ScreenTools.defaultFontPixelWidth * 10
        color:                      XGlobalColor.background2
        visible:                    false
    }

    GripperMenu {
        id: gripperOptions
    }

    FlyViewToolStripActionList {
        id: flyControlActionList

        onDisplayPreFlightChecklist: preFlightChecklistPopup.createObject(mainWindow).open()
    }

    Component {
        id: preFlightChecklistPopup

        FlyViewPreFlightChecklistPopup {
        }
    }

    Item {
        id:      _pipOverlay
        visible: false
        property real fullZOrder: 0
        property real pipZOrder: 0
    }

    Rectangle {
        id:             mainHome
        anchors.fill:   parent
        visible:        !XGlobalProperty.isPlanView
        color:          XGlobalColor.background

        property real _gap:           Math.max(8, _margin * 0.7)
        property real _sideWidth:     Math.max(_margin * 5, width * 0.05)
        property real _rightWidth:    Math.max(_margin * 18, width * 0.18)
        property real _contentTop:    _toolbarHeight + _gap

        Rectangle {
            id:                 leftNav
            anchors.top:        parent.top
            anchors.topMargin:  _toolbarHeight
            anchors.bottom:     parent.bottom
            anchors.left:       parent.left
            width:              mainHome._sideWidth
            color:              XGlobalColor.background
            border.color:       XGlobalColor.line
            border.width:       1

            Column {
                anchors.top:        parent.top
                anchors.topMargin:  mainHome._gap * 1.3
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            mainHome._gap * 0.65

                Repeater {
                    model: root._navItems
                    delegate: Item {
                        width:  leftNav.width
                        height: Math.max(_margin * 4.2, leftNav.width * 0.95)

                        Rectangle {
                            anchors.centerIn: parent
                            width:            parent.width - mainHome._gap * 1.2
                            height:           parent.height
                            radius:           5
                            color:            root._selectedNavIndex === index ? XGlobalColor.theme : "transparent"
                            border.color:     root._selectedNavIndex === index ? XGlobalColor.sub : "transparent"
                            border.width:     root._selectedNavIndex === index ? 0 : 0

                            Column {
                                anchors.centerIn: parent
                                spacing:          mainHome._gap * 0.28

                                XColoredImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:                    Math.min(_margin * 1.65, leftNav.width * 0.34)
                                    height:                   width
                                    source:                   modelData.icon
                                    color:                    root._selectedNavIndex === index ? XGlobalColor.label : XGlobalColor.label2
                                }

                                XLabel {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:                     modelData.label
                                    color:                    root._selectedNavIndex === index ? XGlobalColor.label : XGlobalColor.label2
                                    min:                    true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    root._selectedNavIndex = index
                            }
                        }
                    }
                }
            }
        }

        Item {
            id:                 videoArea
            visible:            root._selectedNavIndex === 0
            anchors.top:        parent.top
            anchors.topMargin:  mainHome._contentTop
            anchors.left:       leftNav.right
            anchors.leftMargin: mainHome._gap
            anchors.right:      rightPanel.left
            anchors.rightMargin: mainHome._gap
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: mainHome._gap

            Repeater {
                model: 5

                delegate: Loader {
                    property bool cardFullScreen: root._fullVideoStreamIndex === index
                    property string cardTitle: root._videoItems[index]
                    property string cardObjectName: root._videoObjectNames[index]
                    property var cardReceiver: root._videoReceivers[index]
                    property var cardRtspFact: root._videoRtspFacts[index]
                    property int cardStreamIndex: index

                    readonly property real _normalTopHeight: (videoArea.height - mainHome._gap) * 0.5
                    readonly property real _normalBottomY: _normalTopHeight + mainHome._gap
                    readonly property real _normalWidth: index < 2 ?
                                                             (videoArea.width - mainHome._gap) / 2 :
                                                             (videoArea.width - mainHome._gap * 2) / 3
                    readonly property real _normalX: index < 2 ?
                                                         index * (_normalWidth + mainHome._gap) :
                                                         (index - 2) * (_normalWidth + mainHome._gap)

                    x:               cardFullScreen ? 0 : _normalX
                    y:               cardFullScreen || index < 2 ? 0 : _normalBottomY
                    width:           cardFullScreen ? videoArea.width : _normalWidth
                    height:          cardFullScreen ? videoArea.height : _normalTopHeight
                    visible:         root._fullVideoStreamIndex < 0 || cardFullScreen
                    z:               cardFullScreen ? 10 : 0
                    sourceComponent: videoCardComponent
                }
            }
        }

        Rectangle {
            id:                 mapArea
            visible:            root._selectedNavIndex === 1
            anchors.top:        parent.top
            anchors.topMargin:  mainHome._contentTop
            anchors.left:       leftNav.right
            anchors.leftMargin: mainHome._gap
            anchors.right:      parent.right
            anchors.rightMargin: mainHome._gap
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: mainHome._gap
            radius:             8
            color:              XGlobalColor.background2
            border.color:       XGlobalColor.line
            border.width:       1
            clip:               true

            FlyViewMap {
                id:                     homeMapControl
                width:                  root._selectedNavIndex === 1 ? parent.width : 0
                height:                 root._selectedNavIndex === 1 ? parent.height : 0
                anchors.margins:        1
                planMasterController:   _homePlanController
                rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
                pipMode:                false
                toolInsets:             _homeMapInsets
                mapName:                "XHomeMapView"
            }
        }

        Rectangle {
            id:                 placeholderArea
            visible:            root._selectedNavIndex >= 2
            anchors.top:        parent.top
            anchors.topMargin:  mainHome._contentTop
            anchors.left:       leftNav.right
            anchors.leftMargin: mainHome._gap
            anchors.right:      parent.right
            anchors.rightMargin: mainHome._gap
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: mainHome._gap
            radius:             8
            color:              XGlobalColor.background2
            border.color:       XGlobalColor.line
            border.width:       1

            Column {
                visible: root._selectedNavIndex !== 4
                anchors.centerIn: parent
                spacing:          mainHome._gap

                XColoredImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:                    _margin * 4
                    height:                   width
                    source:                   root._navItems[root._selectedNavIndex].icon
                    color:                    XGlobalColor.label2
                }

                XLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:                     root._navItems[root._selectedNavIndex].label
                    color:                    XGlobalColor.label2
                    big:                      true
                }

                XLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:                     qsTr("Not developed yet...")
                    color:                    XGlobalColor.label
                    large:                    true
                }
            }

            Item {
                id: scriptPage
                visible:            root._selectedNavIndex === 4
                anchors.fill:       parent
                anchors.margins:    mainHome._gap * 1.2

                property real _fieldHeight: Math.max(_margin * 2.4, 34)
                property real _labelWidth:  Math.max(_margin * 5.2, 80)

                Row {
                    id: scriptHeader
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top
                    height:             Math.max(_margin * 3.2, 48)
                    spacing:            mainHome._gap

                    XLabel {
                        width:                  Math.max(_margin * 12, parent.width * 0.18)
                        anchors.verticalCenter: parent.verticalCenter
                        text:                   qsTr("Script Customization")
                        color:                  XGlobalColor.label
                        big:                    true
                    }

                    Item { width: 1; height: 1 }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing:                mainHome._gap * 0.6
                        width:                  parent.width - x
                        height:                 scriptPage._fieldHeight

                        XLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   "TCP/IP"
                            color:                  XGlobalColor.label2
                            small:                  true
                        }

                        XTextField {
                            id:                     scriptIpField
                            width:                  Math.max(_margin * 12, 150)
                            height:                 scriptPage._fieldHeight
                            text:                   scriptTcpController.tcpServerIP
                            color:                  XGlobalColor.label
                            font.bold:              false
                            font.pixelSize:         Math.max(12, _margin * 1.1)
                            selectByMouse:          true
                        }

                        XLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   qsTr("Port")
                            color:                  XGlobalColor.label2
                            small:                  true
                        }

                        XTextField {
                            id:                     scriptPortField
                            width:                  Math.max(_margin * 6, 82)
                            height:                 scriptPage._fieldHeight
                            text:                   scriptTcpController.tcpServerPort.toString()
                            color:                  XGlobalColor.label
                            font.bold:              false
                            font.pixelSize:         Math.max(12, _margin * 1.1)
                            inputMethodHints:       Qt.ImhDigitsOnly
                            selectByMouse:          true
                        }

                        XButtonLabel {
                            id:                     scriptConnectButton
                            height:                 scriptPage._fieldHeight
                            width:                  Math.max(_margin * 6.5, 88)
                            text:                   scriptTcpController.isConnected ? qsTr("Disconnect") : qsTr("Connect")
                            onClicked: {
                                if (scriptTcpController.isConnected) {
                                    scriptTcpController.disConnectQml()
                                } else {
                                    scriptTcpController.tcpServerIP = scriptIpField.text
                                    scriptTcpController.tcpServerPort = parseInt(scriptPortField.text)
                                    scriptTcpController.connectQml(scriptIpField.text, parseInt(scriptPortField.text))
                                }
                            }
                            background: Rectangle {
                                radius:       5
                                color:        scriptTcpController.isConnected ? "#444c3741" : XGlobalColor.theme
                                border.color: XGlobalColor.line
                                border.width: 1
                            }
                            contentItem: XLabel {
                                text:                scriptConnectButton.text
                                color:               XGlobalColor.label
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                                small:               true
                            }
                        }
                    }
                }

                Rectangle {
                    id: scriptStatusPanel
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        scriptHeader.bottom
                    anchors.topMargin:  mainHome._gap
                    height:             Math.max(_margin * 5.5, 74)
                    radius:             6
                    color:              XGlobalColor.background
                    border.color:       XGlobalColor.line
                    border.width:       1

                    Row {
                        anchors.fill:    parent
                        anchors.margins: mainHome._gap
                        spacing:         mainHome._gap * 1.2

                        Column {
                            width:      parent.width * 0.32
                            height:     parent.height
                            spacing:    mainHome._gap * 0.2
                            XLabel { text: qsTr("Connection Status"); color: XGlobalColor.label2; small: true }
                            XLabel { text: scriptTcpController.isConnected ? qsTr("TCP Connected") : qsTr("TCP Disconnected"); color: scriptTcpController.isConnected ? XGlobalColor.sub : XGlobalColor.label; big: true }
                        }

                        Column {
                            width:      parent.width * 0.28
                            height:     parent.height
                            spacing:    mainHome._gap * 0.2
                            XLabel { text: qsTr("Task Status"); color: XGlobalColor.label2; small: true }
                            XLabel { text: scriptTcpController.statusText; color: XGlobalColor.label; big: true; elide: Text.ElideRight; width: parent.width }
                        }

                        Column {
                            width:      parent.width * 0.18
                            height:     parent.height
                            spacing:    mainHome._gap * 0.2
                            XLabel { text: qsTr("Progress"); color: XGlobalColor.label2; small: true }
                            XLabel { text: scriptTcpController.progress + "%"; color: XGlobalColor.sub; big: true }
                        }

                        Column {
                            width:      parent.width - x
                            height:     parent.height
                            spacing:    mainHome._gap * 0.2
                            XLabel { text: "Task ID"; color: XGlobalColor.label2; small: true }
                            XLabel { text: scriptTcpController.lastTaskId === "" ? "--" : scriptTcpController.lastTaskId; color: XGlobalColor.label; small: true; elide: Text.ElideRight; width: parent.width }
                        }
                    }
                }

                Row {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        scriptStatusPanel.bottom
                    anchors.topMargin:  mainHome._gap
                    anchors.bottom:     parent.bottom
                    spacing:            mainHome._gap

                    Rectangle {
                        width:        Math.max(parent.width * 0.34, _margin * 24)
                        height:       parent.height
                        radius:       6
                        color:        XGlobalColor.background
                        border.color: XGlobalColor.line
                        border.width: 1

                        Column {
                            anchors.fill:    parent
                            anchors.margins: mainHome._gap
                            spacing:         mainHome._gap * 0.8

                            XLabel {
                                text:  qsTr("Start Script")
                                color: XGlobalColor.label
                                big:   true
                            }

                            Row {
                                width: parent.width
                                height: scriptPage._fieldHeight
                                spacing: mainHome._gap
                                XLabel { width: scriptPage._labelWidth; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Script Name"); color: XGlobalColor.label2; small: true }
                                XTextField {
                                    id: scriptNameField
                                    width: parent.width - x
                                    height: parent.height
                                    text: "takeoff_demo.py"
                                    color: XGlobalColor.label
                                    font.bold: false
                                    font.pixelSize: Math.max(12, _margin * 1.1)
                                    selectByMouse: true
                                }
                            }

                            Row {
                                width: parent.width
                                height: scriptPage._fieldHeight
                                spacing: mainHome._gap
                                XLabel { width: scriptPage._labelWidth; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Altitude (m)"); color: XGlobalColor.label2; small: true }
                                XTextField {
                                    id: scriptAltitudeField
                                    width: Math.max(_margin * 8, 96)
                                    height: parent.height
                                    text: "5"
                                    color: XGlobalColor.label
                                    font.bold: false
                                    font.pixelSize: Math.max(12, _margin * 1.1)
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    selectByMouse: true
                                }
                                XLabel {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("ACK Required")
                                    color: XGlobalColor.label2
                                    small: true
                                }
                                XSwitch {
                                    id: scriptAckSwitch
                                    checked: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            XButtonLabel {
                                id: scriptStartButton
                                width:  parent.width
                                height: scriptPage._fieldHeight * 1.15
                                text:   qsTr("Send Start JSON")
                                enabled: scriptTcpController.isConnected
                                onClicked: scriptTcpController.sendStartScript(scriptNameField.text, parseInt(scriptAltitudeField.text), scriptAckSwitch.checked)
                                background: Rectangle {
                                    radius: 5
                                    color: scriptStartButton.enabled ? XGlobalColor.theme : "#334f5b56"
                                }
                                contentItem: XLabel {
                                    text: scriptStartButton.text
                                    color: XGlobalColor.label
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    big: true
                                }
                            }

                            XLabel {
                                text: qsTr("Custom JSON")
                                color: XGlobalColor.label
                                big: true
                            }

                            TextArea {
                                id: customJsonArea
                                width: parent.width
                                height: Math.max(_margin * 12, parent.height - y - scriptPage._fieldHeight * 1.6)
                                text: "{\n  \"task_id\": \"20260513_001\",\n  \"command\": \"start_script\",\n  \"script_name\": \"takeoff_demo.py\",\n  \"params\": {\n    \"altitude\": 5\n  },\n  \"ack_required\": true\n}"
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                color: XGlobalColor.label
                                font.pixelSize: Math.max(12, _margin * 1.0)
                                background: Rectangle {
                                    radius: 5
                                    color: "#88000000"
                                    border.color: XGlobalColor.line
                                    border.width: 1
                                }
                            }

                            XButtonLabel {
                                id: scriptCustomButton
                                width:  parent.width
                                height: scriptPage._fieldHeight
                                text:   qsTr("Send Custom JSON")
                                enabled: scriptTcpController.isConnected
                                onClicked: scriptTcpController.sendJsonText(customJsonArea.text)
                                background: Rectangle {
                                    radius: 5
                                    color: scriptCustomButton.enabled ? "#334fd6a2" : "#334f5b56"
                                    border.color: XGlobalColor.line
                                    border.width: 1
                                }
                                contentItem: XLabel {
                                    text: scriptCustomButton.text
                                    color: XGlobalColor.label
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    small: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        width:        parent.width - x
                        height:       parent.height
                        radius:       6
                        color:        XGlobalColor.background
                        border.color: XGlobalColor.line
                        border.width: 1

                        Column {
                            anchors.fill:    parent
                            anchors.margins: mainHome._gap
                            spacing:         mainHome._gap * 0.6

                            Row {
                                width: parent.width
                                height: scriptPage._fieldHeight
                                XLabel {
                                    width: parent.width - clearLogButton.width
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("UAV JSON Feedback")
                                    color: XGlobalColor.label
                                    big: true
                                }
                                XButtonLabel {
                                    id: clearLogButton
                                    width: Math.max(_margin * 5.5, 72)
                                    height: parent.height
                                    text: qsTr("Clear")
                                    onClicked: scriptTcpController.clearLog()
                                    background: Rectangle {
                                        radius: 5
                                        color: "#22000000"
                                        border.color: XGlobalColor.line
                                        border.width: 1
                                    }
                                    contentItem: XLabel {
                                        text: clearLogButton.text
                                        color: XGlobalColor.label2
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        small: true
                                    }
                                }
                            }

                            ScrollView {
                                width: parent.width
                                height: parent.height - y
                                clip: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                                TextArea {
                                    id: scriptLogArea
                                    width: parent.width
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    text: scriptTcpController.logText
                                    color: XGlobalColor.label
                                    font.pixelSize: Math.max(12, _margin * 1.0)
                                    onTextChanged: cursorPosition = length
                                    background: Rectangle {
                                        radius: 5
                                        color: "#88000000"
                                        border.color: XGlobalColor.line
                                        border.width: 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id:                 rightPanel
            visible:            root._selectedNavIndex === 0
            anchors.top:        parent.top
            anchors.topMargin:  mainHome._contentTop
            anchors.right:      parent.right
            anchors.rightMargin: mainHome._gap
            anchors.bottom:     parent.bottom
            anchors.bottomMargin: mainHome._gap
            width:              mainHome._rightWidth
            spacing:            mainHome._gap
            property int _mode: 0
            property real _tabHeight: Math.max(_margin * 2.4, 34)
            property real _panelHeight: Math.max(0, height - _tabHeight - spacing)
            property real _flyControlHeight: Math.min(Math.max(_margin * 10, _panelHeight * 0.2), _margin * 18)
            property real _availablePanelHeight: Math.max(0, _panelHeight - spacing * 2 - _flyControlHeight)

            Row {
                id: rightPanelTabs
                width: parent.width
                height: rightPanel._tabHeight
                spacing: mainHome._gap * 0.35

                Repeater {
                    model: [
                        qsTr("Flight"),
                        qsTr("Pod")
                    ]

                    delegate: Rectangle {
                        width: (rightPanelTabs.width - rightPanelTabs.spacing) / 2
                        height: rightPanelTabs.height
                        radius: 5
                        color: rightPanel._mode === index ? XGlobalColor.theme : XGlobalColor.background2
                        border.color: XGlobalColor.line
                        border.width: 1

                        XLabel {
                            anchors.centerIn: parent
                            text: modelData
                            color: rightPanel._mode === index ? XGlobalColor.label : XGlobalColor.label2
                            small: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rightPanel._mode = index
                        }
                    }
                }
            }

            Rectangle {
                id:           attitudePanel
                width:        parent.width
                height:       rightPanel._mode === 0 ? rightPanel._availablePanelHeight * 0.48 : 0
                visible:      rightPanel._mode === 0
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1
                clip:         false
                Item {
                    id:             dashBox
                    width:          Math.min(parent.width * 0.78, parent.height * 0.66)
                    height:         width
                    anchors.top:    parent.top
                    anchors.topMargin: mainHome._gap * 1.6
                    anchors.horizontalCenter: parent.horizontalCenter

                    //底部表面板
                    XDashboard {
                        id:                             dashboard
                        anchors.fill:       parent

                        // width:                          _dashWidth
                        // height:                         width
                    }

                    // Image {
                    //     anchors.fill:       parent
                    //     source:             "qrc:/image/xdash.png"
                    //     fillMode:           Image.PreserveAspectFit
                    //     smooth:             true
                    //     mipmap:             true
                    // }
                    // Image {
                    //     anchors.centerIn:   parent
                    //     width:              parent.width * 0.18
                    //     height:             width
                    //     source:             "qrc:/image/xarrow"
                    //     fillMode:           Image.PreserveAspectFit
                    //     smooth:             true
                    //     mipmap:             true
                    //     rotation:           _heading
                    // }
                }
                Row {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.bottom:     parent.bottom
                    anchors.bottomMargin: mainHome._gap
                    anchors.leftMargin: mainHome._gap
                    anchors.rightMargin: mainHome._gap
                    height:             parent.height * 0.22
                    spacing:            mainHome._gap
                    Column {
                        width:      (parent.width - parent.spacing * 2) / 3
                        height:     parent.height
                        spacing:    2
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     qsTr("Pitch")
                            color:                    XGlobalColor.label2
                            small:                    true
                        }
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     _pitchAngle.toFixed(1)
                            color:                    XGlobalColor.label
                            big:                      true
                        }
                    }
                    Column {
                        width:      (parent.width - parent.spacing * 2) / 3
                        height:     parent.height
                        spacing:    2
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     qsTr("Roll")
                            color:                    XGlobalColor.label2
                            small:                    true
                        }
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     _rollAngle.toFixed(1)
                            color:                    XGlobalColor.label
                            big:                      true
                        }
                    }
                    Column {
                        width:      (parent.width - parent.spacing * 2) / 3
                        height:     parent.height
                        spacing:    2
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     qsTr("Yaw")
                            color:                    XGlobalColor.label2
                            small:                    true
                        }
                        XLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:                     _heading.toFixed(1)
                            color:                    XGlobalColor.label
                            big:                      true
                        }
                    }
                }
            }

            Rectangle {
                id:           flightControlPanel
                width:        parent.width
                height:       rightPanel._mode === 0 ? rightPanel._flyControlHeight : 0
                visible:      rightPanel._mode === 0
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1
                clip:         true

                Grid {
                    id:                 flightControlGrid
                    anchors.fill:       parent
                    anchors.margins:    mainHome._gap * 0.7
                    columns:            2
                    rows:               3
                    columnSpacing:      mainHome._gap * 0.55
                    rowSpacing:         mainHome._gap * 0.55
                    visible:            !QGroundControl.videoManager.fullScreen

                    Repeater {
                        model: flyControlActionList.model

                        delegate: XButtonLabel {
                            id:                 flightControlButton
                            width:              (flightControlGrid.width - flightControlGrid.columnSpacing) / 2
                            height:             (flightControlGrid.height - flightControlGrid.rowSpacing * 2) / 3
                            visible:            modelData.iconSource !== "/qmlimages/Plan.svg" && modelData.iconSource !== "/res/Gripper.svg"
                            enabled:            modelData.visible && modelData.enabled
                            hoverEnabled:       !ScreenTools.isMobile

                            property bool _active: checked || pressed
                            property string _iconSource: modelData.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource

                            onClicked: modelData.triggered(flightControlButton)

                            background: Rectangle {
                                anchors.fill:   parent
                                radius:         5
                                color:          flightControlButton._active ? XGlobalColor.theme :
                                                    (flightControlButton.hovered && flightControlButton.enabled ? "#3332473f" : "#22000000")
                                border.color:   flightControlButton.enabled ? XGlobalColor.line : "#334f5b56"
                                border.width:   1
                            }

                            contentItem: Column {
                                anchors.centerIn: parent
                                spacing:          Math.max(1, mainHome._gap * 0.18)

                                Item {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:                    Math.min(flightControlButton.width * 0.34, flightControlButton.height * 0.42)
                                    height:                   width

                                    Image {
                                        anchors.fill:       parent
                                        source:             flightControlButton._iconSource
                                        fillMode:           Image.PreserveAspectFit
                                        smooth:             true
                                        mipmap:             true
                                        visible:            source != "" && modelData.fullColorIcon
                                        opacity:            flightControlButton.enabled ? 1.0 : 0.32
                                    }

                                    QGCColoredImage {
                                        anchors.fill:       parent
                                        source:             flightControlButton._iconSource
                                        fillMode:           Image.PreserveAspectFit
                                        color:              flightControlButton.enabled ?
                                                                (flightControlButton._active ? XGlobalColor.label : XGlobalColor.sub) :
                                                                "#66708078"
                                        visible:            source != "" && !modelData.fullColorIcon
                                    }
                                }

                                XLabel {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:                    flightControlButton.width - mainHome._gap * 0.4
                                    horizontalAlignment:      Text.AlignHCenter
                                    elide:                    Text.ElideRight
                                    text:                     modelData.text
                                    color:                    flightControlButton.enabled ? XGlobalColor.label : "#66708078"
                                    small:                    true
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id:           valuesPanel
                width:        parent.width
                height:       rightPanel._mode === 0 ? rightPanel._panelHeight - attitudePanel.height - flightControlPanel.height - rightPanel.spacing * 2 : 0
                visible:      rightPanel._mode === 0
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1
                clip:         false

                Column {
                    anchors.fill:    parent
                    anchors.margins: mainHome._gap
                    spacing:         mainHome._gap * 0.7

                    Repeater {
                        model: [
                            { "label": qsTr("Altitude"), "value": _altitudeRelative.toFixed(0), "unit": "m" },
                            { "label": qsTr("Speed"),    "value": _groundSpeed.toFixed(1),      "unit": "m/s" }
                        ]
                        delegate: Rectangle {
                            width:        parent.width
                            height:       Math.max(_margin * 3.5, parent.parent.height * 0.16)
                            color:        "transparent"
                            border.color: XGlobalColor.line
                            border.width: 1

                            XLabel {
                                anchors.left:           parent.left
                                anchors.leftMargin:     mainHome._gap * 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                text:                   modelData.label
                                color:                  XGlobalColor.label2
                                small:                  true
                            }

                            Row {
                                anchors.right:          parent.right
                                anchors.rightMargin:    mainHome._gap * 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing:                mainHome._gap * 0.25
                                XLabel {
                                    text:  modelData.value
                                    color: XGlobalColor.sub
                                    big:   true
                                }
                                XLabel {
                                    anchors.bottom: parent.children[0].bottom
                                    text:           modelData.unit
                                    color:          XGlobalColor.label2
                                    small:          true
                                }
                            }
                        }
                    }

                    Grid {
                        width:       parent.width
                        height:      parent.height - y
                        columns:     3
                        rowSpacing:  mainHome._gap * 0.45
                        columnSpacing: mainHome._gap * 0.5

                        Repeater {
                            model: root._paramItems
                            delegate: Item {
                                width:  (parent.width - parent.columnSpacing * 2) / 3
                                height: Math.max(_margin * 3.6, parent.height / 3.2)

                                Column {
                                    anchors.centerIn: parent
                                    spacing:          2
                                    XLabel {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text:                     modelData.label
                                        color:                    XGlobalColor.label2
                                        small:                    true
                                    }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing:                  3
                                        XLabel {
                                            text:  modelData.value
                                            color: XGlobalColor.label
                                            big:   true
                                        }
                                        XLabel {
                                            anchors.bottom: parent.children[0].bottom
                                            text:           modelData.unit
                                            color:          XGlobalColor.label2
                                            small:          true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id:           gimbalPanel
                width:        parent.width
                height:       rightPanel._mode === 1 ? rightPanel._panelHeight : 0
                visible:      rightPanel._mode === 1
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1
                clip:         true

                Flickable {
                    anchors.fill:    parent
                    anchors.margins: mainHome._gap
                    contentWidth:    width
                    contentHeight:   gimbalColumn.height
                    clip:            true

                    Column {
                        id:      gimbalColumn
                        width:   parent.width
                        spacing: mainHome._gap * 0.7

                        XLabel {
                            text:  qsTr("Pod Control")
                            color: XGlobalColor.label
                            big:   true
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: mainHome._gap * 0.45
                            rowSpacing: mainHome._gap * 0.45

                            TextField {
                                id: gimbalIpField
                                width: (parent.width - parent.columnSpacing) * 0.58
                                height: Math.max(_margin * 2.2, 32)
                                text: gimbalTcpController.tcpServerIP
                                color: XGlobalColor.label
                                placeholderText: qsTr("Device IP")
                                selectByMouse: true
                                background: Rectangle {
                                    radius: 4
                                    color: XGlobalColor.background
                                    border.color: XGlobalColor.line
                                    border.width: 1
                                }
                            }

                            TextField {
                                id: gimbalPortField
                                width: (parent.width - parent.columnSpacing) * 0.42
                                height: gimbalIpField.height
                                text: gimbalTcpController.tcpServerPort.toString()
                                color: XGlobalColor.label
                                placeholderText: qsTr("Port")
                                inputMethodHints: Qt.ImhDigitsOnly
                                selectByMouse: true
                                background: Rectangle {
                                    radius: 4
                                    color: XGlobalColor.background
                                    border.color: XGlobalColor.line
                                    border.width: 1
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: mainHome._gap * 0.45

                            XButtonLabel {
                                width: (parent.width - parent.spacing) / 2
                                height: Math.max(_margin * 2.3, 34)
                                text: gimbalTcpController.isConnected ? qsTr("Disconnect") : qsTr("Connect")
                                onClicked: {
                                    gimbalTcpController.tcpServerIP = gimbalIpField.text
                                    gimbalTcpController.tcpServerPort = parseInt(gimbalPortField.text)
                                    if (gimbalTcpController.isConnected) {
                                        gimbalTcpController.disConnectQml()
                                    } else {
                                        gimbalTcpController.connectQml(gimbalIpField.text, parseInt(gimbalPortField.text))
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - parent.spacing) / 2
                                height: Math.max(_margin * 2.3, 34)
                                radius: 4
                                color: gimbalTcpController.isConnected ? "#334fd6a2" : "#33d65f5f"
                                border.color: XGlobalColor.line
                                border.width: 1

                                XLabel {
                                    anchors.centerIn: parent
                                    text: gimbalTcpController.isConnected ? qsTr("Command OK") : qsTr("Command Off")
                                    color: XGlobalColor.label
                                    small: true
                                }
                            }
                        }

                        XLabel {
                            text: qsTr("Video channel: main video area")
                            color: XGlobalColor.label2
                            small: true
                        }

                        Row {
                            width: parent.width
                            height: Math.max(_margin * 2.3, 34)
                            spacing: mainHome._gap * 0.45

                            Item {
                                id: detectionIndicatorContainer
                                width: Math.max(_margin * 3.2, 42)
                                height: parent.height

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Math.max(_margin * 0.35, 5)

                                    Rectangle {
                                        width: Math.max(_margin * 0.85, 10)
                                        height: width
                                        radius: width / 2
                                        color: gimbalTcpController.detectionEnabled ? XGlobalColor.success : XGlobalColor.btnbg2
                                        border.color: gimbalTcpController.detectionEnabled ? XGlobalColor.success : XGlobalColor.line
                                        border.width: 1
                                    }

                                    Rectangle {
                                        width: Math.max(_margin * 0.85, 10)
                                        height: width
                                        radius: width / 2
                                        color: gimbalTcpController.detectionEnabled ? XGlobalColor.btnbg2 : XGlobalColor.danger
                                        border.color: gimbalTcpController.detectionEnabled ? XGlobalColor.line : XGlobalColor.danger
                                        border.width: 1
                                    }
                                }
                            }

                            XButtonLabel {
                                width: parent.width - detectionIndicatorContainer.width - parent.spacing
                                height: parent.height
                                enabled: gimbalTcpController.isConnected
                                text: gimbalTcpController.detectionEnabled ? qsTr("Disable Detection") : qsTr("Enable Detection")
                                _theme: gimbalTcpController.detectionEnabled ? XGlobalColor.theme2 : XGlobalColor.theme
                                onClicked: gimbalTcpController.setDetectionEnabled(!gimbalTcpController.detectionEnabled)
                            }
                        }

                        XLabel {
                            text: qsTr("Target Selection")
                            color: XGlobalColor.label
                            small: true
                        }

                        Row {
                            width: parent.width
                            spacing: mainHome._gap * 0.35

                            XButtonLabel {
                                width: (parent.width - parent.spacing * 2) / 3
                                height: Math.max(_margin * 2.3, 34)
                                text: qsTr("Point Select")
                                _theme: root._trackingInputMode === 0 ? XGlobalColor.theme2 : XGlobalColor.theme
                                onClicked: root._trackingInputMode = 0
                            }
                            XButtonLabel {
                                width: (parent.width - parent.spacing * 2) / 3
                                height: Math.max(_margin * 2.3, 34)
                                text: qsTr("Drag Select")
                                _theme: root._trackingInputMode === 1 ? XGlobalColor.theme2 : XGlobalColor.theme
                                onClicked: root._trackingInputMode = 1
                            }
                            XButtonLabel {
                                width: (parent.width - parent.spacing * 2) / 3
                                height: Math.max(_margin * 2.3, 34)
                                text: qsTr("By ID")
                                _theme: root._trackingInputMode === 2 ? XGlobalColor.theme2 : XGlobalColor.theme
                                onClicked: root._trackingInputMode = 2
                            }
                        }

                        XLabel {
                            width: parent.width
                            text: root._trackingInputMode === 0 ? qsTr("Double-click a target in the video") :
                                  (root._trackingInputMode === 1 ? qsTr("Drag a target box in the video") : qsTr("Enter a target ID"))
                            color: XGlobalColor.label2
                            small: true
                            wrapMode: Text.WordWrap
                        }

                        Row {
                            width: parent.width
                            height: root._trackingInputMode === 2 ? Math.max(_margin * 2.3, 34) : 0
                            spacing: mainHome._gap * 0.45
                            visible: root._trackingInputMode === 2

                            TextField {
                                id: targetIdField
                                width: (parent.width - parent.spacing) * 0.55
                                height: parent.height
                                text: "0"
                                color: XGlobalColor.label
                                placeholderText: qsTr("Target ID")
                                inputMethodHints: Qt.ImhDigitsOnly
                                background: Rectangle { radius: 4; color: XGlobalColor.background; border.color: XGlobalColor.line; border.width: 1 }
                            }

                            XButtonLabel {
                                width: (parent.width - parent.spacing) * 0.45
                                height: parent.height
                                text: qsTr("Track Target ID")
                                onClicked: gimbalTcpController.trackId(parseInt(targetIdField.text))
                            }
                        }

                        XButtonLabel {
                            width: parent.width
                            height: Math.max(_margin * 2.3, 34)
                            text: qsTr("Stop Tracking")
                            onClicked: gimbalTcpController.unlockTracking()
                        }

                        Row {
                            width: parent.width
                            spacing: mainHome._gap * 0.45

                            XButtonLabel { width: (parent.width - parent.spacing) / 2; height: Math.max(_margin * 2.3, 34); text: qsTr("Center"); onClicked: gimbalTcpController.gimbalCenter() }
                            XButtonLabel { width: (parent.width - parent.spacing) / 2; height: Math.max(_margin * 2.3, 34); text: qsTr("Down 90"); onClicked: gimbalTcpController.gimbalDown90() }
                        }

                        Grid {
                            width: parent.width
                            columns: 3
                            columnSpacing: mainHome._gap * 0.35
                            rowSpacing: mainHome._gap * 0.35

                            TextField { id: pitchSetField; width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.1, 30); text: "0"; color: XGlobalColor.label; placeholderText: qsTr("Pitch"); background: Rectangle { radius: 4; color: XGlobalColor.background; border.color: XGlobalColor.line; border.width: 1 } }
                            TextField { id: yawSetField; width: pitchSetField.width; height: pitchSetField.height; text: "0"; color: XGlobalColor.label; placeholderText: qsTr("Yaw"); background: Rectangle { radius: 4; color: XGlobalColor.background; border.color: XGlobalColor.line; border.width: 1 } }
                            XButtonLabel { width: pitchSetField.width; height: pitchSetField.height; text: qsTr("Set"); onClicked: gimbalTcpController.setGimbalAngle(parseInt(pitchSetField.text), parseInt(yawSetField.text)) }
                        }

                        Row {
                            width: parent.width
                            spacing: mainHome._gap * 0.45

                            XButtonLabel { width: (parent.width - parent.spacing) / 2; height: Math.max(_margin * 2.3, 34); text: qsTr("Lock"); onClicked: gimbalTcpController.setGimbalLocked(true) }
                            XButtonLabel { width: (parent.width - parent.spacing) / 2; height: Math.max(_margin * 2.3, 34); text: qsTr("Unlock"); onClicked: gimbalTcpController.setGimbalLocked(false) }
                        }

                        GridLayout {
                            columns: 3
                            rowSpacing: _margin * 0.4
                            columnSpacing: _margin * 0.4
                            anchors.horizontalCenter: parent.horizontalCenter

                            Item { width: _margin * 5; height: _margin * 3.4 }
                            XButtonLabel {
                                text: qsTr("Up")
                                Layout.preferredWidth: _margin * 5
                                Layout.preferredHeight: _margin * 3.4
                                onPressed: gimbalTcpController.sendGimbalSpeed(128, 180);
                                onReleased: gimbalTcpController.stopGimbalSpeed()
                            }
                            Item { width: _margin * 5; height: _margin * 3.4 }

                            XButtonLabel {
                                text: qsTr("Left")
                                Layout.preferredWidth: _margin * 5
                                Layout.preferredHeight: _margin * 3.4
                                onPressed: gimbalTcpController.sendGimbalSpeed(76, 128)
                                onReleased: gimbalTcpController.stopGimbalSpeed()
                            }
                            XButtonLabel {
                                text: qsTr("Stop")
                                Layout.preferredWidth: _margin * 5
                                Layout.preferredHeight: _margin * 3.4
                                onClicked: gimbalTcpController.stopGimbalSpeed()
                            }
                            XButtonLabel {
                                text: qsTr("Right")
                                Layout.preferredWidth: _margin * 5
                                Layout.preferredHeight: _margin * 3.4
                                onPressed: gimbalTcpController.sendGimbalSpeed(180, 128); onReleased: gimbalTcpController.stopGimbalSpeed()
                            }

                            Item { width: _margin * 5; height: _margin * 3.4 }
                            XButtonLabel {
                                text: qsTr("Down")
                                Layout.preferredWidth: _margin * 5
                                Layout.preferredHeight: _margin * 3.4
                                onPressed: gimbalTcpController.sendGimbalSpeed(128, 76); onReleased: gimbalTcpController.stopGimbalSpeed()
                            }
                            Item { width: _margin * 5; height: _margin * 3.4 }
                        }

                        // Grid {
                        //     width: Math.min(parent.width, _margin * 14)
                        //     anchors.horizontalCenter: parent.horizontalCenter
                        //     columns: 3
                        //     rowSpacing: mainHome._gap * 0.35
                        //     columnSpacing: mainHome._gap * 0.35

                        //     Item { width: (parent.width - parent.columnSpacing * 2) / 3; height: speedUpButton.height }
                        //     XButtonLabel { id: speedUpButton; width: (parent.parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.2, 32); text: qsTr("Up"); onPressed: gimbalTcpController.sendGimbalSpeed(128, 180); onReleased: gimbalTcpController.stopGimbalSpeed() }
                        //     Item { width: speedUpButton.width; height: speedUpButton.height }
                        //     XButtonLabel { width: speedUpButton.width; height: speedUpButton.height; text: qsTr("Left"); onPressed: gimbalTcpController.sendGimbalSpeed(76, 128); onReleased: gimbalTcpController.stopGimbalSpeed() }
                        //     XButtonLabel { width: speedUpButton.width; height: speedUpButton.height; text: qsTr("Stop"); onClicked: gimbalTcpController.stopGimbalSpeed() }
                        //     XButtonLabel { width: speedUpButton.width; height: speedUpButton.height; text: qsTr("Right"); onPressed: gimbalTcpController.sendGimbalSpeed(180, 128); onReleased: gimbalTcpController.stopGimbalSpeed() }
                        //     Item { width: speedUpButton.width; height: speedUpButton.height }
                        //     XButtonLabel { width: speedUpButton.width; height: speedUpButton.height; text: qsTr("Down"); onPressed: gimbalTcpController.sendGimbalSpeed(128, 76); onReleased: gimbalTcpController.stopGimbalSpeed() }
                        //     Item { width: speedUpButton.width; height: speedUpButton.height }
                        // }

                        Rectangle {
                            width: parent.width
                            height: Math.max(_margin * 10, statusColumn.height + mainHome._gap)
                            radius: 5
                            color: XGlobalColor.background
                            border.color: XGlobalColor.line
                            border.width: 1

                            Column {
                                id: statusColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: mainHome._gap * 0.5
                                spacing: 2

                                XLabel { text: qsTr("Status") + ": " + gimbalTcpController.trackerStatusText; color: XGlobalColor.sub; small: true }
                                XLabel { text: qsTr("Box") + ": " + gimbalTcpController.trackX + "," + gimbalTcpController.trackY + "," + gimbalTcpController.trackW + "," + gimbalTcpController.trackH; color: XGlobalColor.label2; small: true }
                                XLabel { text: qsTr("Yaw") + ": " + gimbalTcpController.yawDeg.toFixed(2) + "  " + qsTr("Pitch") + ": " + gimbalTcpController.pitchDeg.toFixed(2); color: XGlobalColor.label2; small: true }
                                XLabel { text: qsTr("Targets") + ": " + gimbalTcpController.targetCount; color: XGlobalColor.label2; small: true }
                                XLabel { text: gimbalTcpController.statusText; color: XGlobalColor.label; small: true; wrapMode: Text.WordWrap; width: parent.width }
                            }
                        }

                        ScrollView {
                            width: parent.width
                            height: Math.min(Math.max(_margin * 14, 180), Math.max(_margin * 10, gimbalPanel.height * 0.34))
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                            TextArea {
                                id: gimbalLogArea
                                width: parent.width
                                text: gimbalTcpController.logText
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                color: XGlobalColor.label2
                                font.pixelSize: Math.max(12, _margin * 1.0)
                                onTextChanged: cursorPosition = length
                                background: Rectangle {
                                    radius: 5
                                    color: XGlobalColor.background
                                    border.color: XGlobalColor.line
                                    border.width: 1
                                }
                            }
                        }

                        XButtonLabel {
                            width: parent.width
                            height: Math.max(_margin * 2.2, 32)
                            text: qsTr("Clear Log")
                            onClicked: gimbalTcpController.clearLog()
                        }

                        Grid {
                            width: parent.width
                            columns: 3
                            columnSpacing: mainHome._gap * 0.35
                            rowSpacing: mainHome._gap * 0.35

                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("1") }
                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("2") }
                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("3") }
                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("4") }
                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("5") }
                            XButtonLabel { width: (parent.width - parent.columnSpacing * 2) / 3; height: Math.max(_margin * 2.3, 34); text: qsTr("6") }
                        }
                    }
                }
            }
        }

        Component {
            id: videoCardComponent

            Rectangle {
                property string title: parent ? parent.cardTitle : ""
                property string videoObjectName: parent ? parent.cardObjectName : ""
                property var receiver: parent ? parent.cardReceiver : null
                property var rtspFact: parent ? parent.cardRtspFact : null
                property int streamIndex: parent ? parent.cardStreamIndex : -1
                property bool fullScreenCard: parent && parent.cardFullScreen ? true : false
                property bool decoding: false
                property int sourceVideoWidth: 1920
                property int sourceVideoHeight: 1080
                property bool selectionDragging: false
                property real selectionStartX: 0
                property real selectionStartY: 0
                property real selectionCurrentX: 0
                property real selectionCurrentY: 0
                property bool selectionFeedbackVisible: false
                property int selectionFeedbackKind: 0
                property real selectionFeedbackX: 0
                property real selectionFeedbackY: 0
                property real selectionFeedbackWidth: 0
                property real selectionFeedbackHeight: 0
                property string selectionFeedbackText: ""

                onFullScreenCardChanged: bindVideoSinkTimer.restart()

                function bindVideoSink() {
                    if (videoBackground.width > 0 && videoBackground.height > 0) {
                        QGroundControl.videoManager.bindVideoSink(videoBackground, streamIndex)
                    } else {
                        bindVideoSinkTimer.restart()
                    }
                }

                function startCurrentStream() {
                    bindVideoSink()
                    startVideoTimer.restart()
                }

                function showSelectionFeedback(text, kind, x, y, width, height) {
                    selectionFeedbackText = text
                    selectionFeedbackKind = kind
                    selectionFeedbackX = x
                    selectionFeedbackY = y
                    selectionFeedbackWidth = width
                    selectionFeedbackHeight = height
                    selectionFeedbackVisible = true
                    selectionFeedbackTimer.restart()
                }

                anchors.fill: parent
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1
                clip:         false

                Rectangle {
                    anchors.fill: parent
                    color:        "black"
                }

                Image {
                    anchors.fill: parent
                    source:       "qrc:/image/xuav.png"
                    fillMode:     Image.PreserveAspectCrop
                    smooth:       true
                    mipmap:       true
                    z:            0
                }

                QGCVideoBackground {
                    id:          videoBackground
                    objectName:  videoObjectName
                    receiver:    parent.receiver
                    anchors.fill: parent
                    z:           1

                    Component.onCompleted: {
                        console.log("Video created with objectName:", objectName)
                        bindVideoSinkTimer.start()
                    }
                }

                Item {
                    id: selectionOverlay
                    anchors.fill: videoBackground
                    z: 2

                    Rectangle {
                        visible: selectionDragging
                        x: Math.min(selectionStartX, selectionCurrentX)
                        y: Math.min(selectionStartY, selectionCurrentY)
                        width: Math.abs(selectionCurrentX - selectionStartX)
                        height: Math.abs(selectionCurrentY - selectionStartY)
                        color: XGlobalColor.select
                        border.color: XGlobalColor.label
                        border.width: Math.max(1, _margin * 0.12)
                    }

                    Rectangle {
                        visible: selectionFeedbackVisible && selectionFeedbackKind === 2
                        x: selectionFeedbackX
                        y: selectionFeedbackY
                        width: selectionFeedbackWidth
                        height: selectionFeedbackHeight
                        color: XGlobalColor.select
                        border.color: XGlobalColor.label
                        border.width: Math.max(1, _margin * 0.12)
                    }

                    Item {
                        visible: selectionFeedbackVisible && selectionFeedbackKind === 1
                        x: selectionFeedbackX - width / 2
                        y: selectionFeedbackY - height / 2
                        width: Math.max(_margin * 1.5, 18)
                        height: width

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(1, _margin * 0.12)
                            height: parent.height
                            color: XGlobalColor.label
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: Math.max(1, _margin * 0.12)
                            color: XGlobalColor.label
                        }
                    }

                    Rectangle {
                        visible: selectionFeedbackVisible
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: mainHome._gap * 3.5
                        width: Math.min(parent.width - mainHome._gap * 2,
                                        selectionFeedbackLabel.implicitWidth + mainHome._gap * 1.6)
                        height: selectionFeedbackLabel.implicitHeight + mainHome._gap * 0.7
                        radius: height * 0.5
                        color: XGlobalColor.background
                        border.color: XGlobalColor.line
                        border.width: 1

                        XLabel {
                            id: selectionFeedbackLabel
                            anchors.centerIn: parent
                            text: selectionFeedbackText
                            color: XGlobalColor.label
                            small: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: decoding && root._trackingInputMode !== 2
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: root._trackingInputMode === 0 ? Qt.CrossCursor : Qt.SizeAllCursor

                        onDoubleClicked: {
                            if (root._trackingInputMode !== 0) {
                                return
                            }

                            var point = VideoCoordinateMapper.mapPoint(
                                        mouse.x, mouse.y, width, height,
                                        sourceVideoWidth, sourceVideoHeight)
                            if (!point) {
                                showSelectionFeedback(qsTr("Click inside the video image"), 0, 0, 0, 0, 0)
                                console.log("TRACK_XY rejected: click is outside displayed video")
                                return
                            }
                            if (!gimbalTcpController.isConnected) {
                                showSelectionFeedback(qsTr("Command channel is not connected"), 1,
                                                      mouse.x, mouse.y, 0, 0)
                                return
                            }

                            gimbalTcpController.trackXY(point.x, point.y)
                            showSelectionFeedback(qsTr("Point sent: (%1, %2)").arg(point.x).arg(point.y), 1,
                                                  mouse.x, mouse.y, 0, 0)
                            console.log("TRACK_XY stream=" + streamIndex +
                                        " ui=(" + mouse.x.toFixed(1) + "," + mouse.y.toFixed(1) + ")" +
                                        " video=(" + point.x + "," + point.y + ")" +
                                        " source=" + sourceVideoWidth + "x" + sourceVideoHeight)
                        }

                        onPressed: {
                            if (root._trackingInputMode !== 1) {
                                return
                            }

                            var point = VideoCoordinateMapper.mapPoint(
                                        mouse.x, mouse.y, width, height,
                                        sourceVideoWidth, sourceVideoHeight)
                            if (!point) {
                                selectionDragging = false
                                showSelectionFeedback(qsTr("Click inside the video image"), 0, 0, 0, 0, 0)
                                return
                            }

                            selectionStartX = mouse.x
                            selectionStartY = mouse.y
                            selectionCurrentX = mouse.x
                            selectionCurrentY = mouse.y
                            selectionDragging = true
                        }

                        onPositionChanged: {
                            if (!selectionDragging) {
                                return
                            }

                            var rect = VideoCoordinateMapper.displayRect(
                                        width, height, sourceVideoWidth, sourceVideoHeight)
                            selectionCurrentX = Math.max(rect.x, Math.min(mouse.x, rect.x + rect.width))
                            selectionCurrentY = Math.max(rect.y, Math.min(mouse.y, rect.y + rect.height))
                        }

                        onReleased: {
                            if (!selectionDragging) {
                                return
                            }

                            var box = VideoCoordinateMapper.mapSelection(
                                        selectionStartX, selectionStartY, mouse.x, mouse.y,
                                        width, height, sourceVideoWidth, sourceVideoHeight)
                            selectionDragging = false
                            if (!box) {
                                showSelectionFeedback(qsTr("Drag a non-empty box inside video"), 0, 0, 0, 0, 0)
                                console.log("TRACK_BOX rejected: empty selection")
                                return
                            }
                            if (!gimbalTcpController.isConnected) {
                                showSelectionFeedback(qsTr("Command channel is not connected"), 2,
                                                      box.displayX, box.displayY,
                                                      box.displayWidth, box.displayHeight)
                                return
                            }

                            gimbalTcpController.trackBox(box.x, box.y, box.width, box.height)
                            showSelectionFeedback(qsTr("Box sent: (%1, %2, %3, %4)")
                                                  .arg(box.x).arg(box.y).arg(box.width).arg(box.height), 2,
                                                  box.displayX, box.displayY,
                                                  box.displayWidth, box.displayHeight)
                            console.log("TRACK_BOX stream=" + streamIndex +
                                        " video=(" + box.x + "," + box.y + "," +
                                        box.width + "," + box.height + ")" +
                                        " source=" + sourceVideoWidth + "x" + sourceVideoHeight)
                        }

                        onCanceled: selectionDragging = false
                    }
                }

                Timer {
                    id: selectionFeedbackTimer
                    interval: 1600
                    repeat: false
                    onTriggered: selectionFeedbackVisible = false
                }

                Timer {
                    id:       bindVideoSinkTimer
                    interval: 100
                    repeat:   false
                    onTriggered: bindVideoSink()
                }

                Timer {
                    id:       startVideoTimer
                    interval: 150
                    repeat:   false
                    onTriggered: QGroundControl.videoManager.startVideoStream(streamIndex)
                }

                Connections {
                    target: receiver
                    ignoreUnknownSignals: true

                    function onDecodingChanged(active) {
                        decoding = active
                    }

                    function onVideoSizeChanged(size) {
                        if (size.width > 0 && size.height > 0) {
                            sourceVideoWidth = size.width
                            sourceVideoHeight = size.height
                            console.log("Video source size stream=" + streamIndex +
                                        " " + sourceVideoWidth + "x" + sourceVideoHeight)
                        }
                    }
                }

                Rectangle {
                    anchors.left:      parent.left
                    anchors.top:       parent.top
                    anchors.leftMargin: mainHome._gap
                    anchors.topMargin:  mainHome._gap
                    width:             titleLabel.implicitWidth + mainHome._gap * 1.6
                    height:            Math.max(_margin * 2.1, titleLabel.implicitHeight + mainHome._gap * 0.45)
                    radius:            height * 0.5
                    color:             "#880B0E12"
                    z:                 2

                    XLabel {
                        id:                 titleLabel
                        anchors.centerIn:   parent
                        text:               title
                        color:              XGlobalColor.label2
                        small:              true
                    }
                }

                Rectangle {
                    id:                  fullScreenButton
                    anchors.top:         parent.top
                    anchors.right:       parent.right
                    anchors.topMargin:   mainHome._gap
                    anchors.rightMargin: mainHome._gap
                    width:               Math.max(_margin * 3.2, fullScreenLabel.implicitWidth + mainHome._gap * 1.2)
                    height:              Math.max(_margin * 2.1, fullScreenLabel.implicitHeight + mainHome._gap * 0.45)
                    radius:              4
                    color:               fullScreenMouse.containsMouse ? XGlobalColor.theme : "#880B0E12"
                    border.color:        XGlobalColor.line
                    border.width:        1
                    z:                   3

                    XLabel {
                        id:               fullScreenLabel
                        anchors.centerIn: parent
                        text:             fullScreenCard ? qsTr("Exit") : qsTr("Full Screen")
                        color:            XGlobalColor.label2
                        small:            true
                    }

                    MouseArea {
                        id:           fullScreenMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            root._fullVideoStreamIndex = fullScreenCard ? -1 : streamIndex
                        }
                    }
                }


                // Rectangle {
                //     id:                  configButton
                //     anchors.top:         parent.top
                //     anchors.right:       parent.right
                //     anchors.topMargin:   mainHome._gap * 0.7
                //     anchors.rightMargin: mainHome._gap
                //     width:               Math.max(_margin * 2.2, configLabel.implicitWidth + mainHome._gap)
                //     height:              width
                //     radius:              4
                //     color:               configMouse.containsMouse ? XGlobalColor.theme : "#880B0E12"

                //     XLabel {
                //         id:               configLabel
                //         anchors.centerIn: parent
                //         text:             qsTr("设")
                //         color:            XGlobalColor.label2
                //         small:            true
                //     }

                    // MouseArea {
                    //     id:           configMouse
                    //     anchors.fill: parent
                    //     hoverEnabled: true
                    //     cursorShape:  Qt.PointingHandCursor
                    //     onClicked: {
                    //                           //     }
                    // }
                // }

                Rectangle {
                    anchors.right:       parent.right
                    anchors.bottom:      parent.bottom
                    anchors.rightMargin: mainHome._gap
                    anchors.bottomMargin: mainHome._gap
                    width:              videoSetRow.width + _margin * 1.2
                    height:             videoSetRow.height + _margin
                    radius:             4
                    color:              "#AA0B0E12"
                    z:                  2
                    Row {
                        id:                 videoSetRow
                        spacing:            _margin * 0.6
                        anchors.centerIn:   parent
                        XButtonLabel {
                            id:                   startVideoButton
                            text:                 qsTr("Open")
                            anchors.verticalCenter:     parent.verticalCenter
                            _min:              true
                            _marginwidth:           _margin / 3
                            _marginheight:          _margin / 6
                            onClicked: {
                                startCurrentStream()
                            }
                        }
                        XButtonLabel {
                            text:                 qsTr("Close")
                            anchors.verticalCenter:     parent.verticalCenter
                            _min:              true
                            _marginwidth:           _margin / 3
                            _marginheight:          _margin / 6
                            onClicked: {
                                QGroundControl.videoManager.stopVideoStream(streamIndex)
                                decoding = false
                            }
                        }
                        XButtonImage {
                            id:                     configButton
                            anchors.verticalCenter:     parent.verticalCenter
                            height:                 startVideoButton.height * 0.95
                            width:                  height
                            source:                 "qrc:/image/xsetting"
                            // color:                  XGlobalColor.sub2
                            // imageColor:             XGlobalColor.sub
                            colorEnable:            true
                            imageColor:            XGlobalColor.sub
                            onClicked: {
                                root._videoConfigTitle = title
                                root._videoConfigFact = rtspFact
                                mainWindow.xShowPopup(videoRtspConfigComponent, configButton, 1, Math.max(_margin * 28, configButton.parent.width * 0.45))
                            }
                        }

                    }
                }
            }
        }

        Component {
            id: videoRtspConfigComponent

            Rectangle {
                width:        Math.max(_margin * 32, ScreenTools.defaultFontPixelWidth * 34)
                height:       configColumn.height + mainHome._gap * 2
                radius:       8
                color:        XGlobalColor.background2
                border.color: XGlobalColor.line
                border.width: 1

                Column {
                    id:              configColumn
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.top:     parent.top
                    anchors.margins: mainHome._gap
                    spacing:         mainHome._gap

                    XLabel {
                        text:  root._videoConfigTitle
                        color: XGlobalColor.label2
                        big:   true
                    }

                    FactTextField {
                        width: parent.width
                        fact:  root._videoConfigFact
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width:         Math.max(_margin * 6, closeLabel.implicitWidth + mainHome._gap * 1.8)
                        height:        Math.max(_margin * 2.4, closeLabel.implicitHeight + mainHome._gap * 0.7)
                        radius:        4
                        color:         closeMouse.containsMouse ? XGlobalColor.theme : XGlobalColor.background
                        border.color:  XGlobalColor.line
                        border.width:  1

                        XLabel {
                            id:               closeLabel
                            anchors.centerIn: parent
                            text:             qsTr("Close")
                            color:            XGlobalColor.label
                            small:            true
                        }

                        MouseArea {
                            id:           closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    mainWindow.xClosePopup()
                        }
                    }
                }
            }
        }
    }
//     id:              dashbord
//     property real   _margin:            XScreenTool.base
//     property real   _base:              XScreenTool.base / 21.2
//     property real   _dashWidth:         _base * 240//220 //220  //219  //248
//     property var    _guidedController:  globals.guidedControllerFlyView
//     property real   _buttonWidth:        _margin * 5

//     property var    _activeVehicle:      XGlobalProperty.vhcnull  //QGroundControl.multiVehicleManager.activeVehicle
//     property real   _heading:           _activeVehicle ? _activeVehicle.heading.rawValue : 0
//     property real   _sc:                1.0             //整体仪表比例, 初始化
//     property real   _toolbarHeight: XScreenTool.toolbarHeight

//     //左侧线条
//     Image {
//         id:                     bottomLine
//         width:                  parent.width
//         height:                 parent.height * (20 / 1080)
//         anchors.bottom:         parent.bottom
//         anchors.bottomMargin:   parent.height * (10 / 1080)
//         source:                 "qrc:/image/XBottomLine"
//         asynchronous:           true
//         smooth:                 true
//         mipmap:                 true
//         antialiasing:           true
//         fillMode:               Image.Stretch//Image.PreserveAspectFit
//         visible:                true
//     }

//     // //--左侧控制
//     // XFlightControl {
//     //     anchors.fill:       parent
//     //     anchors.top:        parent.top
//     //     anchors.topMargin:  _toolbarHeight + _margin * 3
//     //     anchors.bottom:     parent.bottom
//     //     anchors.bottomMargin: XGlobalProperty.videoHeight + _margin * 3
//     //     anchors.left:       parent.left
//     //     anchors.leftMargin: _margin * 2
//     //     width:              parent.width
//     // }

//     //左侧线条
//     Image {
//         width:                  parent.width *  (309*0.5 / 1080)
//         height:                 parent.height *  (60 / 1080)
//         anchors.bottom:         dashboard.bottom
//         anchors.bottomMargin:   1
//         anchors.horizontalCenter:   dashboard.horizontalCenter
//         source:                 "qrc:/image/XDashLine"
//         asynchronous:           true
//         smooth:                 true
//         mipmap:                 true
//         antialiasing:           true
//         fillMode:               Image.Stretch//Image.PreserveAspectFit
//     }

//     //底部表面板
//     XDashboard {
//         id:                             dashboard
//         anchors.bottom:                 parent.bottom
//         anchors.bottomMargin:           _margin * 2
//         anchors.right:                  parent.right
//         anchors.rightMargin:            _margin * 4
//         width:                          _dashWidth
//         height:                         width
//         visible:                        false
//     }

//     //左侧线条
//     Image {
//         width:                  parent.width * (60 / 1920)
//         height:                 parent.height * (309 / 1080)
//         anchors.bottom:         dashboard.bottom
//         // anchors.bottomMargin:   parent.height * (10 / 1080)
//         source:                 "qrc:/image/XDashLine"
//         asynchronous:           true
//         smooth:                 true
//         mipmap:                 true
//         antialiasing:           true
//         fillMode:               Image.Stretch//Image.PreserveAspectFit
//     }


//     // //底部装饰
//     // Image {
//     //     id:                     bottomImage
//     //     width:                  parent.width
//     //     height:                 parent.height * (20 / 1080)
//     //     anchors.bottom:         parent.bottom
//     //     anchors.bottomMargin:   parent.height * (10 / 1080)
//     //     source:                 "qrc:/image/XDashBottom"
//     //     asynchronous:           true
//     //     smooth:                 true
//     //     mipmap:                 true
//     //     antialiasing:           true
//     //     fillMode:               Image.Stretch//Image.PreserveAspectFit
//     // }

//     //--底部偏航
//     XYawIndicator {
//         id:                             yawWidget
//         anchors.horizontalCenter:       dashboard.horizontalCenter
//         anchors.bottom:                 dashboard.bottom
//         anchors.bottomMargin:           - _margin * 2
//         // anchors.bottomMargin:           0 + 1.0 * _sc
//         color:                          Qt.rgba(0,0,0,0)
//         width:                          parent.width * 0.18//0.8//0.7
//         height:                         45 * _base * dashbord._sc   //25 20
//         _sc:                            dashbord._sc
//         _headingAngle:                  _heading;
//     }

//     // XGimbal {
//     //     id:     gimbal
//     //     anchors.right:      parent.right
//     //     anchors.rightMargin: _margin * 5
//     //     anchors.bottom:     parent.bottom
//     //     anchors.bottomMargin: _margin * 4
//     //     width:                      _margin * 11
//     //     height:                     width
//     // }
}
