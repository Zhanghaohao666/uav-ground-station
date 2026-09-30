#ifndef LoeManage_H
#define LoeManage_H

#include "protocoltypes.h"
#include <QGeoCoordinate>

#include <QObject>
#include "QGCToolbox.h"
#include <qtimer.h>
#include <QMetaEnum>
#include <QtNetwork>
#include "MAVLinkProtocol.h"
#include "mqttclient.h"


class Vehicle;

class VehicleExt :  public QObject
{
    Q_OBJECT

public:

    VehicleExt  (Vehicle *vehicle,  QObject *parent = nullptr);

    ~VehicleExt();
    //=========================== DYT Rcv ===========================
    Q_PROPERTY(QStringList trackStatus READ trackStatus NOTIFY trackStatusChanged)
    Q_PROPERTY(bool storageOn READ storageOn NOTIFY storageOnChanged)
    Q_PROPERTY(bool motorOn READ motorOn NOTIFY motorOnChanged)
    Q_PROPERTY(bool followModeOn READ followModeOn NOTIFY followModeOnChanged)
    Q_PROPERTY(bool electricLockOn READ electricLockOn NOTIFY electricLockOnChanged)
    Q_PROPERTY(double zoom READ zoom NOTIFY zoomChanged)          // 倍数（如 5.0）
    Q_PROPERTY(double pitchDeg READ pitchDeg NOTIFY pitchChanged) // 单位：度
    Q_PROPERTY(double yawDeg READ yawDeg NOTIFY yawChanged)       // 单位：度

    // 属性读取
    QStringList trackStatus() const { return m_trackStatus; }
    bool storageOn() const { return m_storageOn; }
    bool motorOn() const { return m_motorOn; }
    bool followModeOn() const { return m_followModeOn; }
    bool electricLockOn() const { return m_electricLockOn; }
    double zoom() const { return m_zoom; }
    double pitchDeg() const { return m_pitchDeg; }
    double yawDeg() const { return m_yawDeg; }

    // 解析函数：传入收到的原始字节（至少32字节），若帧有效则解析并更新属性
    Q_INVOKABLE bool parseFrame(const dyt_recv_frame_t &data);

    //=========================== Radar ===========================

    Q_PROPERTY(MqttClient* mqtt READ mqtt CONSTANT)
    // Q_PROPERTY(bool mqttForward READ mqttForward WRITE setMqttForward NOTIFY mqttForwardChanged)
    Q_PROPERTY(int radarCount READ radarCount WRITE setRadarCount NOTIFY radarCountChanged)

    MqttClient* mqtt() const { return _mqtt; }
    bool mqttForward() const { return _mqttForward; }
    // void setMqttForward(bool enabled);
    void  setRadarCount(int count);
    int radarCount() const { return m_radarCount; }


    //------------------------- Other -------------------------------//


    //自锁状态状态
    Q_PROPERTY(bool  disarmed           READ disarmed        NOTIFY disarmedChanged)
    bool disarmed() const {return _disarmed; }
    Q_PROPERTY(bool  discern           READ discern         NOTIFY discernChanged)
    bool discern() const {return _discern; }

    //目标解锁
    Q_PROPERTY(bool    targetArmed           READ targetArmed        NOTIFY targetArmedChanged)
    bool targetArmed() const {return _targetArmed; }

    //1-2波门
    Q_PROPERTY(QStringList   waveDoor     READ waveDoor    NOTIFY waveDoorChanged)
    QStringList waveDoor() const {return _waveDoor; }

    //2-1框架角度
    Q_PROPERTY(QStringList   frameAngle     READ frameAngle    NOTIFY frameAngleChanged)
    QStringList frameAngle() const {return _frameAngle; }

    //2-2框架速度
    Q_PROPERTY(QStringList   frameSpeed     READ frameSpeed    NOTIFY frameSpeedChanged)
    QStringList frameSpeed() const {return _frameSpeed; }

    //2-3 激光测距信息
    Q_PROPERTY(qreal   laserRanging     READ laserRanging         NOTIFY laserRangingChanged)
    qreal laserRanging() const {return _laserRanging; }

    //2-4 目标1失调角
    Q_PROPERTY(QStringList   misAngle     READ misAngle         NOTIFY misAngleChanged)
    QStringList misAngle() const {return _misAngle; }

    //2-5 产品信息
    Q_PROPERTY(QStringList   dytInfo     READ dytInfo    NOTIFY dytInfoChanged)
    QStringList dytInfo() const {return _dytInfo; }

    //2-6 惯性角度
    Q_PROPERTY(QStringList   inertiaAngle     READ inertiaAngle    NOTIFY inertiaAngleChanged)
    QStringList inertiaAngle() const {return _inertiaAngle; }

