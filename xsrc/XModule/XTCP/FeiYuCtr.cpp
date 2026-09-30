/*
    实际为拓扑联创的
*/

#include "FeiYuCtr.h"
//#include <stdio.h>
//#include <string.h>
#include <QString>




FeiYuCtr::FeiYuCtr(QObject* parent)
    : TCPController         (parent)
{
    initDytState();

    QObject::connect(tcpClient(),  &CcTcpClient::ReceiveParse, this, &FeiYuCtr::ReceiveParseCtr);

    _pro_state = SANHANG_DEFAULT;
    detectBox =  (SgTaskDetectBox *)malloc(sizeof(SgTaskDetectBox));
    state     =  (SgTaskSubstate *)malloc(sizeof(SgTaskSubstate));
    state1     =  (SgTaskSubstate *)malloc(sizeof(SgTaskSubstate));

    qDebug() << "SKYNODE_GND_TRACKINFO_SSKYNODE_GND_TRACKINFO_SSKYNODE_GND_TRACKINFO_S" << sizeof(SKYNODE_GND_TRACKINFO_S) ;
//    ///--UI相关初始化
//    // 测试显示十字svg
//    times = 0;
//    timer = new QTimer(this);
//    timer->setInterval(1000);
//    connect(timer, &QTimer::timeout, this, &FeiYuCtr::timerEvent);
//    x=1280/2-100; y=960/2-100; w=100; h=100;
//    connect(timer, &QTimer::timeout, this, &FeiYuCtr::changeX_Y_W);
//    timer->start();

}

FeiYuCtr::~FeiYuCtr(void) {

}

void FeiYuCtr::initDytState() {
    //初始化相关代码
}

void FeiYuCtr::ReceiveParseCtr(QByteArray buf) {
//    qDebug() << "收到数据!" << buf.length();

//    for(int i=0;i<buf.length();i++){
//        qDebug() << buf.at(i);
//    }

    // 班工要求添加的监控sgvins光流开关状态
    if(buf.length() == 24 && buf.at(2) == 34){
//        qDebug("buf.at(14) = %d \n", buf.at(14));
        emit vins_state(buf.at(14));
        return;
    }

    // 地面站发来的86消息
    if(buf.length() == 56){
        memset(&message_86, 0x0, sizeof(set_position_target_global_int_t));
        memcpy(&message_86, buf.data(),sizeof(set_position_target_global_int_t));
//        qDebug() << "message_86.lat_int:" << message_86.lat_int;
//        qDebug() << "message_86.lon_int:" << message_86.lon_int;
        emit message_86_info(message_86.lat_int,message_86.lon_int);
        return;
    }

    // SgTaskDetectBox 多个检测框  //TODO: 左上
    if(buf.length() == 102 ){
        memset(detectBox, 0x0, sizeof(SgTaskDetectBox));
        memcpy(detectBox, buf.data(),sizeof(SgTaskDetectBox));
        for(int i=0;i<8;i++){
            // emit detectBox_info(x,y,box_w,box_h,i, confidence)
            emit detectBox_info(detectBox->nodes[i].x, detectBox->nodes[i].y, detectBox->nodes[i].box_w, detectBox->nodes[i].box_h, i, detectBox->nodes[i].confidence, detectBox->img_w, detectBox->img_h);
        }
        emit redraw_detect_node();
    }

    //假的mavlink， 左上角状态
    if(buf.length() == 38 && buf.at(2) == 2){
//        qDebug() << "收到数据!";
        memset(state, 0x0, sizeof(SgTaskSubstate));
        memcpy(state, buf.data(),sizeof(SgTaskSubstate));
//        qDebug() << state->substate << state->value;
        if(state->substate == 1){
            emit state_info(state->value);
        }
    }

    //无
    if(buf.length() == 38 && buf.at(2) == 3){
//        qDebug() << "收到自检数据!";
        memset(state1, 0x0, sizeof(SgTaskSubstate));
        memcpy(state1, buf.data(),sizeof(SgTaskSubstate));
//        qDebug() << state1->value;
        emit state1_info(state1->value);
    }

    for (int i = 0; i < buf.length(); i++)
    {
        /* code */
        if (sanhang_parse_char(static_cast<unsigned char>(buf[i]), _msg))
        {
            /* code */
            switch (_msg.msg_head.cmd)
            {
//            case 0xB4:    /* 设备信息 */
//                _devinfo_process(_msg);
//                break;
            case 0xB5:    /* 基础信息 */
                _baseinfo_process(_msg);
                break;
            case 0xB6:    /* 检测信息 */
                _detectinfo_process(_msg);
                break;
            case 0xB7:    /* 跟踪信息 */
                _trackinfo_process(_msg);
                break;
            case 0xC1:    /* 任务板信息 */
                _rwbInfo_process(_msg);
                break;
            case 0x7B:   /* 弹着点*/
                times_hitpoints = 0;
                _bouncing_point(_msg);
                break;
            case 0xC2:   /* 光流点 */
//                qDebug("收到光流点~~~");
                _optical_flow_inf_process(_msg);
                break;
            case 0xC3:   /* 截图指令 */
                qDebug("截图！！！");
                #if defined(Q_OS_WIN)
                    emit screenshot(0);
                #elif defined(Q_OS_LINUX)
                    emit screenshot(1);
                #else
                    emit screenshot(2);
                #endif

//                _optical_flow_inf_process(_msg);
                break;
            default:
                break;
            }
            if(_msg.msg_head.cmd != 0x7B  && times_hitpoints > 100){
                emit notShowTrack();   // 100次没发就消失
            }
        }
    }
    if(times_hitpoints < 1000){
        times_hitpoints++;
//        qDebug() << "times_hitpoints:" << times_hitpoints;
    }
//    qDebug() << "times_hitpoints:" << times_hitpoints;
}

