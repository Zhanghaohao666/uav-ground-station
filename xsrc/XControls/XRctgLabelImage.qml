import QtQuick                  2.12
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.SGControls    1.0
import QGroundControl               1.0
import QGroundControl.Controls      1.0

Rectangle {
    id:         rootRectangle

    radius:                         4
    //外部给定宽高和文字的宽高
    color:      qgcPal.sgButton

    function getWidth() {
//        console.log("SGRectangleLabel: maxWidth:",maxWidth)
//        console.log("defaultWidth:",defaultWidth)

        if(maxWidth >= defaultWidth) {
            return defaultWidth
        }
        else {
//            console.log("bbbbbb")
//            fontPointsize = fontPointsize-1
            return maxWidth
        }
    }

    height:     row.implicitHeight + 4*2
    width:      defaultWidth                // /*getWidth()  //*/label.implicitWidth + 4*2

    property real   maxWidth :            defaultWidth
    property real   defaultWidth :        row.implicitWidth + 4*2

    property real fontPointsize:            QGroundControl.corePlugin.sgPointSize
    property alias _image:                  leftImage.source
    property alias _contentColor:           leftImage.color
    property alias _labelName:              labelName.text
    property alias _labelValue:             labelValue.text

    //后续添加图片
    Row {
        id:                             row
        anchors.centerIn:               parent
        spacing:                        4

        QGCColoredImage {
            id:                         leftImage
            width:                      columnLabel.height * 0.5
            height:                     width
            color:                      "yellow"
            anchors.verticalCenter:     columnLabel.verticalCenter
        }

        ///--确定了宽高
        Column {
            id:                         columnLabel

            SGLabel {
                id:                     labelName
//                font.pointSize:     fontPointsize
                color:              "black"
                font.bold:              isPicked ? true : false
            }
            SGLabel {
                id:                     labelValue
//                font.pointSize:     isPicked ? fontPointsize : fontPointsize - 1
                color:              "black"
                font.bold:          isPicked ? true : false
            }
        }
    }

//    onIsPickedChanged: {
//        if(isPicked)  {
//            an1.running = true
//        }
//        else {
//            an1.running = false
//        }
//    }

//    SequentialAnimation {
//        id:     an1
//        loops:  Animation.Infinite
//        PropertyAnimation {
//            id:         an11
//            target:     rootRectangle
//            property:   "opacity"         //记得加引号
//            from:   1
//            to:     opacityLow + 0.1
//            duration: 800//600//1000//2000//1500
//        }
//        PropertyAnimation {
//            id:         an12
//            target:     rootRectangle
//            property:   "opacity"
//            from:   opacityLow
//            to:     1
//            duration: 800//600//1000//2000//1500
//        }
//    }

}

/* [素材]
//    PropertyAnimation {
//        id:     an
//        target: rootRectangle
//        property:   "opacity"
//        from:   1
//        to:     0.2
//        loops:  Animation.Infinite
//        duration: 2000
//        running: true
//    }
*/
