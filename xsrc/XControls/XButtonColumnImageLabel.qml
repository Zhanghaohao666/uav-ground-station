import QtQuick 2.3
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import XUI 1.0
//TODO_CCH: 图标加文字的形式，参考SGGC控件
Button {
    id:     button
    padding:    0

    property real _margin :                 XScreenTool.base

    property color backC:                   "#EE000000"
    property color borderC:                 "white"
    property color imageC:                  "white"         //图标颜色
    property color labelC:                  imageC          //文字颜色

    property color backPressC:              "#cc000000"
    property color backDisenabelC:          "#33000000"
    property color checkC:                   XGlobalColor.theme

    property alias source:              image.source
    property alias rtt:                 image.cusrotation
    property alias  rectBackground:     back
    property alias  rectRadius:         back.radius

    property real  rectBordW:          0
    property real imageScale:          0.7

    property bool haveImage:            true
    property bool isMapItem:            false

    implicitWidth:  content.implicitWidth  + _margin * 2 //Math.max(content.implicitWidth, label.implicitWidth) + _margin * 2
    implicitHeight: content.implicitHeight + _margin * 2


    background: Rectangle   {
        id:                 back
        radius:             _margin
        color:              "transparent"
        anchors.fill:       parent
        border.color:       borderC
        border.width:       rectBordW
    }

    contentItem: Column {
        id:                         content
        anchors.centerIn:           parent
        spacing:                    _margin * 0.5
        //宽高外部已经传入
        Rectangle {
            id:                         iconBox
            width:                      image.implicitWidth
            height:                     isMapItem ? width*0.8 : width    // label.implicitHeight * 1.2 : 0
            anchors.horizontalCenter:   parent.horizontalCenter
            color:                      "transparent"
            border.color:               button.enabled ? (pressed ?   backPressC:  (checked ?checkC : backC)) : backDisenabelC
            border.width:               2
            radius:                     height * 0.05
            XColoredImage {
                id:                         image
                height:                     isMapItem ? _margin * 4 : _margin * 4 * imageScale //parent.height * (isMapItem ? 1.0 : imageScale)
                width:                      isMapItem ? _margin * 4 : _margin * 4 * imageScale //parent.width *  (isMapItem ? 1.0 : imageScale)
                sourceSize.height:          height
                color:                      isMapItem ? "transparent" : (button.enabled ? (pressed ?   backPressC:  backC) : backDisenabelC)
                anchors.centerIn:           parent
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * 0.25
                color:  checkC
                radius:  parent.radius * 0.5
                visible: checked
                XColoredImage {
                    width:                      height
                    height:                     parent.height * 0.8
                    anchors.centerIn:           parent
                    sourceSize.height:          height
                    color:                      "white"
                    source:                     "qrc:/image/CheckboxCheck.svg"

                }
            }
        }

        XLabel {
            id:                         label
            text:                       button.text
            color:                      checked ? checkC : "black"
            anchors.horizontalCenter:   parent.horizontalCenter
            small:                      true
        }
    }

//     /*
//                    默认         |     悬浮
//              |  默认  |  按下   |  默认 | 按下
//      背景     |  黑      小麦色  |  白
//      图标     | 主题      黑     |  黑
//      外圈     | 主题      黑     |  黑
//     */
// //    state:                        "Default"
// //    states: [
// //        State {
// //            name:                       "Default"
// //            PropertyChanges {
// //                target: button;
// //                backC:             pressed ?   backPressC:  backC
// //                borderC:            pressed ?   "88ffffff" :  "#88000000"
// //                imageC:            pressed ?   "#bbffff00" : "#aa000000"
// //            }
// //        }
// //    ]
}