int FeiYuCtr::sanhang_parse_char(unsigned char char_d, SANHANG_MSG& msg)
{
    int ret_bool = 0;
//     printf("pro_state:%d\n", _pro_state);
    switch (_pro_state)
    {
    case SANHANG_DEFAULT:
        /* code */
        if (char_d == 0xeb) {
            /* code */
            memset(&msg, 0, sizeof(msg));
            msg.msg_head.header[0] = char_d;
            _pro_state = SANHANG_HEAD;
        }
        _data_index = 0;
        break;
    case SANHANG_HEAD:
        if (char_d == 0x90) {
            /* code */
            msg.msg_head.header[1] = char_d;
            _pro_state = SANHANG_LEN1;
        }
        else {
            _pro_state = SANHANG_DEFAULT;
        }
        break;
    case SANHANG_LEN1:
        msg.msg_head.len = char_d;
        _pro_state = SANHANG_LEN2;
        break;
    case SANHANG_LEN2:
        msg.msg_head.len |= char_d << 8;
        _pro_state = SANHANG_ID1;
        break;
    case SANHANG_ID1:
        msg.msg_head.identificationCode[0] = char_d;
        _pro_state = SANHANG_ID2;
        break;
    case SANHANG_ID2:
        msg.msg_head.identificationCode[1] = char_d;
        _pro_state = SANHANG_CMD;
        break;
    case SANHANG_CMD:
        msg.msg_head.cmd = char_d;
        _pro_state = SANHANG_DATA;
        break;
    case SANHANG_DATA:
        msg.data[_data_index] = char_d;
        _data_index++;
        if ((msg.msg_head.len - 7) == _data_index) {
            /* code */
            _pro_state = SANHANG_CRC1;
        }
        break;
    case SANHANG_CRC1:
        msg.crc = char_d;
        // printf("msg.crc1:0x%x\n", msg.crc);
        // msg.data[_data_index] = char_d;
        // printf("SANHANG_CRC1:0x%x\n", char_d);
        _pro_state = SANHANG_CRC2;
        break;
    case SANHANG_CRC2:
    {
        // printf("msg.crc21:0x%x\n", msg.crc);
        // printf("msg.len:0x%x\n", msg.msg_head.len);

        msg.crc |= ((short)char_d)<<8;
        // printf("msg.crc22:0x%x\n", msg.crc);

        // msg.data[_data_index + 1] = char_d;
        unsigned short crc = crcCount((char*)&msg + 2, (int)msg.msg_head.len - 2);
        // printf("SANHANG_CRC2:0x%x\n", char_d);
        _pro_state = SANHANG_DEFAULT;
        if (crc == msg.crc) {
            /* code */
            ret_bool = 1;
        }
        else {
//           qDebug("udp", "[cmd:%.2x]crc error!!! crcCount:%d crcData:%d\n", msg.msg_head.cmd, crc, msg.crc);           //qDebug("udp", "[cmd:%.2x]crc error!!! crcCount:%d crcData:%d\n", msg.msg_head.cmd, crc, msg.crc);
//            qDebug() << QString("[cmd:%.2x]crc error!!! crcCount:%d crcData:%d\n").arg(msg.msg_head.cmd).arg(crc).arg(msg.crc);
        }
        if (msg.msg_head.cmd == 0xb4) {
            /* code */
            ret_bool = 1;
        }
    }
        break;
    default:
        break;
    }
    return ret_bool;
}

