/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Attitude Instrument
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.FlightMap     1.0

import QGroundControl.Vehicle       1.0

Item {
    id: root

    property bool showPitch:    true
    property var  vehicle:      null
    property real size
    property real ccAHSize;

    property real _rollAngle:   vehicle ? vehicle.roll.rawValue  : 0
    property real _pitchAngle:  vehicle ? vehicle.pitch.rawValue : 0

    width:  size
    height: size

//    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             instrument
        anchors.fill:   parent
//        visible:        false
//        radius:     width/2;

        //----------------------------------------------------
        //-- Artificial Horizon
        //地平仪，蓝色天空和灰色地面,会偏移和旋转
        Rectangle {
            id: ccRect
            anchors.horizontalCenter: parent.horizontalCenter;
            anchors.verticalCenter:   parent.verticalCenter;
            height:     ccAHSize;
            width:      ccAHSize;
            radius:     width/2;
            visible:    false

            PIEArtificialHorizon {
                rollAngle:          _rollAngle
                pitchAngle:         _pitchAngle
                anchors.fill:       parent
            }
        }
        //start_cch_xx_20200427 为了画这个圆，只得用介个呢
        Rectangle {
            id:             mask
            anchors.fill:   ccRect
            radius:         width / 2
            visible:        false
        }
        OpacityMask {
            anchors.fill: ccRect
            source: ccRect
            maskSource: mask
        }
        //end_cch

        //----------------------------------------------------
        //-- Pointer
        //黄色固定的指针
        Image {
            id:                 pointer
            source:             _outdoorPalette ? "/qmlimages/LightRollPointer.svg" : "/qmlimages/ccYellowPointer.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
//            anchors.top:        parent.top
            sourceSize.height:  parent.height
        }
        //----------------------------------------------------
        //-- Instrument Dial
        //白色会偏移的ROLL指示
        Image {
            id:                 instrumentDial
            source:             _outdoorPalette ? "/qmlimages/LightCircularScale.svg" : "/qmlimages/ccCircularScale.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            transform: Rotation {
                origin.x:       root.width  / 2
                origin.y:       root.height / 2
                angle:          -_rollAngle
            }
        }
        //----------------------------------------------------
        //-- Pitch
        //核心数字卡尺等，这个是核心
        QGCPitchIndicator {
            id:                 pitchWidget
            visible:            root.showPitch
            size:               root.size * 0.5
            anchors.verticalCenter: parent.verticalCenter
            pitchAngle:         _pitchAngle
            rollAngle:          _rollAngle
            color:              Qt.rgba(0,0,0,0)
            _color:             _outdoorPalette ?  "black" : "white"
        }
        //----------------------------------------------------
        //-- Cross Hair
        //水平面
        Image {
            id:                 crossHair
            anchors.centerIn:   parent
            source:              _outdoorPalette ? "/qmlimages/LightHorizonLine.svg" :"/qmlimages/ccHorizonLine.svg"
            mipmap:             true
            width:              size
            sourceSize.width:   width
            fillMode:           Image.PreserveAspectFit
        }
    }

//    Rectangle {
//        id:             mask
//        anchors.fill:   instrument
//        radius:         width / 2
////        radius:         width ////start_cch_xx_20200417

//        color:          "black"
//        visible:        false
//    }

//    OpacityMask {
//        anchors.fill: instrument
//        source: instrument
//        maskSource: mask
//    }

}
