import QtQuick 2.0
import QtQuick.Controls 2.12

import XUI 1.0

Button {
    id: root

    property alias  backRect:		  backRectangle


    property real _imageRatio:  0.55

    property color _themeC:		XGlobalColor.theme
    property color _subC:		XGlobalColor.sub//lighterTheme   // "YELLOW "//qgcPal.hxHigh //"yellow"//qgcPal.hxTheme
    property color _backC:		"#9f000000"   ///XGlobalColor.background

    property color _backDefault:  _backC
    property color _backChecked:  _subC
    property color _imageDefault:  "white"
    property color _imageChecked:   "black"
    property color _borderChecked:  "black"
    property color _borderDefault:  _themeC

    property color  _backgroundColor:    "#9f000000" //"white"         //_b
    property color  _borderColor:       _themeC      // 边框颜色
    property color _imageColor:                 "white"
    property bool   _small :        false

    property var source

    height:      contentItem.implicitHeight  + ScreenTool.base * 2
    width:       contentItem.implicitWidth  + ScreenTool.base * 3

    background: Rectangle   {
        id:                 backRectangle
        radius:             height/2
        color:              _backgroundColor// //root.enabled ? "#88000000" : "#22000000"//"transparent"
        anchors.fill:       parent
        border.color:       _borderColor//
        border.width:       1
    }

    contentItem: Item {
        id:      itemControl
        XColoredImage {
            anchors.centerIn:                   parent
            height:                             parent.height * _imageRatio
            width:                              height
            source:                             root.source
            color:                              root.enabled ? _imageColor  :  "#77ffffff"//"grey" //root.enabled ? GlobalColor.theme : "#337f8f8f"//"#4480f0f0" // : "#4480f0f0"//GlobalColor.lighterTheme
        }
    }

    state:                              "Default"
    states: [
        State {
            name:                       "Default"
            PropertyChanges {
                target:						   root;
                _borderColor:                 (checked || pressed) ?   _borderChecked : _borderDefault //"black" :  "white"
                _backgroundColor:             (checked || pressed) ?   _backChecked: _backDefault
                _imageColor:                  (checked || pressed) ?   _imageChecked : _imageDefault   //_themeC
            }
        }
    ]
}
