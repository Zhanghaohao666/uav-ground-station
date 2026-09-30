#include <QtQml>
#include "vehicleexternal.h"

#include "QGCApplication.h"
#include "qdebug.h"

#include "QGCCorePlugin.h"
#include "MAVLinkProtocol.h"

#include <QHostInfo>
#include <QSignalSpy>

#include <iostream>
#include <string>
#include <stdio.h>
using namespace std;


VehicleExt::VehicleExt(Vehicle* vehicle, QObject *parent)
    : QObject(parent)
    , _activeVehicle(vehicle)
    , m_storageOn(false)
    , m_motorOn(false)
    , m_followModeOn(false)
    , m_electricLockOn(false)
    , m_zoom(0.0)
    , m_pitchDeg(0.0)
    , m_yawDeg(0.0)
{

    _tsPosition.setLatitude(28.197539);
    _tsPosition.setLongitude(112.903970);
    _tsPosition.setAltitude(30);
    initDytState();


    _mqtt = new MqttClient(this);      // 父对象为 this，Qt 自动管理内存
    // 信号槽连接，不用 lambda
    connect(_mqtt, &MqttClient::forwardPrepared,
                      this, &VehicleExt::sendRadarData);
}

void VehicleExt::initDytState() {
    //1-2 波门
    _waveDoor << "0" << "0" << "1920" << "1080";
    //2-1 框架角度
    _frameAngle << "0.00" << "0.00";
    //2-2 框架速度
    _frameSpeed << "-0.04" << "0.00";
    //2-2 激光测距
    _laserRanging = 2.52;
    //2-4 目标1失调角
    _misAngle << "0.00" << "0.00";
    //2-5 产品信息
    _dytInfo << "5" << "5" << "2";

    _inertiaAngle << "0.00" << "0.00";

    //start_cch_20230809 修改后：
    //目标状态                       纬度、            经度、          海拔 、
    _tsValues <<  ""        <<"28.197539"   << "112.903970"  << "30"      << "3"     << "0.00"     <<  "2.53"
              <<  "NULL"    <<"80"       <<   "50"         << "10"     << "2"   << "0.00"     <<  "0.0" << "使用框架角";
    //目标状态
    _tsNames  << "RWB状态："  << "纬度："    <<  "经度："      << "高度："  << "攻击速度："    << "俯仰惯性角："  << "激光测距："
              << "YX状态："     << "x距离："   << "y距离："      <<"z距离："  << "攻击加速度："  << "横滚惯性角：" << "Kp：" << "算法：";
    //目标单位
    _tsUnits  << ""        << "°"        <<  "°"          <<  "m"        <<"m/s"          << "°"   << "m"
              << ""        << "m"       <<  "m"           <<  "m"         <<"m/s2"         << "°"   << " " << " ";

    _status << "0.01"<<  "0.01" <<  "0.01"  << "0.01" <<   "0.01";
    emit statusChanged(_status);
//    _statusNames <<

    qmlRegisterUncreatableType<VehicleExt>("ZYLibs.Ext",           1, 0, "VehicleExt",       "Reference only");
}


VehicleExt::~VehicleExt()
{
}


// ==================== 工具函数 ==================== //
uint8_t VehicleExt::calcChecksum(const void *data, size_t length)
{
    const uint8_t *ptr = reinterpret_cast<const uint8_t *>(data);
    uint8_t sum = 0;
    for (size_t i = 0; i < length; ++i)  // 前15字节
        sum += ptr[i];
    return sum;
}

QString VehicleExt::algorithmName(uint8_t bits54)
{
    int newAlgo = 0;
    QString rtl;

    switch (bits54 & 0x03) { // but expect bits in position 5-4 -> shifted already
    case 0x00: newAlgo = 0; rtl = QString(tr("自适应")); break;
    case 0x01: newAlgo = 1; rtl = QString(tr("人员"));  break;
    case 0x02: newAlgo = 2; rtl =  QString(tr("车辆")); break;
    case 0x03: newAlgo = 3; rtl =  QString(tr("建筑")); break;
    default:   newAlgo = 0; rtl =  QString(tr("未知")); break;
    }

    if (newAlgo != m_trackingMode) {
        m_trackingMode = newAlgo;
        emit currentTrackingModeChanged();
        qDebug() << "导引头算法类型更新:" << trackingModes().at(m_trackingMode);
    }

    return rtl;
}

