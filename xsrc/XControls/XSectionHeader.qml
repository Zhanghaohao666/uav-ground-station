import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtGraphicalEffects 1.0

import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.SGControls        1.0

FocusScope {
    id:         _root
    height:     column.height
    width:      Math.max(_maxWidth, _maxContextWidth)  //(_maxWidth >= _maxContextWidth) ? _maxContextWidth : _maxWidth

    property alias          color:          label.color
    property alias          text:           label.text
    property alias          pointSize:     label.font.pointSize
    property alias          imageSource:    leftImage.source

    property bool           checked:        true
    property bool           showSpacer:     true
    property ExclusiveGroup exclusiveGroup: null

    property real           _sectionSpacer:     ScreenTools.defaultFontPixelWidth / 2  // spacing between section headings
    property real           _maxContextWidth:   leftImage.width + label.width + label.anchors.leftMargin + rightimage.width
    property real           _maxWidth           //父提供

    onExclusiveGroupChanged: {
        if (exclusiveGroup)
            exclusiveGroup.bindCheckable(_root)
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    QGCMouseArea {
        anchors.fill: parent

        onClicked: {
            _root.focus = true
            checked = !checked
        }

        ColumnLayout {
            id:             column
            anchors.left:   parent.left
            anchors.right:  parent.right

            Item {
                height:     1
                width:      1
                visible:    showSpacer
            }

            Item {
                id:                     _item
                Layout.fillWidth:       true
                height:                 label.height;

                QGCColoredImage { ///--image
                    id:                             leftImage
                    anchors.verticalCenter:         parent.verticalCenter
                    source:                         "/qmlimages/SG/FenceIcon.png"
                    width:                          label.height;
                    height:                         width
                    color:                          qgcPal.sgTheme
                }

                SGLabel {
                    id:                             label
                    anchors.left:                   leftImage.right
                    anchors.leftMargin:             4
                    font.pointSize:                 11
                    color:                          qgcPal.sgTheme
                }

                QGCColoredImage {
                    id:                             rightimage
                    anchors.right:                  parent.right
                    anchors.verticalCenter:         label.verticalCenter
                    width:                          label.height * 3/4
                    height:                         width
                    source:                         "/qmlimages/arrow-down.png"
                    color:                          qgcPal.sgTheme//qgcPal.text
                    _rotation:                      _root.checked ? 180:0
                }
            }

            Rectangle {
                Layout.fillWidth:   true
                height:             1
                color:              qgcPal.sgTheme
            }
        }
    }
}
