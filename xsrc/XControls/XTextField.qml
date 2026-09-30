import QtQuick 2.12
import QtQuick.Controls 2.12
import XUI 1.0

TextField {
    id: root

    property real  _margin :  XScreenTool.base
    property color _theme :  XGlobalColor.theme

    property bool  submit: false
    property alias backRect: back
    property string unit: ""
    property string         oldText: ""
    property var            verifyFunc: null
    property bool           valid: true

    property bool   showUnits:          false
    property bool   showHelp:           false
    property string unitsLabel:         ""
    property string extraUnitsLabel:    ""

    function setSaveText(text) {
        root.text = text
        oldText = text
        valid = true
    }

    onVisibleChanged: {
        if(!visible){
            root.focus = false
        }
    }

    onFocusChanged: {
        if(!focus && oldText != text&&submit){
            setSafeText(oldText)
            valid = true
        }
    }

    onTextChanged: {
        if(submit && verifyFunc){
            valid = verifyFunc(text)
        }
    }
    Component.onCompleted: oldText = root.text

    signal save

    background: Rectangle {
        id: back
        radius:   5 //_margin
        color: "black"//enabled ? "transparent" : "#606060"
        border.color:  "white" //"#808080"
        border.width:  1
    }
    implicitWidth:  _margin * 15
    implicitHeight: _margin * 4
    font.pixelSize: _margin * 1.6
    font.bold:      true
    color:          _theme //"white"
    XLabel {
        // font.pixelSize: parent.height/2
        anchors.verticalCenter: parent.verticalCenter
        anchors.right:          parent.right
        anchors.rightMargin:    _margin
        text:                   unit
        visible:    submit ? (oldText == root.text || !valid) : true
        small:      true
    }

    // XImageButton {
    //     height: parent.height * 0.7
    //     width: height
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.right: parent.right
    //     anchors.rightMargin: _margin * 2
    //     visible: submit && oldText != root.text && valid
    //     source: "qrc:/image/save.png"
    //     onClicked: {
    //         oldText = root.text
    //         save()
    //     }
    // }
}
