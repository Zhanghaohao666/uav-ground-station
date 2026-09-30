import QtQuick 2.12
import QtGraphicalEffects   1.0

import QGroundControl.FlightMap     1.0
import QGroundControl.Vehicle       1.0

Item {

    property real _sc

    property int speedIndex: 0   //lightblue
    property int heightIndex: 0  //lightblue

    property real speedValue:       0
    property real altitudeValue:    0
    property real speedMax:         30
    property real heightMax:        350

    property real paraWidth:        18 * _sc  //16
    property real paraheight:       16        //14
    property color paraColorNull:  "#021119"
    property color paraColorFill:  "#01F2B0"//"white"//"#02190e"
    property real  horCenterOffset:   _base * _sc * 268//255 //250//236
    property real _num: 11//15

    onSpeedValueChanged: {
        speedIndex = _num * speedValue.toFixed(2) / speedMax
        for(var i=0; i<_num; i++) {
            if (speed.children[i].toString().startsWith("HXParallelogram")) {
                if(i<speedIndex) {
                    speed.children[i].color = paraColorFill
                }
                else {
                    speed.children[i].color = paraColorNull
                }
            }
        }
    }

    onAltitudeValueChanged: {
        heightIndex = _num * altitudeValue / heightMax
        for(var i=0; i<_num; i++) {
            if (height.children[i].toString().startsWith("HXParallelogram")) {
                if(i<heightIndex) {
                    height.children[i].color = paraColorFill
                }
                else {
                    height.children[i].color = paraColorNull
                }
            }
        }
    }

    onHeightIndexChanged: {
//        for(var i=0; i<15; i++) {
//            if (height.children[i].toString().startsWith("HXParallelogram")) {
//                if(i<heightIndex) {
//                    height.children[i].color = paraColorFill
//                }
//                else {
//                    height.children[i].color = paraColorNull
//                }
//            }
//        }
    }

    //右边
    Row {
        id:  speed
        anchors.horizontalCenter:        parent.horizontalCenter
        anchors.horizontalCenterOffset:  horCenterOffset//113.5
        anchors.verticalCenter:          parent.verticalCenter

//        y: 104.5
        spacing: 2 * _sc

        Repeater {
            id: speedRep
            model: _num
            HXParallelogram {
                xs: index==14 ? -0.3: -0.6
                ys: 0.01
                radius: 1
                width: paraWidth
                color:    paraColorNull
                height: 7 + (paraheight-7) * (_num-index) / _num
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -index
            }
        }
    }


    //左边：高度
    Row {
        id:                         height
        layoutDirection :         Qt.RightToLeft
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset:  -horCenterOffset/*-paraWidth*0.3*/
        anchors.verticalCenter:          parent.verticalCenter

        spacing: 2 * _sc

        Repeater {
            id: heightRep
            model: _num
            HXParallelogram {
                xs: index==14 ? 0.3 :0.6
                ys: 0.01
                radius: 1
                width: paraWidth
                color:    paraColorNull
                height: 7 + (paraheight-7) * (_num-index) / _num
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -index
                }
        }
    }

//    Text {
//        id: heightText
//        anchors.bottom:             height.top
//        anchors.bottomMargin:       20//25//50
//        anchors.right:               parent.right
//        anchors.rightMargin:         300-45
//        text: "高度: " + altitudeValue.toFixed(2) + " m"
//        font.pointSize:             13
//        font.bold:                  true
//        color:                      paraColorFill
//        rotation:                   -7//-15
//    }
}
