

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0

import ZHControls    1.0
import ZHSingletonControl   1.0

import XUI 1.0

Item {
    id:     rootI
    height: _rootItem.height + _margin * 2

    property color  labelColor: "white"

    property real   firstItemHeight:    _margin * 2// ScreenTools.defaultFontPixelHeight * 1.8
    property real   secondItemHeight:   _margin * 2// ScreenTools.defaultFontPixelHeight * 2.4

    property int    _margin:            XScreenTool.base

    ///--外部输入
    property real    _valueMin:                 -10    //1~10
    property real    _valueMax:                  10    //1~10
    property real    _valueField:               _valueMax - _valueMin  //1~10
    property string  _name:                     "Slider"
    property string  _unit:                     ""
    // property string  _unit:                     textField.unitsLabel

    ///--内部调整
    property color  _themeC:                    XGlobalColor.theme//ZHGlobalColor.topFillCrl
    property color  _subC:                      "yellow"
    property color  _backgroundC:               "grey"
    property color  _labelC:                    "#000000"
    property int    _labelSize:                 15

    property real    _defaultSilderValueOut:     0
    property real    _defaultSilderValueInner:   0
    property real   _defaultValue :              0
    property int    _baseSize:                   _margin

    ///--计算的固定值
    property int    _silderValueMax:            container.width - slider.width

    signal upValue(real value)

    property real presion: 10

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
        _defaultSilderValueInner = (_defaultValue - _valueMin) * _silderValueMax / _valueField
    }

    Column {
        id:                     _rootItem
        width:                  parent.width
        spacing:                _margin * 2
        anchors.centerIn:       parent

        //- 上侧值显示模块
        Item {
            width:                          parent.width
            height:                         firstItemHeight

            XLabel {
                id:                             labelName
                text:                           _name
                color:                          labelColor
                anchors.verticalCenter:         parent.verticalCenter
                small: true
            }
            XLabel {
                id:                             textField
                text:                           upValueFun() + " " + _unit
                color:                          labelColor
                anchors.right:                  parent.right
                anchors.verticalCenter:         parent.verticalCenter
                small: true
            }
            /*
            QGCTextField {
                id:                             textField
                height:                         _baseSize * 4
                width:                          height * 2.5
                anchors.right:                  parent.right
                anchors.verticalCenter:         parent.verticalCenter
                text:                           upValueFun()
                showUnits:                      true
            }
            */
        }

        //- 下测滑块模块
        Item  {
            width:              parent.width
            height:             secondItemHeight

            ///左侧滑动显示值
            Rectangle {
                id:                         container
                width:                      parent.width
                height:                     parent.height * 0.3//0.33
                radius:                     height/2;
                antialiasing:               true
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      _backgroundC        // 滑块长条背景色

                //填充的颜色
                Rectangle {
                    id:                 fillRctg
                    height:             parent.height
                    radius:             height / 2
                    width:              slider.x + 4
                    color:              _themeC
                    Rectangle {
                        height:         parent.height
                        width:          parent.width * 0.3
                        color:          parent.color
                        anchors.right:  parent.right
                    }
                }

                //小滑块条
                Rectangle {
                    id:                 slider
                    x:                  _defaultSilderValueInner
                    y:                  -height/2 + container.height/2
                    height:             secondItemHeight
                    width:              height
                    radius:             height/2
                    antialiasing:       true
                    color:              _themeC     // 填充长条颜色

                    MouseArea {
                        anchors.fill:       parent
                        anchors.margins:    -ScreenTools.defaultFontPixelHeight * 2
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
/*
            QGCLabel {
                id:                 minValue
                anchors.left:       container.left
                anchors.top:        container.bottom
                anchors.topMargin:  _margin * 3
                text:               _valueMin
                color:              labelColor
            }
            QGCLabel {
                id:                 maxValue
                anchors.right:      container.right
                anchors.top:        minValue.top
                text:               _valueMax
                color:              labelColor
            }
            */
        }
    }
}
