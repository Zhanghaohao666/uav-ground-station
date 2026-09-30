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
 *   @brief QGC Artificial Horizon
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick 2.3

Item {
    id: root
    property real rollAngle :   0
    property real pitchAngle:   0
    clip:           true
    anchors.fill:   parent
    property real angularScale: pitchAngle * root.height / 45

    Item {
        id: artificialHorizon
        width:  root.width  * 4
        height: root.height * 8
        anchors.centerIn: parent
        //sky
        Rectangle {
            id: sky
            anchors.fill: parent
            smooth: true
            // antialiasing: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0;
                    color:    XGlobalColor.theme//"#e79635"//"#55fffc99"//"#66f89e37"//"#88f89e37"//"#002321"

                }
                GradientStop {
                    position: 0.1;
                    //最新：
                    color:   XGlobalColor.theme//"#e79635"//"#88f89e37"//"#bbf89e37"//"#002321"
                }
            }
        }

        //ground
        Rectangle {
            id: ground
            height: sky.height / 2
            anchors {
                left:   sky.left;
                right:  sky.right;
                // bottom: mid.bottom
            }
            smooth: true
            gradient: Gradient {
                GradientStop {
                    position: 0.4;
                    //最新:
                    color:  "#ee141714"//"#442ea6ff"//"#002321" //"#ee00CBFF" //bb 88//"#66002321"   //AA00CBFF  //"#FF00fffa"
                }
                GradientStop {
                    position: 0.5;
                    //最新：                                     //CC40E0D0
                    color:  "#ee141714"//"#442ea6ff"//"#005E71" //"#ff88CBFF" //"#88005E71"
                }
            }
        }

        //蓝绿面板的旋转， transform
        transform: [
            Translate {
                y:  angularScale  //start_cch_xx_20200417 Y轴方向的偏移量
            },
            Rotation {
                origin.x: artificialHorizon.width  / 2
                origin.y: artificialHorizon.height / 2
                angle:    -rollAngle
            }]
    }

    Rectangle {
        id:     mid
        color: "black"
        height : 2
        width: parent.width
        y:     root.height/2 - 0.5
    }
}
