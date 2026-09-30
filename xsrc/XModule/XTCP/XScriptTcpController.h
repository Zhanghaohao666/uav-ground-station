#pragma once

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable: 4819)
#endif
#include "XTCPClient.h"
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

#include <QJsonObject>

class XScriptTcpController : public TCPController
{
    Q_OBJECT

public:
    explicit XScriptTcpController(QObject* parent = nullptr);

    Q_PROPERTY(QString lastTaskId READ lastTaskId NOTIFY feedbackChanged)
    Q_PROPERTY(QString lastStatus READ lastStatus NOTIFY feedbackChanged)
    Q_PROPERTY(int progress READ progress NOTIFY feedbackChanged)
    Q_PROPERTY(QString message READ message NOTIFY feedbackChanged)
    Q_PROPERTY(QString lastJson READ lastJson NOTIFY feedbackChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY feedbackChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)

    QString lastTaskId() const { return _lastTaskId; }
    QString lastStatus() const { return _lastStatus; }
    int progress() const { return _progress; }
    QString message() const { return _message; }
    QString lastJson() const { return _lastJson; }
    QString statusText() const { return _statusText; }
    QString logText() const { return _logText; }

    Q_INVOKABLE void sendStartScript(const QString& scriptName, int altitude, bool ackRequired);
    Q_INVOKABLE void sendJsonText(const QString& jsonText);
    Q_INVOKABLE void clearLog();

signals:
    void feedbackChanged();
    void logTextChanged();

private slots:
    void _receiveBytes(QByteArray bytes);

private:
    void _handleJsonObject(const QJsonObject& object, const QString& rawJson);
    void _appendLog(const QString& line);
    QString _statusDisplayText(const QString& status) const;

    QByteArray _receiveBuffer;
    QString _lastTaskId;
    QString _lastStatus;
    int _progress = 0;
    QString _message;
    QString _lastJson;
    QString _statusText;
    QString _logText;
};