unsigned short FeiYuCtr::crcCount(char *buff, int len)
{
    unsigned short crc = 0x0;
    unsigned short checksum =0;
    for(int i=0; i<len; i++) {
        crc += *buff++;
    }
    checksum = crc &0xff;
    return checksum;
}

//************************************接收******************************************
///4.2.1.设备信息   不一定需要显示
///4.2.2.基础信息 需要显示 0xB5返回基础信息
///4.2.2.基础信息 需要显示 0xB5返回基础信息
int FeiYuCtr::_baseinfo_process(SANHANG_MSG msg)
{
    // sgxx::log::info("udp_c", "基础信息\n");
    if (msg.msg_head.len + 2 != sizeof(SKYNODE_GND_BASEINFO_S))
    {
//        qDebug("sanhang", "struct len:%d  msg len:%d   baseinfo len error!!!\n", sizeof(SKYNODE_GND_BASEINFO_S), msg.msg_head.len + 2);
        return -1;
    }
    // baseinfo_mtx.lock();
    memcpy(&_base_info, &msg, sizeof(SKYNODE_GND_BASEINFO_S));

    _baseValue.clear();
    //1
    if(_base_info.currentMode == 0xD1) {
        _trackMode = 0;
        _baseValue.append("无");      //当前模式
    }
    else if(_base_info.currentMode == 0xD2) {
        _trackMode = 1;
        _baseValue.append("检测模式");   //当前模式
    }
    else if(_base_info.currentMode == 0xD3) {
        _trackMode = 2;
        _baseValue.append("追踪模式");
    }
//    //2 云台状态
//    _baseValue.append(_base_info.ptzStatus);   //当云台是否可控
    //3 三轴角度
    _base_info.yaw /= 100;
    _base_info.pitch /= 100;
    _base_info.roll /= 100;
    _baseValue.append(QString::number(_base_info.yaw));
    _baseValue.append(QString::number(_base_info.pitch));
    _baseValue.append(QString::number(_base_info.roll));
    _gimbalPitch = _base_info.pitch;

//    emit trackModeChanged(_trackMode);

    emit gimbalPitchChanged(_gimbalPitch);
//    emit baseValueChanged(_baseValue);

    return 0;
}

