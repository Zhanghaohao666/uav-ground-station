import QtQuick 2.12
import QtQuick.Controls 2.12

import XUI   1.0

Rectangle {
    id: root

    //平台定义
    property real  _margin :  XScreenTool.base
    property color _themeC:  XGlobalColor.theme

    property var model: null
    property int currentIndex: -1
    property alias currentText: text.text

    signal activated

    onModelChanged: {
        if(model && model.length > 0 ){
            if(currentIndex == -1)
                currentIndex = 0
            text.text = model[currentIndex]
        }
    }

    function getGlobalY(){
        return root.mapToItem(flightView,0,0)

    }

    onCurrentIndexChanged: {
        if(model && model.length > 0 && currentIndex >= 0 && currentIndex < model.length){
            //console.log("=====onCurrentIndexChanged",currentIndex,model)
            text.text = model[currentIndex]
        }
    }

    implicitHeight:     _margin * 5.5
    implicitWidth:      _margin * 15
    radius:             5
    border.color:       "white"//_themeC//"#108968"
    border.width:       1
    color:              "black"
    XLabel {
        id: text
        anchors.fill: parent
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        color:          _themeC
        text: ""
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if(model){
                popup.animationEnabled = true
                popup.up =  getGlobalY().y > flightView.height * 0.5 ? true : false
                popup.maxHeight = popup.up ? getGlobalY().y + root.height-_margin*2  : flightView.height - getGlobalY().y - _margin * 2
                popup.open()
            }
            //console.log(model.length)
        }
    }
    Popup {
        id: popup
        property bool animationEnabled: false
        property bool up: false
        property real maxHeight: height
        width: root.width
        height: root.height
        padding: 0
        onHeightChanged: {
            if(up){
                y = -(height - parent.height)
            }else {
                y = 0
            }
        }
        background: Rectangle {
            border.color:       "white"//"#108968"
            border.width: 1
            color:              "black"
            radius:             5
        }
//        Behavior on height{
//            enabled: popup.animationEnabled
//            PropertyAnimation{
//                duration: 300
//            }}
        onOpened: {
            animationEnabled = true
            popup.height = root.height * root.model.length > maxHeight ? maxHeight : root.height * root.model.length
        }
        onClosed: {
            animationEnabled = false
            popup.height = root.height

        }

        ListView {
            id:  listComboBox
            model: root.model
            width: parent.width
            height: parent.height
            clip: true
            delegate: XLabel {
                width: root.width
                height: root.height
                color: root.currentIndex === index ? _themeC : "white"//"#108968" : "white"
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                text: modelData
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(root.currentIndex !== index){
                            root.currentIndex = index
                            activated()
                        }
                        popup.close()
                    }
                }
            }
        }

    }

    function textAt() {
        return model[currentIndex]
    }

    function find(searchItem) {

        var idx = -1;
//        console.log("listComboBox.count:" + listComboBox.count);

        for (var i = 0; i < listComboBox.count; ++i) {
//            console.log("modelData:" + listComboBox.model[i]);
            if (listComboBox.model[i] === searchItem) {
                idx = i;
                break;
            }
        }
//        console.log("idx of " + searchItem + ": " + idx);
        //listComboBox.model.get(i).modelData

        return idx
    }
}
