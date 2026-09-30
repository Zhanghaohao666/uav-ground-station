

import QtQuick 2.3
import QtQuick.Controls 2.0//2.5
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import QGroundControl.Palette 1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools           1.0

import HXHControls 1.0

Button {
    id:     button
    padding:    ScreenTools.base * 1.0

    text:   ""
    property color backC:                   "#ccffffff"//"#cc000000"
    property color borderC:                 "white"
    property color imageC:                  "white"         //图标颜色
    property color labelC:                  imageC          //文字颜色

    property color backPressC:              GlobalColor.sub //qgcPal.hxHigh//qgcPal.hxTheme//"#cc000000"
    property color backDisenabelC:          "#33000000"
    property color checkC:                  GlobalColor.sub //qgcPal.hxTheme   //GlobalColor.theme

    property alias source:              image.source
    property alias  rectBackground:     back
    property alias  rectRadius:         back.radius
    property real  rectBordW:          1.5
    property real imageScale:          0.66

    property bool haveImage:            true
    property bool isMapItem:            false
    property bool needChecked:          false


    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    background: Rectangle   {
        id:                 back
        radius:             ScreenTools.base
        color:              "transparent"
        anchors.fill:       parent
        border.color:       button.enabled ? (pressed | checked ?   backPressC:  backC) : backDisenabelC
        border.width:       rectBordW
    }

    contentItem: Row {
        id:                         content
        anchors.centerIn:           parent
        spacing:                    button.text === "" ? 0 : ScreenTools.base * 0.2  //text.   Screenbase.Size * 0.6
        //宽高外部已经传入
        Rectangle {
            height:                     button.height * 0.7
            width:                      isMapItem ? height*0.8 : height  // label.implicitHeight * 1.2 : 0
            anchors.verticalCenter:     parent.verticalCenter
            color:                      "transparent" //
            border.color:               borderC   //button.enabled ? (pressed | checked ?   backPressC:  backC) : backDisenabelC
            border.width:               0//1.0
            radius:                     2
            QGCColoredImage {
                id:                         image
                height:                     parent.height * (isMapItem ? 1.0 : imageScale)
                width:                      parent.width *  (isMapItem ? 1.0 : imageScale)
                sourceSize.height:          height
                color:                      isMapItem ? "transparent" : (button.enabled ? (pressed | checked?   backPressC:  backC) : backDisenabelC)
                anchors.centerIn:           parent
            }
            // Rectangle {
            //     anchors.bottom: parent.bottom
            //     width: parent.width
            //     height: parent.height * 0.25
            //     color:  checkC
            //     radius:  parent.radius * 0.5
            //     visible: checked && needChecked
            //     QGCColoredImage {
            //         width:                      height
            //         height:                     parent.height * 0.8
            //         anchors.centerIn:           parent
            //         color:                      "white"
            //         source:                     "qrc:/image/settings/checkbox-check.svg"
            //     }
            // }
        }
        HXHLabel {
            id:                         label
            text:                       button.text
            color:                      checked ? checkC : "white"
            anchors.verticalCenter:     parent.verticalCenter
        }
    }

    /*
                   默认         |     悬浮
             |  默认  |  按下   |  默认 | 按下
     背景     |  黑      小麦色  |  白
     图标     | 主题      黑     |  黑
     外圈     | 主题      黑     |  黑
    */
//    state:                        "Default"
//    states: [
//        State {
//            name:                       "Default"
//            PropertyChanges {
//                target: button;
//                backC:             pressed ?   backPressC:  backC
//                borderC:            pressed ?   "88ffffff" :  "#88000000"
//                imageC:            pressed ?   "#bbffff00" : "#aa000000"
//            }
//        }
//    ]
}
