

/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0
import QGroundControl.Controllers           1.0
import QGroundControl.SettingsManager       1.0

import ZHControls            1.0
import ZHSingletonControl   1.0


Item {
    id:                 _linkRoot
    anchors.fill:       parent
    anchors.margins:    5//ScreenTools.defaultFontPixelWidth


    property real   _comboFieldWidth:           30 * XScreenTool.base//  23  230 * ScreenTools.pixelRatio
    property var    _planViewSettings:          QGroundControl.settingsManager.planViewSettings
    property var    _videoSettings:             QGroundControl.settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.value
    property bool   _isGst:                     QGroundControl.videoManager.isGStreamer
    property bool   _isUDP264:                  _isGst && _videoSource === _videoSettings.udp264VideoSource
    property bool   _isUDP265:                  _isGst && _videoSource === _videoSettings.udp265VideoSource
    property bool   _isRTSP:                    _isGst && _videoSource === _videoSettings.rtspVideoSource
    property bool   _isTCP:                     _isGst && _videoSource === _videoSettings.tcpVideoSource
    property bool   _isMPEGTS:                  _isGst && _videoSource === _videoSettings.mpegtsVideoSource
    property bool   _videoAutoStreamConfig:     QGroundControl.videoManager.autoStreamConfigured
    property bool   _showSaveVideoSettings:     _isGst || _videoAutoStreamConfig
    property bool   _disableAllDataPersistence: QGroundControl.settingsManager.appSettings.disableAllPersistence.rawValue


    //        _rtspUrlFact->setRawValue("rtsp://192.168.144.64:554/h264/ch1/main/av_stream");
//    if
//    Component.onCompleted: {
//        if(!_videoSettings.rtspUrl.value) {
//            _videoSettings.rtspUrl.value = "rtsp://192.168.144.64:554/h264/ch1/main/av_stream"
//        }
//    }

    ZHLabel {
        id:                 header
        text:               qsTr("video setting")//视频设置
        big:             true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    GridLayout {
        id:                     videoGrid
        anchors.top:            header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        columns:    2

        ZHLabel {
            text:       qsTr("IP: ")
            visible:    !_videoAutoStreamConfig && _videoSettings.videoSource.visible
            big:     true
        }

        QGCTextField {
            id:         ipValue
            Layout.preferredWidth:  _comboFieldWidth
            text:       "192.168.144.64"//"192.168.1.64"
        }
        ZHLabel {
            text:       qsTr("port：")//端口
            visible:    !_videoAutoStreamConfig && _videoSettings.videoSource.visible
            big:     true
        }

        QGCTextField {
            id:         portValue
            Layout.preferredWidth:  _comboFieldWidth
            text:       "8000"
        }
        ZHLabel {
            text:       qsTr("user：")//用户
            visible:    !_videoAutoStreamConfig && _videoSettings.videoSource.visible
            big:     true
        }

        QGCTextField {
            id:         userValue
            Layout.preferredWidth:  _comboFieldWidth
            text:       "admin"

        }
        ZHLabel {
            text:       qsTr("password：")//密码
            visible:    !_videoAutoStreamConfig && _videoSettings.videoSource.visible
            big:     true
        }

        QGCTextField {
            id:         passwordValue
            Layout.preferredWidth:  _comboFieldWidth
            text:     "njzh123456789"// "hk123456"//"zhd123456"
        }

//        ///--qsTr("2.video Setting")
//        ZHLabel {
//            id: videoConfigure
//            text: qsTr("address：")//地址
//            big:     true
//        }

//        FactTextField {
//            Layout.preferredWidth:      _comboFieldWidth
//            fact:                       _videoSettings.rtspUrl
//        }
    }

    ZHButton2 {
        text:         qsTr("OK")
        anchors.top:  videoGrid.bottom
        anchors.topMargin: XScreenTool.base*2
        anchors.right:videoGrid.right

        _haveImage:   false
        height:       XScreenTool.base * 6
        width:        _comboFieldWidth
        // big:         true
        anchors.horizontalCenter: parent.horizontalCenter
        backRadius:   8
        onClicked: {
            console.log("Video Setting Enter!")

            //start_cch_20231222
            gloalHKWS.onClickedLogin(ipValue.text, portValue.text, userValue.text, passwordValue.text)
            ZHGlobalProperty.joystickVisible = true
        }
    }
}

//        ZHLabel {
//            id:         udpPortLabel
//            text:       qsTr("UDP Port")
//            visible:    !_videoAutoStreamConfig && (_isUDP264 || _isUDP265 || _isMPEGTS) && _videoSettings.udpPort.visible
//            _small:     true

//        }
//        FactTextField {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.udpPort
//            visible:                udpPortLabel.visible
//        }
//        ZHLabel {
//            id:         rtspUrlLabel
//            text:       qsTr("RTSP URL")
//            visible:    !_videoAutoStreamConfig && _isRTSP && _videoSettings.rtspUrl.visible
//            _small:     true
//        }
//        FactTextField {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.rtspUrl
//            visible:                rtspUrlLabel.visible
//        }
//        ZHLabel {
//            id:         tcpUrlLabel
//            text:       qsTr("TCP URL")
//            visible:    !_videoAutoStreamConfig && _isTCP && _videoSettings.tcpUrl.visible
//            _small:     true
//        }
//        FactTextField {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.tcpUrl
//            visible:                tcpUrlLabel.visible
//        }
//        ZHLabel {
//            text:                   qsTr("Aspect Ratio")
//            visible:                !_videoAutoStreamConfig && _isGst && _videoSettings.aspectRatio.visible
//            _small:     true
//        }
//        FactTextField {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.aspectRatio
//            visible:                !_videoAutoStreamConfig && _isGst && _videoSettings.aspectRatio.visible
//        }

//        ZHLabel {
//            id:         videoFileFormatLabel
//            text:       qsTr("File Format")
//            visible:    _showSaveVideoSettings && _videoSettings.recordingFormat.visible
//            _small:     true
//        }
//        FactComboBox {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.recordingFormat
//            visible:                videoFileFormatLabel.visible
//        }
//        ZHLabel {
//            id:         maxSavedVideoStorageLabel
//            text:       qsTr("Max Storage Usage")
//            visible:    _showSaveVideoSettings && _videoSettings.maxVideoSize.visible && _videoSettings.enableStorageLimit.value
//            _small:     true
//        }
//        FactTextField {
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.maxVideoSize
//            visible:                _showSaveVideoSettings && _videoSettings.enableStorageLimit.value && maxSavedVideoStorageLabel.visible
//        }
//        ZHLabel {
//            id:         videoDecodeLabel
//            text:       qsTr("Video decode priority")
//            visible:    forceVideoDecoderComboBox.visible
//            _small:     true
//        }
//        FactComboBox {
//            id:                     forceVideoDecoderComboBox
//            Layout.preferredWidth:  _comboFieldWidth
//            fact:                   _videoSettings.forceVideoDecoder
//            visible:                fact.visible
//            indexModel:             false
//        }
//        Item { width: 1; height: 1}
//        FactCheckBox {
//            text:       qsTr("Disable When Disarmed")
//            fact:       _videoSettings.disableWhenDisarmed
//            visible:    !_videoAutoStreamConfig && _isGst && fact.visible
//        }

//        Item { width: 1; height: 1}
//        FactCheckBox {
//            text:       qsTr("Low Latency Mode")
//            fact:       _videoSettings.lowLatencyMode
//            visible:    !_videoAutoStreamConfig && _isGst && fact.visible
//        }

//        Item { width: 1; height: 1}
//        FactCheckBox {
//            text:       qsTr("Auto-Delete Saved Recordings")
//            fact:       _videoSettings.enableStorageLimit
//            visible:    _showSaveVideoSettings && fact.visible
//        }