//========================== =DYT ================================
/*
    type: 1: 俯仰框架转动角度
          2: 偏航框架转动角度
          5:
          cmd 0  type       data       项
           0       0      0~65535     跟踪帧
*/
/* DYT封装发送程序 */
void  VehicleExt::sendToDYT(int cmdType, int x = 0, int y = 0, int zoom = 0) {

    uint8_t cmd = static_cast<uint8_t>(cmdType);
    int16_t ix = static_cast<int16_t>(x);
    int16_t iy = static_cast<int16_t>(y);
    int8_t zm = static_cast<int8_t>(zoom);

    cmd_gcs_to_dyt_t pkt;
    memset(&pkt, 0, sizeof(pkt));

    pkt.header[0] = HEADER1;
    pkt.header[1] = HEADER2;
    pkt.cmd       = cmd;

    pkt.paramX    = ix;
    pkt.paramY    = iy;
    pkt.param3    = 0;
    pkt.zoomSpeed = zm;

    pkt.checksum  = calcChecksum(&pkt, sizeof(pkt) - 1);

    if(_activeVehicle) {
        _activeVehicle->tunnelPackedSend(&pkt, Type_DYT);
        if (cmd == 0x26) {
            qDebug() << "[DYT] center command sent: sendToDYT(0x26, 0, 0, 0)";
        }



        QByteArray data(reinterpret_cast<const char*>(&pkt), sizeof(pkt));

        // QString hexStr;
        // for (unsigned char ch : data)
        //     hexStr += QString("%1 ").arg(ch, 2, 16, QLatin1Char('0')).toUpper();

        // qDebug().noquote() << "pkt raw bytes:" << hexStr.trimmed();
        // qDebug() << QString("tunnelPackedSend");

    }
    else {
        qDebug() << QString("Vehicle is null");
    }
}

void VehicleExt::setCurrentTrackingMode(int mode)
{
    if (mode == m_trackingMode)
        return;

    m_trackingMode = mode;
    emit currentTrackingModeChanged();

    // 对应控制信息码映射
    uint8_t cmd = 0x13 + mode; // 0x13 ~ 0x16

    sendToDYT(cmd, 0, 0, 0);

    qDebug() << QString("cmd : %1、 %2").arg(cmd).arg(m_trackingMode);

}

