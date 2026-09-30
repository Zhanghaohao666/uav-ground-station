#include "appcontroller.h"
#include <QCoreApplication>
#include "QGCApplication.h"
#include "QGCCorePlugin.h"


AppController::AppController(QObject *parent)
    : QObject(parent)
{
    _mqtt = new MqttClient(this);      // 父对象为 this，Qt 自动管理内存

    connect(_mqtt, &MqttClient::forwardPrepared,
            this, &AppController::sendRadarData);


    // _tsPosition.setLatitude(28.197539);
    // _tsPosition.setLongitude(112.903970);
    // _tsPosition.setAltitude(30);

    // connect(_serial, &XSerial::closeSerial,
    //                   this, &AppController::stopLogging);


    // 信号槽连接，不用 lambda
    // bool ok = connect(_mqtt, &MqttClient::forwardPrepared,
    //         this, &AppController::handleForwardPrepared);

    // 连接 MQTT 接收 -> 串口发送
    // connect(_mqtt, &MqttClient::messageReceived,
    //         this, [=](const QString &topic, const QByteArray &msg) {
    //     if (_mqttForward && _serial->isOpen()) {
    //         _serial->writeData(msg);
    //     }
    // });
    // bool ok = connect(_mqtt, &MqttClient::forwardPrepared, this, [=](const QByteArray &forwardMsg) {
    //     qDebug() << "forwardMsg:" << forwardMsg;
    //     if (_mqttForward && _serial->isOpen()) {
    //         qDebug() << "forwardMsg:2" ;
    //         _serial->writeData(forwardMsg);
    //     }
    // });
    // qDebug() << "connect ok?" << ok;
}

//======================= Radar ================================
/* DYT封装发送程序 */
void  AppController::sendRadarData(cmd_radar_t radar) {

    // qDebug() << "appcontroller Radar Data Received:"
    //          << "lat =" << radar.lat
    //          << "lon =" << radar.lon
    //          << "alt =" << radar.alt
    //          << "speed =" << radar.speed;

    _activeVehicle = qgcApp()->toolbox()->multiVehicleManager()->activeVehicle();
    if(_activeVehicle) {

        _activeVehicle->tunnelPackedSend(&radar, Type_RADAR);
        _activeVehicle->tunnelPackedSend(&radar.speed, Type_SPEED);
        qDebug() << QString("appcontroller Type_RADAR") << m_radarCount;

        // 数据计数
        m_radarCount++;
        emit radarCountChanged();
        // 转成可读字符串
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


    //更新经纬度, 目标点，显示在地图上
    if(radar.lat == 0.0 || radar.lon == 0.0) {
    }
    else {
        QGeoCoordinate newPosition(radar.lat / 1e7, radar.lon / 1e7, radar.alt);
        _tsPosition = newPosition;
        emit tsPositionChanged(_tsPosition);
        qDebug() << "_tsPosition:" << _tsPosition;
    }
}


void  AppController::setRadarCount(int count){

    m_radarCount = count;
    emit radarCountChanged();
}

// void AppController::setMqttForward(bool enable)
// {
//     if (_mqttForward == enable) return;
//     _mqttForward = enable;
//     emit mqttForwardChanged();
// }

// void AppController::handleForwardPrepared(const QByteArray &forwardMsg)
// {
//     // qDebug() << "handleForwardPrepared got:" << forwardMsg;
//     if (_mqttForward ) {
//         // qDebug() << "handleForwardPrepared writing serial...";

//         if (!_isRecording)
//             startLogging();   // 首次写入时开始日志

//         _serial->writeData(forwardMsg);

//         // 当前时间戳（精确到毫秒）
//         qint64 msSinceStart = QDateTime::currentMSecsSinceEpoch() % 86400000; // 当天毫秒数（00:00起）
//         QString msStr = QString::number(msSinceStart);


//         // 解析 forwardMsg，例如 "$TGT,lonInt,latInt,altInt"
//         QString msgStr = QString::fromUtf8(forwardMsg).trimmed();
//         QStringList parts = msgStr.split(QLatin1Char(','));

//         if (parts.size() >= 4) {
//             QString lonInt = parts[1];
//             QString latInt = parts[2];
//             QString altInt = parts[3];
//             QString logLine = QString(tr("%1,%2,%3,%4"))
//                                   .arg(msStr)
//                                   .arg(lonInt)
//                                   .arg(latInt)
//                                   .arg(altInt);
//             writeLogLine(logLine);
//         }
//     }
// }

// 启动日志记录
void AppController::startLogging()
{
    if (_isRecording)
        return;

    QString timestamp = QDateTime::currentDateTime().toString(tr("yyyyMMdd_hhmmss_zzz"));
    QString basePath  = QCoreApplication::applicationDirPath() + tr("/log");

    // ✅ 2若目录不存在则自动创建
    QDir dir(basePath);
    if (!dir.exists()) {
        dir.mkpath(basePath);
    }

    // csv 日志
    QString csvFileName = QString(tr("%1/%2.csv")).arg(basePath).arg(timestamp);

    _csvFile = new QFile(csvFileName);

    bool csvOk = _csvFile->open(QIODevice::WriteOnly | QIODevice::Text);

    if ( csvOk)
    {
        _csvStream.setDevice(_csvFile);
        _isRecording = true;
        // ✅ 写入 CSV 表头
        _csvStream << "Time,Longitude,Latitude,Altitude,Speed\n";
        // ✅ 2️⃣ 写入文件创建时间（第二行）
        QString dateTimeStr = QDateTime::currentDateTime().toString(tr("yyyy-MM-dd hh:mm:ss.zzz"));
        _csvStream << dateTimeStr << "\n";

        qDebug() << "开始日志录制:" << csvFileName;
    }
    else
    {
        qWarning() << "无法创建日志文件";
        if (_csvFile) { delete _csvFile; _csvFile = nullptr; }
    }
}

// 停止日志记录
void AppController::stopLogging()
{
    if (_isRecording)
    {
        if (_csvFile) {
            _csvStream.flush();
            _csvFile->close();
            delete _csvFile;
            _csvFile = nullptr;
        }

        _isRecording = false;
        qDebug() << "日志录制结束";
    }
}

// 写入一行数据
void AppController::writeLogLine(const QString &line)
{
    if (!_isRecording)
        return;


    if (_csvFile) {
        _csvStream << line << "\n";
        _csvStream.flush();
    }
}

