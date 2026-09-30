import QtQuick                  2.12
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl               1.0
import QGroundControl.Controls      1.0

import XUI 1.0

Rectangle {
    id:             rootRectangle
    radius:         4
    color:          Qt.rgba(0,0,0,0)
    //外部给定宽高和文字的宽高

    function getWidth() {
        if(maxWidth >= defaultWidth) {
            return defaultWidth
        }
        else {
            return maxWidth
        }
    }

    height:     row.implicitHeight + 4*2
    width:      defaultWidth                // /*getWidth()  //*/label.implicitWidth + 4*2

    property real   _margin:                XScreenTool.base
    property real   defaultWidth :          row.implicitWidth + _margin*2
    property real   maxWidth :              defaultWidth

    property alias  _image:                  leftImage.source
    property alias  labelName:               labelName.text
    property alias  labelValue:              labelValue.text
    property alias  imageSource:             leftImage.source

    //后续添加图片
    Row {
        id:                             row
        anchors.centerIn:               parent
        spacing:                        XScreenTool.base * 0.5

        // QGCColoredImage {
        //     id:                         leftImage
        //     width:                      columnLabel.height * 0.8
        //     height:                     width
        //     color:                      "black"
        //     anchors.verticalCenter:     columnLabel.verticalCenter
        //     source:                     "/qmlimages/Gps.svg"
        // }
        Image {
            id:                 leftImage
            width:              columnLabel.height * 0.65
            height:             width
            smooth:             true
            mipmap:             true
            antialiasing:       true
            fillMode:           Image.PreserveAspectFit
            sourceSize.height:  height
            source:             "/qmlimages/Gps.svg"
            anchors.verticalCenter: parent.verticalCenter
        }

        ///--确定了宽高
        Column {
            id:                         columnLabel
            XLabel {
                id:                     labelName
                color:                  "white"
                small:                  true
            }
            XLabel {
                id:                     labelValue
                color:                  "white"
                small:                  true
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
