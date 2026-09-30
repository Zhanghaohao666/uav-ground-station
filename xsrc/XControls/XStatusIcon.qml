import QtQuick 2.12

import XUI   1.0

Item {
    id: root
    property bool wait: false
    property bool success: false

    implicitHeight: XScreenTool.baseSize * 3
    implicitWidth: implicitHeight

    Image {
        id: image
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        opacity: 0
        source: wait ? "qrc:/image/loading.png" : success ? "qrc:/image/success.png" : "qrc:/image/failed.png"
    }
    RotationAnimation {
        id: rotationAm
        target: image
        running: wait
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
        onStopped: image.rotation = 0
        onFinished: image.rotation = 0
    }
    onWaitChanged: {
        if(wait){
            opacityAm.stop()
            image.opacity = 1
        }else{
            opacityAm.start()
        }
    }

    PropertyAnimation {
        id: opacityAm
        target: image
        property: "opacity"
        to: 0
        duration: 2000
    }
}