bool VehicleExt::parseFrame(const dyt_recv_frame_t &frame)
{
    // dyt_recv_frame_t frame;
    // // 安全拷贝前 32 字节到结构体（struct 被 pack 为 32 字节）
    // memcpy(&frame, data.constData(), sizeof(dyt_recv_frame_t));

    // 检查帧头
    if (frame.header[0] != 0xEE || frame.header[1] != 0x16) {
        // qWarning() << "DytReceiver: invalid header" << frame.header[0] << frame.header[1];
        return false;
    }

    // // 不校验和
    // if (!validateChecksum(frame)) {
    //     qWarning() << "DytReceiver: checksum mismatch";
    //     return false;
    // }

    // 解析 state1 (byte[2])
    // Bit5-4：跟踪算法类型（需要右移4后取低2位）
    uint8_t algBits = (frame.state1 >> 4) & 0x03;
    QString algName = algorithmName(algBits);

    // Bit2：目标跟踪状态 1=锁定 0=搜索
    bool locked = (frame.state1 >> 2) & 0x01;

    // 组成 trackStatus 字符串列表（两项）
    QStringList newTrackStatus;
    newTrackStatus << algName;
    newTrackStatus << (locked ? QString(tr("锁定")) : QString(tr("搜索")));

    if (newTrackStatus != m_trackStatus) {
        m_trackStatus = newTrackStatus;
        emit trackStatusChanged();
    }

    // 解析 state2 (byte[3])
    bool newStorageOn = ((frame.state2 >> 5) & 0x01);
    bool newMotorOn   = ((frame.state2 >> 3) & 0x01);
    bool newFollowOn  = ((frame.state2 >> 2) & 0x01);
    bool newElockOn   = ((frame.state2 >> 1) & 0x01);

    if (newStorageOn != m_storageOn) { m_storageOn = newStorageOn; emit storageOnChanged(); }
    if (newMotorOn   != m_motorOn)   { m_motorOn   = newMotorOn;   emit motorOnChanged(); }
    if (newFollowOn  != m_followModeOn) { m_followModeOn = newFollowOn; emit followModeOnChanged(); }
    if (newElockOn   != m_electricLockOn) { m_electricLockOn = newElockOn; emit electricLockOnChanged(); }

    // 解析变焦： zoom_low + zoom_high4(bit0-3) => uint16_t, 单位 0.1 倍
    uint16_t zoomHigh = frame.zoom_high4 & 0x0F;
    uint16_t zoomVal = (zoomHigh << 8) | frame.zoom_low;
    double newZoom = zoomVal * 0.1; // 实际倍数
    if (!qFuzzyCompare(newZoom + 1.0, m_zoom + 1.0)) { // 防止浮点比较问题
        m_zoom = newZoom;
        emit zoomChanged();
    }

    // 解析角度： int16 存储为单位 0.01°
    double newPitch = static_cast<double>(frame.pitch_frame) * 0.01;
    double newYaw   = static_cast<double>(frame.yaw_frame)   * 0.01;
    if (!qFuzzyCompare(newPitch + 1.0, m_pitchDeg + 1.0)) { m_pitchDeg = newPitch; emit pitchChanged(); }
    if (!qFuzzyCompare(newYaw + 1.0, m_yawDeg + 1.0))     { m_yawDeg = newYaw; emit yawChanged(); }

    // 解析完成
    return true;
}


//======================= Radar ================================
/* DYT封装发送程序 */
void  VehicleExt::sendRadarData(cmd_radar_t radar) {

    qDebug() << " vehicleexternal.cc : Radar Data Received:"
             << "lat =" << radar.lat
             << "lon =" << radar.lon
             << "alt =" << radar.alt
             << "speed =" << radar.speed;

    if(_activeVehicle) {
        _activeVehicle->tunnelPackedSend(&radar, Type_RADAR);
        _activeVehicle->tunnelPackedSend(&radar.speed, Type_SPEED);

        qDebug() << "vehicleexternal : Radar Data Received2";

        // QByteArray data(reinterpret_cast<const char*>(&pkt), sizeof(pkt));
        // QString hexStr;
        // for (unsigned char ch : data)
        //     hexStr += QString("%1 ").arg(ch, 2, 16, QLatin1Char('0')).toUpper();

        // qDebug().noquote() << "pkt raw bytes:" << hexStr.trimmed();
        qDebug() << QString(" vehicleexternal: Type_RADAR") << m_radarCount;

        // 数据计数
        m_radarCount++;
        emit radarCountChanged();

        // 转成可读字符串
        // QString line = QString("NO.%1  lat:%2  lon:%3  alt:%4\n")
        QString line = QString("lat:%1  lon:%2  alt:%3  speed:%4\n")
                // .arg(m_radarCount)
                .arg(radar.lat / 1e7, 0, 'f', 7)
                .arg(radar.lon / 1e7, 0, 'f', 7)
                .arg(radar.alt)
                .arg(radar.speed / 100.0, 0, 'f', 2);

        // 累加写入
        emit radarLineReady(line);

    }
    else {
        qDebug() << QString("Vehicle is null");
    }
}

