import QtQuick                  2.12
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl               1.0
import QGroundControl.Controls      1.0

import HXUI             1.0
import HXControls       1.0


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

    property real   offset:                 5
    property real   defaultWidth :          row.implicitWidth + offset*2
    property real   maxWidth :              defaultWidth

    property alias  _image:                  leftImage.source
    property alias  contentColor:            leftImage.color
    property alias  labelName:               labelName.text
    property alias  labelValue:              labelValue.text
    property alias  imageSource:             leftImage.source

    //后续添加图片
    Row {
        id:                             row
        anchors.centerIn:               parent
        spacing:                        ScreenTools.base * 0.5

        QGCColoredImage {
            id:                         leftImage
            width:                      columnLabel.height * 0.8
            height:                     width
            color:                      "white"
            anchors.verticalCenter:     columnLabel.verticalCenter
        }

        ///--确定了宽高
        Column {
            id:                         columnLabel
            HXLabel {
                id:                     labelName
                color:                  "white"
                min:                    true
            }
            HXLabel {
                id:                     labelValue
                color:                  "white"
                min:                    true

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
