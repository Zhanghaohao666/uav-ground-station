import QtQuick 2.15
import QtQuick.Controls  2.15

import ZHSingletonControl   1.0
import ZHControls           1.0
import QGroundControl       1.0
import QGroundControl.Vehicle   1.0

import XUI 1.0

Item {
    id: root
    property Vehicle activeVehicle: ZHGlobalProperty.activeVehicle
    property var _guidedController: globals.guidedControllerFlyView
    property bool   _armed:         activeVehicle ? activeVehicle.armed : false


    property bool flying: false
    property int projectileNums: 0
    property bool hasRed: false
    property int unRead: 0
    property string _flightMode:            _activeVehicle ? _activeVehicle.flightMode : ""
    property bool   _vehicleArmed:          _activeVehicle ? _activeVehicle.armed  : false
    property bool   _fixedWingOnApproach:   _activeVehicle ? _activeVehicle.fixedWing && _vehicleLanding : false
    property bool   _vehicleFlying:         _activeVehicle ? _activeVehicle.flying  : false
    property bool _vehiclePaused :        _activeVehicle ? _flightMode === _activeVehicle.pauseFlightMode : false

    property real _margin:               XScreenTool.base
    property bool _showPause:            _guidedController.showPause
    property bool _showStartMission:     _guidedController.showStartMission
    property real _toolButtonW:         _margin * 4.5
    property var    _planMasterController:      globals.planMasterControllerPlanView

    Connections {
        target: ZHGlobalProperty
        onMessageViewVisibleChanged:{
            unRead = 0
            hasRed = false
        }
    }

    objectName : ZHGlobalZOder.nameFlightControl
    y: XScreenTool.base * 3.5  //3.5
    z: ZHGlobalZOder.currentOrderObject[objectName]

//    anchors.fill: parent
    visible: !ZHGlobalProperty.inAirway

    // spacing: XScreenTool.base * 1.6

//    Column {
//        spacing: XScreenTool.base*2
//        y: XScreenTool.base * 6
//        x: ZHGlobalProperty.videoFull ? -width : XScreenTool.base * 3
//        Behavior on x { PropertyAnimation { duration: 300}}

//         ZHToolButton {
//             width:                      _toolButtonW
//             height:                     width
//             // _imageColor:                "black"
//             imageSource:                _armed ? "qrc:/image/unlock.svg" : (forceArm ?  "qrc:/image/unlock.svg"  : "qrc:/image/armed.svg" )
// //            imageSource:                _armed ? "qrc:/image/armed.svg"  : (forceArm ?  "qrc:/image/unlock.svg"  : "qrc:/image/unlock.svg" )
// //            text:                       _armed ?  qsTr("Disarm") :      (forceArm ?   qsTr("Force Arm") : qsTr("Arm"))

//             property bool forceArm: false
//             hoverEnabled:   true
//             onPressAndHold: forceArm = true
//             onClicked: {
//                 if (_armed) {
//                     mainWindow.disarmVehicleRequest()

//                 } else {
//                     if (forceArm) {
//                         mainWindow.forceArmVehicleRequest()
//                         // _planMasterController.loadFromVehicle()
//                     } else {
//                         mainWindow.armVehicleRequest()
//                         // _planMasterController.loadFromVehicle()
//                     }
//                 }
//                 forceArm = false
//                 mainWindow.hideIndicatorPopup()
//             }
//         }



    Column {
        id:                 colRoot
        anchors.verticalCenter: parent.verticalCenter
        // spacing: _margin * 1.5
        spacing: _margin * 3 //XGlobalProperty.getSpacing(colRoot, root.height)
            /*{
            var count = 0
            for (var i = 0; i < children.length; i++) {
                if (children[i].visible)
                    count++
            }
            // 根据可见数量返回不同间距
            var spa = _margin
            switch(count) {
                case 1:   spa = _margin * 2; break;
                case 2:   spa = _margin * 2; break;
                case 3:   spa = _margin * 1.5; break;
                case 4:   spa = _margin * 1.0; break;
                case 5:   spa = _margin * 0.5; break;
                default:  spa = _margin * 0.3; break;
            }
            return spa;
        }*/
        // //加锁解锁按钮
        // XButtonImageRectangle {
        //     id:                     armButton
        //     width:                  _toolButtonW
        //     height:                  width
        //     // padding:                _margin / 4
        //     anchors.horizontalCenter: parent.horizontalCenter
        //     source:                 _armed ? "qrc:/image/unlock.svg" : (forceArm ? "qrc:/image/unlock.svg" : "qrc:/image/armed.svg")
        //     property bool forceArm: false
        //     property string lastImageSource: ""
        //     hoverEnabled: true
        //     onPressAndHold: forceArm = true
        //     onClicked: {
        //         if (_armed) {
        //             mainWindow.disarmVehicleRequest()
        //         } else {
        //             if (forceArm) {
        //                 mainWindow.forceArmVehicleRequest()
        //             } else {
        //                 mainWindow.armVehicleRequest()
        //             }
        //         }
        //         forceArm = false
        //         //mainWindow.hideIndicatorPopup()
        //     }
        //     onSourceChanged: {
        //         if (imageSource === "qrc:/image/unlock.svg" && lastImageSource === "qrc:/image/armed.svg") {
        //             _planMasterController.loadFromVehicle()
        //         }
        //         lastImageSource = imageSource
        //     }
        //     Component.onCompleted: {
        //         lastImageSource = imageSource
        //     }
        // }

        //根据原型设计，自动模式
        XButtonImageRectangle {
            width:                      _toolButtonW
            height:                     width
            anchors.horizontalCenter: parent.horizontalCenter
            source:                  "qrc:/image/XAuto.svg"
            onClicked: {
               if(_activeVehicle)
               {
                   _guidedController.closeAll()
                   _guidedController.confirmAction(_guidedController.actionAuto)  //开始按钮
               }
            }
        }

        XButtonImageRectangle {
            width:                      _toolButtonW
            height:                     width
            anchors.horizontalCenter: parent.horizontalCenter
            _imageRatio:                0.65
            source:                "/image/StopStrart"
            // _imageColor:                "black"
            onClicked: {
                if(_activeVehicle) {
                    _guidedController.closeAll()
                    _guidedController.confirmAction(_guidedController.actionLoiter)

                }
            }
        }
        //return
        XButtonImageRectangle {
            width:                      _toolButtonW
            height:                     width
            // _imageColor:                "black"
            source:                     "qrc:/image/XBack2"
            _imageRatio:                   0.55
            onClicked: {
                _guidedController.closeAll()
                _guidedController.confirmAction(_guidedController.actionRTL)
            }
        }
    }
}
