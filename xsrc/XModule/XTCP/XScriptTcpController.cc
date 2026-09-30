#include "XScriptTcpController.h"

#include <QDateTime>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonValue>
#include <QStringList>

namespace {
constexpr int kMaxLogLines = 300;
}

XScriptTcpController::XScriptTcpController(QObject* parent)
    : TCPController(parent)
{
    _statusText = tr("Disconnected");

    connect(tcpClient(), &CcTcpClient::ReceiveParse, this, &XScriptTcpController::_receiveBytes);
    connect(this, &TCPController::isConnectedChanged, this, [this](bool connected) {
        _statusText = connected ? tr("TCP Connected") : tr("TCP Disconnected");
        _appendLog(_statusText);
        emit feedbackChanged();
    });
}

void XScriptTcpController::sendStartScript(const QString& scriptName, int altitude, bool ackRequired)
{
    const QString taskId = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss_zzz"));

    QJsonObject params;
    params.insert(QStringLiteral("altitude"), altitude);

    QJsonObject command;
    command.insert(QStringLiteral("task_id"), taskId);
    command.insert(QStringLiteral("command"), QStringLiteral("start_script"));
    command.insert(QStringLiteral("script_name"), scriptName.trimmed().isEmpty() ? QStringLiteral("takeoff_demo.py") : scriptName.trimmed());
    command.insert(QStringLiteral("params"), params);
    command.insert(QStringLiteral("ack_required"), ackRequired);

    const QString payload = QString::fromUtf8(QJsonDocument(command).toJson(QJsonDocument::Compact)) + QStringLiteral("\n");
    sendTextQml(payload);

    _lastTaskId = taskId;
    _lastStatus = QStringLiteral("sent");
    _progress = 0;
    _message = tr("Script start command sent");
    _lastJson = payload.trimmed();
    _statusText = tr("Waiting for UAV feedback");
    _appendLog(tr("Sent: %1").arg(_lastJson));
    emit feedbackChanged();
}

void XScriptTcpController::sendJsonText(const QString& jsonText)
{
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(jsonText.toUtf8(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        _message = tr("JSON format error: %1").arg(error.errorString());
        _statusText = tr("Send failed");
        _appendLog(_message);
        emit feedbackChanged();
        return;
    }

    const QString payload = QString::fromUtf8(QJsonDocument(document.object()).toJson(QJsonDocument::Compact)) + QStringLiteral("\n");
    sendTextQml(payload);
    _lastJson = payload.trimmed();
    _statusText = tr("JSON sent");
    _appendLog(tr("Sent: %1").arg(_lastJson));
    emit feedbackChanged();
}

void XScriptTcpController::clearLog()
{
    if (_logText.isEmpty()) {
        return;
    }

    _logText.clear();
    emit logTextChanged();
}

void XScriptTcpController::_receiveBytes(QByteArray bytes)
{
    _receiveBuffer.append(bytes);

    int newlineIndex = _receiveBuffer.indexOf('\n');
    while (newlineIndex >= 0) {
        const QByteArray line = _receiveBuffer.left(newlineIndex).trimmed();
        _receiveBuffer.remove(0, newlineIndex + 1);
        if (!line.isEmpty()) {
            QJsonParseError error;
            const QJsonDocument document = QJsonDocument::fromJson(line, &error);
            if (error.error == QJsonParseError::NoError && document.isObject()) {
                _handleJsonObject(document.object(), QString::fromUtf8(line));
            } else {
                _appendLog(tr("Received non-JSON: %1").arg(QString::fromUtf8(line)));
            }
        }
        newlineIndex = _receiveBuffer.indexOf('\n');
    }

    if (_receiveBuffer.trimmed().startsWith('{') && _receiveBuffer.trimmed().endsWith('}')) {
        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(_receiveBuffer.trimmed(), &error);
        if (error.error == QJsonParseError::NoError && document.isObject()) {
            const QString rawJson = QString::fromUtf8(_receiveBuffer.trimmed());
            _receiveBuffer.clear();
            _handleJsonObject(document.object(), rawJson);
        }
    }
}

void XScriptTcpController::_handleJsonObject(const QJsonObject& object, const QString& rawJson)
{
    _lastTaskId = object.value(QStringLiteral("task_id")).toString(_lastTaskId);
    _lastStatus = object.value(QStringLiteral("status")).toString(_lastStatus);
    _progress = object.value(QStringLiteral("progress")).toInt(_progress);
    _message = object.value(QStringLiteral("msg")).toString(object.value(QStringLiteral("message")).toString(_message));
    _lastJson = rawJson;

    const QString statusDisplay = _statusDisplayText(_lastStatus);
    _statusText = _message.isEmpty() ? statusDisplay : QStringLiteral("%1: %2").arg(statusDisplay, _message);
    _appendLog(tr("Received: %1").arg(rawJson));
    emit feedbackChanged();
}

void XScriptTcpController::_appendLog(const QString& line)
{
    const QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
    const QString logLine = QStringLiteral("[%1] %2").arg(timestamp, line);
    _logText = _logText.isEmpty() ? logLine : _logText + QStringLiteral("\n") + logLine;
    QStringList lines = _logText.split(QLatin1Char('\n'));
    while (lines.count() > kMaxLogLines) {
        lines.removeFirst();
    }
    _logText = lines.join(QLatin1Char('\n'));
    emit logTextChanged();
}

QString XScriptTcpController::_statusDisplayText(const QString& status) const
{
    const QString normalized = status.trimmed().toLower();
    if (normalized == QStringLiteral("running")) {
        return tr("Running");
    }
    if (normalized == QStringLiteral("success") || normalized == QStringLiteral("succeeded") ||
            normalized == QStringLiteral("ok") || normalized == QStringLiteral("done") ||
            normalized == QStringLiteral("finished")) {
        return tr("Start succeeded");
    }
    if (normalized == QStringLiteral("failed") || normalized == QStringLiteral("failure") ||
            normalized == QStringLiteral("error")) {
        return tr("Start failed");
    }
    if (normalized == QStringLiteral("sent")) {
        return tr("Sent");
    }
    return status.isEmpty() ? tr("Unknown status") : status;
}
