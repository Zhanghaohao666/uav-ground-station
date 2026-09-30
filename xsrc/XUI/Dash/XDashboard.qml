import QtQuick 2.12
import QtGraphicalEffects   1.0

import QGroundControl.FlightMap     1.0
import QGroundControl.Vehicle       1.0

//import QtQuick 2.3
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl               1.0

import XUI 1.0

Item {
    id:             dashbord
    property var    _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property real _rollAngle:   _activeVehicle ? _activeVehicle.roll.rawValue  : 0
    property real _pitchAngle:  _activeVehicle ? _activeVehicle.pitch.rawValue : 0
    property real _speed:       _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real _altitude:    _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real _vehicleID:   _activeVehicle ? _activeVehicle.id : 0
    ///--YAW刻度修改1:
    property real _heading:         _activeVehicle ? _activeVehicle.heading.rawValue : 0
    property color _themeColor:     "#01F2B0"

    ///---外部传输
    ///---内部使用
    readonly property color _textColor:         "#ffffff"//"#66FFFF"
    readonly property color _bgColor:           "#88ffffff"//qgcPal.hxBack //"black"

    property real   _base:                      XScreenTool.base /21.2
    readonly property real   _rectScl:          XScreenTool.base * 1.0

    Image {
        id:                             sgOverallImage
        width:                          parent.width
        height:                         parent.height
        sourceSize.width:               width
        source:                         "/image/xdash"
        mipmap:                         true
        fillMode:                       Image.PreserveAspectFit //必须有
        antialiasing:                   true
    }

    ///-- Artificial Horizon
    ///地平仪，蓝色天空和灰色地面,会偏移和旋转
    Rectangle {
        id:                             ccRect
        anchors.centerIn:               parent
        height:                         200 * _base * _sc  //165 170 180
        width:                          200 * _base * _sc
        radius:                         width/2
        color:                          "#88000000"
        visible:                        false
        XArtificialHorizon {
            rollAngle:          _rollAngle
            pitchAngle:         _pitchAngle
            anchors.fill:       parent
        }
    }
    //为了画这个圆
    Rectangle {
        id:                 mask
        anchors.fill:       ccRect
        radius:             width / 2
        visible:            false
    }
    OpacityMask {
        anchors.fill:       ccRect
        source:             ccRect
        maskSource:         mask
    }
    //-----------END---------///


    XColoredImage {
        id:                 headingImage
        anchors.centerIn:   pitchWidget
        source:             "/qmlimages/adsbVehicle.svg" //"/image/YellowIndicate.png"
        width:              _base * 40 //178 //220 200
        height:             width
        color:              XGlobalColor.sub
        transform: Rotation {
            origin.x:       headingImage.width / 2
            origin.y:       headingImage.height / 2 //+ _base * 4
            angle:         _heading//-_rollAngle
        }
    }

    // ///Roll的黄色箭头
    // XColoredImage {
    //     source:                     "/image/Triangle.svg"
    //     anchors.top:                pointer.top
    //     height:                     _margin * 1.5 *_base
    //     width:                      height
    //     fillMode:                   Image.PreserveAspectFit
    //     anchors.horizontalCenter:   parent.horizontalCenter
    //     anchors.topMargin:          0//-2
    //     color:                      "#ddffff00"
    // }

        ///------------------------START---------------------------
        ///-- Pitch
        //核心数字卡尺等，这个是核心
        QGCPitchIndicator {
            id:                 pitchWidget
            size:               ccRect.height * 0.7//0.55
            anchors.horizontalCenter:   ccRect.horizontalCenter
            anchors.verticalCenter:     ccRect.verticalCenter
            pitchAngle:         _pitchAngle
            rollAngle:          _rollAngle
            color:              Qt.rgba(0,0,0,0)
        }
        ///-----------END---------///


        ///------------------------START---------------------------//
        ///-- Artificial Horizon
        //固定的黄色指示，需放最后，高亮醒目
        // Image {
        //     id:                 crossHair
        //     anchors.centerIn:   pitchWidget
        //     source:             "/image/Center.png" //"/image/YellowIndicate.png"
        //     mipmap:             true
        //     // width:              parent.width
        //     // sourceSize.width:   parent.width
        //     fillMode:           Image.PreserveAspectFit
        //     width:              pitchWidget.width * 0.7
        // }
        //-----------END---------///

        ///------------------------START---------------------------//
        ///-- Irregular Bar 不规则进度条 高度和相对速度
        // HXIrregularBar {
        //     anchors.horizontalCenter: parent.horizontalCenter
        //     anchors.verticalCenter:   parent.verticalCenter
        //     anchors.verticalCenterOffset:  65 * _base * _sc//70//50//100    //向下为正
        //     _sc:                    dashbord._sc
        //     speedValue:             _speed
        //     altitudeValue:          _altitude
        // }
        //-----------END---------///

        ///------------------------START---------------------------//
        ///-- Yaw scale
        // HXYawIndicator {
        //     id:                             yawWidget
        //     anchors.horizontalCenter:       parent.horizontalCenter
        //     anchors.bottom:                 parent.bottom
        //     anchors.bottomMargin:           -ScreenTools.base * 0.5
        //     // anchors.bottomMargin:           0 + 1.0 * _sc
        //     color:                          Qt.rgba(0,0,0,0)
        //     width:                          parent.width * 0.55//0.8//0.7
        //     height:                         45 * _base * dashbord._sc   //25 20
        //     _sc:                            dashbord._sc
        //     _headingAngle:                  _heading;
        // }
        //----------------------------------------------------
        //-- YAW数值显示
        // HXOutlineLabel {
        //     anchors {
        //         horizontalCenter:       parent.horizontalCenter;
        //         bottom:                 yawWidget.top;
        //         bottomMargin:           -2//1//5
        //     }
        //     text:                    _headingString3
        //     property string _headingString:  _activeVehicle ? _heading.toFixed(0) : "N/A"
        //     property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
        //     property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
        // }

        ///------------------------START---------------------------//
        ///-- PITCH数值显示
        // HXOutlineLabel {
        //     id:                         pitchText
        //     anchors {
        //         verticalCenter:           parent.verticalCenter;
        //         verticalCenterOffset:     -10//-10  向上向左为负
        //         horizontalCenter:         parent.horizontalCenter;
        //         //start_cch_20210705 seze
        //         // horizontalCenterOffset:   -parent.width * 140/765    //127 125 130 90 120
        //         horizontalCenterOffset:   -parent.width * 150 * _base/_maxWidth    //127 125 130 90 120
        //     }
        //     text:               qsTr("P:") + (_activeVehicle ? _pitchAngle.toFixed(0) : "N/A")

        // }

        // HXOutlineLabel {
        //     text:  "R:" + (_activeVehicle ? _rollAngle.toFixed(0) : "N/A")
        //     anchors {
        //         verticalCenter:           parent.verticalCenter;
        //         verticalCenterOffset:     pitchText.anchors.verticalCenterOffset
        //         horizontalCenter:         parent.horizontalCenter;
        //         horizontalCenterOffset:   - pitchText.anchors.horizontalCenterOffset
        //     }
        // }

        ///------------------------START---------------------------//
        ///-- SPEED数值显示
        // HXOutlineLabel {
        //     id:                         speedRect
        //     text:  "HS:" + _speed.toFixed(1) + "m/s"
        //     anchors {
        //         verticalCenter:         parent.verticalCenter
        //         verticalCenterOffset:   20 * _base// 10 5 | 28  //30//0//5
        //         right:                  parent.right
        //         rightMargin:            20 * _base  //30
        //     }
        // }

        ///------------------------START---------------------------//
        ///-- heightText 数值显示
        // HXOutlineLabel {
        //     text:   "H:" + _altitude.toFixed(1) + "m"
        //     anchors {
        //         verticalCenter:         parent.verticalCenter
        //         verticalCenterOffset:   speedRect.anchors.verticalCenterOffset//30//0//5
        //         left:                   parent.left
        //         leftMargin:             speedRect.anchors.rightMargin
        //     }
        //     rotation:                   -speedRect.rotation
        // }
    // }
}