    //--接收： 导引头解析，vehicle调用
    //--接收： YX解析，vehicle调用
    //------------------------ dyt send --------------------
    Q_PROPERTY(QStringList trackingModes READ trackingModes CONSTANT)
    Q_PROPERTY(int currentTrackingMode READ currentTrackingMode WRITE setCurrentTrackingMode NOTIFY currentTrackingModeChanged)

    QStringList trackingModes() const {
        return {"自适应", "人员", "车辆", "建筑"};
    }
    int currentTrackingMode() const { return m_trackingMode; }
    void setCurrentTrackingMode(int mode);

    //初始化DYT接收
    void initDytState(void);


    //----------------------- targetStatus --------------------------------------//
    //targetStatus = ts 目标状态值
    Q_PROPERTY(QVariantList tsValues    READ tsValues   NOTIFY tsValuesChanged)
    QVariantList tsValues() const { return _tsValues; }

    //目标状态名
    Q_PROPERTY(QVariantList tsNames    READ tsNames   NOTIFY tsNamesChanged)
    QVariantList tsNames() const { return _tsNames; }

    //目标单位
    Q_PROPERTY(QVariantList tsUnits    READ tsUnits   NOTIFY tsUnitsChanged)
    QVariantList tsUnits() const { return _tsUnits; }

    //目标经纬度
    Q_PROPERTY(QGeoCoordinate tsPosition  READ tsPosition  NOTIFY tsPositionChanged)
    QGeoCoordinate tsPosition() const { return _tsPosition; }

    void yxDecode (yx_wu_result_t& yxRcv);
    //--接收：目标状态解析，vehicle调用
    void targetStateDecode (targetState_Rcv_t& ts_rcv_t);
    //--接收：目标状态信息提示解析，vehicle调用
    void targetStateInfoDecode (QString & info);
    //--接收：版本信息打印
    void rwbVsDecode (QString & info);


    enum TargetStatusEnum {
        TS_WAIT = 0,
        TS_WAYPIONT,
        TS_FOLLOW,
        TS_ATTACK,
        TS_FIRE
    };
    Q_ENUMS(TargetStatusEnum)

    //**************************** YX *******************************//
    enum YX_Status
    {
        STATE_NUll = 0,
        STATE_QUERY ,  //查询
        STATE_SELFCHECK  ,
        STATE_FIRST_PEOTECT_cmd, //指令
        STATE_FIRST_PEOTECT,
        STATE_SECOND_PEOTECT_cmd,
        STATE_SECOND_PEOTECT,
        STATE_FIRE
    };
    Q_ENUMS(YX_Status)

    Q_PROPERTY(YX_Status    yxstatus     READ yxstatus      WRITE setYxstatus    NOTIFY yxstatusChanged)
    YX_Status   yxstatus          () { return _yxstatus; }
    void setYxstatus    (YX_Status status);

    ///test query
    Q_PROPERTY(bool    query     READ query      NOTIFY queryChanged)
    bool   query          () { return _queryAck; }

    QString getYXStatusString(YX_Status status);

    //----------------------- 版本号打印 --------------------------------------//
    //targetStatus = ts 目标状态值
    Q_PROPERTY(QString rwbVs    READ rwbVs   NOTIFY rwbVsChanged)
    QString rwbVs() const { return _rwbVs; }

    //----------------------- 导引头版本号处理 --------------------------------------//
    Q_PROPERTY(QString dytVsImage    READ dytVsImage   NOTIFY dytVsImageChanged)
    QString dytVsImage() const { return _dytVsImage; }

    Q_PROPERTY(QString dytVsServo    READ dytVsServo   NOTIFY dytVsServoChanged)
    QString dytVsServo() const { return _dytVsServo; }

    Q_INVOKABLE void rcMoveChanged(int value10, int value11, int value12);

    Q_INVOKABLE void rcSpeedChanged(int value);

    ///--ekf
    Q_PROPERTY(QStringList  status           READ status        NOTIFY statusChanged)
    QStringList status() const {return _status; }
    Q_PROPERTY(quint16  flags      READ flags        NOTIFY flagsChanged)
    quint16 flags() const {return _flags; }
    //解析 estimator mavlink 飞控调用
    void ekfStatusDecode(mavlink_ekf_status_report_t status);
    Q_INVOKABLE QStringList getStatusName(void);

    //============== 工具函数 ===============================
    QString algorithmName(uint8_t bits54) ;
    uint8_t calcChecksum(const void *data, size_t length);
    Q_INVOKABLE void  sendToDYT(int cmdType, int x , int y , int zoom );

