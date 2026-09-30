import QtQuick 2.12
import QtQuick.Controls 2.12

import XUI 1.0

Label {
    id: root
    verticalAlignment:  Qt.AlignVCenter
    font.pixelSize:     getPixel()
    font.family:        XScreenTool.normalFontFamily
    color:              "white"
    font.bold:          true
    antialiasing:       true

    property bool minminmin:false
    property bool minmin:   false
    property bool min:      false
    property bool small:    false
    property bool big:      false
    property bool large:    false
    property real margin:   XScreenTool.base

    function getPixel() {
        ///从小到大的
        if(minmin) {
            return margin * 1.0
        }
        else if(min) {
            return margin * 1.1
        }
        else if(small) {
            return margin * 1.25
        }
        else if(big) {
            return margin * 1.55
        }
        else if(large) {
            return margin * 1.7
        }
        else if(minminmin) {
            return margin * 0.9
        }
        else {
            return margin * 1.4
        }
    }
}
