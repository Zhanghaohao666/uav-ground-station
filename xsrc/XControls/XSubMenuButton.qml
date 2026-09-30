
import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtGraphicalEffects       1.0

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls       1.0

// Important Note: SubMenuButtons must manage their checked state manually in order to support
// view switch prevention. This means they can't be checkable or autoExclusive.

Button {
    id:             _rootButton
    property bool   setupComplete:  true                                    ///< true: setup complete indicator shows as completed
    property bool   setupIndicator: true                                    ///< true: show setup complete indicator
    property var    imageColor:     "white"//undefined
    property string imageResource:  "/qmlimages/subMenuButtonImage.png"     ///< Button image
    property size   sourceSize:     Qt.size(ScreenTools.defaultFontPixelHeight * 2, ScreenTools.defaultFontPixelHeight * 2)

    property real _width:  ScreenTools.base * 2.5//2.0//2.5
    text:               ""//"Button"  ///< Pass in your own button text
    activeFocusOnPress: true

    implicitHeight: _width + ScreenTools.base * 3//ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3.5 : ScreenTools.defaultFontPixelHeight * 2.5
    implicitWidth:  implicitHeight//__panel.implicitWidth

    onCheckedChanged: checkable = false

    style: ButtonStyle {
        id: buttonStyle

        QGCPalette {
            id:                 qgcPal
            colorGroupEnabled:  control.enabled
        }

        property bool showHighlight: control.pressed | control.checked

        background: Rectangle {
            id:         innerRect
            color:      showHighlight ? qgcPal.hxHigh : "transparent"//qgcPal.windowShade
            radius:     1000
            implicitWidth: titleBar.x + control.text === "" ? 0 : (titleBar.contentWidth + ScreenTools.base/2)// ScreenTools.defaultFontPixelWidth
            border.width:   2
            border.color:   showHighlight ?  "black" : "white"
            QGCColoredImage {
                id:                     image
                anchors.centerIn:       parent
                // anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                // anchors.left:           parent.left
                // anchors.verticalCenter: parent.verticalCenter
                width:                  _width //ScreenTools.defaultFontPixelHeight * 2
                height:                 _width //ScreenTools.defaultFontPixelHeight * 2
                fillMode:               Image.PreserveAspectFit
                mipmap:                 true
                color:                  control.setupComplete ? (showHighlight ? "black" : imageColor ) :  "red"// (control.setupComplete ? qgcPal.button : "red")
                source:                 control.imageResource
                sourceSize:             _rootButton.sourceSize
            }

            HXLabel {
                id:                     titleBar
                anchors.leftMargin:     text === "" ? 0 : ScreenTools.defaultFontPixelWidth
                anchors.left:           image.right
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment:      TextEdit.AlignVCenter
                color:                  showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText
                text:                   control.text
            }
        }

        label: Item {}
    }
}

// import QtQuick 2.3
// import QtQuick.Controls 2.0//2.5
// import QtQuick.Controls.Styles 1.4
// import QtGraphicalEffects 1.0

// import QGroundControl.Palette 1.0
// import QGroundControl.Controls      1.0

// Button {
//     id:     button
//     padding:    0//XScreenTool.base

//     text:   ""
//     property color backC:                   "#cc000000"
//     property color borderC:                 "white"
//     property color imageC:                  "white"         //图标颜色
//     property color labelC:                  imageC          //文字颜色

//     property color backPressC:              "#cc000000"
//     property color backDisenabelC:          "#33000000"
//     property color checkC:                  qgcPal.hxTheme   //GlobalColor.theme

//     property alias source:              image.source
//     property alias  rectBackground:     back
//     property alias  rectRadius:         back.radius
//     property real  rectBordW:          0
//     property real imageScale:          0.7

//     property bool haveImage:            true
//     property bool isMapItem:            false
//     property bool needChecked:          false

//     QGCPalette { id: qgcPal; colorGroupEnabled: true }

//     background: Rectangle   {
//         id:                 back
//         radius:             ScreenTools.base
//         color:              "transparent"
//         anchors.fill:       parent
//         border.color:       borderC
//         border.width:       rectBordW
//     }

//     contentItem: Column {
//         id:                         content
//         anchors.centerIn:           parent
//         spacing:                    button.text === "" ? 0 : ScreenTools.base * 0.4  //text.   Screenbase.Size * 0.6
//         //宽高外部已经传入
//         Rectangle {
//             width:                      button.width
//             height:                     isMapItem ? width*0.8 : width // label.implicitHeight * 1.2 : 0
//             anchors.horizontalCenter:   parent.horizontalCenter
//             color:                      "transparent" //
//             border.color:               button.enabled ? (pressed ?   backPressC:  (checked ?checkC : backC)) : backDisenabelC
//             border.width:               1.3
//             radius:                     height * 0.05
//             QGCColoredImage {
//                 id:                         image
//                 height:                     parent.height * (isMapItem ? 1.0 : imageScale)
//                 width:                      parent.width *  (isMapItem ? 1.0 : imageScale)
//                 sourceSize.height:          height
//                 color:                      isMapItem ? "transparent" : (button.enabled ? (pressed ?   backPressC:  backC) : backDisenabelC)
//                 anchors.centerIn:           parent
//             }
//             Rectangle {
//                 anchors.bottom: parent.bottom
//                 width: parent.width
//                 height: parent.height * 0.25
//                 color:  checkC
//                 radius:  parent.radius * 0.5
//                 visible: checked && needChecked
//                 QGCColoredImage {
//                     width:                      height
//                     height:                     parent.height * 0.8
//                     anchors.centerIn:           parent
//                     color:                      "white"
//                     source:                     "qrc:/image/settings/checkbox-check.svg"
//                 }
//             }
//         }
//         HXLabel {
//             id:                         label
//             text:                       button.text
//             color:                      checked ? checkC : "black"
//             anchors.horizontalCenter:   parent.horizontalCenter
//             small:                      true
//         }
//     }

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
// }