//start_cch_20240114 +++
//************************************接收******************************************
int FeiYuCtr::_rwbInfo_process(SANHANG_MSG msg)
{
//    qDebug() << QString("msg.msg_head.len: %1, %2").arg(msg.msg_head.len).arg(sizeof(SKYNODE_GND_TRACKINFO_S));
    if (msg.msg_head.len + 2 != sizeof(SKYNODE_GND_UAV_STATE_S)) {
        /* code */
        qDebug() << QString("[sanhang] rwbInfo len error!!!\n");
        return -1;
    }

    // track_mtx.lock();
//    _uav_state_st = nullptr;
    memcpy(&_uav_state_st, &msg, sizeof(SKYNODE_GND_UAV_STATE_S));
//    _trackInfo = new TrackInfo(_uav_state_st);
//    trackInfoChanged(_trackInfo);
//
    _rwb_git_id = "";
    for(int i=0; i< 8 ; i++)
    {
        _rwb_git_id +=  static_cast<char>(_uav_state_st.git_id[i]);
    }
//    qDebug() << QString("_rwb_git_id: %1").arg(_rwb_git_id);
    emit gitIdChanged(_rwb_git_id);


    _rwb_git_ver = "";
    for(int i=0; i< 16 ; i++)
    {
        _rwb_git_ver +=  static_cast<char>(_uav_state_st.git_ver[i]);
    }
//    qDebug() << QString("_rwb_git_ver: %1").arg(_rwb_git_ver);
    emit gitverChanged(_rwb_git_ver);


    _ptzstate = _uav_state_st.ptz_state;
    emit ptzstateChanged(_ptzstate);
//    qDebug() << QString("_ptzstate: %1").arg(_ptzstate);

    _mavstate = _uav_state_st.mav_state;
    emit mavstateChanged(_mavstate);
//    qDebug() << QString("_mavstate: %1").arg(_mavstate);

    _taskstate = _uav_state_st.task_state;
    emit taskstateChanged(_taskstate);
//    qDebug() << QString("_taskstate: %1").arg(_taskstate);
    return 0;
}


void FeiYuCtr::_optical_flow_inf_process(SANHANG_MSG msg){

    memcpy(&optical_flow_inf, &msg, sizeof(SendTo_GND_Optical_Flow_Inf));
//    qDebug() << "position_N:" << optical_flow_inf.position_N;
//    qDebug() << "position_E:" << optical_flow_inf.position_E;
//    qDebug() << "x0:" << optical_flow_inf.node[0].x;
//    qDebug() << "y0:" << optical_flow_inf.node[0].y;
//    qDebug() << "x1:" << optical_flow_inf.node[1].x;
//    qDebug() << "y1:" << optical_flow_inf.node[1].y;
//    qDebug() << "healthy:" << optical_flow_inf.reserve[0];


//    qDebug() << "show_optical_flow" << optical_flow_inf.show_optical_flow;
//    qDebug() << "sizeof(SendTo_GND_Optical_Flow_Inf)" << sizeof(SendTo_GND_Optical_Flow_Inf);
    if(optical_flow_inf.show_optical_flow){
        for(int i=0;i<10;i++){   // 10个点， x和y都不为0则显示
            guangliu_x = optical_flow_inf.node[i].x;
            guangliu_y = optical_flow_inf.node[i].y;
            //  optical_flow_info(unsigned short x, unsigned short y, int position_N, int position_E, int direction, int times, float healthy);
            emit optical_flow_info(guangliu_x, guangliu_y, optical_flow_inf.position_N, optical_flow_inf.position_E, optical_flow_inf.direction, i, optical_flow_inf.reserve[0]);
        }
        emit redraw_node();
    }

}


QString FeiYuCtr::getGitId(void) {
    return  _rwb_git_id;
}

QString FeiYuCtr::getGitVer(void) {
    return  _rwb_git_ver;
}


///4.2.2.检测信息 需要显示0xB6
int FeiYuCtr::_detectinfo_process(SANHANG_MSG msg)
{
//    qDebug("udp_c", "检测信息\n");
    detect_st detectinfo;
    std::vector<SKYNODE_GND_DETECTINFOS_S> boxs;
    memcpy(&detectinfo, &msg, sizeof(detect_st) - 6);
    if (detectinfo.boxLen == 0)
    {
//        qDebug("uart", "no detect tar!!!\n");
        return -1;
    }

    _detectInfos.clear();
    for (size_t i = 0; i < detectinfo.boxLen; i++)
    {
        SKYNODE_GND_DETECTINFOS_S box;

        /* code */
        memcpy(&box, (unsigned char*)&msg + sizeof(detect_st) - 6 + i * sizeof(SKYNODE_GND_DETECTINFOS_S), sizeof(SKYNODE_GND_DETECTINFOS_S));
//        boxs.push_back(box);
//        qDebug("box.confidence", box.confidence);
            DetectInfo * detectInfo = nullptr;
            detectInfo = new DetectInfo(box);
            _detectInfos.append(detectInfo);
    }
    detectInfosChanged(&_detectInfos);

//    _haveTrack = true;
//    haveTrackChanged(_haveTrack);

    return 0;
}

