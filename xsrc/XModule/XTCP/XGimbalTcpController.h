#pragma once

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable: 4819)
#endif
#include "XTCPClient.h"
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

#include <QByteArray>
#include <QStringList>
#include <QVariantList>

class XGimbalTcpController : public TCPController
{
    Q_OBJECT

public:
    explicit XGimbalTcpController(QObject* parent = nullptr);

    Q_PROPERTY(int trackerStatus READ trackerStatus NOTIFY feedbackChanged)
    Q_PROPERTY(QString trackerStatusText READ trackerStatusText NOTIFY feedbackChanged)
    Q_PROPERTY(int trackX READ trackX NOTIFY feedbackChanged)
    Q_PROPERTY(int trackY READ trackY NOTIFY feedbackChanged)
    Q_PROPERTY(int trackW READ trackW NOTIFY feedbackChanged)
    Q_PROPERTY(int trackH READ trackH NOTIFY feedbackChanged)
    Q_PROPERTY(double yawDeg READ yawDeg NOTIFY feedbackChanged)
    Q_PROPERTY(double pitchDeg READ pitchDeg NOTIFY feedbackChanged)
    Q_PROPERTY(int targetCount READ targetCount NOTIFY feedbackChanged)
    Q_PROPERTY(bool detectionEnabled READ detectionEnabled NOTIFY feedbackChanged)
    Q_PROPERTY(QVariantList targets READ targets NOTIFY targetsChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY feedbackChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)
    Q_PROPERTY(QString lastCommandText READ lastCommandText NOTIFY feedbackChanged)
    Q_PROPERTY(QString lastFrameText READ lastFrameText NOTIFY feedbackChanged)

    int trackerStatus() const { return _trackerStatus; }
    QString trackerStatusText() const;
    int trackX() const { return _trackX; }
    int trackY() const { return _trackY; }
    int trackW() const { return _trackW; }
    int trackH() const { return _trackH; }
    double yawDeg() const { return _yawDeg; }
    double pitchDeg() const { return _pitchDeg; }
    int targetCount() const { return _targetCount; }
    bool detectionEnabled() const { return _detectionEnabled; }
    QVariantList targets() const { return _targets; }
    QString statusText() const { return _statusText; }
    QString logText() const { return _logText; }
    QString lastCommandText() const { return _lastCommandText; }
    QString lastFrameText() const { return _lastFrameText; }

    Q_INVOKABLE void trackXY(int x, int y);
    Q_INVOKABLE void trackBox(int x, int y, int width, int height);
    Q_INVOKABLE void setDetectionEnabled(bool enabled);
    Q_INVOKABLE void trackByPoint(int x, int y);
    Q_INVOKABLE void trackId(int id);
    Q_INVOKABLE void unlockTracking();
    Q_INVOKABLE void gimbalCenter();
    Q_INVOKABLE void gimbalDown90();
    Q_INVOKABLE void setGimbalAngle(int pitchDeg, int yawDeg);
    Q_INVOKABLE void sendGimbalSpeed(int yawSpeed, int pitchSpeed);
    Q_INVOKABLE void stopGimbalSpeed();
    Q_INVOKABLE void setGimbalLocked(bool locked);
    Q_INVOKABLE void clearLog();

signals:
    void feedbackChanged();
    void targetsChanged();
    void logTextChanged();

protected:
    XGimbalTcpController(QObject* parent, const QString& settingsGroup,
                         const QString& defaultIP, int defaultPort);

private slots:
    void _receiveBytes(QByteArray bytes);

private:
    enum CommandId : quint8 {
        CmdTrackXY = 0x01,
        CmdTrackID = 0x02,
        CmdTrackUnlock = 0x03,
        CmdTrackBox = 0x04,
        CmdDetectionControl = 0x05,
        CmdGimbalCenter = 0x10,
        CmdGimbalDown90 = 0x11,
        CmdGimbalSetAngle = 0x12,
        CmdGimbalSpeed = 0x13,
        CmdGimbalLock = 0x14,
        CmdStatusReport = 0x80,
        CmdTargetList = 0x81,
    };

    void _sendFrame(quint8 commandId, const QByteArray& payload, const QString& text);
    void _parseFrames();
    void _handleStatusReport(const QByteArray& payload);
    void _handleTargetList(const QByteArray& payload);
    void _appendLog(const QString& line);
    void _setStatusText(const QString& text);
    static void _appendInt16(QByteArray& payload, qint16 value);
    static void _appendInt32(QByteArray& payload, qint32 value);
    static qint16 _readInt16(const QByteArray& payload, int offset);
    static qint32 _readInt32(const QByteArray& payload, int offset);

    QByteArray _receiveBuffer;
    int _trackerStatus = 0;
    int _trackX = 0;
    int _trackY = 0;
    int _trackW = 0;
    int _trackH = 0;
    double _yawDeg = 0.0;
    double _pitchDeg = 0.0;
    int _targetCount = 0;
    bool _detectionEnabled = false;
    QVariantList _targets;
    QString _statusText;
    QString _logText;
    QString _lastCommandText;
    QString _lastFrameText;
    QStringList _logLines;
};
