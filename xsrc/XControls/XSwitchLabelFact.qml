import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QGroundControl.FactSystem 1.0

import XUI 1.0

Item {
    id: root

    property string     icon: ""
    property alias      desc: text.text
    property alias      checked:    switchBox.checked
    property bool       _iconExist: icon != ""
    property bool       lineVisible: true
    property Fact       fact: null
    property real       _margin:  XScreenTool.base

    signal clicked

    implicitHeight: _margin * 8
    implicitWidth:  _margin * 30

    Connections {
        target: fact
        ignoreUnknownSignals: true
        onRawValueChanged:{
            switchBox.checked = fact.value
        }
    }

    Image {
        id:     iconImage
        height: parent.height * 0.5
        width:  _iconExist ? height : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: _iconExist ? _margin * 5 : 0
        source: icon
    }

    XLabel {
        id:         text
        font.bold:  true
        anchors.left: parent.left
        anchors.leftMargin:    _margin//_iconExist ?  parent.width * 0.1 : 0
        anchors.verticalCenter: parent.verticalCenter
    }

    XLabel {
        id:                 statusText
        anchors.right:      parent.right
        anchors.rightMargin: 0//_margin * 2
    }

    XSwitch {
        id: switchBox
        height: _margin * 3
        width:  _margin * 7
        anchors.verticalCenter: parent.verticalCenter
        anchors.right:          parent.right
        anchors.rightMargin:    _margin //parent.width * 0.06
        checked: fact ? fact.value : false
        onToggled: {
            // console.log("Toggled:", checked)

            if(fact) {
                fact.rawValue = checked
            }
//            console.log("QGroundControl.settingsManager.appSettings.virtualJoystick = ", fact.rawValue)
        }
    }

    Rectangle {
        width:  parent.width
        height: 1
        visible: lineVisible
        color:  "#aaaaaa"
        anchors.bottom:     parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
