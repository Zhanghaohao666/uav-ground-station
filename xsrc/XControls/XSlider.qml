

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.SGControls    1.0


Item {
    id:     rootI
    height: _rootItem.height

    property int    _pix:                      14
    property int    _margin:                   10
    property int    oldWidth:                   container.width;

    ///--外部输入
    property real    _valueMin:                 -10    //1~10
    property real    _valueMax:                  10    //1~10
    property real    _valueField:               _valueMax -  _valueMin  //1~10
    property string    _name:                  "框选阈值"

    ///--内部调整
    property color  _themeC:                    "#01F2B0"//ZHGlobalColor.topFillCrl   //qgcPal.ccLight
    property color  _subC:                      "yellow"
    property color  _backgroundC:               "grey"
    property color  _labelC:                    "#ffffff"//"#CCFF80"
    property int    _labelSize:                 14
    property int    _labelHeaderSize:           _labelSize
    property int    _defaultSilderValueOut:     0
    property real    _defaultSilderValueInner:   0
    property real   _defaultValue :             0
    property int    _baseSize:                   10
    property bool   lineVisible:                 false
    ///--计算的固定值
    property real    _silderValueMax:            container.width - slider.width

    signal upValue(real value)

    property real presion: 10  //精度 需要除以10的

    function upValueFun() {
        var val = (slider.x * _valueField / _silderValueMax + _valueMin).toFixed(1);
        var rem = (val * 10) % presion  //余数 4.6 * 10 / 5   rem = 1
        var div = (val * 10) / presion  //商                  div = 11
        if(rem !==0) {
            val = val * 10 + presion - rem
            return (val/10).toFixed(1)
        }
        else {
            return val
        }
    }

    Component.onCompleted: {
//        _defaultSilderValueInner = _defaultSilderValueOut  //2.0
        _defaultSilderValueInner = (_defaultValue - _valueMin) * _silderValueMax / _valueField
//        console.log("_defaultSilderValueInner: ", _defaultSilderValueInner)
    }

    Column {
        id:                     _rootItem
        width:                  parent.width
//        spacing:                _baseSlineVisible ? _baseSize:  0
        ///--上侧值显示
        Item {
            width:                          parent.width
            height:                         textField.height + _baseSize

            SGLabel {
                id:                             labelName
                text:                           _name
                anchors.verticalCenter:         parent.verticalCenter
                x:                              5
                y:                              5
                color:                          _labelC
                font.pointSize:                 _labelHeaderSize
            }
            QGCTextField {
                id:                 textField
                height:             _baseSize * 3
                width:              height * 2.5
                enabled:            true
//                color:                      "black"
//                backRect.border.color:      "#FF9900"
//                backRect.color:             "white"
                y:                  _baseSize
                anchors.right:       parent.right
                text: upValueFun()
            }
        }

        Item {
            width: 1
            height: _baseSize
        }

        ///左侧滑动显示值
        Rectangle {
            id:                 container
            width:              parent.width * 0.98
            height :            _pix/2
            radius:             height/2;
            antialiasing:       true          // 抗锯齿，具体效果见下面图片
//            width:               parent.width *0.9
            //黑色——>棕色的渐变
            gradient: Gradient {
                GradientStop { position: 0.0; color: _backgroundC }
                GradientStop { position: 1.0; color: _backgroundC }
            }

            //填充的颜色
            Rectangle {
                id:         fillRctg
                height:     parent.height
                radius:     parent.radius
                width:      slider.x + 4
                color:      _themeC
            }

            //小滑块条
            Rectangle {
                id:         slider
                x:          Math.min(Math.max(_defaultSilderValueInner,0), container.width)//_defaultSilderValueInner
                y:          -height/2 + container.height/2
                height:     _pix*2
                width:      height
                radius:     height/2;
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0;  color:  _themeC    }
                    GradientStop { position: 1.0;  color:  _themeC    }
                }
                MouseArea {
                    anchors.fill:       parent
                    anchors.margins:    -_pix
                    drag.target:        parent;
                    drag.axis:          Drag.XAxis
                    drag.minimumX:      0
                    drag.maximumX:      _silderValueMax
                }
                onXChanged: {
                    rootI.upValue(upValueFun())
                }
            }
        }

        Item {
            width: 1
            height: _baseSize
        }

        Item {
            width:      parent.width
            height:     minValue.height
            SGLabel {
                id:                 minValue
                anchors.left:       parent.left
                text:               _valueMin
                color:              _labelC
                font.pointSize:     _labelSize
            }
            SGLabel {
                id:                 maxValue
                anchors.right:      parent.right
                text:               _valueMax
                color:              _labelC
                font.pointSize:     _labelSize
            }
        }

        Item {
            width: 1
            height: lineVisible ? _baseSize : 0
        }

        Rectangle {
            height: lineVisible ? 2 : 0
            width:  parent.width * 0.9
            color:  "#88ffffff"//_subC
            anchors.horizontalCenter: parent.horizontalCenter
            visible: lineVisible
        }
    }
}

