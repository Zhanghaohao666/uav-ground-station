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
    // Previous versions asked users to paste a token. Never reuse a token for a replacement board.
    settings.remove("BoardRecording/code");
    settings.remove("BoardRecording/remember");
    _network.setProxy(QNetworkProxy::NoProxy);
    _poll.setInterval(3000);
    connect(&_poll, &QTimer::timeout, this, &XBoardRecordingController::refresh);

}

XBoardRecordingController::~XBoardRecordingController()
{
    cancelRequest(); // Never send stop on disconnect, page close or app exit.
}

void XBoardRecordingController::cancelRequest()
{
    _poll.stop();
    if (_bootstrap) {
        disconnect(_bootstrap, nullptr, this, nullptr);
        _bootstrap->kill();
        _bootstrap->deleteLater();
        _bootstrap = nullptr;
    }
    if (_reply) {
        disconnect(_reply, nullptr, this, nullptr);
        _reply->abort();
        _reply->deleteLater();
        _reply = nullptr;
    }
    _busy = false;
}

bool XBoardRecordingController::configure(const QString& address)
{
    const QString trimmedAddress=address.trimmed();
    const QUrl url(QStringLiteral("http://")+trimmedAddress);
    if (!url.isValid() || !BoardSsh::validHost(url.host()) || !url.userInfo().isEmpty() ||
        (!url.path().isEmpty() && url.path()!="/") || url.hasQuery() || url.hasFragment() ||
        (url.port()!=-1 && (url.port()<1 || url.port()>65535))) {
        _error=QString::fromUtf8("\xe8\xaf\xb7\xe8\xbe\x93\xe5\x85\xa5\xe6\x9c\x89\xe6\x95\x88\xe7\x9a\x84\xe4\xb8\xbb\xe6\x8e\xa7\x20\x49\x50\xef\xbc\x88\xe5\x8f\xaf\xe5\xb8\xa6\xe5\xbd\x95\xe5\x83\x8f\xe6\x8e\xa5\xe5\x8f\xa3\xe7\xab\xaf\xe5\x8f\xa3\xef\xbc\x89\xe3\x80\x82"); _operationError=true; emit changed();return false;
    }
    cancelRequest();
    _address=trimmedAddress;_code.clear();_configured=true;
    _connected=false;_status.clear();_error.clear();_operationError=false;
    QSettings().setValue("BoardRecording/address",_address);
    emit configurationChanged();emit changed();refresh();return true;
}