void  VehicleExt::setRadarCount(int count){

    m_radarCount = count;
    emit radarCountChanged();
}


/* DYT封装发送程序 */
void  VehicleExt::statusSendToVehicle(int cmdType) {


    if(_activeVehicle) {
        _activeVehicle->tunnelPackedSend(&cmdType, Type_STATUS);

        // QByteArray data(reinterpret_cast<const char*>(&pkt), sizeof(pkt));

        // QString hexStr;
        // for (unsigned char ch : data)
        //     hexStr += QString("%1 ").arg(ch, 2, 16, QLatin1Char('0')).toUpper();

        // qDebug().noquote() << "pkt raw bytes:" << hexStr.trimmed();
        // qDebug() << QString("tunnelPackedSend");

    }
    else {
        qDebug() << QString("Vehicle is null");
    }
}


//====================== YX ================================//
/* YX封装发送程序
 *
 * 第一个参数，1：查询  2：命令
 * 第二个参数，0，      1,          2,      3,     4，      5
 *                 手动查询、  自检查询，  一保查询、二保查询
 *                            自检指令   一保解除、二保解除、 发火
 */

/* YX 解析程序 */
void VehicleExt::yxDecode (yx_wu_result_t& yxRcv) {
    qDebug() <<QString("\r\n[YX_SYATE]： %1").arg(_yxstatus);
//    qDebug() << QString("yxRcv.self_check_state: %1").arg(yxRcv.self_check_state);

    _queryAck = false;
    if(yxRcv.self_check_state) {
        qDebug() << QString("0x01成功接收到指令!");
        _queryAck = true;
        emit queryChanged(_queryAck);

        if(yxRcv.selfcheck_cmd_state) {
            qDebug() << QString("0x02自检通过！");
            _yxstatus = STATE_SELFCHECK;
            //zhz 补充YX状态 20231012
            //zhz 修改YX状态已验证204YX
            if(yxRcv.first_cmd_get_state) {
                qDebug() << QString("0x03一保指令已收到！");
                _yxstatus = STATE_FIRST_PEOTECT_cmd;

                if(yxRcv.second_cmd_get_state || yxRcv.first_safe_release_state ||  yxRcv.second_safe_release_state)
                {
                    if(yxRcv.first_safe_release_state) {
                        qDebug() << QString("0x05一保已解除！");
                        _yxstatus = STATE_FIRST_PEOTECT;
                        emit yxstatusChanged(_yxstatus);
                    }

                    if(yxRcv.second_cmd_get_state ){
                        qDebug() << QString("0x04二保指令已收到！");
                        _yxstatus = STATE_SECOND_PEOTECT_cmd;
                        emit yxstatusChanged(_yxstatus);
                    }

                    if(yxRcv.second_safe_release_state) {
                        qDebug() << QString("0x06二保已解除！");
                        _yxstatus = STATE_SECOND_PEOTECT;
                        emit yxstatusChanged(_yxstatus);

                        if(yxRcv.detonated_cmd_state) {
                            qDebug() << QString("0x07起爆指令已收到！");
                            _yxstatus = STATE_FIRE;
                            emit yxstatusChanged(_yxstatus);
                        }
                    }
                }
            }
            emit yxstatusChanged(_yxstatus);
        }
    }
}

void VehicleExt::setYxstatus(YX_Status status)
{
    _yxstatus = status;
    emit yxstatusChanged(_yxstatus);
}