/// The SliderSwitch control implements a sliding switch control similar to the power off
/// control on an iPhone.

//SGSliderSwitch {
//    Layout.columnSpan:       2
//    Layout.preferredWidth:  _comboFieldWidth
//    _sliderWidth:           ScreenTools.isMobile ? _comboFieldWidth * 0.7 : _comboFieldWidth * 0.7
//    color:                  qgcPal.windowShade
//}

//Item {
//    id:     rootI
//    height: 50

//    property int _pix:                      16
//    property int _margin:                   10
//    property int    oldWidth:               container.width;

//    ///--外部输入
//    property int    _valueMin:                 -10    //1~10
//    property int    _valueMax:                  10    //1~10
//    property int    _valueField:               _valueMax -  _valueMin  //1~10

//    ///--内部调整
//    property color  _themeC:                "#01F2B0"//qgcPal.sgTheme
//    property color  _subC:                  "yellow"
//    property color  _backgroundC:           "#88000000"
//    property color  _labelC:                "#ffffff"//"#CCFF80"
//    property int    _labelSize:             15
//    property int    _defaultSilderValue:    0

//    ///--计算的固定值
//    property int    _silderValueMax:        container.width - slider.width

//    signal upValue(int value)

//    function upValueFun() {
//        return (slider.x * _valueField / _silderValueMax + _valueMin).toFixed(0);
//    }

//    Item {
//        id:                     _rootItem
//        width:                  parent.width
//        anchors.top:            parent.top;
//        anchors.topMargin:      _margin * 2;
//        ///左侧滑动显示值
//        Rectangle {
//            id:                 container
//            width:              parent.width * 0.66
//            height :            _pix/2
//            radius:             height/2;
//            antialiasing:       true          // 抗锯齿，具体效果见下面图片
//            anchors.left:       parent.left
////            width:               parent.width *0.9
//            //黑色——>棕色的渐变
//            gradient: Gradient {
//                GradientStop { position: 0.0; color: _backgroundC }
//                GradientStop { position: 1.0; color: _backgroundC }
//            }

//            //填充的颜色
//            Rectangle {
//                id:         fillRctg
//                height:     parent.height
//                radius:     parent.radius
//                width:      slider.x + 4
//                color:      _themeC
//            }

//            //小滑块条
//            Rectangle {
//                id:         slider
//                x:          _defaultSilderValue;
//                y:          -height/2 + container.height/2
//                height:     _pix*2
//                width:      height
//                radius:     height/2;
//                antialiasing: true
//                gradient: Gradient {
//                    GradientStop { position: 0.0;  color:  _themeC    }
//                    GradientStop { position: 1.0;  color:  _themeC    }
//                }
//                MouseArea {
//                    anchors.fill:       parent
//                    anchors.margins:    -_pix
//                    drag.target:        parent;
//                    drag.axis:          Drag.XAxis
//                    drag.minimumX:      _defaultSilderValue;
//                    drag.maximumX:      _silderValueMax
//                }
//                onXChanged: {
//                    rootI.upValue(upValueFun())
//                }
//            }
//        }

//        SGLabel {
//            id:                 minValue
//            anchors.left:       container.left
//            anchors.top:        container.bottom
//            anchors.topMargin:  _margin*0.8
//            font.pointSize:     _labelSize
//            text:               _valueMin
//            color:              _labelC
//        }
//        SGLabel {
//            id:                 maxValue
//            anchors.right:      container.right
//            anchors.top:        minValue.top
//            font.pointSize:     _labelSize
//            text:               _valueMax
//            color:              _labelC
//        }

//        ///右侧显示值
//        Rectangle {
//            id:                     valueR
//            width:                  Math.max( valueL.width * 1.8 ,  parent.width - container.width - valueR.anchors.leftMargin*2)
//            height:                 valueL.height * 1.5
//            color:                  Qt.rgba(0,0,0,0)
//            border.color:           _labelC
//            border.width:           2
//            anchors.left:           container.right
//            anchors.leftMargin:     _margin*2
//            radius:                 1
//            anchors.verticalCenter:         container.verticalCenter
//            anchors.verticalCenterOffset:   _margin*0.5

//            SGLabel {
//                id:                valueL
//                anchors.centerIn:  parent
//                font.pointSize:    _labelSize
//                color:             _themeC
//                text:              upValueFun()
//            }
//        }
//    }
//}

