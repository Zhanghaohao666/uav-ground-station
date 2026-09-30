pragma Singleton

import QtQuick          2.12
import QtQuick.Controls 1.2
import QtQuick.Window   2.2

import XUI 1.0

Item {
    id: _screenTools

    // --- DPI-based scale factor ---
    property real screenDpi: Screen.pixelDensity * 25.4       // pixels/mm → DPI
    property real scaleFactor: screenDpi / 160                 // 160 DPI as reference

    // --- Fixed dpw/dph, no longer dependent on font point size ---
    property real dpw: 14
    property real dph: 14

    // --- Scalable base unit for layout (clamped range [10, 24]) ---
    property real base: {
        var b = 14 * scaleFactor
        return Math.max(10, Math.min(b, 24))
    }

    // Optional: default font sizing logic (can be used elsewhere)
    property real defaultFontPointSize:  (ScreenToolsController.isMobile ? 14 : 10) * 1.3
    property real platformFontPointSize: (ScreenToolsController.isMobile ? 14 : 10) * 1.3
    property real defaultFontPixelWidth: defaultFontPointSize * 1.0//0.8//1.4
    property real defaultFontPixelHeight: defaultFontPointSize * 1.7//2.0

    property real smallFontPointSize: 10
    property real mediumFontPointSize: 10
    property real largeFontPointSize: 10

    property real toolbarHeight: base * 5.0

    readonly property real smallFontPointRatio:  0.75
    readonly property real mediumFontPointRatio: 1.25
    readonly property real largeFontPointRatio:  1.5

    property bool isAndroid:    ScreenToolsController.isAndroid
    property bool isiOS:        ScreenToolsController.isiOS
    property bool isMobile:     ScreenToolsController.isMobile
    property bool isWindows:    ScreenToolsController.isWindows
    property bool isDebug:      ScreenToolsController.isDebug
    property bool isMac:        ScreenToolsController.isMacOS

    // property string siyuanName:   siyuanFont1.name
//    property string oppoScansName: oppoScans.name

    // FontLoader {
    //     id: siyuanFont1;
    //     source: "qrc:/font/SourceHanSansCN-Normal.otf"
    // }

    // property real realPixelDensity: {
    //     if (QGroundControl.corePlugin.options.devicePixelDensity != 0) {
    //         return QGroundControl.corePlugin.options.devicePixelDensity
    //     }
    //     if (isAndroid) {
    //         if ((Screen.width / Screen.pixelDensity) > 300) {
    //             return Screen.pixelDensity * 2
    //         }
    //     }
    //     return Screen.pixelDensity
    // }

    // property bool isTinyScreen: (Screen.width / realPixelDensity) < 120
    // property bool isShortScreen: ((Screen.height / realPixelDensity) < 120) || (ScreenToolsController.isMobile && ((Screen.height / Screen.width) < 0.6))
    // property bool isHugeScreen: (Screen.width / realPixelDensity) >= (23.5 * 25.4)
    property bool isSerialAvailable: ScreenToolsController.isSerialAvailable

    readonly property real minTouchMillimeters: 10
    property real minTouchPixels: 0

    property real implicitButtonWidth:      Math.round(dpw *  (isMobile ? 7.0 : 5.0))
    property real implicitButtonHeight:     Math.round(dph *  (isMobile ? 2.0 : 1.6))
    property real implicitCheckBoxHeight:   Math.round(dph *  (isMobile ? 2.0 : 1.0))
    property real implicitRadioButtonHeight: implicitCheckBoxHeight
    property real implicitTextFieldHeight:  Math.round(dph *  (isMobile ? 2.0 : 1.6)) * 2.6
    property real implicitComboBoxHeight:   Math.round(dph *  (isMobile ? 2.0 : 1.6)) * 1.1//1.3//2.5
    property real implicitComboBoxWidth:    Math.round(dpw *  (isMobile ? 7.0 : 5.0))
    property real comboBoxPadding:          dpw
    property real implicitSliderHeight:     isMobile ? Math.max(dph, minTouchPixels) : dph
    property real checkBoxIndicatorSize:    2 * Math.floor(dph * (isMobile ? 1.6 : 1.2) / 2) + 2
    property real radioButtonIndicatorSize: checkBoxIndicatorSize

    readonly property string normalFontFamily:   ScreenToolsController.normalFontFamily
    // readonly property string demiboldFontFamily: ScreenToolsController.boldFontFamily
    // readonly property string fixedFontFamily:    ScreenToolsController.fixedFontFamily


    // Connections {
    //     target: QGroundControl.settingsManager.appSettings.appFontPointSize
    //     function onValueChanged() {
    //         platformFontPointSize = QGroundControl.settingsManager.appSettings.appFontPointSize.value
    //     }
    // }

    Component.onCompleted: {
        console.log("Screen DPI:", screenDpi,
                    "ScaleFactor:", scaleFactor,
                    "Base:", base,
                    "Screen:", Screen.width, "x", Screen.height,
                    "PixelDensity:", Screen.pixelDensity)
    }

    function printScreenStats() {
        console.log('ScreenTools: Screen.width:', Screen.width,
                    'Screen.height:', Screen.height,
                    'Screen.pixelDensity:', Screen.pixelDensity)
    }

    function mouseX() {
        return ScreenToolsController.mouseX()
    }

    function mouseY() {
        return ScreenToolsController.mouseY()
    }

    // Text {
    //     id: _textMeasure
    //     text: "X"
    //     font.family: normalFontFamily
    //     property real fontWidth: contentWidth
    //     property real fontHeight: contentHeight
    //     Component.onCompleted: {
    //         var _appFontPointSizeFact = QGroundControl.settingsManager.appSettings.appFontPointSize
    //         var baseSize = _appFontPointSizeFact.value
    //         if (baseSize < _appFontPointSizeFact.min || baseSize > _appFontPointSizeFact.max) {
    //             baseSize = platformFontPointSize
    //             _appFontPointSizeFact.value = baseSize
    //         }
    //         platformFontPointSize = baseSize
    //     }
    // }
}


