#ifndef FeiYuCtr_H
#define FeiYuCtr_H

#include <QObject>
#include "QmlObjectListModel.h"
#include "CcTcpClient.h"
#include "SanHangStruct.h"
#include "DetectInfo.h"
#include "TrackInfo.h"
#include "DevInfo.h"
#include <QDateTime>

class FeiYuCtr : public TCPController
{
    Q_OBJECT

public:
    FeiYuCtr(QObject *parent = nullptr);
    ~FeiYuCtr();

    void initDytState(void);

    int sanhang_parse_char(unsigned char char_d, SANHANG_MSG& msg);
    unsigned short crcCount(char *buff, int len);

    //--0xB6 检测消息
    Q_PROPERTY(QmlObjectListModel*  detectInfos      READ detectInfos   NOTIFY detectInfosChanged)
    QmlObjectListModel*     detectInfos (void) { return &_detectInfos ;}

    //--0xB7 跟踪消息
    Q_PROPERTY(TrackInfo *trackInfo    READ trackInfo   NOTIFY trackInfoChanged)
    TrackInfo *trackInfo() const { return _trackInfo; }

    Q_PROPERTY(bool   haveTrack       READ haveTrack    WRITE setHaveTrack       NOTIFY haveTrackChanged)
    bool haveTrack() const { return _haveTrack; }
    void setHaveTrack(bool track) { _haveTrack = track ; }
    //********************发送***************************
//    Q_INVOKABLE int query_device();
    Q_INVOKABLE int set_ptz(unsigned char moveType, unsigned char direction, unsigned short angle, unsigned char speed);
    Q_INVOKABLE int set_detect_model(unsigned char devno,
                                     unsigned char box_flag,
                                     unsigned char output_parameters_flag);
    Q_INVOKABLE int set_track_mode(unsigned char _devno, unsigned char ptz_track_flag, unsigned char tar_class, unsigned short xMin, unsigned short yMin, unsigned short box_w, unsigned short box_h, unsigned short img_w, unsigned short img_h);
    Q_INVOKABLE void send_TV_guidance(unsigned short xMin, unsigned short yMin, unsigned short box_w, unsigned short box_h, unsigned short img_w, unsigned short img_h);
//    Q_INVOKABLE int send_gpsinfo(long lng, long lat, long alt, long yaw, long pitch, long roll);
    Q_INVOKABLE int set_move(unsigned char move_yaw_flag,   unsigned short yaw,     unsigned char yaw_speed,
                           unsigned char move_pitch_flag, unsigned short pitch,  unsigned char pitch_speed,
                           unsigned char move_roll_flag,  unsigned short roll,   unsigned char roll_speed);

    // qiwei导引头专用
    Q_INVOKABLE void dytPackedXY( short trackMode,  short centerFullX,  short centerFullY,  short rectFullW,  short rectFullH, int control_command);

    Q_INVOKABLE void startVideoRecord(bool flag);
    Q_INVOKABLE void ptzDownwards(int flag);
    Q_INVOKABLE void ptzControl(int flag);
    Q_INVOKABLE void obstacleSetting(int flag);
    Q_INVOKABLE void target_tracking(int flag, int type, int kongyu_height);

    Q_PROPERTY(int   ptzstate       READ ptzstate           NOTIFY ptzstateChanged)
    int ptzstate() const { return _ptzstate; }

    Q_PROPERTY(int   mavstate       READ mavstate           NOTIFY mavstateChanged)
    int mavstate() const { return _mavstate; }

    Q_PROPERTY(int   taskstate       READ taskstate           NOTIFY taskstateChanged)
    int taskstate() const { return _taskstate; }

    Q_PROPERTY(QString   gitverstate       READ gitverstate           NOTIFY gitverChanged)
    QString gitverstate() const { return _rwb_git_ver; }

    Q_PROPERTY(QString   gitIdstate       READ gitIdstate           NOTIFY gitIdChanged)
    QString gitIdstate() const { return _rwb_git_id; }

    Q_INVOKABLE QString getGitId(void);
    Q_INVOKABLE QString getGitVer(void);

    //不报错，与 SanHangCtr.h 一致
//    Q_PROPERTY(short gimbalPitch    READ gimbalPitch   NOTIFY gimbalPitchChanged)
//    short gimbalPitch() const { return _gimbalPitch; }
    Q_PROPERTY(short gimbalRoll    READ gimbalRoll   NOTIFY gimbalRollChanged)
    short gimbalRoll() const { return _gimbalRoll; }

    Q_INVOKABLE void target_recognition(int flag);

signals:
    void detectInfosChanged(QmlObjectListModel *detectInfo);
    void trackInfoChanged(TrackInfo *trackInfo);
    void ptzstateChanged(int ptzstate);
    void mavstateChanged(int mavstate);
    void taskstateChanged(int taskstate);
    // 任务板ID和任务板版本
    void gitverChanged(QString gitverstate);
    void gitIdChanged(QString gitIdstate);


