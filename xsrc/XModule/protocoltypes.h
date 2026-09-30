
#ifndef PROTOCOL_TYPES_H   //ProtocolTypes.h
#define PROTOCOL_TYPES_H

#include <stdint.h>
#include <stdbool.h>

//#include <QString>
//#include <QString>
//#include "stdio.h"
//#include <QtGlobal>

/*
V2_extension消息：
Message type：11  代表YX回传消息给地面站
Message type：10  代表地面站控制指令给YX
Message type：22  代表DYT回传识别结果消息给地面站的
Message type：21  代表DYT回传消息给地面站状态
Message type：20  代表地面站控制指令给DYT
*/

#define HEADER1  0xEB
#define HEADER2  0x90

typedef enum {
    Type_DYT = 0,
    Type_RADAR = 1,
    Type_SPEED = 2,
    Type_POWER = 3,
    Type_SIM = 20,
    Type_STATUS = 55
} Tunnel_t;


typedef enum {
    TypeMulNull = 0,
    TypeMul1,
    TypeMul2,
    TypeMul4,
} videoMul_t;

#define GET_BIT(x, bit) ((x & (1 << bit)) >> bit) /* 获取第bit位 */
#define SET_BIT(x, bit) (x |= (1 << bit))         /* 置位第bit位 */
#define RESET_BIT(x, bit) (x &= ~(1 << bit))      /* 置位第bit位 */

#pragma pack(push,1)		// 保存原来的字节对齐方式
//#pragma pack(push)
//#pragma pack(1)
//#pragma once

//====================== YX 相关 ===========================//
//MissionUnit(YX) TO GCS
typedef struct
{
    bool comunicate_fault;         //与引信通信故障
    bool detonated_cmd_state;      //起B指令状态
    bool fault_state;              //故障状态
    bool work_power_on;            //工作电源状态
    bool second_safe_release_state; //二保状态
    bool second_cmd_get_state;     //二保指令状态
    bool first_safe_release_state; //一保状态
    bool first_cmd_get_state;       //一保指令状态
    bool self_check_state;         //自检状态       //[2]检查yx返回状态, 正常true
    bool selfcheck_cmd_state;      //自检指令状态
    uint32_t factory_year;         //出厂年份
    uint32_t factory_mounth;       //出厂月份
    uint32_t factory_day;          //出厂日期
    uint32_t factory_sn;           //出厂SN
    uint32_t factory_batch;        //出厂批次
    uint32_t factory_name;         //厂家名
    uint64_t frame_num;            //帧号
} yx_wu_result_t;

//GCS TO MissionUnit(YX)
typedef struct YX_CMD_TO_USER
{
    bool control_cmd{false};         //控制指令？查询指令  cmd为true则指令  fasle为state
    bool self_check_cmd{false};      //自检
    bool first_safe_release{false};  //一保解除
    bool second_safe_release{false}; //二保解除
    bool detonated_cmd{false};       // QB指令
} yx_cmd_to_user_t;



typedef struct YX_CMD_TO_SEIAL
{
    uint8_t header[2]{0x55, 0xAA};
    uint8_t data_len{0x05};
    uint8_t cmd[2]{0x00, 0x00};
    uint8_t space[2]{0x00, 0x00};
    uint8_t checkSum{0x00};
} yx_cmd_to_seial_t;



//====================== DYT 相关 ===========================//
// GCS → DYT 协议包结构
typedef struct
{
    uint8_t header[2];    // 帧头：0xEB 0x90
    uint8_t cmd;          // 控制信息
    int16_t paramX;       // 参数X（第4~5字节）
    int16_t paramY;       // 参数Y（第6~7字节）
    uint8_t param3;       // 参数3（第8字节）
    int8_t  zoomSpeed;    // 变焦速率（第9字节）
    uint8_t reserved[6];  // 保留（第10~14字节）
    uint8_t checksum;     // 校验和（第15字节，0~14累加取低8位）
} cmd_gcs_to_dyt_t;

typedef struct {
    int32_t lat;
    int32_t lon;
    int32_t alt;
    int32_t speed;
} cmd_radar_t;