///4.2.4.跟踪信息 需要显示0xB7
int FeiYuCtr::_trackinfo_process(SANHANG_MSG msg)
{
//    qDebug("跟踪信息!\n");
//    qDebug() << QString("msg.msg_head.len: %1, %2").arg(msg.msg_head.len).arg(sizeof(SKYNODE_GND_TRACKINFO_S));
    if (msg.msg_head.len + 2 != sizeof(SKYNODE_GND_TRACKINFO_S)) {
        /* code */
        qDebug() << QString("[sanhang] takeinfo len error!!!\n");
        qDebug() << msg.msg_head.len;
        qDebug() << sizeof(SKYNODE_GND_TRACKINFO_S);
        return -1;
    }
    // track_mtx.lock();
    memcpy(&_track_st, &msg, sizeof(SKYNODE_GND_TRACKINFO_S));

    _trackInfo = nullptr;
    _trackInfo = new TrackInfo(_track_st);

    trackInfoChanged(_trackInfo);

//    qDebug() << "2222222" << _track_st.zoom;
//      qDebug() << "111111111" << _track_st.trackBox.session;
    return 0;
}


int FeiYuCtr::set_ptz(unsigned char moveType, unsigned char direction, unsigned short angle, unsigned char speed)
{
//    qDebug() << QString("enter set_ptz %1,%2,%3,%4").arg(moveType).arg(direction).arg(angle).arg(speed);
    _ptzMsg.head[0] = 0xeb;
    _ptzMsg.head[1] = 0x90;
    _ptzMsg.len = sizeof(GND_SKYNODE_PTZ_S) - 2;
    _ptzMsg.device_id[0] = 0x13;
    _ptzMsg.device_id[1] = 0x13;
    _ptzMsg.cmd = 0xA1;
    _ptzMsg.move_type = moveType;             //移动类型
    _ptzMsg.rotation_direction = direction;   //移动方向
    _ptzMsg.rotation_angle = angle;           //移动角度
    _ptzMsg.rotation_speed = speed;           //移动速度
    unsigned char* p;
    p = (unsigned char*)&_ptzMsg;
    _ptzMsg.crc = crcCount((char*)p + 2, sizeof(_ptzMsg) - 4);
//    sendData(p, sizeof(_ptzMsg));
    return 1;
}

int FeiYuCtr::set_detect_model(unsigned char devno,
                               unsigned char box_flag,
                               unsigned char output_parameters_flag)
{
    GND_SKYNODE_SETDETECTMODE_S msg;
    msg.head[0] = 0xeb;
    msg.head[1] = 0x90;
    msg.len = sizeof(GND_SKYNODE_SETDETECTMODE_S) - 2;
    msg.device_id[0] = 0x13;
    msg.device_id[1] = 0x13;
    msg.cmd = 0xA3;
    msg.device_index = devno;           //设备编号 01可见光 02红外光 03画中画
    msg.return_box_flag = box_flag;
    msg.output_parameters = output_parameters_flag;
    unsigned char* p;
    p = (unsigned char*)&msg;
    msg.crc = crcCount((char*)p + 2, sizeof(msg) - 4);
//    sendData(p, sizeof(msg));
    return 1;
    //return _common_pointer->send(p, sizeof(msg));
}

/***************************************************************
 *
 * 设置跟踪模式
 * ptz_track_flag          云台跟踪  0x00 否  0x01 是
 * tar_class               目标分类
 * *************************************************************/