//====================== 移动目标状态 ================================//
//接收解析
void VehicleExt::targetStateDecode (targetState_Rcv_t& ts_rcv_t) {

    _tsValues.clear();

    //1-1 状态
    _tsEnum = static_cast<TargetStatusEnum>(ts_rcv_t.status);
    _tsValues.append(ts_rcv_t.status);

    /// 1-2~2~4 经纬高
    //更新经纬度, 目标点，显示在地图上
    if(ts_rcv_t.lat == 0.0 || ts_rcv_t.lng == 0.0) {
//        _tsPosition.setLatitude(28.197539);
//        _tsPosition.setLongitude(112.903970);
        ///--如果没有收到目标经纬度则定位在无人机上
        Vehicle* activeVehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
        if (activeVehicle) {
            _tsPosition = activeVehicle->coordinate();//homePosition();
        }
        else {
            _tsPosition.setLatitude(0.0);
            _tsPosition.setLongitude(0.0);
            _tsPosition.setAltitude(0.0);
        }
    }
    else {
        QGeoCoordinate newPosition(ts_rcv_t.lat, ts_rcv_t.lng, ts_rcv_t.alt);
        _tsPosition = newPosition;
    }

    tsPositionChanged(_tsPosition);

    ///--QString::number xx转字符串
    /// 经纬高
    _tsValues.append(QString::number(ts_rcv_t.lat, 'f', 7));
    _tsValues.append(QString::number(ts_rcv_t.lng, 'f', 7));
    _tsValues.append(QString::number(ts_rcv_t.alt, 'f', 2));

//    _tsValues.append(QString::number(ts_rcv_t.x_vel, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.y_vel, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.z_vel, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.distance, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.yaw_to_target, 'f', 1));

//    _tsValues.append(QString::number(ts_rcv_t.follow_init_distance, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.attact_speed, 'f', 1));

    /// 2-5 最大攻击速度
//    _tsValues.append(QString::number(ts_rcv_t.kp_attack, 'f', 1));
    _tsValues.append(QString::number(ts_rcv_t.max_attack_speed, 'f', 1));
//    _tsValues.append(QString::number(ts_rcv_t.wp_index_now));
    //start_cch_20230225
//    _tsValues.append(ts_rcv_t.autoStrike);

    /// 2-6 俯仰框架角 改俯仰惯性角 //start_cch_20240104
    _tsValues.append(_inertiaAngle.at(0));

    /// 2-7 激光测距信息
    _tsValues.append(QString::number(_laserRanging, 'f', 2));

    ///第二列
    /// 2-1yx状态
    _tsValues.append(getYXStatusString(_yxstatus));
    ///
    /// 2-2~2-4 xyz距离
    _tsValues.append(QString::number(ts_rcv_t.del_x, 'f', 1));
    _tsValues.append(QString::number(ts_rcv_t.del_y, 'f', 1));
    _tsValues.append(QString::number(ts_rcv_t.del_z, 'f', 1));

    ///2-5 最大攻击加速度
    _tsValues.append(QString::number(ts_rcv_t.max_attack_acc_speed, 'f', 1));

    //2-6 横滚框架角
    _tsValues.append(_inertiaAngle.at(1));
//    _tsValues.append(ts_rcv_t.attack_from_head);
//    _tsValues.append(ts_rcv_t.launch_compelted);
//    _tsValues.append(ts_rcv_t.auto_run_waypoint);

    _tsValues.append(QString::number(ts_rcv_t.kp_attack, 'f', 1));

    _tsSITL =  ts_rcv_t.use_sitl_pos;
    //start_cch_20240106 新增
    if(_tsSITL) {
        _tsValues.append("惯性角解算");
    }
    else {
        _tsValues.append("框架角解算");
    }

    emit tsValuesChanged(_tsValues);
}

/*
    STATE_NUll = 0,
    STATE_QUERY ,  //查询
    STATE_SELFCHECK  ,
    STATE_FIRST_PEOTECT_cmd, //指令
    STATE_FIRST_PEOTECT,
    STATE_SECOND_PEOTECT_cmd,
    STATE_SECOND_PEOTECT,
    STATE_FIRE
*/

QString VehicleExt::getYXStatusString(YX_Status status) {

    switch (status) {
        case STATE_QUERY:
            return  "查询";
        case STATE_SELFCHECK:
            return  "自检";
        case STATE_FIRST_PEOTECT_cmd:
            return  "一保指令已收到";
        case STATE_FIRST_PEOTECT:
            return  "一保已解除";
        case STATE_SECOND_PEOTECT_cmd:
            return  "二保指令已收到";
        case STATE_SECOND_PEOTECT:
            return  "二保已解除";
        case STATE_FIRE:
            return  "发火";
        default:
            return "Null";
    }
}

