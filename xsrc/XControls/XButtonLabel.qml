import QtQuick 2.0
import QtQuick.Controls 2.12
import QGroundControl.Palette           1.0

import XUI   1.0

Button {
    id: root

    property real _marginwidth:     XScreenTool.base * 1.2
    property real _marginheight:    XScreenTool.base * 1.0

    property color _theme:           XGlobalColor.theme
    property color _theme2:          XGlobalColor.theme2
    property color _sub:           XGlobalColor.sub


    property color _backgroundColor //矩形背景颜色
    property color _borderColor     // 边框颜色
    property color _fontColor       // 字体颜色
    property bool _small : false
    property bool _min : false

    height:      contentItem.implicitHeight  + _marginheight
    width:       contentItem.implicitWidth  +  _marginwidth
    padding:     0

    contentItem: XLabel {
        id:                 textControl
        anchors.centerIn:   parent
        text:               root.text
        opacity:            enabled ? 1.0 : 0.3
        color:              _fontColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:  Text.AlignVCenter
        elide:              Text.ElideRight
        small:              _small
        min:                _min
    }

    background: Rectangle   {
        id:                 buttonBkRect
        radius:             6
        color:              _backgroundColor
        anchors.fill:       parent
        opacity:            0.95
        border.color:       _borderColor
        border.width:       0
    }

    state:                                  "Default"
    states: [
        State {
            name:                           "Default"
            PropertyChanges {
                target: root;
                _borderColor:                  pressed ?   "white": "white"//"#449698"
                _backgroundColor:        enabled ?    (pressed ?   _sub:  _theme)   : "grey"
                _fontColor:              enabled ?    (pressed ?   "white":   "white") : "black"
            }
        }
    ]
}
