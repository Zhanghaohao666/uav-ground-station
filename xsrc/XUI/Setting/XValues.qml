import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs  1.2    //StandardButton

import QtGraphicalEffects   1.0

import QGroundControl.FlightMap     1.0
import QGroundControl.Vehicle       1.0

import QGroundControl               1.0

//import QtQuick 2.3
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0
import ZHControls 1.0

//ValuesController 注入QGroundControl.Controllers中
import QGroundControl.Controllers   1.0
//fact
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.PX4           1.0

Item {
    id:         valuesRoot
    width:      flickRoot.width
    height:     flickRoot.height

    ///----内部使用：
    property color _valueColor:     "yellow"//"#F9FDAA"
    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool _ellipsis:        false

    property real _margins:         ScreenTools.pixelRatio * 5  //5   //10
    property real _opacity:         0.95
    property real _scaleV:          2

    //start_cch_20210906
    property var voltageVal:                 _activeVehicle ? _activeVehicle.voltage0 :  0
                                            //[0]、               1、                    2、                   3、                        4、                          5、                       6、                        7、
                                        //  *高度、                *电压、                *速度、                *GPS                       时间  、                    *出发距离、                                          油门、              电量、                        总路程(随意)，
    property var modelContent:          ["altitudeRelative",   "myVoltage",         "groundSpeed",           "gps.count"       ]    //"flightTime",             "distanceToHome",                  ] //"throttlePct",        "battery.percentRemaining",  "flightDistance" ,
    property var modelContentTranslate: [qsTr("Altitude"),      qsTr("Voltage"),    qsTr("Ground Speed"),   qsTr("GPS count")  ]    //qsTr("Flight distance") , qsTr("Distance To Home"),  ] //qsTr("Throttle Pct")  qsTr("Percent Remaining"),    qsTr("Flight Distance"),]
//    property var modelImages :        [heightWidgets,         canvasDash,         speedWidgets,           fixWidgets,     ]       //fixWidgets,               fixWidgets,                  ,        ] fixWidgets             canvasDash,
    property var modelImages :          [fixWidgets,            fixWidgets,           fixWidgets,           fixWidgets,      ]      //fixWidgets,               fixWidgets        ] //canvasDash,           batteryWidgets                fixWidgets,             ]
    property var modelMax:              [150,                   4.2 * 6,              10,                    100             ]      //100,                      100,                         100               ] //100,                  100,                          100,                    ]
    property var modelMin:              [ 0,                    3.7 * 6,               0,                     0             ]      //0,                        0,                           0                 ] //0,                     0,                            0,                     ]
    property var modelSvg:              ["/qmlimages/SG/Altitude.svg",  "/qmlimages/SG/Voltage.svg", "/qmlimages/SG/Speed.svg","/qmlimages/SG/Satellite.svg"]  //"/qmlimages/SG/Time.svg","/qmlimages/SG/FlightDistance.svg","/qmlimages/SG/DistanceToHome.svg"

//    property var modelImageUrl:         ["/qmlimages/SG/Altitude.svg", qsTr("Ground Speed"), qsTr("Altitude"),                                       ]
    ///--只读常量
    readonly property color      _themeColor:               qgcPal.sgTheme                     //qgcPal.sgButton
    readonly property real       _mar:                      5
    readonly property real      defaultWidgetsWidth:       defaultWidgetsWidth * 0.9//globalType===2?  ScreenTools.hugeImage : ScreenTools.mediumImage //ScreenTools.isMobile ? parent.height - 10 * _scaleV : ScreenTools.imagePixelNor//    (ScreenTools.isMobile ? 30 * _scaleV : 28)   //32 28
    readonly property real      defaultWidgetsHeight:      defaultWidgetsWidth * 0.9 //ScreenTools.isMobile ? parent.height - 18 * _scaleV : ScreenTools.imagePixelNor//   (ScreenTools.isMobile ? 35 * _scaleV : 23)   //23

    ///--默认颜色
    function getValueColor(fact) {
        if(_activeVehicle) {
            if(fact === 0 || fact === 0.0 || fact === "--.--" || fact === "0" || fact === "0.0")    return _themeColor //qgcPal.colorGrey
            else                                                                                    return _themeColor
        }
        return _themeColor//qgcPal.colorGrey
    }

    ///--获取模型的颜色
    function getModelColor(index, fact) {
        if(getValueColor(fact) === qgcPal.colorGrey)        return qgcPal.colorGrey
        switch(index) {
            ///电压
            case 1:
                //voltage 22.2~25.2
                if(fact > modelMin[index] +  (modelMax[index]-modelMin[index]) * 0.3)          return _themeColor
                if(fact > modelMin[index] +  (modelMax[index]-modelMin[index]) * 0.1)          return "yellow"
                if(fact >= modelMin[index] + (modelMax[index]-modelMin[index]) * 0.0)          return "red"
                return _themeColor//qgcPal.colorGrey
            ///地速
            case 2:
                if(fact < 8.3)          return _themeColor
                if(fact <= 12)          return "yellow"
                if(fact > 12 )          return "red"
                return _themeColor      //qgcPal.colorGrey
            ///高度
            case 0:
                if(fact <  120)         return _themeColor
                if(fact <= 150)         return "yellow"
                if(fact >  200)         return "red"
                return _themeColor      //qgcPal.colorGrey
            //GPS
            case 3:
                if(fact < 1  )          return _themeColor
                if(fact < 3  )          return qgcPal.colorGrey
                if(fact < 10 )          return "yellow"
                return _themeColor
            default:
                return                  _themeColor
        }
    }

    ///--获取值的形式
    function getValueText(index, fact) {
        switch(index) {
            ///电压
//            case 0:
//                return (isNaN(voltageVal) ? (0+"v") : (voltageVal + "v"))
//            ///时间
//            case 3:
//                return fact.valueEqualsDefault ?  "00:00:00" :   fact.enumOrValueString
            ///GPS
            case 3:
                return fact.valueEqualsDefault ?  " " : (fact.enumOrValueString === "--.--" ? "--": fact.value.toFixed(0))
            default:
                return fact.valueEqualsDefault ?  " " : (fact.enumOrValueString === "--.--" ? "--": fact.value.toFixed(1))  + fact.units
        }
    }

    Item {
        id:                     flickRoot
        width:                  rowRoot.width   //parent.width
        height:                 rowRoot.height  //parent.height

        Row {
            id:                 rowRoot
            spacing:            _margins
            Repeater {
                model:          modelContent
                Item {
                    width:  row1.width
                    height: row1.height
                    property Fact fact: _activeVehicle.getFact(modelData);

                    Row {
                        id:     row1
                        spacing: 1
                        Loader {
                            id: loaderDash
                            anchors.verticalCenter: parent.verticalCenter
                            sourceComponent:        modelImages[index]
                        }
                        Component.onCompleted: {
                            loaderDash.item._image = modelSvg[index]
                        }
                        ///--更新值和颜色
                        Timer{
                            id:             timer
                            interval:       1000
                            running:        true
                            repeat:         true
                            onTriggered: {
                                var val
    //                            if(index == 0) {
    //    //                          console.log("voltageVal" ,valuesRoot.voltageVal)
    //                                val = isNaN(voltageVal) ? 0 : voltageVal
    //                            }
    //                            else {
                                    val = isNaN(fact.enumOrValueString) ? 0.0 : fact.enumOrValueString          //初步判断是否有效
    //                            }
                                val = (val<0) ? 0 : val                                                         //初步判断是否为0
                                val= (val - modelMin[index]) / (modelMax[index]-modelMin[index]) * 100
                                loaderDash.item._value = (val<0) ? 0 : val
                                loaderDash.item._color = sgLabel.color
                            }
                        }

                        Column {
                            anchors.verticalCenter:         parent.verticalCenter
                            ZHLabel {
                                id:                         sgLabel
                                horizontalAlignment:        Text.AlignHCenter
                                color:                      getModelColor(index, ((index===10) ? (isNaN(voltageVal) ? 0 : voltageVal) : fact.enumOrValueString))
                                text:                       getValueText(index, fact)
                                small:                     large ? false : true
                                large:                      globalType === 2 ? true : false
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill:   parent
                        onClicked: {
                            if(index==0)        mainWindow.ssShowPopup(altitudeInfo,  parent, 3)
                            else if(index==1)   mainWindow.ssShowPopup(voltageInfo,   parent, 3)
                            else if(index==2)   mainWindow.ssShowPopup(speedInfo,     parent, 3)
                            else if(index==3)   mainWindow.ssShowPopup(gpsInfo,       parent, 3)
                        }
                    }
                }
            }
        }
    }


    ///--1
    Component {
        id:         altitudeInfo
        Rectangle {
            width:  altitudeCol.width   + _margins * 4
            height: altitudeCol.height  + _margins * 4
            radius: _margins
            color:                  "#aa000000"
            border.color:           "#aaffffff"
            border.width:           2

            Column {
                id:                 altitudeCol
                spacing:            _margins
                width:              Math.max(altitudeGrid.width, altitudeLabel.width)
                anchors.margins:    _margins
                anchors.centerIn:   parent

                ZHLabel {
                    id:             altitudeLabel
                    text:           qsTr("Flight Altitude")
                    anchors.horizontalCenter: parent.horizontalCenter
                    color:          qgcPal.sgTheme
                }

                Item {
                    width: 1
                    height: 1
                }

                GridLayout {
                    id:                 altitudeGrid
                    anchors.margins:    _margins
                    columnSpacing:      _margins
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    ZHLabel { text: qsTr("Maximum flight limit altitude:")    ;    color: "white" ; small: true}
                    ZHLabel { text: qsTr("120m") ;          color: "white" ; small: true}
                }


            }
        }
    }
    ///--2
    Component {
        id:             voltageInfo
        Rectangle {
            id:         voltageRect
            width:      voltageCol.width   + _margins * 4
            height:     voltageCol.height  + _margins * 4
            radius:     _margins
            color:                  "#AA000000"
            border.color:           "#AAffffff"
            border.width:           2

            property real _voltage :               _activeVehicle ? _activeVehicle.myVoltage.rawValue : 0
            property var    _flyViewSettings:        QGroundControl.settingsManager.flyViewSettings

//            property real _cells :   4   //目前人为定义
//            property int _cells : _flyViewSettings ? _flyViewSettings.batteryCells.rawValue : 0

            Column {
                id:                 voltageCol
                spacing:            _margins
                width:              Math.max(voltageGrid.width, voltageLabel.width)
                anchors.margins:    _margins
                anchors.centerIn:   parent

                ZHLabel {
                    id:             voltageLabel
                    text:           qsTr("Voltage Status")
                    anchors.horizontalCenter: parent.horizontalCenter
                    color:          qgcPal.sgTheme
                }

                Item {
                    width: 1
                    height: 1
                }

                GridLayout {
                    id:                 voltageGrid
                    anchors.margins:    _margins
                    columnSpacing:      _margins
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    ZHLabel { text: qsTr("Number of battery cells:")   ;   color: "white" ;}
                    FactTextField {
                        id:                     cells
                        fact:                   _batteryCells
                        Layout.fillWidth:       true
                        Layout.maximumWidth:     100 * ScreenTools.pixelRatio
                        validator: IntValidator{bottom: 1; top: 20;}
                        property Fact _batteryCells: QGroundControl.settingsManager.flyViewSettings.batteryCells

//                        onEditingFinished: {
//                            if(text < 1 || text > 9) {
//                                text = 4
//                                mainWindow.showMessageDialog(qsTr("警告"), qsTr("电芯数量必须为1~9"))
//                            }
//                        }
//                        onAccepted: {
//                            if(text < 1 || text > 9) {
//                                text = 4
//                                mainWindow.showMessageDialog(qsTr("警告"), qsTr("电芯数量必须为1~9"))
//                            }
//                        }
                    }
                    ZHLabel { text: qsTr("Average single:")    ;    color: "white" }
                    ZHLabel {
                        id: singleVol;
                        text: (voltageRect._voltage/(cells.text===0 ? 1 : cells.text)).toFixed(2) + "v" ;
                        color: "white" ;
                        Layout.fillWidth:       true
                    }
                }
            }
        }

//        Component.onCompleted: {
////            hostField.text = tcpClinet.tcpServerIP
////            portField.text = tcpClinet.tcpServerPort
////            console.log("hostField.text:" ,hostField.text,  "portField.text", portField.text)
//        }
    }
    ///--3
    Component {
        id:             speedInfo
        Rectangle {
            id:         speedRect
            width:      speedCol.width   + _margins * 4
            height:     speedCol.height  + _margins * 4
            radius:     _margins
            color:                  "#AA000000"
            border.color:           "#aaffffff"
            border.width:           2

//            property real _speed : _activeVehicle ? _activeVehicle.myspeed.rawValue : 0
//            property real _cells :   4   //目前人为定义


            Column {
                id:                 speedCol
                spacing:            _margins
                width:              Math.max(speedGrid.width, speedLabel.width)
                anchors.margins:    _margins
                anchors.centerIn:   parent

                ZHLabel {
                    id:             speedLabel
                    text:           qsTr("Speed Information")
                    anchors.horizontalCenter: parent.horizontalCenter
                    color:          qgcPal.sgTheme

                }

                Item {
                    width: 1
                    height: 1
                }

                GridLayout {
                    id:                 speedGrid
                    anchors.margins:    _margins
                    columnSpacing:      _margins
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    ZHLabel { text: qsTr("Normal:")    ;    color: "white" ; small: true}
                    ZHLabel { text: qsTr("0~15m/s") ;    color: _themeColor ; small: true}
                    ZHLabel { text: qsTr("Fast:")      ;   color: "white"    ; small: true}
                    ZHLabel { text: qsTr("15~20m/s") ;   color: "yellow"    ; small: true}
                    ZHLabel { text: qsTr("Dangerous:") ;        color: "white"       ; small: true}
                    ZHLabel { text: qsTr("Above 20m/s")  ;  color: "red"       ; small: true}
                }
            }
        }
    }
    ///--4
    Component {
        id:         gpsInfo
        Rectangle {
            width:  gpsCol.width   + _margins * 4
            height: gpsCol.height  + _margins * 4
            radius: _margins
            color:                  "#DD000000"
            border.color:           "#DDffffff"
            border.width:           2
            Column {
                id:                 gpsCol
                spacing:            _margins
                width:              Math.max(gpsGrid.width, gpsLabel.width)
                anchors.margins:    _margins
                anchors.centerIn:   parent

                ZHLabel {
                    id:             gpsLabel
                    text:           (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? qsTr("GPS Status") : qsTr("GPS data not available")
                    anchors.horizontalCenter: parent.horizontalCenter
                    color:          qgcPal.sgTheme
                }

                Item {
                    width: 1
                    height: 1
                }

                GridLayout {
                    id:                 gpsGrid
                    visible:            (_activeVehicle && _activeVehicle.gps.count.value >= 0)
                    anchors.margins:    _margins
                    columnSpacing:      _margins
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2

                    ZHLabel { text: qsTr("GPS Number:"); small: true}
                    ZHLabel { text: _activeVehicle ? _activeVehicle.gps.count.valueString : qsTr("N/A", "No data") ; small: true}
                    ZHLabel { text: qsTr("GPS Type:") ; small: true}
                    ZHLabel { text: _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : qsTr("N/A", "No data") ; small: true}
                    ZHLabel { text: qsTr("Horizontal Accuracy:") ; small: true}
                    ZHLabel { text: _activeVehicle ? _activeVehicle.gps.hdop.valueString : qsTr("--.--", "No data") ; small: true}
                    ZHLabel { text: qsTr("Vertical Accuracy:") ; small: true}
                    ZHLabel { text: _activeVehicle ? _activeVehicle.gps.vdop.valueString : qsTr("--.--", "No data") ; small: true}
                }
            }
        }
    }

    ///------------------------------------------------------------------------------------///
    ///------------------ 动态小仪表 ------------------
    ///电压和油门
    Component {
    id: canvasDash
        Item {
            width:  defaultWidgetsWidth
            height: defaultWidgetsHeight
            anchors.centerIn:   parent

            property real _value : 0
            property real _angle: (_value * (180-10) / 100 + (180+10))
            property string _text : ""
            property color _color: '#01E9A9'
            property color _backgroundColor: "white"

            on_ValueChanged: canvas.requestPaint();

            Canvas{ ///画布
                id: canvas
                width:  parent.width       //40
                height: width/2            //20
                anchors.centerIn:           parent

                contextType:  "2d";
                function paintGimbalYaw(ctx,x,y,r,angle1,angle2,color) {
                    ctx.fillStyle = color
                    ctx.save();
                    ctx.beginPath();
                    ctx.moveTo(x,y);
                    ctx.arc(x,y,r,angle1*Math.PI/180,angle2*Math.PI/180);
                    ctx.closePath();
                    ctx.fill()
                    ctx.restore();
                }

                onPaint: {
                    var ctx = getContext("2d");  ///画师
                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2,      180,  360,  _backgroundColor)//'#005840')
                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2,      180,  _angle, _color)
                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.85,  0,    360,  "#142c29")

                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.7, 180,  360,_backgroundColor) //'#005840')
                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.7, 180,_angle, _color)
                    paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.6, 0,   360,    "#142c29")
                }
                //文字
                ZHLabel {
                    id:                         txt_progress
                    visible:                    _text != ""
                    anchors.bottom:             parent.bottom
                    anchors.bottomMargin:       ScreenTools.isMobile ? -7 : -4//-2
                    anchors.horizontalCenter:   parent.horizontalCenter
                    small :                    true
//                    font.pointSize:             8
                    text:                       _text       //"V"
                    color:                      _color
                }
                QGCColoredImage {
                    visible:        !txt_progress.visible
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    source:                     "/qmlimages/SG/Oil.svg"
                    fillMode:                   Image.PreserveAspectFit
                    color:                      _color
                    width:                      ScreenTools.isMobile ? 20 : 10  //16 //8
                    height:                     width
                }
            }
        }
    }

    ///------------------ 矩形速度   ------------------
    ///速度
    Component {
    id: speedWidgets
        Rectangle {
            width:  defaultWidgetsWidth  * 0.9      //40  30
            height: defaultWidgetsHeight * 0.6//0.5//0.66
            anchors.centerIn:   parent

            color:              Qt.rgba(0,0,0,0)
            border.color:       "white"
            border.width:       _borderWidth
            radius:             2

            property color          _color  //pct
            property real           _value
            property real           _borderWidth:   2

            Rectangle {
                height:             parent.height - _borderWidth*2
                width:              Math.min(Math.max(10/100*parent.width,  (_value-_borderWidth)/100*parent.width), parent.width-_borderWidth*2)   //为了 点缀一点主题色
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                anchors.margins:    parent.border.width
                color:              _color
            }
        }
    }

    ///------------------ 矩形高度   ------------------
    ///速度
    Component {
        id: heightWidgets
        Item {
            width:   defaultWidgetsWidth * 0.5
            height:  defaultWidgetsHeight

            property color      _color
            property real       _value  //pct
            property real       _borderWidth: 2

            Rectangle {
                width:   parent.width
                height:  parent.height
                anchors.left:        parent.left
                color:              Qt.rgba(0,0,0,0)
                border.color:       "white"
                border.width:       _borderWidth
                radius:             2

                Rectangle {
                    height:             Math.min(Math.max(10/100*parent.height,  (_value-_borderWidth)/100*parent.height), parent.height-_borderWidth*2)   //为了 点缀一点主题色
                    width:              parent.width - _borderWidth*2
                    anchors.bottom:     parent.bottom
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.margins:    _borderWidth
                    color:              _color
                }
            }
        }
    }

    ///------------------ 矩形电量   ------------------
    ///电量
    Component {
        id: batteryWidgets
        Item {
            id:      batteryItem
            width:   defaultWidgetsWidth
            height:  defaultWidgetsHeight

            property color      _color
            property real       _value  //pct

            function getBatterySource() {
//                console.log("_value",       _value)
                if(_activeVehicle) {
                    if(_value > 75)  return "/qmlimages/SG/Power4.svg"
                    if(_value > 55)  return "/qmlimages/SG/Power3.svg"
                    if(_value > 30)  return "/qmlimages/SG/Power2.svg"
                }
                return "/qmlimages/SG/Power1.svg"
            }
            QGCColoredImage {
                anchors.fill:               parent
                source:                     batteryItem.getBatterySource()
                color:                      _color
            }
        }
    }

    ///------------------ 固定的小仪表，更加简洁  ------------------
    ///距离
    Component {
    id: fixWidgets
        Item {
            width:   defaultWidgetsWidth
            height:  defaultWidgetsHeight

            property color      _color
            property real       _value          //pct
            property var        _image

            QGCColoredImage {
                anchors.fill:               parent
                source:                     _image
                color:                      "white"//_color
            }
        }
    }
}