/*====================== 版本显示 ================================*/
void VehicleExt::rwbVsDecode (QString & info) {
    _rwbVs = info;
    emit rwbVsChanged(_rwbVs);
}


void VehicleExt::rcMoveChanged(int value10, int value11, int value12)
{

    static bool cnt11_1 = false;
    //按键触发10
    if (value11 >1700 && value11 < 2000) {
        if(!cnt11_1) {
            cnt11_1 = true;
            emit settingExpandChanged();
        }
    }
    else {
        cnt11_1 = false;
    }

    float minSpeed = 3;
    float maxSpeed = 12;
    float fieldSpeed = maxSpeed - minSpeed;

    float minRc = 1000;
    float maxRc = 2000;
    float fieldRc = maxRc - minRc;
    //映射速度
    float setSpeed = 0;
    setSpeed =  (value12 - minRc) * fieldSpeed / fieldRc  + minSpeed ;
    int setSpeedInt = static_cast<int>(setSpeed * 10) ;
    if( setSpeedInt / 5 ==0 ) { //证明是3 3.5 4 4.5
        //设置速度 controller.getParameterFact(-1, guid_vel_dn_z)
        //[待测试]
        emit changeSpeed(setSpeed);

    }
}

void VehicleExt::rcSpeedChanged(int value)
{

}


void VehicleExt::ekfStatusDecode(mavlink_ekf_status_report_t   status_struct) {

    _status.clear();

    //1-1 状态
    _status.append(QString::number(status_struct.velocity_variance, 'f', 2));

    _status.append(QString::number(status_struct.pos_horiz_variance, 'f', 2));

    _status.append(QString::number(status_struct.pos_vert_variance, 'f', 2));

    _status.append(QString::number(status_struct.compass_variance, 'f', 2));

    _status.append(QString::number(status_struct.terrain_alt_variance, 'f', 2));

    _flags = status_struct.flags;

    emit statusChanged(_status);

}

QStringList  VehicleExt::getStatusName(void) {
    QStringList lists = { "Velocity",  "Position H",  "Positon V",  "Compass",  "Terrain"};
//    qDebug() << lists;
    return lists;
}


//===================== 飞行状态 ========================
VehicleExt::FlyState VehicleExt::flyState() const
{
    return _flyState;
}

void VehicleExt::setFlyState(FlyState state)
{
    if (_flyState == state)
        return;

    _flyState = state;
    emit flyStateChanged();

    qDebug() << "_flyState:" << _flyState;
}

QString VehicleExt::flyStateText() const
{
    switch (_flyState) {
    case Init:           return tr("初始化中");
    case ReadyToLaunch:  return tr("待发射");
    case TakingOff:      return tr("起飞中");
    case WaitRadar:      return tr("等待雷达数据");
    case RadarGuidance:  return tr("雷达制导中");
    // case WaitDYT:        return tr("等待DYT数据");
    case FinalGuidance:  return tr("末制导中");
    case Finished:       return tr("完成");
    default:             return tr("未知状态");
    }
}

QColor VehicleExt::flyStateColor() const
{
    switch (_flyState) {
    case Init:
        return QColor("#9E9E9E"); // 灰
    case ReadyToLaunch:
        return QColor("#00C853"); // 绿
    case TakingOff:
        return QColor("#FF9800"); // 橙
    case WaitRadar:
        return QColor("#03A9F4"); // 蓝
    case RadarGuidance:
        return QColor("#2196F3"); // 深蓝
    // case WaitDYT:
    //     return QColor("#00BCD4"); // 青
    case FinalGuidance:
        return QColor("#F44336"); // 红
    case Finished:
        return QColor("#607D8B"); // 蓝灰
    default:
        return QColor("white");
    }
}

