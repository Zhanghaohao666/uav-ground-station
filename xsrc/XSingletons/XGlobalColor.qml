pragma Singleton

import QtQuick 2.3
import QtLocation  5.12

QtObject {

    readonly property color background :  "#0b0e12" //背景颜色
    readonly property color background2 : "#121721"//"#aa001834"  //背景颜色
    readonly property color background3 : "#884782E9"//"#aa001834"  //背景颜色


    readonly property color line : "#4d4389FF"//"#aa001834"  //背景颜色

    readonly property color theme : "#4782E9"//"#aa001834"  //背景颜色
    readonly property color theme2 : "#1A5BCB"//"#aa001834"  //背景颜色

    readonly property color sub : "#00FFFF"//"#aa001834"  //背景颜色
    readonly property color sub3 : "#F3AC20"//
    readonly property color sub2 : "#6600FFFF"//"#aa001834"  //背景颜色



    readonly property color label : "#ffffff"//"#aa001834"  //背景颜色
    readonly property color label2 : "#BAD4FF"//"#aa001834"  //背景颜色
    readonly property color label3 : sub//"#BAD4FF"//"#aa001834"  //背景颜色
    readonly property color labeldisable : "#cc111620"//"#BAD4FF"//"#aa001834"  //背景颜色

    readonly property color btnbg : theme//"#aa001834"  //背景颜色
    readonly property color btnbg2 : "#253146"

    ///---

    readonly property color lighterTheme : "#3300f0f0"//
    readonly property color text : "white"//"#aa001834"  //背景颜色 透明黑
    readonly property color select : "#A0FCCA07"  //航点选中 透明黄
    readonly property color orange:  "#88E99D42"
    readonly property color success: "#4fd6a2"
    readonly property color danger:  "#d65f5f"
}
