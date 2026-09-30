import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import XUI 1.0

Item {
    id: root

    property real       _margin:  XScreenTool.base
    property string     icon: ""
    property alias      desc: text.text
    property alias      currentIndex: combobox.currentIndex
    property alias      currentText: combobox.currentText
    property alias      model: combobox.model
    property bool       _iconExist: icon != ""
    property alias      fact: combobox.fact
    property alias      box: combobox
    property bool       _line : true
    signal activated

    implicitHeight: _margin * 8
    implicitWidth:  _margin * 30
    Layout.fillWidth: true

    Image {
        id: iconImage
        height: parent.height * 0.5
        width:  _iconExist ? height : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: _margin
        source: icon
    }

    XLabel {
        id: text
        Layout.fillHeight: true
        anchors.left: parent.left
        anchors.leftMargin: _margin //_iconExist ?  parent.width * 0.1 : _margin * 6
        anchors.verticalCenter: parent.verticalCenter
    }

    // XLabel {
    //     id: statusText
    //     Layout.fillHeight: true
    //     anchors.right: parent.right
    //     anchors.rightMargin: _margin
    // }

    XComboBoxFact {
        id:     combobox
        height: _margin * 4
        width:  _margin * 25
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: _margin//parent.width * 0.06
        onActivated: {
            //console.log("========currentText",currentText)
            root.activated()
        }
    }

    Rectangle {
        width: parent.width //_iconExist ? parent.width * 0.85 : parent.width * 0.9
        height: _line ? 1 : 0
        // x: _iconExist ?  parent.width * 0.1 : parent.width * 0.05
        color:  "#aaaaaa"   //"white"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
