#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include "mqttclient.h"
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QTextStream>
#include "protocoltypes.h"

#include "Vehicle.h"
#include "MultiVehicleManager.h"


class AppController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MqttClient* mqtt READ mqtt CONSTANT)
    // Q_PROPERTY(bool mqttForward READ mqttForward WRITE setMqttForward NOTIFY mqttForwardChanged)
    Q_PROPERTY(int radarCount READ radarCount WRITE setRadarCount NOTIFY radarCountChanged)
    //目标经纬度
    Q_PROPERTY(QGeoCoordinate tsPosition  READ tsPosition  NOTIFY tsPositionChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    // 暴露给 QML
    MqttClient* mqtt() const { return _mqtt; }
    // bool mqttForward() const { return _mqttForward; }
    // void setMqttForward(bool enabled);
    void  setRadarCount(int count);
    int radarCount() const { return m_radarCount; }
    QGeoCoordinate tsPosition() const { return _tsPosition; }

signals:
    // void mqttForwardChanged();
    void radarCountChanged();
    // 每条日志行（仅该行）发给 QML
    void radarLineReady(const QString &line);
    void tsPositionChanged(QGeoCoordinate cor);


public slots:
    void sendRadarData(cmd_radar_t radar);

private slots:
    // void handleMqttMessage();
    // void handleForwardPrepared(const QByteArray &forwardMsg);  // 👈 槽函数
    void stopLogging(void);

private:
    Vehicle* _activeVehicle         = nullptr;

    MqttClient *_mqtt = nullptr;
    bool _mqttForward { true };
    int m_radarCount = 0;

    QGeoCoordinate _tsPosition ;


    QFile *_csvFile = nullptr;      // ✅ 新增
    QTextStream _logStream;
    QTextStream _csvStream;         // ✅ 新增
    bool _isRecording = false;

    void startLogging();
    void writeLogLine(const QString &line);

};

#endif // APPCONTROLLER_H