    //===================== 飞行状态 ========================
    // 飞行状态枚举
    enum FlyState {
        Init            = 0, // 初始化中
        ReadyToLaunch   = 1, // 待发射
        TakingOff       = 2, // 起飞中
        WaitRadar       = 3, // 等待雷达数据
        RadarGuidance   = 4, // 雷达制导中
        // WaitDYT         = 5, // 等待DYT数据
        FinalGuidance   = 5, // 末制导中
        Finished        = 6  // 完成
    };
    Q_ENUM(FlyState)
    //当前飞行状态（给 QML 用）====================
    Q_PROPERTY(FlyState flyState READ flyState WRITE setFlyState NOTIFY flyStateChanged)
    Q_PROPERTY(QString flyStateText READ flyStateText NOTIFY flyStateChanged)
    Q_PROPERTY(QColor  flyStateColor READ flyStateColor NOTIFY flyStateChanged)

    FlyState flyState() const;
    void setFlyState(FlyState state);
    QString flyStateText() const;
    QColor  flyStateColor() const;

    Q_INVOKABLE void  statusSendToVehicle(int cmdType);


signals:
    //=========================== dyt rcv ===========================
    void trackStatusChanged();
    void storageOnChanged();
    void motorOnChanged();
    void followModeOnChanged();
    void electricLockOnChanged();
    void zoomChanged();
    void pitchChanged();
    void yawChanged();

    void currentTrackingModeChanged();

    //=========================== radar ===========================
    void mqttForwardChanged();
    void radarCountChanged();
    // 每条日志行（仅该行）发给 QML
    void radarLineReady(const QString &line);

    //=========================== other ===========================
    void disarmedChanged(bool disarmed);            //框架电解锁状态
    void discernChanged(bool discern);              //识别状态
    void targetArmedChanged(bool discern);          //目标解锁
    void waveDoorChanged(QStringList wave);
    void frameAngleChanged(QStringList angle);
    void inertiaAngleChanged(QStringList angle);
    void frameSpeedChanged(QStringList speed);
    void misAngleChanged(QStringList misAngle);
    void dytInfoChanged(QStringList info);
    void laserRangingChanged(qreal laser);
    void tsValuesChanged(QVariantList ts);
    void tsNamesChanged(QVariantList ts);
    void tsUnitsChanged(QVariantList ts);
    void tsPositionChanged(QGeoCoordinate cor);
    void yxstatusChanged(YX_Status yxstatus);
    //YX:
    void queryChanged(bool query);
    void selfcheckChanged(bool selfcheck);
    void rwbVsChanged(QString ts);
    void dytVsImageChanged(QString vs);
    void dytVsServoChanged(QString vs);
    //EXPAND
    void settingExpandChanged();

    //ekf
    void statusChanged(QStringList list);
    void flagsChanged();

    //speed
    void changeSpeed(float value);

    //===================== 飞行状态 ========================
    void flyStateChanged();


public slots:
    void sendRadarData(cmd_radar_t radar);  // ⭐ 槽函数

private:
    //------------------------- DYT RCV ------------------------------
    Vehicle*    _activeVehicle;

    // stored
    QStringList m_trackStatus;
    bool m_storageOn;
    bool m_motorOn;
    bool m_followModeOn;
    bool m_electricLockOn;
    double m_zoom;
    double m_pitchDeg;
    double m_yawDeg;

    int m_trackingMode = 0;  // 0: 自适应, 1: 人员, 2: 车辆, 3: 建筑

    //------------------------- Radar -----------------------------
    MqttClient *_mqtt = nullptr;
    bool _mqttForward { true };
    int m_radarCount = 0;

    //
    bool _disarmed = false;    //自锁状态  _armed true 锁定状态   false  解锁状态 disarmed
    bool _discern = false;     //识别
    bool _targetArmed = false;

    QStringList _waveDoor;
    QStringList _frameAngle;
    QStringList _inertiaAngle;
    QStringList _frameSpeed;
    qreal _laserRanging;
    QStringList _misAngle;
    QStringList _dytInfo;

    QVariantList _tsValues;
    QVariantList _tsNames;
    QVariantList _tsUnits;

    //默认为dyt模式
    bool _tsSITL = true;
    int  _tsEnum = TS_WAIT;

    QGeoCoordinate _tsPosition ;

    QString _rwbVs = "RMB_VERSION";          //任务板版本号
    QString _dytVsImage = "DYT_I_VERSION";  //导引头图像版本号
    QString _dytVsServo = "DYT_S_VERSION";  //导引头伺服版本号

    const QString _n1C = "#01F2B0";  //n=normal c=color 1=one  2=two
    const QString _n2C = "#FFFFCE";
    const QString _n3C = "red";

    YX_Status  _yxstatus = STATE_NUll; //状态
    bool       _query = false;
    bool       _queryAck = false;
    bool       _selfcheckAck = false;
    bool       _firstprotectAck = false;
    bool       _secondprotectAck = false;

    QStringList _status;
    quint16                 _flags = 0;
    QVariantList _statusNames;


    //===================== 飞行状态 ========================
    FlyState _flyState = Init;

};

#endif
