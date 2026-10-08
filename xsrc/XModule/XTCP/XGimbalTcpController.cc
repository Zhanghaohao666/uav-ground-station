#include "XGimbalTcpController.h"

#include <QDateTime>
#include <QtGlobal>
#include <QVariantMap>

#include <limits>

namespace {
constexpr int kMaxTargets = 32;
constexpr int kMaxPayloadLength = 1024;
constexpr quint8 kMagic = 0xAA;
constexpr int kMaxProtocolCoordinate = std::numeric_limits<qint16>::max();

int clampInt(int value, int minValue, int maxValue)
{
    return qMin(qMax(value, minValue), maxValue);
}
}

XGimbalTcpController::XGimbalTcpController(QObject* parent)
    : XGimbalTcpController(parent, QStringLiteral("gimbalTcpClient"), QStringLiteral("192.168.2.36"), 9000)
{
    // The old shared control panel could have been repointed at the algorithm
    // relay. That endpoint now has its own controller and settings group.
    if ((tcpServerIP() == QStringLiteral("192.168.2.36") ||
         tcpServerIP() == QStringLiteral("192.168.1.104")) && tcpServerPort() == 9001) {
        setTcpServerPort(9000);
    }
}

XGimbalTcpController::XGimbalTcpController(QObject* parent, const QString& settingsGroup,
                                         const QString& defaultIP, int defaultPort)
    : TCPController(parent, settingsGroup, defaultIP, defaultPort)
{
    _statusText = tr("Disconnected");

    connect(tcpClient(), &CcTcpClient::ReceiveParse, this, &XGimbalTcpController::_receiveBytes);
    connect(this, &TCPController::isConnectedChanged, this, [this](bool connected) {
        _setStatusText(connected ? tr("Command channel connected") : tr("Command channel disconnected"));
        _appendLog(_statusText);
        if (!connected) {
            _receiveBuffer.clear();
            _trackerStatus = 0;
            _trackX = 0;
            _trackY = 0;
            _trackW = 0;
            _trackH = 0;
            _yawDeg = 0.0;
            _pitchDeg = 0.0;
            _targetCount = 0;
            _detectionEnabled = false;
            _targets.clear();
            _lastFrameText.clear();
            emit targetsChanged();
        }
        emit feedbackChanged();
    });
}

QString XGimbalTcpController::trackerStatusText() const
{
    switch (_trackerStatus) {
    case 1: return tr("WAIT");
    case 2: return tr("SEARCH");
    case 3: return tr("TRACK");
    case 4: return tr("RECAP");
    case 5: return tr("LOST");
    default: return tr("UNKNOWN");
    }
}

void XGimbalTcpController::trackXY(int x, int y)
{
    const int trackX = clampInt(x, 0, kMaxProtocolCoordinate);
    const int trackY = clampInt(y, 0, kMaxProtocolCoordinate);
    QByteArray payload;
    _appendInt16(payload, static_cast<qint16>(trackX));
    _appendInt16(payload, static_cast<qint16>(trackY));
    _sendFrame(CmdTrackXY, payload, tr("Track by pixel (%1, %2)").arg(trackX).arg(trackY));
}

void XGimbalTcpController::trackBox(int x, int y, int width, int height)
{
    const int trackX = clampInt(x, 0, kMaxProtocolCoordinate);
    const int trackY = clampInt(y, 0, kMaxProtocolCoordinate);
    const int trackWidth = clampInt(width, 1, kMaxProtocolCoordinate);
    const int trackHeight = clampInt(height, 1, kMaxProtocolCoordinate);

    QByteArray payload;
    _appendInt16(payload, static_cast<qint16>(trackX));
    _appendInt16(payload, static_cast<qint16>(trackY));
    _appendInt16(payload, static_cast<qint16>(trackWidth));
    _appendInt16(payload, static_cast<qint16>(trackHeight));
    _sendFrame(CmdTrackBox, payload, tr("Track box (%1, %2, %3, %4)")
               .arg(trackX).arg(trackY).arg(trackWidth).arg(trackHeight));
}

void XGimbalTcpController::setDetectionEnabled(bool enabled)
{
    QByteArray payload;
    payload.append(static_cast<char>(enabled ? 1 : 0));
    _detectionEnabled = enabled;
    _sendFrame(CmdDetectionControl, payload, enabled ? tr("Enable detection") : tr("Disable detection"));
}

