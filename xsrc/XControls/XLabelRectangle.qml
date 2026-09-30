import QtQuick                  2.12
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl               1.0

import HXControls       1.0

Rectangle {

    id:         rootRectangle

    property bool isPicked:         false
    property string  _enbleText:      "已上电"
    property string  _disableText:     _enbleText
    property bool       _enble:           false

    property real opacityLow: 0.7

    radius:             2
    border.color:       'black'
    border.width:       0
    //外部给定宽高和文字的宽高
    color:      isPicked ? qgcPal.hxTheme: "#F5F5DC"
    opacity:    isPicked ? 1.0 : opacityLow


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

    height:     label.implicitHeight + 4*2
    width:      getWidth()  //label.implicitWidth + 4*2

    property real   maxWidth :            defaultWidth
    property real   defaultWidth :        label.implicitWidth + 4*2

    //后续添加图片

    HXLabel {
        id:                 label
        anchors.centerIn:   parent
        text:               isPicked ? _enbleText : _disableText
        color:              "black"
    }

    onIsPickedChanged: {
        if(isPicked)  {
            an1.running = true
//            an1.start()
        }
        else {
            an1.running = false
//            an1.stop()
        }
    }

    SequentialAnimation {
        id:     an1
        loops:  Animation.Infinite
        PropertyAnimation {
            id:         an11
            target:     rootRectangle
            property:   "opacity"         //记得加引号
            from:   1
            to:     opacityLow + 0.1
            duration: 800//600//1000//2000//1500
        }
        PropertyAnimation {
            id:         an12
            target:     rootRectangle
            property:   "opacity"
            from:   opacityLow
            to:     1
            duration: 800//600//1000//2000//1500
        }
    }
}



