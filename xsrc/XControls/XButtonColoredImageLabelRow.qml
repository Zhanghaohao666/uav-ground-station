import QtQuick 2.3
import QtQuick.Controls 2.5

// import QtQuick.Controls 2.5
import XUI        1.0

Button {
	id:									button
	padding:							_margin

	property real _widthMargin:      _margin * 2
	property real _heightMargin:		_margin * 1

	property bool _small: false
	property real   _spacing:		  _margin / 2
	property alias  backRect:		  backRectangle
	property alias  label:				_label
	property real   _margin:		  XScreenTool.base
	property real   _rotation:			0
	property var    source
	property real   _imageRatio:		1.0

	property color _themeC:		XGlobalColor.theme
	property color _subC:		XGlobalColor.theme2//lighterTheme   // "YELLOW "//qgcPal.hxHigh //"yellow"//qgcPal.hxTheme
	property color _backC:		"transparent" /*"#dd000000"*///XGlobalColor.background

	property color _backDefault:  _backC
	property color _backChecked:  _subC
	property color _imageDefault:  _themeC
	property color _imageChecked:  "white"
	property color _borderChecked: "white"
	property color _borderDefault: "white"

	property color  _backgroundColor:            "white"
	property color  _borderColor
	property color  _labelColor
	property color _imageColor:                 "white"         //图标颜色

	implicitHeight:	row.height + _heightMargin
	implicitWidth:  row.width +  _widthMargin

	background: Rectangle {
		id:					backRectangle
		anchors.fill:		parent
		color:              _backgroundColor
		border.color:       _borderColor
		border.width:       0
		radius:				10//height/8
	}

	contentItem: Item {
		anchors.fill: parent

		Row {
			id: row
			anchors.centerIn: parent
			spacing:				_spacing

			XColoredImage {
				id:                     innerImage
				width:                  _label.height * _imageRatio
				height:                 width
				source:                 button.source
				color:                  _imageColor
				visible:                button.source !== ""
				rotation:               _rotation
				anchors.verticalCenter: _label.verticalCenter
			}

			XLabel {
				id:                         _label
				visible:                    text !== ""
				text:                       button.text
				anchors.verticalCenter:     parent.verticalCenter
				color:                      _labelColor
				small:						_small
			}
		}
	}

	state:                              "Default"
	states: [
		State {
			name:                       "Default"
			PropertyChanges {
				target:						   button;
				_borderColor:                 (checked || pressed) ?   _borderChecked : _borderDefault //"black" :  "white"
				_backgroundColor:             (checked || pressed) ?   _backChecked: _backDefault
				_imageColor:                  (checked || pressed) ?   _imageChecked : _imageDefault   //_themeC
				_labelColor:                  (checked || pressed) ?   "white" : "white"
			}
		}
	]
}