void XGimbalTcpController::trackByPoint(int x, int y)
{
    const int px = clampInt(x, 0, 1919);
    const int py = clampInt(y, 0, 1079);
    for (const QVariant& item : _targets) {
        const QVariantMap target = item.toMap();
        const int tx = target.value(QStringLiteral("x")).toInt();
        const int ty = target.value(QStringLiteral("y")).toInt();
        const int tw = target.value(QStringLiteral("w")).toInt();
        const int th = target.value(QStringLiteral("h")).toInt();
        if (px >= tx && px < tx + tw && py >= ty && py < ty + th) {
            trackId(target.value(QStringLiteral("id")).toInt());
            return;
        }
    }

    _appendLog(tr("No cached target hit, falling back to pixel tracking"));
    trackXY(px, py);
}

void XGimbalTcpController::trackId(int id)
{
    QByteArray payload;
    _appendInt32(payload, static_cast<qint32>(id));
    _sendFrame(CmdTrackID, payload, tr("Track target ID %1").arg(id));
}

void XGimbalTcpController::unlockTracking()
{
    _sendFrame(CmdTrackUnlock, QByteArray(), tr("Stop tracking"));
}

void XGimbalTcpController::gimbalCenter()
{
    _sendFrame(CmdGimbalCenter, QByteArray(), tr("Gimbal center"));
}

void XGimbalTcpController::gimbalDown90()
{
    _sendFrame(CmdGimbalDown90, QByteArray(), tr("Gimbal down 90"));
}

void XGimbalTcpController::setGimbalAngle(int pitchDeg, int yawDeg)
{
    const int pitch = clampInt(pitchDeg, -90, 30);
    const int yaw = clampInt(yawDeg, -180, 180);
    QByteArray payload;
    _appendInt16(payload, static_cast<qint16>(pitch));
    _appendInt16(payload, static_cast<qint16>(yaw));
    _sendFrame(CmdGimbalSetAngle, payload, tr("Set gimbal angle pitch=%1 yaw=%2").arg(pitch).arg(yaw));
}

void XGimbalTcpController::sendGimbalSpeed(int yawSpeed, int pitchSpeed)
{
    QByteArray payload;
    payload.append(static_cast<char>(clampInt(yawSpeed, 0, 255)));
    payload.append(static_cast<char>(clampInt(pitchSpeed, 0, 255)));
    _sendFrame(CmdGimbalSpeed, payload, tr("Gimbal speed yaw=%1 pitch=%2").arg(clampInt(yawSpeed, 0, 255)).arg(clampInt(pitchSpeed, 0, 255)));
}

void XGimbalTcpController::stopGimbalSpeed()
{
    sendGimbalSpeed(128, 128);
}

void XGimbalTcpController::setGimbalLocked(bool locked)
{
    QByteArray payload;
    payload.append(static_cast<char>(locked ? 1 : 0));
    _sendFrame(CmdGimbalLock, payload, locked ? tr("Lock gimbal") : tr("Unlock gimbal"));
}

void XGimbalTcpController::clearLog()
{
    _logLines.clear();
    _logText.clear();
    emit logTextChanged();
}

void XGimbalTcpController::_receiveBytes(QByteArray bytes)
{
    _receiveBuffer.append(bytes);
    _parseFrames();
}

void XGimbalTcpController::_sendFrame(quint8 commandId, const QByteArray& payload, const QString& text)
{
    QByteArray frame;
    frame.append(static_cast<char>(kMagic));
    frame.append(static_cast<char>(commandId));
    frame.append(static_cast<char>(payload.size() & 0xff));
    frame.append(static_cast<char>((payload.size() >> 8) & 0xff));
    frame.append(payload);

    sendBytes(frame);
    _lastCommandText = text;
    _appendLog(tr("Sent %1 (0x%2)").arg(text, QString::number(commandId, 16).rightJustified(2, QLatin1Char('0')).toUpper()));
    emit feedbackChanged();
}

