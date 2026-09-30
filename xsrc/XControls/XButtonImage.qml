import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12


Rectangle {
    id: root

    property string     source:     "qrc:/image/simple.png"
    property string     checkedSource: ""
    property string     pressedSource: ""
    property real       padding:        2
    property real       borderWidth:    0

    property bool       checked:        false
    property bool       colorEnable :   false

    property color     imageColor :            XGlobalColor.sub//"black"            //图标：默认
    property color     imagePressedColor :     XGlobalColor.sub//"#DD000000"     //GlobalColor.orange  //图标：按下

    property color      backgroundColor:        "transparent"  //背景：默认颜色
    property color      backgroundPressedColor: "transparent"  //背景：按下去的颜色

    property color      bordColor:              "#000000"         //背景：默认颜色
    property color      bordPressedColor:       "#000000"        //背景：按下去的颜色

    property bool       autoChecked: false
    property alias      img: image2

    property real      _margin:  XScreenTool.base

    signal clicked
    signal pressAndHold

    radius:         height/2
    color:          enabled ? (mouseArea.pressed || checked ? backgroundPressedColor : backgroundColor) : "grey"
    border.color:   mouseArea.pressed || checked ? bordPressedColor : bordColor
    border.width:   colorEnable ? borderWidth : 0
    implicitHeight: _margin * 5
    implicitWidth:  _margin * 5

    Image {
        id:             image2
        width:          parent.width - padding
        height:         parent.height - padding
        anchors.centerIn: parent
        source: mouseArea.pressed && pressedSource != "" ? pressedSource : checked && checkedSource != "" ? checkedSource : root.source
        asynchronous:       true
        smooth:             true
        mipmap:             true
        antialiasing:       true
        layer.enabled:      colorEnable
        fillMode:           Image.PreserveAspectFit
        layer.effect: ColorOverlay {
            color: mouseArea.pressed || checked ? imagePressedColor : imageColor  // 你希望覆盖的颜色
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: parent.enabled
        onClicked: {

            if(autoChecked){
                checked  = true
            } else
                root.clicked()
        }
        onPressAndHold: {
            root.pressAndHold()
            root.clicked()
        }
    }
}
