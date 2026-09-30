import QtQuick 2.3
import QtQuick.Controls 2.5

import QGroundControl.Palette 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl               1.0

// import QtQuick.Controls 2.5
import HXControls        1.0


Button {
	id:									button
	padding:							_margin

	property real   _margin:		  ScreenTools.base
	property real   _rotation:			0
	property var    imageSource

	property color _themeC:		qgcPal.hxTheme
	property color _subC:		qgcPal.hxHigh //"yellow"//qgcPal.hxTheme
	property color _backC:		qgcPal.hxBack

	property color  _backgroundColor:            "white"         //_b
	property color  _borderColor
	property color  _labelColor
	property color _imageColor:                 "white"         //图标颜色

	background: Rectangle {
		anchors.fill:		parent
		color:              _backgroundColor
		border.color:       _borderColor
		border.width:       1
		radius:				height/8
	}

	contentItem: Row {
		anchors.centerIn:           parent
		spacing:                    _margin / 2

		QGCColoredImage {
			id:                     innerImage
			width:                  _label.height * 0.7
			height:                 width
			source:                 imageSource
			color:                  _imageColor
			visible:                imageSource !== ""
			rotation:               _rotation
			anchors.verticalCenter: _label.verticalCenter
		}

		HXLabel {
			id:                         _label
			visible:                    text !== ""
			text:                       button.text
			anchors.verticalCenter:     parent.verticalCenter
			color:                      _labelColor
		}
	}

	// Change the colors based on button states
	/*
				   默认         |     悬浮
			 |  默认  |  按下   |  默认 | 按下
	 背景     |  黑      小麦色  |  白
	 图标     | 主题      黑     |  黑
	 外圈     | 主题      黑     |  黑
	*/
	state:                              "Default"
	states: [
		State {
			name:                       "Default"
			PropertyChanges {
				target:							button;
				_borderColor:                 checked ?   "black" :  "white"
				_backgroundColor:             (checked ?   _subC: _backC)
				_imageColor:                  (checked ?   "black" : _themeC)
				_labelColor:                  (checked ?   "black" : "white")
			}
		}
	]
}