///DYT to GCS  接收       [4]  1自检状态 2自检故障  3正在自检
typedef struct {
    uint8_t header[2];    // 帧头：0xEE 0x16
    uint8_t state1;       // [2] 状态信息反馈1
    uint8_t state2;       // [3] 状态信息反馈2
    uint8_t zoom_low;     // [4] 变焦低8位
    uint8_t zoom_high4;   // [5] 高4位 (bit0-3)
    uint8_t r6;           // [6] ~ [9] reserved
    uint8_t r7;
    uint8_t r8;
    uint8_t r9;
    uint8_t r10;          // [10] ~ [11] reserved
    uint8_t r11;
    int16_t pitch_frame;  // [12-13] 俯仰框架角 (单位 0.01°) 左负右正，上正下负
    int16_t yaw_frame;    // [14-15] 方位框架角 (单位 0.01°)
    uint8_t reserved2[15];// [16-30] 保留
    uint8_t checksum;     // [31] 校验和
} dyt_recv_frame_t;

//====================== 移动目标打击 目标状态 ===========================//
typedef struct TUNNEL_MSG_CTR //地面站->任务板
{
    //     // 状态机
    // enum EXEC_STATE
    // {
    //   WAIT,
    //   WAYPIONT,
    //   FOLLOW,
    //   ATTACK,
    //   FIRE,
    // };
    unsigned char status;
    bool use_sitl_pos;           //是否使用SITL的目标位置
    unsigned char set_param;     //控制字 0：无 1~5 对应一下五个数据
    float follow_init_distance;  //1. 跟随距离，跟随模式下的
    float attact_speed;          //2. 攻击速度
    float kp_attack;             //3. 攻击kp值
    float max_attack_speed;      //4.
    uint16_t wp_index_now;       //5.
    bool autoStrike;             //6.
    //start_cch_20230303 添加  +3
    float max_attack_acc_speed;  //7. 攻击最大加速度
    bool attack_from_head;       //8. 灌顶式攻击（移动目标采用）
    bool auto_run_waypoint;      //9.  auto run way point after launch completed
} targetState_Send_t;

typedef  struct TUNNEL_MSG_BACK //任务板->地面站
{
    unsigned char status;   //状态机
    bool use_sitl_pos;      //是否使用SITL目标的位置
    double lat;             //目标纬度
    double lng;             //目标经度
    double alt;             //目标海拔
    float x_vel;            //目标x速度
    float y_vel;            //目标y速度
    float z_vel;            //目标z速度

    float distance;         //目标距飞机距离
    float yaw_to_target;    //目标航向
    float del_x;            //目标x距离
    float del_y;            //目标y距离
    float del_z;            //目标z距离

    //start_cch_20230206 新增
    float follow_init_distance;
    float attact_speed;
    float kp_attack;
    float max_attack_speed;
    uint16_t wp_index_now;
    bool autoStrike;           //巡航时自动打击目标

    float max_attack_acc_speed; //攻击最大加速度
    bool attack_from_head;      //灌顶式攻击（移动目标采用）
    bool launch_compelted;      //发射是否完成
    bool auto_run_waypoint;     // // auto run way point after launch completed

} targetState_Rcv_t;

struct SEEKER_CMD_TO_USER
{
    uint8_t capture_cmd; //捕控指令，详见SEEKER_CMD_ENUM
    int16_t pitch_angle;
    int16_t yaw_angle;
    int16_t pitch_rate;
    int16_t yaw_rate;
    uint8_t track_modle;                  // 0x00 普通模式 0x01 点选模式 0x02 框选模式
    uint16_t tracking_frame_number{0x00}; //默认为0 采用 跟踪帧号为当前帧
    int16_t tracking_center_x;
    int16_t tracking_center_y;
    uint16_t tracking_frame_wid;
    uint16_t tracking_frame_alt;
    uint8_t display_image_mode; // 0x00 图像模式 0x01显示图像识别框，0x02显示识别框和目标类型  其他值无效
};

#pragma pack(pop)		  // 恢复字节对齐方式

#endif