void XGimbalTcpController::_parseFrames()
{
    while (_receiveBuffer.size() >= 4) {
        if (static_cast<quint8>(_receiveBuffer.at(0)) != kMagic) {
            _receiveBuffer.remove(0, 1);
            continue;
        }

        const quint8 commandId = static_cast<quint8>(_receiveBuffer.at(1));
        const int payloadLength = static_cast<quint8>(_receiveBuffer.at(2)) |
                                  (static_cast<quint8>(_receiveBuffer.at(3)) << 8);
        if (payloadLength > kMaxPayloadLength) {
            _appendLog(tr("Invalid payload length %1, resyncing").arg(payloadLength));
            _receiveBuffer.remove(0, 1);
            continue;
        }
        if (_receiveBuffer.size() < 4 + payloadLength) {
            return;
        }

        const QByteArray payload = _receiveBuffer.mid(4, payloadLength);
        _receiveBuffer.remove(0, 4 + payloadLength);

        _lastFrameText = QStringLiteral("0x%1 len=%2").arg(QString::number(commandId, 16).rightJustified(2, QLatin1Char('0')).toUpper()).arg(payloadLength);
        if (commandId == CmdStatusReport) {
            _handleStatusReport(payload);
        } else if (commandId == CmdTargetList) {
            _handleTargetList(payload);
        } else {
            _appendLog(tr("Ignored unknown frame %1").arg(_lastFrameText));
            emit feedbackChanged();
        }
    }
}

void XGimbalTcpController::_handleStatusReport(const QByteArray& payload)
{
    if (payload.size() != 14) {
        _appendLog(tr("Invalid status payload length: %1").arg(payload.size()));
        return;
    }

    _trackerStatus = static_cast<quint8>(payload.at(0));
    _trackX = _readInt16(payload, 1);
    _trackY = _readInt16(payload, 3);
    _trackW = _readInt16(payload, 5);
    _trackH = _readInt16(payload, 7);
    _yawDeg = _readInt16(payload, 9) / 100.0;
    _pitchDeg = _readInt16(payload, 11) / 100.0;
    _targetCount = static_cast<quint8>(payload.at(13));
    _setStatusText(tr("Status %1, targets %2").arg(trackerStatusText()).arg(_targetCount));
    emit feedbackChanged();
}

void XGimbalTcpController::_handleTargetList(const QByteArray& payload)
{
    if (payload.isEmpty()) {
        _appendLog(tr("Invalid target list payload"));
        return;
    }

    const int count = qMin(static_cast<int>(static_cast<quint8>(payload.at(0))), kMaxTargets);
    const int expectedLength = 1 + count * 12;
    if (payload.size() < expectedLength) {
        _appendLog(tr("Invalid target list length: %1").arg(payload.size()));
        return;
    }

    QVariantList targets;
    for (int i = 0; i < count; ++i) {
        const int offset = 1 + i * 12;
        QVariantMap target;
        target.insert(QStringLiteral("x"), _readInt16(payload, offset));
        target.insert(QStringLiteral("y"), _readInt16(payload, offset + 2));
        target.insert(QStringLiteral("w"), _readInt16(payload, offset + 4));
        target.insert(QStringLiteral("h"), _readInt16(payload, offset + 6));
        target.insert(QStringLiteral("id"), _readInt32(payload, offset + 8));
        targets.append(target);
    }

    _targets = targets;
    _targetCount = count;
    emit targetsChanged();
    emit feedbackChanged();
}

void XGimbalTcpController::_appendLog(const QString& line)
{
    const QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
    _logLines.append(QStringLiteral("[%1] %2").arg(timestamp, line));
    while (_logLines.size() > 200) {
        _logLines.removeFirst();
    }
    _logText = _logLines.join(QStringLiteral("\n"));
    emit logTextChanged();
}

void XGimbalTcpController::_setStatusText(const QString& text)
{
    _statusText = text;
}

void XGimbalTcpController::_appendInt16(QByteArray& payload, qint16 value)
{
    payload.append(static_cast<char>(value & 0xff));
    payload.append(static_cast<char>((value >> 8) & 0xff));
}

void XGimbalTcpController::_appendInt32(QByteArray& payload, qint32 value)
{
    payload.append(static_cast<char>(value & 0xff));
    payload.append(static_cast<char>((value >> 8) & 0xff));
    payload.append(static_cast<char>((value >> 16) & 0xff));
    payload.append(static_cast<char>((value >> 24) & 0xff));
}

qint16 XGimbalTcpController::_readInt16(const QByteArray& payload, int offset)
{
    return static_cast<qint16>(static_cast<quint8>(payload.at(offset)) |
                               (static_cast<quint8>(payload.at(offset + 1)) << 8));
}

qint32 XGimbalTcpController::_readInt32(const QByteArray& payload, int offset)
{
    return static_cast<qint32>(static_cast<quint8>(payload.at(offset)) |
                               (static_cast<quint8>(payload.at(offset + 1)) << 8) |
                               (static_cast<quint8>(payload.at(offset + 2)) << 16) |
                               (static_cast<quint8>(payload.at(offset + 3)) << 24));
}