int FeiYuCtr::set_track_mode(unsigned char _devno, unsigned char ptz_track_flag, unsigned char tar_class,
                             unsigned short xMin, unsigned short yMin,
                             unsigned short box_w, unsigned short box_h,
                             unsigned short img_w, unsigned short img_h)
{


    _trackMsg.head[0] = 0xeb;
    _trackMsg.head[1] = 0x90;
    _trackMsg.len = 18;
    _trackMsg.device_id[0] = 0x13;
    _trackMsg.device_id[1] = 0x13;
    _trackMsg.cmd = 0xA4;
    if(img_w == 1920 && img_h == 1080){
        _trackMsg.device_index = 0x1;  // 默认也是0
    }else if(img_w == 1280 && img_h == 800){
        _trackMsg.device_index = 0x2;
    }else{  //  处理1280*800 分辨率
        _trackMsg.device_index = 0x3;
    }

    _trackMsg.ptz_track_flag = ptz_track_flag;    //云台跟踪
    _trackMsg.target_class = tar_class;           // 1开始跟踪 3停止跟踪


    _trackMsg.xMin = xMin;                        //按画面比例
    _trackMsg.yMin = yMin;
    _trackMsg.xMax = box_w;
    _trackMsg.yMax = box_h;


//    qDebug() << _trackMsg.device_index << _trackMsg.xMin << _trackMsg.yMin << _trackMsg.xMax << _trackMsg.yMax;
    _trackMsg.crc = crcCount((char*)&_trackMsg + 2, sizeof(GND_SKYNODE_SETTRACKMODE_S) - 4);
//    qDebug() << "发送框选坐标！";
    if(_tcpClient->_connected){
        _tcpClient->writeData((const char*)&_trackMsg, sizeof(GND_SKYNODE_SETTRACKMODE_S));
    }

    return 1;
}


/***************************************************************
 * 4.1.4.多个轴的转动  0xA5
 * 设置检测模式
 * box_flag                 返回检测框开 关    0x00 关闭   0x01 打开
 * output_parameters_flag   是否输出参数
 * *************************************************************/
//                                    0xC3    0x00左或者上 0x01右或者下                    90                    100
int FeiYuCtr::set_move(unsigned char move_yaw_flag,   unsigned short yaw,     unsigned char yaw_speed,
                       unsigned char move_pitch_flag, unsigned short pitch,  unsigned char pitch_speed,
                       unsigned char move_roll_flag,  unsigned short roll,   unsigned char roll_speed)
{
//    qDebug() << QString("enter set_ptz %1,%2,%3,%4").arg(moveType).arg(direction).arg(angle).arg(speed);
    _setmoveMsg.head[0] = 0xeb;
    _setmoveMsg.head[1] = 0x90;
    _setmoveMsg.len = sizeof(_GND_SKYNODE_SETMOVE_S) - 2;
    _setmoveMsg.device_id[0] = 0x13;
    _setmoveMsg.device_id[1] = 0x13;
    _setmoveMsg.cmd = 0xA5;

    _setmoveMsg.move_yaw_flag = move_yaw_flag;           //0xff 右 0x00 不动  0x01左
    _setmoveMsg.yaw = yaw;                               // 移动角度
    _setmoveMsg.yaw_speed = yaw_speed;                   //

    _setmoveMsg.move_pitch_flag = move_pitch_flag;             //移动类型
    _setmoveMsg.pitch = pitch;                  //移动方向
    _setmoveMsg.pitch_speed = pitch_speed;

    _setmoveMsg.move_roll_flag = move_roll_flag;             //移动类型
    _setmoveMsg.roll = roll;                                    //移动方向
    _setmoveMsg.roll_speed = roll_speed;
    unsigned char* p;
    p = (unsigned char*)&_setmoveMsg;
    _setmoveMsg.crc = crcCount((char*)p + 2, sizeof(_setmoveMsg) - 4);
//    sendData(p, sizeof(_setmoveMsg));
    return 1;
}

int FeiYuCtr::_bouncing_point(SANHANG_MSG msg){

    if (msg.msg_head.len + 2 != sizeof(hitpoints)) {
        /* code */
        qDebug() << QString("[sanhang] takeinfo len error!!!\n");
        return -1;
    }

    memcpy(&_hitpoints, &msg, sizeof(hitpoints));
//    x = _hitpoints.x*1280-25;  // 归一化后恢复1920尺寸
//    y = _hitpoints.y*720-25 + 40;

    x = _hitpoints.x;
    y = _hitpoints.y;

//    qDebug() << _hitpoints.x ;
//    qDebug() << _hitpoints.y ;
//    qDebug() << x ;
//    qDebug() << y ;

    w = 50;
    h = 50;
    emit changex_y_w(x,y,w,h);
    if(_hitpoints.classId == 123){
        emit showTrack();
    } else if(_hitpoints.classId == 124){
        emit showHitPointsTrack(0);
    }

//    qDebug() << "_hitpoints.classId:" << _hitpoints.classId;
//    qDebug() << "x y w h:" << x << y << w << h;
    return 1;
}

