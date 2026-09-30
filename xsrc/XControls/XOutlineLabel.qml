import QtQuick 2.12
import QtQuick.Controls 2.12
import QGroundControl.Palette               1.0

import HXControls       1.0

Item {

    property bool mouseEnabled: false

    width:     outline1.implicitWidth
    height:    outline1.implicitHeight

    property alias textBold:    outline1.font.bold
    property alias text:        outline1.text
    property alias color:       content.color
    property color outColor:    "black"
    property alias min:         outline1.min
    property alias small:       outline1.small
    property alias big:         outline1.big
    property alias large:       outline1.large
    property real  line:        1

    HXLabel {
        id:                     outline1
        text:                   "Text"
        font.bold:              true
        anchors.centerIn:       parent
        color:                  outColor
        anchors.horizontalCenterOffset: -line
        anchors.verticalCenterOffset:   -line
    }
    HXLabel {
        id:                     outline2
        text:                   outline1.text
        font.pixelSize:         outline1.font.pixelSize
        font.bold:              true
        anchors.centerIn:       parent
        color:                  outColor
        anchors.horizontalCenterOffset: -line
        anchors.verticalCenterOffset:   line
    }
    HXLabel {
        text:                   outline1.text
        font.pixelSize:         outline1.font.pixelSize
        font.bold:              true
        anchors.centerIn:       parent
        color:                  outColor
        anchors.horizontalCenterOffset: line
        anchors.verticalCenterOffset:   -line
    }
    HXLabel {
        text:                   outline1.text
        font.pixelSize:         outline1.font.pixelSize
        font.bold:              true
        anchors.centerIn:       parent
        color:                  outColor
        anchors.horizontalCenterOffset: line
        anchors.verticalCenterOffset:   line
    }
    // 顶层文本，显示实际内容
    HXLabel {
        id:                     content
        text:                   outline1.text
        font.pixelSize:         outline1.font.pixelSize
        anchors.centerIn:       parent
        font.bold:              true
        color:                  "white"
    }

   signal clicked

   MouseArea {
       anchors.fill: parent
       enabled:    mouseEnabled
       onClicked:  root.clicked()
   }
}
//    //horizontalAlignment: Qt.AlignHCenter
//    verticalAlignment: Qt.AlignVCenter
//    //font.family: ScreenTool.oppoScansName
//    color:              "white"

