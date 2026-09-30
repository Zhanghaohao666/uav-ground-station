import QtQuick 2.12
import QtGraphicalEffects   1.0

import QGroundControl.FlightMap     1.0
import QGroundControl.Vehicle       1.0

import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl               1.0

import Controls                    1.0
import UI                          1.0

Item {
    id:             dashbord
    property real   _margin:            ScreenTools.base
    property real   _base:              ScreenTools.base / 21.2
    property real   _dashWidth:         _base * 295//248
    property real   _dashHeight:        _base * 297//259
    property var    _guidedController:  globals.guidedControllerFlyView
    property real   _buttonWidth:        _margin * 5

    //右侧飞行控制
    Item {
        anchors.top:            parent.top
        anchors.topMargin:      GlobalProperty.toolbarHeight + _margin * 2
        anchors.bottom:         dashboard.top
        anchors.bottomMargin:   _margin * 2
        anchors.right:          parent.right
        anchors.rightMargin:    _margin * 2
        width:                  _buttonWidth
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: _margin * 1.0

            //规划界面入口
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/image/Plan"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                     mainWindow.showPlanView()
                }
            }
            //起飞
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/image/Takeoff"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                enabled:                _guidedController.showTakeoff
                visible:        _guidedController.showTakeoff || !_guidedController.showLand
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionTakeoff)
                }
            }
            //降落
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/image/Land"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                enabled:                _guidedController.showLand
                visible:    _guidedController.showLand && !_guidedController.showTakeoff
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionLand)
                }
            }
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/image/RTL"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                enabled:                _guidedController.showRTL
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionRTL)
                }
            }
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/image/Pause"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                visible:    _guidedController.showPause
                enabled:    _guidedController.showPause
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionPause)
                }
            }
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/res/action.svg"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                visible:                _guidedController.showActionList
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionActionList)
                }
            }
            Button_ImageLabel {
                width:                  _buttonWidth
                height:                 width
                source:                 "/res/Gripper.svg"
                padding:                _margin / 4
                anchors.horizontalCenter: parent.horizontalCenter
                visible:    !_isVehicleArmed && _grip_enable
                enabled:    _grip_enable

                property var   activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
                property bool  _initialConnectComplete: activeVehicle ? activeVehicle.initialConnectComplete : false
                property bool  _grip_enable:            _initialConnectComplete ? activeVehicle.hasGripper : false
                property bool  _isVehicleArmed:         _initialConnectComplete ? activeVehicle.armed : false
                onClicked: {
                    _guidedController.closeAll()
                    _guidedController.confirmAction( _guidedController.actionGripper)
                }
            }
        }
    }

    //右下侧值控制
    CHValue {
        anchors.right:          dashboard.right
        anchors.rightMargin:    _dashWidth/2
        anchors.verticalCenter: dashboard.verticalCenter
        height:                 _dashHeight
        width:                  height * 2.2
        color:                  "#c008253d"
    }

    //右下侧仪表面板
    CHDashboard {
        id:                             dashboard
        anchors.bottom:                 parent.bottom
        anchors.bottomMargin:           _margin
        anchors.right:                  rpy.left
        anchors.rightMargin:            _margin
        width:                          _dashWidth
        height:                         _dashHeight
    }

    //右下侧姿态角
    CHRPY {
        id:                             rpy
        anchors.verticalCenter:         dashboard.verticalCenter
        height:                         _dashHeight
        anchors.right:                   parent.right
        anchors.rightMargin:             _margin
    }

    //左侧导引头
    CHDYT {
        id :                         dyt
        anchors.left:               parent.left
        anchors.leftMargin:         _margin
        anchors.top:                parent.top
        anchors.topMargin:          GlobalProperty.toolbarHeight + _margin * 1
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       _margin * 1
 //       width:                      _base * (450 + 400) + _margin//500//700//296
        // height:                 911
    }
}
