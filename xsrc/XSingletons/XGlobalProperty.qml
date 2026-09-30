pragma Singleton


import QtQuick 2.12
import QtLocation  5.12
import QGroundControl               1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controllers   1.0
import XUI 1.0

QtObject {

    //================== 全局属性 ==================
    property string version:    "v1.01.09"
    property string date:       "20260924"
    property real _margin:   XScreenTool.base
    property bool  videoMax: true      //主窗口为视频
    property var  vhcoffline:   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property var  vhcnull:      QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : null
    property var  ext:          vhcoffline.ext
    property bool isPlanView:   false
    property real statusBarHeight : _margin * 5  //7//状态栏高度

    // property bool mapIsFull: QGroundControl.loadBoolGlobalSetting("MapIsFull", false)


    // onMapIsFullChanged: {
    //     console.log("MapIsFull:", mapIsFull)
    // }


    //================== 全局组件 ==================
    property Map mainMap: null            //初始化复制
    property Map thumbnailMap: null       //缩略图地图
    property var  guidedActionsController: null      //二次确认控制器,提供数据
    // readonly property var       guidedControllerFlyView:        flightView.guidedController

    //plan
//     property PlanMasterController       planMasterPlan:       PlanMasterController {
//         Component.onCompleted: {
//             start(false)
// //            setCurrentPlanViewSeqNum(0, true)
// //            globals.planMasterControllerPlanView = _planMasterController
//             //console.log("PlanMasterController",false)
//         }
    // }
    property var planMasterPlan
    property var currentPlanMissionItem:  planMasterPlan ? planMasterPlan.missionController.currentPlanViewItem : null

    //flyView
    property PlanMasterController       planMasterFly:       PlanMasterController {
        flyView: true
        Component.onCompleted: start(true)
    }

    property real    minViewWidth :  _margin * 18
    property bool settingViewVisible: false

    property int        settingType: settingType_General //当前设置菜单位置

    // readonly property int settingType_Check: 1
    readonly property int settingType_General:  1
    readonly property int settingType_Link:     2
    readonly property int settingType_Gimbal:   3
    readonly property int settingType_Param:    4
    readonly property int settingType_Abort:    5
    readonly property int settingType_Safe:     6

    property string     mapProvider:               QGroundControl.settingsManager.flightMapSettings.mapProvider.value
    property string     mapType:                   QGroundControl.settingsManager.flightMapSettings.mapType.value
    property bool       healthAndArmingChecksSupported: false//activeVehicle ? activeVehicle.healthAndArmingCheckReport.supported : false

    //参数是否加载
    property bool  fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
                                                  && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters

    signal dimensionsChanged(real width)

    onFullParameterVehicleAvailableChanged: {
//        console.log("====================onFullParameterVehicleAvailableChanged", fullParameterVehicleAvailable)
//        parameterLoader.sourceComponent = fullParameterVehicleAvailable ? parameterComponent : undefined
//        flightModesLoader.sourceComponent = fullParameterVehicleAvailable ? apmflightModesComponent : undefined
//        radioLoader.sourceComponent = fullParameterVehicleAvailable ? radioComponent : undefined
    }

    //================== 参数 ==================
    property real   loadProgress:      vhcnull ? vhcnull.parameterManager.loadProgress : 0
    property bool   loadParameters:    false      //参数加载完成标志

    onLoadProgressChanged: {
       // console.log("loadProgress",loadProgress)
        if(loadProgress >=0.8  && vhcnull) {
            loadParameters = true
        }
    }

    onVhcnullChanged: {
        if(!vhcnull) {
            console.log("vhcnull", vhcnull)
            loadParameters = false
        }
    }

    //================function=====================
    function getSpacing(row, wid) {
        var totalChildWidth = 0
        for (var i = 0; i < row.children.length; ++i) {
            var item = row.children[i]
            // 过滤掉非 Item 类型的对象（比如内置的 QQuickKeysAttached 等）
            if (item.visible && item.width !== undefined)
                totalChildWidth += item.width
        }
        var count = 0
        for (var j = 0; j < row.children.length; ++j) {
            if (row.children[j].visible && row.children[j].width !== undefined)
                count++
        }
        return count > 1 ? (wid - totalChildWidth) / (count - 1) : 0
    }


//    // 方法暴露给外部
//     function startTimer() {
//         console.log("Starting singleton timer...");
//         delayLoad.restart();
//     }

//     Timer {
//         id: delayLoad
//         repeat: false
//         running: false
//         interval: 1000
//         onTriggered: {
//             loadParameters = true
//         }
//     }
    ////========== END =========


    property bool       mainViewVisible: true
    property bool       videoFull: false    //全屏视频
    property bool       selfcheckVisible: false //显示检查列表界面
    property bool       projectileVisible: false //抛投器抛投界面是否显示
    property bool       messageViewVisible: false //飞机信息页是否显示
    property bool       parameterVisible: false //调参界面是否显示
    property bool       offlineMapVisible: false //打开离线地图管理器
    property bool       sightVisible: false //视频界面显示准星
    property bool       correction: false
    property bool       mapFollowVehicle: false //地图跟随飞机
    property bool       labelMapVisble: true //是否开启标注地图
    property bool       trajectoryVisible: false //轨迹是否显示
    property bool       noflyZoneVisible: false//禁飞区
    property bool       airwayManagerVisible: false
    property bool       airwayEditorVisible: false
    onAirwayEditorVisibleChanged: if(airwayEditorVisible) videoMax = false

    property bool       addWaypointEnabled: false
    property bool       missionInEdit: false

    property bool       showALSMView: false           //alsm高度显示
    property bool       teachingVideoVisible: false   //教学视频页是否显示
    property bool       userViewVisible: false        //用户页是否显示

    property bool       missionFlod:   false             //航线列表展开

    property bool       locationVisble:  false
    property bool       mapSettingVisble:  false
    property bool       flySettingVisble:  false
    property bool       targetVisble:  true

    property real       bottomDashValueWidth:  0   //底部仪表宽 + 参数宽
    property real       stateTextHeight


    property bool       virtualJoystick : false

    property string     u85 :       "CED85"
    property string     u120 :      "CED120"
    property string     u150 :      "CEM150"
    property string     u150_7 :    "CED150-7"
    property string     uCEM8 :     "CEM8"


    property bool upgradeViewVisible: false     // 是否弹出更新框

    //ZHAirwayView.AirwayViewIndex.AirwayViewIndex_Waypoint
    enum UAVModeIndex {
        UAV_CED85 = 1,
        UAV_CED120,
        UAV_CED150,
        UAV_CED150_7,
        UAV_CEM8
    }

    //主要
    property var mainWindow
    //机型选择
    property var  gimbal

    // 设置里的手持起飞
    property bool checked1: false

    // 设置里面的目标跟踪
    property bool checked2: true
    // 判断任务板是否处于目标跟踪状态
    property bool checked6: false

    // 设置里面的目标识别
    property bool checked3: true
    // 判断任务板是否处于已经识别到目标的状态
    property bool checked7: false

    // flyview中的避障标志
    property bool checked4: false

    // 设置里的拒止导航
    property bool checked5: false

//    // 设置里的镜头跟随
//    property bool checked6: false
    // 设置里面的目标类型
    property int target_type: 1

    //
    property int _idx:  0

    // 飞控发来的86消息
    property int lat_int_86: 0
    property int lon_int_86: 0

    property int rtspflag_id1: 0

    //========== signal ===========
    signal changeMapType(var type, bool isLabel)

    // 解锁相关
    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest


}

