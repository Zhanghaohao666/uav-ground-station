#include "XBoardRecordingController.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkProxy>
#include <QRegularExpression>
#include <QSettings>
#include <QUrl>

XBoardRecordingController::XBoardRecordingController(QObject* parent) : QObject(parent)
{
    QSettings settings;
    _address = settings.value("BoardRecording/address", _address).toString();
    _remember = settings.value("BoardRecording/remember", true).toBool();
    if (_remember) _code = settings.value("BoardRecording/code").toString();
    _network.setProxy(QNetworkProxy::NoProxy);
    _poll.setInterval(3000);
    connect(&_poll, &QTimer::timeout, this, &XBoardRecordingController::refresh);
    _poll.start();
}

XBoardRecordingController::~XBoardRecordingController()
{
    cancelRequest(); // Never send stop on disconnect, page close or app exit.
}

void XBoardRecordingController::cancelRequest()
{
    if (_reply) {
        disconnect(_reply, nullptr, this, nullptr);
        _reply->abort();
        _reply->deleteLater();
        _reply = nullptr;
    }
    _busy = false;
}

bool XBoardRecordingController::configure(const QString& address, const QString& code, bool remember)
{
    const QString trimmedAddress = address.trimmed();
    const QUrl url(QStringLiteral("http://") + trimmedAddress);
    const QString trimmedCode = code.trimmed();
    if (!url.isValid() || url.host().isEmpty() || !url.userInfo().isEmpty() ||
        (!url.path().isEmpty() && url.path() != "/") || url.hasQuery() || url.hasFragment() ||
        !QRegularExpression("^[0-9a-f]{64}$").match(trimmedCode).hasMatch()) {
        _error = tr("请输入主控 IP（可带端口）及 64 位连接码");
        _operationError = true;
        emit changed();
        return false;
    }
    cancelRequest();
    _address = trimmedAddress;
    _code = trimmedCode;
    _remember = remember;
    _connected = false;
    _status.clear();
    _error.clear();
    _operationError = false;
    QSettings settings;
    settings.setValue("BoardRecording/address", _address);
    settings.setValue("BoardRecording/remember", _remember);
    if (_remember) settings.setValue("BoardRecording/code", _code);
    else settings.remove("BoardRecording/code");
    emit configurationChanged();
    emit changed();
    refresh();
    return true;
}

void XBoardRecordingController::refresh() { if (!_code.isEmpty() && !_busy) request("status"); }
void XBoardRecordingController::startSelected(const QStringList& keys) { request("start", keys); }
void XBoardRecordingController::stopSelected(const QStringList& keys) { request("stop", keys); }
void XBoardRecordingController::stopAll() { request("stop", {"all"}); }

void XBoardRecordingController::request(const QString& action, const QStringList& keys)
{
    if (_busy) return;
    if (_code.isEmpty() || (action != "status" && keys.isEmpty())) {
        _error = tr("请先连接主控并选择要录制或停止的视频");
        _operationError = true;
        emit changed();
        return;
    }
    QUrl url(QStringLiteral("http://") + _address);
    if (url.port() < 0) url.setPort(9072);
    url.setPath("/v1/" + action);
    QNetworkRequest networkRequest(url);
    networkRequest.setRawHeader("Authorization", "Bearer " + _code.toUtf8());
    networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    networkRequest.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    _busy = true;
    if (action != "status") { _error.clear(); _operationError = false; }
    emit changed();
    QNetworkReply* reply = action == "status" ? _network.get(networkRequest) :
        _network.post(networkRequest, QJsonDocument(QJsonObject{{"streams", QJsonArray::fromStringList(keys)}}).toJson(QJsonDocument::Compact));
    _reply = reply;
    auto timeout = new QTimer(reply);
    timeout->setSingleShot(true);
    timeout->start(action == "status" ? 6000 : 90000);
    connect(timeout, &QTimer::timeout, reply, [reply]() { reply->setProperty("timedOut", true); reply->abort(); });
    connect(reply, &QNetworkReply::finished, this, [this, reply, timeout, action]() {
        timeout->stop();
        _reply = nullptr;
        _busy = false;
        const QByteArray bytes = reply->readAll();
        const auto object = QJsonDocument::fromJson(bytes).object();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const auto statusObject = object.value("status").toObject();
        if (reply->error() == QNetworkReply::NoError && httpStatus == 200 &&
            object.value("ok").toBool() && statusObject.value("api_version").toInt() == 1 &&
            statusObject.value("streams").isArray() && statusObject.value("storage").isObject()) {
            _status = statusObject.toVariantMap();
            _connected = true;
            if (!_operationError) _error.clear();
        } else {
            _connected = false;
            _operationError = action != "status";
            _error = object.value("error").toString();
            if (_error.isEmpty()) _error = reply->property("timedOut").toBool() ?
                tr("主控响应超时；操作结果未确认，请刷新状态") :
                tr("未能确认主控录像状态，请检查地址、连接码和网络");
        }
        reply->deleteLater();
        emit changed();
    });
}
