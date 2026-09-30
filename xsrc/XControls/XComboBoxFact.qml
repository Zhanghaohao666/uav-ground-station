import QtQuick 2.12

import QGroundControl.FactSystem 1.0

import XUI 1.0

XComboBox {
    id: root

    property Fact fact: null
    property bool indexModel: true  ///< true: model must be specifed, selected index is fact value, false: use enum meta data
    property bool upload: false
    property bool leftStatusIcon: false

    model: fact ? fact.enumStrings : null

    //currentIndex: fact ? (indexModel ? fact.value : fact.enumIndex) : 0

    onActivated: {
        if(fact){
            if (indexModel) {
                fact.value = currentIndex
            } else {
                fact.value = fact.enumValues[currentIndex]
            }
            // statusIcon.wait = upload
        }
    }
    Component.onCompleted: {
        if(fact){
            currentIndex = indexModel ? fact.rawValue : fact.enumIndex
        }
    }

    Connections {
        target: fact
        ignoreUnknownSignals: true
        function onVehicleUpdated() {
            // statusIcon.wait = false
            if( root.currentIndex !== fact.enumIndex){
                root.currentIndex = indexModel ? fact.rawValue : fact.enumIndex
            }
            if(fact.enumIndex === root.currentIndex){
                // statusIcon.success = true
            }
        }
        function onSetParameterResult(){
            // statusIcon.success = result
        }
    }

    // XStatusIcon {
    //     id: statusIcon
    //     anchors.verticalCenter: parent.verticalCenter
    //     x: leftStatusIcon ? -(width + XScreenTool.base) : parent.width + XScreenTool.base
    // }
}
