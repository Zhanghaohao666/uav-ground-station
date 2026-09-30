import QtQuick 2.3
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Controls              1.0
import QGroundControl   1.0

Button {
    id:         button
    padding:    haveBorder ? 10 : 0

    property bool picked: false
    property bool haveBorder : true
    property real factor:    0.85
    property var imageSource
    property color _themeC: "orange"
    property color _disC: "#66ffffff"
    property color _backgroundColor: "white"
    property color _borderColor
    property color _pressedColor: "green"  // 按下时的颜色
    property color _activeColor: "green"   // 新增：激活状态的颜色
    property bool active: false            // 新增：激活状态

    contentItem: Item {
        id: content
        Image {
            id: image
            anchors.centerIn: parent
            width: parent.width * factor
            height: width
            sourceSize.height: height
            sourceSize.width: width
            source: imageSource
            fillMode: Image.PreserveAspectFit
            visible: !button.active && !button.pressed
        }

        ColorOverlay {
            anchors.fill: image
            source: image
            color: button.pressed ? _pressedColor : (button.active ? _activeColor : "transparent")
            visible: button.active || button.pressed
        }
    }

    background: Rectangle   {
        id:                 buttonBkRect
        radius:             width*0.1
        color:              _backgroundColor //Qt.rgba(0,0,0,0)
        anchors.fill:       parent
        opacity:            1.0
        border.color:       _borderColor
        border.width:       haveBorder ? 4 : 0
    }

    /*
                   默认           |     悬浮
             |  默认  |  按下     |  默认 | 按下
     背景     | 黑        主题    |  白
     图标     | 黑        黑      |  黑
     外圈     | 主题      黑      |  黑             */
    state:                                  "Default"
    states: [
        State {
            name: "Default"
            PropertyChanges {
                target: button;
                _backgroundColor:       enabled ?   (pressed ?   _themeC :  "white") :  _disC
               // _imageColor:            enabled ?   (pressed ?   "black" :  "black") :  "black"
                _borderColor:           enabled ?   (pressed ?   "white" :  _themeC) :  _themeC
            }
        }
    ]
}
