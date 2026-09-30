import QtQuick 2.12
import QtQuick.Controls 2.12

import XUI   1.0

Switch {
    id: control
    property color backgroundColor: "#000000"
    property alias border:          back.border
    property color _themeC:  XGlobalColor.theme

    implicitHeight: XScreenTool.base * 3
    implicitWidth:  XScreenTool.base * 6

    indicator: Rectangle {
        id: back
        anchors.fill: parent
        radius: height/2
        border.color: "white"
        color: enabled ? control.checked ? _themeC : backgroundColor : "#808080"
        Rectangle {
            height: parent.height
            width: height
            radius: height/2
            x: control.checked ? parent.width - width : 0
        }
    }

}