int FeiYuCtr::_hitPointsTrack(SANHANG_MSG msg){

    if (msg.msg_head.len + 2 != sizeof(detonationpoint)) {
        /* code */
        qDebug() << QString("[sanhang] takeinfo len error!!!\n");
        return -1;
    }

    memcpy(&_detonationpoint, &msg, sizeof(detonationpoint));
    emit showTrack();
    x = _detonationpoint.x;
    y = _detonationpoint.y;
    w = _detonationpoint.width;
    h = _detonationpoint.height;
    emit changex_y_w(x,y,w,h);
    emit showHitPointsTrack(_detonationpoint.score);
//    qDebug() << "x y w h:" << x << y << w << h;
    return 1;
}

void FeiYuCtr::timerEvent()
{
//    // 在定时器事件中执行的任务
//    qDebug() << "times:" << times;
//    times++;
//    if(times/10%2){
//        emit showTrack();
//    }else{
//        emit notShowTrack();
//        emit showHitPointsTrack(0);
//    }
    #if defined(Q_OS_WIN)
        emit screenshot(0);
    #elif defined(Q_OS_LINUX)
        emit screenshot(1);
    #else
        emit screenshot(2);
    #endif
}

void FeiYuCtr::changeX_Y_W(){
    x++; y++; w++; h++;
    emit changex_y_w(x,y,w,h);
}

// //发送电视制导给地面站节点
// send_TV_guidance(unsigned short xMin, unsigned short yMin, unsigned short box_w, unsigned short box_h, unsigned short img_w, unsigned short img_h);
void FeiYuCtr::send_TV_guidance(unsigned short xMin, unsigned short yMin, unsigned short box_w, unsigned short box_h, unsigned short img_w, unsigned short img_h){
    memset(&_trackMsg, 0x0, sizeof(GND_SKYNODE_SETTRACKMODE_S));
    _trackMsg.head[0] = 0xeb;
    _trackMsg.head[1] = 0x90;
    _trackMsg.len = 18;
    _trackMsg.device_id[0] = 0x13;
    _trackMsg.device_id[1] = 0x13;
    _trackMsg.cmd = 0xA5;
    if(img_w == 1920 && img_h == 1080){
        _trackMsg.device_index = 0x1;  // 默认也是0
    }else if(img_w == 1280 && img_h == 720){
        _trackMsg.device_index = 0x2;
    }else if(img_w == 1280 && img_h == 800){
        _trackMsg.device_index = 0x3;
    }
    _trackMsg.xMin = xMin;
    _trackMsg.yMin = yMin;
    _trackMsg.xMax = box_w;
    _trackMsg.yMax = box_h;

    _trackMsg.crc = crcCount((char*)&_trackMsg + 2, sizeof(GND_SKYNODE_SETTRACKMODE_S) - 4);
    qDebug() << "发送框选坐标！" << xMin << yMin << box_w << box_h << img_w << img_h;
    if(_tcpClient->_connected){
        _tcpClient->writeData((const char*)&_trackMsg, sizeof(GND_SKYNODE_SETTRACKMODE_S));
    }
}

// //发送qiwei框选点选给地面站节点
void FeiYuCtr::dytPackedXY(short trackMode,  short centerFullX,  short centerFullY,  short rectFullW,  short rectFullH, int control_command){
    qDebug() << "==================";
    qDebug() << trackMode << centerFullX << centerFullY << rectFullW << rectFullH << control_command;
    qDebug() << "==================";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0xA6;

    _sendto_sgtask_qiwei_info.trackMode = trackMode;
    _sendto_sgtask_qiwei_info.centerFullX = centerFullX;
    _sendto_sgtask_qiwei_info.centerFullY = centerFullY;
    _sendto_sgtask_qiwei_info.rectFullW = rectFullW;
    _sendto_sgtask_qiwei_info.rectFullH = rectFullH;
    _sendto_sgtask_qiwei_info.control_command = control_command;

    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    if(_tcpClient->_connected){
        _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
    }

}