BoardSshLaunch XBoardRecordingController::connectionPlan(QString* error) const {
    const QString host=QUrl("http://"+_address).host();
    QSettings settings;
    const int port=host==settings.value("BoardMaintenance/mainHost","192.168.2.36").toString()
        ? settings.value("BoardMaintenance/mainPort",22).toInt():22;
    const QVariantMap config={{"mainHost",host},{"mainPort",port},{"algorithmHost","192.168.10.2"},
        {"algorithmPort",22},{"viaMain",false}};
    auto result=BoardSsh::plan(config,"main",BoardSsh::clientProgram(),BoardSsh::askpassProgram(),BoardSsh::stateDirectory(),error,false);
    if(!result.program.isEmpty()) result.arguments<<"printf '%s\\n' dev | sudo -S -p '' cat /etc/uav-record-api/token";
    return result;
}
void XBoardRecordingController::fetchConnection() {
    if(_busy || !_configured)return;
    QString error;const auto plan=connectionPlan(&error);
    if(plan.program.isEmpty()) {_error=error;emit changed();return;}
    _busy=true;_connected=false;emit changed();
    auto process=new QProcess(this);_bootstrap=process;
    process->setProcessEnvironment(BoardSsh::environment(plan));
    process->setWorkingDirectory(plan.workingDirectory);
    auto timer=new QTimer(process);timer->setSingleShot(true);timer->start(25000);
    connect(timer,&QTimer::timeout,process,[process](){process->setProperty("timedOut",true);process->kill();});
    connect(process,&QProcess::readyReadStandardOutput,process,[process](){
        auto bytes=process->property("output").toByteArray()+process->readAllStandardOutput();
        if(bytes.size()>4096){process->setProperty("invalidOutput",true);process->kill();return;}
        process->setProperty("output",bytes);
    });
    // Never show or persist credential output in the UI or logs.
    connect(process,&QProcess::readyReadStandardError,process,[process](){process->readAllStandardError();});
    auto finish=[this,process,timer](){
        if(_bootstrap!=process)return;
        timer->stop();_bootstrap=nullptr;_busy=false;
        const auto code=QString::fromLatin1(process->property("output").toByteArray()+process->readAllStandardOutput()).trimmed();
        const bool valid=process->exitStatus()==QProcess::NormalExit && process->exitCode()==0 &&
            !process->property("timedOut").toBool() && !process->property("invalidOutput").toBool() &&
            QRegularExpression("^[0-9a-f]{64}$").match(code).hasMatch();
        if(valid) {_code=code;_error.clear();_operationError=false;_poll.start();}
        else {_code.clear();_error=QString::fromUtf8("\xe4\xb8\xbb\xe6\x8e\xa7\xe8\x87\xaa\xe5\x8a\xa8\xe8\xbf\x9e\xe6\x8e\xa5\xe5\xa4\xb1\xe8\xb4\xa5\xe3\x80\x82\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\x20\x49\x50\xe3\x80\x81\x53\x53\x48\x20\xe7\xab\xaf\xe5\x8f\xa3\xe3\x80\x81\x64\x65\x76\x20\xe8\xb4\xa6\xe5\x8f\xb7\xe5\x92\x8c\xe6\x9d\xbf\xe7\xab\xaf\xe5\xbd\x95\xe5\x83\x8f\xe6\x9c\x8d\xe5\x8a\xa1\xef\xbc\x9b\xe6\x9b\xb4\xe6\x8d\xa2\xe5\x90\x8c\x20\x49\x50\x20\xe6\x9d\xbf\xe5\x8d\xa1\xe5\xaf\xbc\xe8\x87\xb4\xe6\x8c\x87\xe7\xba\xb9\xe5\x8f\x98\xe5\x8c\x96\xe6\x97\xb6\xe9\x9c\x80\xe5\x85\x88\xe7\xa1\xae\xe8\xae\xa4\xe6\x8c\x87\xe7\xba\xb9\xe3\x80\x82");_operationError=true;}
        process->deleteLater();emit changed();if(valid)request("status");
    };
    connect(process,QOverload<int,QProcess::ExitStatus>::of(&QProcess::finished),this,[finish](int,QProcess::ExitStatus){finish();});
    connect(process,&QProcess::errorOccurred,this,[finish](QProcess::ProcessError e){if(e==QProcess::FailedToStart)finish();});
    process->start(plan.program,plan.arguments);
}
void XBoardRecordingController::refresh() {
    if(_busy || !_configured)return;
    if(_code.isEmpty())fetchConnection();else request("status");
}
void XBoardRecordingController::startSelected(const QStringList& keys) { request("start", keys); }
void XBoardRecordingController::stopSelected(const QStringList& keys) { request("stop", keys); }
void XBoardRecordingController::stopAll() { request("stop", {"all"}); }

void XBoardRecordingController::request(const QString& action, const QStringList& keys)
{
    if (_busy) return;
    if (_code.isEmpty() || (action != "status" && keys.isEmpty())) {
        _error = QString::fromUtf8("\xe8\xaf\xb7\xe5\x85\x88\xe8\xbf\x9e\xe6\x8e\xa5\xe4\xb8\xbb\xe6\x8e\xa7\xe5\xb9\xb6\xe9\x80\x89\xe6\x8b\xa9\xe8\xa6\x81\xe5\xbd\x95\xe5\x88\xb6\xe6\x88\x96\xe5\x81\x9c\xe6\xad\xa2\xe7\x9a\x84\xe8\xa7\x86\xe9\xa2\x91");
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
            if (httpStatus == 401) { _code.clear(); _poll.stop(); }
            _operationError = action != "status";
            _error = object.value("error").toString();
            if (_error.isEmpty()) _error = reply->property("timedOut").toBool() ?
                QString::fromUtf8("\xe4\xb8\xbb\xe6\x8e\xa7\xe5\x93\x8d\xe5\xba\x94\xe8\xb6\x85\xe6\x97\xb6\xef\xbc\x9b\xe6\x93\x8d\xe4\xbd\x9c\xe7\xbb\x93\xe6\x9e\x9c\xe6\x9c\xaa\xe7\xa1\xae\xe8\xae\xa4\xef\xbc\x8c\xe8\xaf\xb7\xe5\x88\xb7\xe6\x96\xb0\xe7\x8a\xb6\xe6\x80\x81") :
                QString::fromUtf8("\xe6\x9c\xaa\xe8\x83\xbd\xe7\xa1\xae\xe8\xae\xa4\xe4\xb8\xbb\xe6\x8e\xa7\xe5\xbd\x95\xe5\x83\x8f\xe7\x8a\xb6\xe6\x80\x81\xef\xbc\x8c\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\x20\x49\x50\xe3\x80\x81\xe7\xbd\x91\xe7\xbb\x9c\xe5\x92\x8c\xe5\xbd\x95\xe5\x83\x8f\xe6\x9c\x8d\xe5\x8a\xa1");
        }
        reply->deleteLater();
        emit changed();
    });
}
