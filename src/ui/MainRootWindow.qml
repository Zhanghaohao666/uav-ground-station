/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs  1.3
import QtQuick.Layouts  1.11
import QtQuick.Window   2.11

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0

import XUI 1.0
/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? Screen.width  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? Screen.height : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120) {
            mainWindow.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? Screen.width  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? Screen.height : Math.min(150 * Screen.pixelDensity, Screen.height)
        }

        // Start the sequence of first run prompt(s)
        // firstRunPromptManager.nextPrompt()
    }

    QtObject {
        id: firstRunPromptManager

        property var currentDialog:     null
        property var rgPromptIds:       QGroundControl.corePlugin.firstRunPromptsToShow()
        property int nextPromptIdIndex: 0

        function clearNextPromptSignal() {
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() {
            if (nextPromptIdIndex < rgPromptIds.length) {
                var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                currentDialog = component.createObject(mainWindow)
                currentDialog.closed.connect(nextPrompt)
                currentDialog.open()
                nextPromptIdIndex++
            } else {
                currentDialog = null
                showPreFlightChecklistIfNeeded()
            }
        }
    }

    property var                _rgPreventViewSwitch:       [ false ]

    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5
    property string appVersion: XGlobalProperty.version
    property string appDate:    XGlobalProperty.date

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var       activeVehicle:                  QGroundControl.multiVehicleManager.activeVehicle
        readonly property real      defaultTextHeight:              ScreenTools.defaultFontPixelHeight
        readonly property real      defaultTextWidth:               ScreenTools.defaultFontPixelWidth
        readonly property var       planMasterControllerFlyView:    flightView.planController
        readonly property var       guidedControllerFlyView:        flightView.guidedController

        property var                planMasterControllerPlanView:   null
        property var                currentPlanMissionItem:         planMasterControllerPlanView ? planMasterControllerPlanView.missionController.currentPlanViewItem : null

        // Property to manage RemoteID quick acces to settings page
        property bool               commingFromRIDIndicator:        false
    }

    /// Default color palette used throughout the UI
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions

    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest
    signal vtolTransitionToFwdFlightRequest
    signal vtolTransitionToMRFlightRequest
    signal showPreFlightChecklistIfNeeded

    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    /// Prevent view switching
    function pushPreventViewSwitch() {
        _rgPreventViewSwitch.push(true)
    }

    /// Allow view switching
    function popPreventViewSwitch() {
        if (_rgPreventViewSwitch.length == 1) {
            console.warn("mainWindow.popPreventViewSwitch called when nothing pushed")
            return
        }
        _rgPreventViewSwitch.pop()
    }

    /// @return true: View switches are not currently allowed
    function preventViewSwitch() {
        return _rgPreventViewSwitch[_rgPreventViewSwitch.length - 1]
    }

    function viewSwitch(currentToolbar) {
        toolDrawer.visible      = false
        toolDrawer.toolSource   = ""
        flightView.visible      = false
        planView.visible        = false
        toolbar.currentToolbar  = currentToolbar
    }

    function showFlyView() {
        if (!flightView.visible) {
            mainWindow.showPreFlightChecklistIfNeeded()
        }
        viewSwitch(toolbar.flyViewToolbar)
        flightView.visible = true
    }

    function showPlanView() {
        viewSwitch(toolbar.planViewToolbar)
        planView.visible = true
    }

    function showTool(toolTitle, toolSource, toolIcon) {
        toolDrawer.backIcon     = flightView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle    = toolTitle
        toolDrawer.toolSource   = toolSource
        toolDrawer.toolIcon     = toolIcon
        toolDrawer.visible      = true
    }

    function showAnalyzeTool() {
        showTool(qsTr("Analyze Tools"), "AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }

    function showSetupTool() {
        showTool(qsTr("Vehicle Setup"), "SetupView.qml", "/qmlimages/Gears.svg")
    }

    function showSettingsTool() {
        showTool(qsTr("Application Settings"), "AppSettings.qml", "/res/QGCLogoWhite")
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = StandardButton.Ok, acceptFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
        }
    }

    /// Saves main window position and size
    MainWindowSavedState {
        window: mainWindow
    }

    property bool _forceClose: false

    function finishCloseProcess() {
        _forceClose = true
        // For some reason on the Qml side Qt doesn't automatically disconnect a signal when an object is destroyed.
        // So we have to do it ourselves otherwise the signal flows through on app shutdown to an object which no longer exists.
        firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo();
        mainWindow.close()
    }

    // On attempting an application close we check for:
    //  Unsaved missions - then
    //  Pending parameter writes - then
    //  Active connections

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission() {
        if (globals.planMasterControllerPlanView && globals.planMasterControllerPlanView.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              StandardButton.Yes | StandardButton.No,
                              function() { checkForPendingParameterWrites() })
        } else {
            checkForPendingParameterWrites()
        }
    }

    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                    StandardButton.Yes | StandardButton.No,
                    function() { checkForActiveConnections() })
                return
            }
        }
        checkForActiveConnections()
    }

    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                StandardButton.Yes | StandardButton.No,
                function() { finishCloseProcess() })
        } else {
            finishCloseProcess()
        }
    }

    onClosing: {
        if (!_forceClose) {
            close.accepted = false
            checkForUnsavedMission()
        }
    }

    // //-------------------------------------------------------------------------
    // /// Main, full window background (Fly View)
    // background: Item {
    //     id:             rootBackground
    //     anchors.fill:   parent
    // }
    FlyView {
        id:             flightView
        anchors.fill:   parent
        visible:        !XGlobalProperty.isPlanView
    }

    property real toolbarHeight : XScreenTool.toolbarHeight

    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        XGlobalProperty.isPlanView
    }

    ///--新增的顶部工具栏
    XStatusBar {
        id:         toolbar
        height:     toolbarHeight
        width:      parent.width
    }

    // ///--新增多功能设置
    // XSettingView {
    //     id:     settingsView
    //     anchors.fill: parent
    // }

    property real _margin: XScreenTool.base
    ///========================= xShowPopup ===========================
    ///--dir        1: 正中间弹出   2：右边弹出  3: 正下方弹出
    ///--raiseItem:  要弹出的控件
    ///--parentItem: 要弹出的控件的爸爸
    ///--
    //-------------------------------------------------------------------------
    function xShowPopup(raiseItem, parentItem, dir, w) {
        xPopup.raiseItem = raiseItem
        xPopup.dir = dir
        xPopup.parentItem = parentItem
        xPopup.wid = w
        xPopup.open()
    }
    function xClosePopup() {
        xPopup.close()
    }
    Popup {
        id:             xPopup
        modal:          true
        focus:          true
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding:        0                   //很重要
        width:          ssloader.width
        height:         ssloader.height
        property var    raiseItem:          null
        property var    dir:                null
        property var    wid:                 null
        property var    parentItem:         null
        property real   _margins:           XScreenTool.base * 3
        background: Rectangle {
            color:  "#88000000"  //Qt.rgba(0,0,0, 0)             // Qt.rgba(0, 0, 0, 0.1) // 半透明黑色遮罩
            anchors.fill: parent
            radius:  10
        }
        Loader {
            id:             ssloader
            onLoaded: {
                switch(xPopup.dir) {
                case 1:
                    ssloader.opacity = 1.0
                    xPopup.x = (mainWindow.width - ssloader.width) * 0.5
                    xPopup.y = (mainWindow.height - ssloader.height) * 0.5
                    break;
                case 2:
                    ssloader.opacity = 0.9
                    xPopup.x = (mainWindow.width - ssloader.width)
                    xPopup.y = 2
                    break;
                case 3:
                    ssloader.opacity = 0.9
                    var x = mainWindow.contentItem.mapFromItem(xPopup.parentItem, 0, 0).x  /*- ssloader.width*0.5  + xPopup.parentItem.width*0.5 *///向左移动控件一半的宽度*/
                    if((x + xPopup.width) > (mainWindow.width - xPopup._margins)) {
//                        console.log("x", x, "xPopup.width", xPopup.width)
                        x = mainWindow.width - xPopup.width - xPopup._margins
                    }
                    xPopup.x = x
                    var y = mainWindow.contentItem.mapFromItem(xPopup.parentItem, 0, 0).y +  xPopup.parentItem.height + xPopup._margins * 0.5
                    if((y + xPopup.height) > (mainWindow.height - xPopup._margins)) {
                        y = mainWindow.height - xPopup.height - xPopup._margins
                    }
                    xPopup.y = y
                    break;
                default:
                    break;
                }
            }
        }
        onOpened: {
            ssloader.sourceComponent = xPopup.raiseItem
        }
        onClosed: {
            ssloader.sourceComponent = null
            xPopup.raiseItem = null
        }
    }
    ///========================= END ===========================


    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

    function showToolSelectDialog() {
        if (!mainWindow.preventViewSwitch()) {
            toolSelectDialogComponent.createObject(mainWindow).open()
        }
    }

    Component {
        id: toolSelectDialogComponent

        QGCPopupDialog {
            id:         toolSelectDialog
            title:      qsTr("Select Tool")
            buttons:    StandardButton.Close

            property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3.2
            property real _margins:             ScreenTools.defaultFontPixelWidth * 1.4
            property real _buttonRadius:         6
            property real _panelWidth:           Math.max(ScreenTools.defaultFontPixelWidth * 22,
                                                          Math.min(mainWindow.width - (ScreenTools.defaultFontPixelWidth * 8),
                                                                   ScreenTools.defaultFontPixelWidth * 36))

            Item {
                width:          toolSelectDialog._panelWidth
                height:         innerLayout.implicitHeight + (toolSelectDialog._margins * 2)

                ColumnLayout {
                    id:             innerLayout
                    x:              toolSelectDialog._margins
                    y:              toolSelectDialog._margins
                    width:          parent.width - (toolSelectDialog._margins * 2)
                    spacing:        ScreenTools.defaultFontPixelWidth * 0.8

                    Rectangle {
                        id:                 setupButton
                        height:             toolSelectDialog._toolButtonHeight
                        Layout.fillWidth:   true
                        radius:             toolSelectDialog._buttonRadius
                        color:              setupMouseArea.pressed ? XGlobalColor.theme2 :
                                            (setupMouseArea.containsMouse ? XGlobalColor.theme : XGlobalColor.background)
                        border.color:       setupMouseArea.containsMouse ? XGlobalColor.sub : XGlobalColor.line
                        border.width:       1

                        RowLayout {
                            anchors.fill:       parent
                            anchors.margins:    toolSelectDialog._margins * 0.7
                            spacing:            toolSelectDialog._margins

                            QGCColoredImage {
                                Layout.preferredWidth:     ScreenTools.defaultFontPixelHeight * 1.45
                                Layout.preferredHeight:    ScreenTools.defaultFontPixelHeight * 1.45
                                fillMode:                   Image.PreserveAspectFit
                                mipmap:                     true
                                color:                      setupMouseArea.containsMouse ? XGlobalColor.label : XGlobalColor.sub
                                source:                     "/qmlimages/Gears.svg"
                            }

                            QGCLabel {
                                Layout.fillWidth:       true
                                text:                   qsTr("Vehicle Setup")
                                color:                  XGlobalColor.label
                                font.pointSize:         ScreenTools.defaultFontPointSize
                                verticalAlignment:      Text.AlignVCenter
                                elide:                  Text.ElideRight
                            }
                        }

                        QGCMouseArea {
                            id:             setupMouseArea
                            anchors.fill:   parent
                            hoverEnabled:   true
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    toolSelectDialog.close()
                                    mainWindow.showSetupTool()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id:                 analyzeButton
                        height:             toolSelectDialog._toolButtonHeight
                        Layout.fillWidth:   true
                        visible:            QGroundControl.corePlugin.showAdvancedUI
                        radius:             toolSelectDialog._buttonRadius
                        color:              analyzeMouseArea.pressed ? XGlobalColor.theme2 :
                                            (analyzeMouseArea.containsMouse ? XGlobalColor.theme : XGlobalColor.background)
                        border.color:       analyzeMouseArea.containsMouse ? XGlobalColor.sub : XGlobalColor.line
                        border.width:       1

                        RowLayout {
                            anchors.fill:       parent
                            anchors.margins:    toolSelectDialog._margins * 0.7
                            spacing:            toolSelectDialog._margins

                            QGCColoredImage {
                                Layout.preferredWidth:     ScreenTools.defaultFontPixelHeight * 1.45
                                Layout.preferredHeight:    ScreenTools.defaultFontPixelHeight * 1.45
                                fillMode:                   Image.PreserveAspectFit
                                mipmap:                     true
                                color:                      analyzeMouseArea.containsMouse ? XGlobalColor.label : XGlobalColor.sub
                                source:                     "/qmlimages/Analyze.svg"
                            }

                            QGCLabel {
                                Layout.fillWidth:       true
                                text:                   qsTr("Analyze Tools")
                                color:                  XGlobalColor.label
                                font.pointSize:         ScreenTools.defaultFontPointSize
                                verticalAlignment:      Text.AlignVCenter
                                elide:                  Text.ElideRight
                            }
                        }

                        QGCMouseArea {
                            id:             analyzeMouseArea
                            anchors.fill:   parent
                            hoverEnabled:   true
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    toolSelectDialog.close()
                                    mainWindow.showAnalyzeTool()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id:                 settingsButton
                        height:             toolSelectDialog._toolButtonHeight
                        Layout.fillWidth:   true
                        visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
                        radius:             toolSelectDialog._buttonRadius
                        color:              settingsMouseArea.pressed ? XGlobalColor.theme2 :
                                            (settingsMouseArea.containsMouse ? XGlobalColor.theme : XGlobalColor.background)
                        border.color:       settingsMouseArea.containsMouse ? XGlobalColor.sub : XGlobalColor.line
                        border.width:       1

                        RowLayout {
                            anchors.fill:       parent
                            anchors.margins:    toolSelectDialog._margins * 0.7
                            spacing:            toolSelectDialog._margins

                            Rectangle {
                                Layout.preferredWidth:     ScreenTools.defaultFontPixelHeight * 1.45
                                Layout.preferredHeight:    ScreenTools.defaultFontPixelHeight * 1.45
                                radius:                     width / 2
                                color:                      settingsMouseArea.containsMouse ? XGlobalColor.label : XGlobalColor.sub

                                QGCLabel {
                                    anchors.centerIn:   parent
                                    text:               QGroundControl.appName.length > 0 ? QGroundControl.appName[0] : "Q"
                                    color:              settingsMouseArea.containsMouse ? XGlobalColor.theme : XGlobalColor.background
                                    font.bold:          true
                                }
                            }

                            QGCLabel {
                                Layout.fillWidth:       true
                                text:                   qsTr("Application Settings")
                                color:                  XGlobalColor.label
                                font.pointSize:         ScreenTools.defaultFontPointSize
                                verticalAlignment:      Text.AlignVCenter
                                elide:                  Text.ElideRight
                            }
                        }

                        QGCMouseArea {
                            id:             settingsMouseArea
                            anchors.fill:   parent
                            hoverEnabled:   true
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    toolSelectDialog.close()
                                    mainWindow.showSettingsTool()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth:   true
                        height:             1
                        color:              XGlobalColor.line
                    }

                    ColumnLayout {
                        Layout.fillWidth:       true
                        spacing:                0
                        // Layout.alignment:       Qt.AlignHCenter

                        // QGCLabel {
                        //     id:                     versionLabel
                        //     text:                   qsTr("%1 Version").arg(QGroundControl.appName)
                        //     color:                  XGlobalColor.label2
                        //     font.pointSize:         ScreenTools.smallFontPointSize
                        //     wrapMode:               QGCLabel.WordWrap
                        //     Layout.maximumWidth:    parent.width
                        //     Layout.alignment:       Qt.AlignHCenter
                        // }

                        XLabel {
                            id:                     versionLabel1
                            text:                   QGroundControl.appName
                            color:                  XGlobalColor.label2
                            wrapMode:               QGCLabel.WordWrap
                            Layout.maximumWidth:    parent.width
                            // Layout.alignment:       Qt.AlignHCenter
                            min:        true
                        }
                        XLabel {
                           id:               versionLabel2
                           text:            qsTr("Version ") + appVersion
                           // Layout.alignment:       Qt.AlignHCenter
                           color:                  XGlobalColor.label2
                           min:        true

                        }
                        XLabel {
                           text:            qsTr("Date ") + appDate
                           // Layout.alignment:       Qt.AlignHCenter
                           color:                  XGlobalColor.label2
                           min:        true
                        }


                        // QGCLabel {
                        //     text:                   QGroundControl.qgcVersion
                        //     color:                  XGlobalColor.label2
                        //     font.pointSize:         ScreenTools.smallFontPointSize
                        //     wrapMode:               QGCLabel.WrapAnywhere
                        //     Layout.maximumWidth:    parent.width
                        //     Layout.alignment:       Qt.AlignHCenter

                        //     QGCMouseArea {
                        //         id:                 easterEggMouseArea
                        //         anchors.topMargin:  -versionLabel.height
                        //         anchors.fill:       parent

                        //         onClicked: {
                        //             if (mouse.modifiers & Qt.ControlModifier) {
                        //                 QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                        //                 showTouchAreasNotification.open()
                        //             } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                        //                 if(!QGroundControl.corePlugin.showAdvancedUI) {
                        //                     advancedModeOnConfirmation.open()
                        //                 } else {
                        //                     advancedModeOffConfirmation.open()
                        //                 }
                        //             }
                        //         }

                        //         // This allows you to change this on mobile
                        //         onPressAndHold: {
                        //             QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                        //             showTouchAreasNotification.open()
                        //         }

                        //         MessageDialog {
                        //             id:                 showTouchAreasNotification
                        //             title:              qsTr("Debug Touch Areas")
                        //             text:               qsTr("Touch Area display toggled")
                        //             standardButtons:    StandardButton.Ok
                        //         }

                        //         MessageDialog {
                        //             id:                 advancedModeOnConfirmation
                        //             title:              qsTr("Advanced Mode")
                        //             text:               QGroundControl.corePlugin.showAdvancedUIMessage
                        //             standardButtons:    StandardButton.Yes | StandardButton.No
                        //             onYes: {
                        //                 QGroundControl.corePlugin.showAdvancedUI = true
                        //                 advancedModeOnConfirmation.close()
                        //             }
                        //         }

                        //         MessageDialog {
                        //             id:                 advancedModeOffConfirmation
                        //             title:              qsTr("Advanced Mode")
                        //             text:               qsTr("Turn off Advanced Mode?")
                        //             standardButtons:    StandardButton.Yes | StandardButton.No
                        //             onYes: {
                        //                 QGroundControl.corePlugin.showAdvancedUI = false
                        //                 advancedModeOffConfirmation.close()
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
        }
    }


    // FlyView {
    //     id:             flightView
    //     anchors.fill:   parent
    // }

    // PlanView {
    //     id:             planView
    //     anchors.fill:   parent
    //     visible:        false
    // }

    Drawer {
        id:             toolDrawer
        width:          mainWindow.width
        height:         mainWindow.height
        edge:           Qt.LeftEdge
        dragMargin:     0
        closePolicy:    Drawer.NoAutoClose
        interactive:    false
        visible:        false

        property alias backIcon:    backIcon.source
        property alias toolTitle:   toolbarDrawerText.text
        property alias toolSource:  toolDrawerLoader.source
        property alias toolIcon:    toolIcon.source

        // Unload the loader only after closed, otherwise we will see a "blank" loader in the meantime
        onClosed: {
            toolDrawer.toolSource = ""
        }
        
        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:          qgcPal.toolbarBackground

            RowLayout {
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCColoredImage {
                    id:                     backIcon
                    width:                  ScreenTools.defaultFontPixelHeight * 2
                    height:                 ScreenTools.defaultFontPixelHeight * 2
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    color:                  qgcPal.text
                }

                QGCLabel {
                    id:     backTextLabel
                    text:   qsTr("Back")
                }

                QGCLabel {
                    font.pointSize: ScreenTools.largeFontPointSize
                    text:           "<"
                }

                QGCColoredImage {
                    id:                     toolIcon
                    width:                  ScreenTools.defaultFontPixelHeight * 2
                    height:                 ScreenTools.defaultFontPixelHeight * 2
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    color:                  qgcPal.text
                }

                QGCLabel {
                    id:             toolbarDrawerText
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            QGCMouseArea {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                x:                  parent.mapFromItem(backIcon, backIcon.x, backIcon.y).x
                width:              (backTextLabel.x + backTextLabel.width) - backIcon.x
                onClicked: {
                    toolDrawer.visible      = false
                }
            }
        }

        Loader {
            id:             toolDrawerLoader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target:                 toolDrawerLoader.item
                ignoreUnknownSignals:   true
                onPopout:               toolDrawer.visible = false
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    function showCriticalVehicleMessage(message) {
        indicatorPopup.close()
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            // We received additional wanring message while an older warning message was still displayed.
            // When the user close the older one drop the message indicator tool so they can see the rest of them.
            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = true
        } else {
            criticalVehicleMessagePopup.criticalVehicleMessage      = message
            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false
            criticalVehicleMessagePopup.open()
        }
    }

    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.55
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true
        closePolicy:        Popup.CloseOnEscape

        property alias  criticalVehicleMessage:        criticalVehicleMessageText.text
        property bool   dropMessageIndicatorOnClose:   false

        background: Rectangle {
            anchors.fill:   parent
            color:          qgcPal.alertBackground
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            border.color:   qgcPal.alertBorder
            border.width:   2

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.top:                parent.top
                anchors.topMargin:          -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      vehicleWarningLabel.contentWidth + _margins
                height:                     vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 vehicleWarningLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Vehicle Error")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }

            Rectangle {
                id:                         additionalErrorsIndicator
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.bottom:             parent.bottom
                anchors.bottomMargin:       -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      additionalErrorsLabel.contentWidth + _margins
                height:                     additionalErrorsLabel.contentHeight + _margins
                visible:                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 additionalErrorsLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Additional errors received")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }
        }

        QGCLabel {
            id:                 criticalVehicleMessageText
            width:              criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn:   parent
            wrapMode:           Text.WordWrap
            color:              qgcPal.alertText
            textFormat:         TextEdit.RichText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.dropMessageIndicatorOnClose) {
                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false;
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                    toolbar.dropMessageIndicatorTool();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Popups

    function showIndicatorPopup(item, dropItem, dim = true) {
        indicatorPopup.currentIndicator = dropItem
        indicatorPopup.currentItem = item
        indicatorPopup.dim = dim
        indicatorPopup.open()
    }

    function hideIndicatorPopup() {
        indicatorPopup.close()
        indicatorPopup.currentItem = null
        indicatorPopup.currentIndicator = null
    }

    Popup {
        id:             indicatorPopup
        padding:        ScreenTools.defaultFontPixelWidth * 0.75
        modal:          true
        focus:          true
        dim:            false
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property var    currentItem:        null
        property var    currentIndicator:   null
        background: Rectangle {
            width:  loader.width
            height: loader.height
            color:  Qt.rgba(0,0,0,0)
        }
        Loader {
            id:             loader
            onLoaded: {
                var centerX = mainWindow.contentItem.mapFromItem(indicatorPopup.currentItem, 0, 0).x - (loader.width * 0.5)
                if((centerX + indicatorPopup.width) > (mainWindow.width - ScreenTools.defaultFontPixelWidth)) {
                    centerX = mainWindow.width - indicatorPopup.width - ScreenTools.defaultFontPixelWidth
                }
                indicatorPopup.x = centerX
            }
        }
        onOpened: {
            loader.sourceComponent = indicatorPopup.currentIndicator
        }
        onClosed: {
            loader.sourceComponent = null
            indicatorPopup.currentIndicator = null
        }
    }

    // We have to create the popup windows for the Analyze pages here so that the creation context is rooted
    // to mainWindow. Otherwise if they are rooted to the AnalyzeView itself they will die when the analyze viewSwitch
    // closes.

    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title
        windowedPage.source = source
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:      ScreenTools.defaultFontPixelWidth  * 100
            height:     ScreenTools.defaultFontPixelHeight * 40
            visible:    true

            property alias source: loader.source

            Rectangle {
                color:          QGroundControl.globalPalette.window
                anchors.fill:   parent

                Loader {
                    id:             loader
                    anchors.fill:   parent
                    onLoaded:       item.popped = true
                }
            }

            onClosing: {
                visible = false
                source = ""
            }
        }
    }
}