// 发送开始、停止录屏指令
void FeiYuCtr::startVideoRecord(bool flag){
    qDebug() << "==================";
    qDebug() << flag;
    qDebug() << "==================";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0xA7;

    _sendto_sgtask_qiwei_info.trackMode = flag;   // 给tplc发是否开启视频
    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    if(_tcpClient->_connected){
        _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
    }
}

// 发送云台向下指令
void FeiYuCtr::ptzDownwards(int flag){
    qDebug() << "==================";
    qDebug() << flag;
    qDebug() << "==================";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0xA8;

    _sendto_sgtask_qiwei_info.trackMode = flag;   // 给tplc发是否开启视频
    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    int send_times = 2;
    if(_tcpClient->_connected){
        while(send_times--){
            _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
        }
    }
}

// 发送云台控制指令
void FeiYuCtr::ptzControl(int flag){
    qDebug() << "==================";
    qDebug() << flag;
    qDebug() << "==================";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0xA9;

    _sendto_sgtask_qiwei_info.trackMode = flag;   // 给tplc发是否开启视频
    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    if(_tcpClient->_connected){
        _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
    }
}

// 发送避障开关
void FeiYuCtr::obstacleSetting(int flag){
    qDebug() << "-------------------------";
    qDebug() << flag;
    qDebug() << "-------------------------";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0x10;

    _sendto_sgtask_qiwei_info.trackMode = flag;
    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    int send_times = 2;
    if(_tcpClient->_connected){
        while(send_times--){
            _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
        }
    }
}

// 发送目标跟踪和目标类型
// flag 0 关闭
// flag 1 开启

// type 0 人
// type 1 车

void FeiYuCtr::target_tracking(int flag, int type,  int kongyu_height){
    qDebug() << "-------------------------";
    qDebug() << "flag = " << flag << "; type = " << type;
    qDebug() << "-------------------------";

    qDebug() << "-------------------------";
    qDebug() << flag;
    qDebug() << "-------------------------";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;
    _sendto_sgtask_qiwei_info.cmd = 0x11;

    _sendto_sgtask_qiwei_info.trackMode = flag | _sendto_sgtask_qiwei_info.trackMode;    // 给高8位 低8位分别赋值
    _sendto_sgtask_qiwei_info.trackMode = type << 8 | _sendto_sgtask_qiwei_info.trackMode;

    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    int send_times = 2;
    if(_tcpClient->_connected){
        while(send_times--){
            _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
        }
    }
}

// 是否开启目标识别
void FeiYuCtr::target_recognition(int flag){
    qDebug() << "-------------------------";
    qDebug() << "flag = " << flag;
    qDebug() << "-------------------------";

    qDebug() << "-------------------------";
    qDebug() << flag;
    qDebug() << "-------------------------";
    memset(&_sendto_sgtask_qiwei_info, 0x0, sizeof(SendTo_SGTASK_QIWEI_INFO));
    _sendto_sgtask_qiwei_info.head[0] = 0xeb;
    _sendto_sgtask_qiwei_info.head[1] = 0x90;
    _sendto_sgtask_qiwei_info.len = sizeof(SendTo_SGTASK_QIWEI_INFO) - 2;
    _sendto_sgtask_qiwei_info.device_id[0] = 0x13;
    _sendto_sgtask_qiwei_info.device_id[1] = 0x13;

    _sendto_sgtask_qiwei_info.cmd = 0x12;

    _sendto_sgtask_qiwei_info.trackMode = flag | _sendto_sgtask_qiwei_info.trackMode;

    _sendto_sgtask_qiwei_info.crc = crcCount((char*)&_sendto_sgtask_qiwei_info + 2, sizeof(SendTo_SGTASK_QIWEI_INFO) - 4);
    int send_times = 2;
    if(_tcpClient->_connected){
        while(send_times--){
            _tcpClient->writeData((const char*)&_sendto_sgtask_qiwei_info, sizeof(SendTo_SGTASK_QIWEI_INFO));
        }
    }
}
