import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl 1.0

import XUI 1.0

Item {
    id:              dashbord
    visible:        XGlobalProperty.gimbal

    property real   _margin:            XScreenTool.base
    property real   margin_distance:  _margin/3
    property real   upWidth:            _margin * 4

    Rectangle {
        anchors.fill:               parent
        radius:                     height * 0.5
        border.color:               XGlobalColor.theme
        color:                      "#9f000000"//"transparent"
        Rectangle {   // 中心圆点
            id :        center_point
            anchors.centerIn: parent
            height:     parent.height * 0.22
            width:  height
            radius: height * 0.5
            // border.color:               XGlobalColor.theme
            color: "white"
        }
        XButtonImageRectangle {  // 上
            height: upWidth
            width: height
            _imageChecked:   "#bbffff00"
            _backDefault:   "transparent"
            _backChecked:  "transparent"
            source: "qrc:/image/Left"
            backRect.border.width: 0
            _imageRatio:    1.0
            rotation: 270
            y:  margin_distance
            anchors.horizontalCenter: parent.horizontalCenter
            onPressed:{
                console.log("11")
                gloalHKWS.hkwsMoveUpStart()
            }
            onReleased:{
                console.log("12")
                gloalHKWS.hkwsMoveUpStop()
            }
        }
        XButtonImageRectangle {  // 下
            height: upWidth
            rotation: 90
            width: height
            _imageChecked: "#bbffff00"
            _backDefault:   "transparent"
            _backChecked:  "transparent"
            _imageRatio:    1.0
            backRect.border.width: 0
            source: "qrc:/image/Left"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: margin_distance
            anchors.horizontalCenter: parent.horizontalCenter
            onPressed:{
                console.log("21")
                gloalHKWS.hkwsMoveDownStart()
            }
            onReleased:{
                console.log("21")
                gloalHKWS.hkwsMoveDownStop()
            }
        }
        XButtonImageRectangle {  // 左
            height: upWidth
            width: height
            backRect.border.width: 0
            _imageRatio:    1.0
            _imageChecked: "#bbffff00"
            _backDefault:   "transparent"
            _backChecked:  "transparent"
            source:         "qrc:/image/Left"
            rotation:       180
            anchors.verticalCenter: parent.verticalCenter
            x: margin_distance
            onPressed:{
                console.log("31")
                gloalHKWS.hkwsMoveLeftStart()
            }
            onReleased:{
                console.log("32")
                gloalHKWS.hkwsMoveLeftStop()
            }
        }
        XButtonImageRectangle {  // 右
            height: upWidth
            width: height
            backRect.border.width: 0
            _imageRatio:    1.0
            _imageChecked: "#bbffff00"
            _backDefault:   "transparent"
            _backChecked:  "transparent"
            source: "qrc:/image/Left"
            rotation: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: margin_distance
            onPressed:{
                console.log("41")
                gloalHKWS.hkwsMoveRightStart()
            }
            onReleased:{
                console.log("42")
                gloalHKWS.hkwsMoveRightStop()
            }
        }
    }
}
