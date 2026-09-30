/**
 *   @brief QGC Yaw Indicator
 *   @author: chuck_chee@163.com
 */
import QtQuick 2.3
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0

import XUI 1.0

Rectangle {
    border.color:                   Qt.rgba(0,0,0,0)//"black"
    border.width:                   2
    color:                          Qt.rgba(0,0,0,0)//"black"
    radius:                         height/2

    property real _headingAngle
    property real _longDash:        height/2 * 0.7
    property real _shortDash:       _longDash*0.6
    property color _color:          "white"
    property int   _scale:          15 //一个小刻度代表15°
    property real  _sc

    /* 0~8~32~40  15°一个刻度  120/15 = 8  360/15=24
    0~8:  对应的240°~360° ，为了看起来像个循环，左边多120°
    8~32：对应的0~360°
    32~40: 对应的0~120°，为了看起来像个循环，右边多120°
    */
    function getYawValue(inputYaw) {
        var outputYaw = 0
        if(inputYaw >= 32) {
            outputYaw = (inputYaw-32)* _scale
        }
        else if((inputYaw >= 8) && (inputYaw < 32)) {
            outputYaw = (inputYaw-8)* _scale
        }
        else if(inputYaw < 8) {
            outputYaw = (16+inputYaw) * _scale   //  (24-(8-x))*15
        }
        return outputYaw
    }

    //省略了NE、SE、SW、NW四个特殊方位
    function getESWN(yaw) {
        var yawESWN
        if(yaw === 0) {
            yawESWN = "N"
        }else if(yaw === 90) {
            yawESWN = "E"
        }else if(yaw === 180) {
            yawESWN = "S"
        }else if(yaw === 270) {
            yawESWN = "W"
        }else {
            yawESWN = yaw
        }
        return yawESWN
    }

//    Rectangle {
//        width:  parent.width - (radius*2)
//        height: 2
//        color: "black"
//        anchors.top: parent.top
//        anchors.horizontalCenter: parent.horizontalCenter
//    }


    //为了把左右两边的刻度剪掉，另加一个Item
    Item {

        height:                         parent.height
        width:                          parent.width - (radius*2)  //为了把左右两边的刻度剪掉
        anchors.horizontalCenter:       parent.horizontalCenter
        clip: 							true             //开启剪切功能, 最外层剪切，很重要
        Item {
            width : parent.width;
            height: parent.height;
            Row{
                id: _ccYawIndicatorRow;
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: (_scale * 2 -2)                    //每一个刻度的间距，本身宽度为1  间距：实际读数值 = 2:1
                Repeater {
                    id:                                     _ccYawIndicatorRep;
                    model:                                  24+16+1             //对应yaw的360°
                    Rectangle {
                        property int yaw: getYawValue(modelData)

                        width:                              2;
                        height:                             (yaw % (_scale*2)) === 0 ? _longDash : _shortDash
                        color:                              "black"//"#66FFFF"
                        antialiasing:                       true
                        smooth:                             true
                        Rectangle {
                            anchors.fill:                   parent
                            color:                          "white"
                        }
                        XLabelOutline {
                            id:                         innerLabel
                            anchors.horizontalCenter:       parent.horizontalCenter
                            anchors.verticalCenter:         parent.verticalCenter
                            anchors.verticalCenterOffset:   _longDash + 4;
                            anchors.centerIn:           parent
                            text:                       getESWN(yaw) //_yaw3;
                            color:                      "white"//"#66FFFF"//_color
                            min:                        true
                            visible:                   (yaw != 360) && ((yaw % (_scale*2)) === 0)
                        }
                    }
                }
            }

            //刚开始的时候，指针在180°，指向0°的话需要右移180°，对应需要平移多少宽度呢？
            //15°对应15的实际距离  1°对应了1的实际距离
            transform: [ Translate {
                     x:  (-_headingAngle*2 + 180*2 + 1)  //向右平移180
                    }]
        }
    }
    ///固定的黄色箭头，黄色箭头资源自己添加哦，在阿里巴巴矢量图上找的
    XColoredImage {
        height:                     ScreenTools.base * 2.0//2.4
        width:                      height * 1.0    //* 1.5     //2
        source:                     "/image/Triangle.svg"
        fillMode:                   Image.PreserveAspectFit
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.horizontalCenterOffset: 2
        anchors.top:                parent.top
        anchors.topMargin:          -4//-2
        color:                      "yellow"
    }
}