    void haveTrackChanged(bool track);
    //不报错，与 SanHangCtr.h 一致
//    void gimbalPitchChanged(short gimbalPitch);
    void gimbalRollChanged(short gimbalRoll);
    void showTrack();
    void notShowTrack();
    void showHitPointsTrack(unsigned short score);
    void notShowHitPointsTrack();
    void changex_y_w(float x, float y, float w, float h);
    void screenshot(int type);

    /* ===start 光流点需求=== */
    void redraw_node();
    void optical_flow_info(float x, float y, float position_N, float position_E, int direction, int times, float healthy);
    /* ===end=== */

    /* ===start 检测框需求=== */
    void detectBox_info(float x, float y, float w, float h, int i, int confidence, int img_w, int img_h);
    void redraw_detect_node();
    /* ===end=== */

    /* ===start 屏幕显示状态需求=== */
    void state_info(int state);  //
    void state1_info(int state); // 自检状态
    /* ===end=== */

    /* ===start 班工要求添加的监控sgvins光流开关状态 === */
    void vins_state(int state);  //
    /* ===end=== */

    /* 地面站86消息，只要经纬度*/
    void message_86_info(unsigned int lat_int, unsigned int lon_int);

private slots:
    void ReceiveParseCtr( QByteArray buf);
    void timerEvent();  //测试用
    void changeX_Y_W();

private:
    int _devinfo_process(SANHANG_MSG msg);
    int _baseinfo_process(SANHANG_MSG msg);
    int _detectinfo_process(SANHANG_MSG msg);
    int _trackinfo_process(SANHANG_MSG msg);
    int _rwbInfo_process(SANHANG_MSG msg);
    int _bouncing_point(SANHANG_MSG msg);
    int _hitPointsTrack(SANHANG_MSG msg);
    void _optical_flow_inf_process(SANHANG_MSG msg);

    //**********************接收***************************
    SANHANG_MSG _msg;                       //消息
    SANHANG_PRO_STATE _pro_state;           //状态
    SKYNODE_GND_BASEINFO_S _base_info;      //设备信息
    SKYNODE_GND_TRACKINFO_S _track_st;      //0xB6跟踪信息
    SKYNODE_GND_UAV_STATE_S _uav_state_st;  //0xB6跟踪信息
    hitpoints _hitpoints;  // 弹着点
    detonationpoint _detonationpoint;  // 起爆点
    SendTo_GND_Optical_Flow_Inf  optical_flow_inf; // 光流点信息


    GND_SKYNODE_SETDETECTMODE_S _set_detect_mode_s;  //0xA3设置检测模式
    SgTaskDetectBox *detectBox;   // 跟踪框  多个
    SgTaskSubstate  *state;       // 状态，显示在屏幕上
    SgTaskSubstate  *state1;       // 自检状态，显示在屏幕上
    set_position_target_global_int_t message_86;  // 地面站发来的86消息

    //***********************UI 相关**************************
    //0xB5基础信息
    QVariantList        _baseValue;
    short               _gimbalPitch = 0;
    QVariantList        _baseZoom;
    QVariantList        _baseName;
    QVariantList        _baseUnit;
    int                _trackMode;
    QmlObjectListModel  _detectInfos;        //识别信息
    QmlObjectListModel  _devInfos;           //设备消息
    int                 _data_index;
    TrackInfo*          _trackInfo = nullptr;

    //start_cch_20230315 修改 需要全局的变量
    GND_SKYNODE_PTZ_S           _ptzMsg;
    GND_SKYNODE_SETTRACKMODE_S  _trackMsg;
    GND_SKYNODE_SETMOVE_S       _setmoveMsg;
    SendTo_SGTASK_QIWEI_INFO    _sendto_sgtask_qiwei_info;


    unsigned char _devno = 0x55;
    bool _targetClass = true;

    QString    _rwb_git_id   = "Unknown";
    QString    _rwb_git_ver  = "Unknown";

    int _ptzstate = -2;
    int _mavstate = -1;
    int _taskstate = -1;

    bool _haveTrack = false;
    //不报错，与 SanHangCtr.h 一致
//    short               _gimbalPitch = 0;
    short               _gimbalRoll = 0;

    QTimer *timer;  // 定时器测试用
    int times;   // 发送次数，测试用
    bool show_track_svg;  // 20240418 跟踪svg显示用
    float x,y,w,h;  // 20240418 跟踪svg的位置测试
    float guangliu_x,guangliu_y;
    int times_hitpoints;
    QDateTime startTime;  // 20240530 计算时间间隔
    qint64 intervalTimeMS;
};
#endif
