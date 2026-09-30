#include <QtQml>
//#include "TcpServerController.h"
#include "XTCPClient.h"
#include "QGCApplication.h"
#include "qdebug.h"

//#include "QGCCorePlugin.h"

#include <QHostInfo>
#include <QNetworkProxy>

#include <iostream>
#include <string>
#include <stdio.h>

#include <qthread.h>

using namespace std;

namespace {
constexpr int kConnectionTimeoutMs = 15000;
}

//QGC_LOGGING_CATEGORY(CcTcpClient,  "CcTcpClient")
///--待增加的，定时器停止后，连接上了，而当连接断开的时候，需要重新启动定时器的

CcTcpClient::CcTcpClient(TCPController* controller)
    :  _controller        (controller)
{
    QObject::connect(_controller, &TCPController::_initThreadWorker,    this, &CcTcpClient::threadStart);
    QObject::connect(_controller, &TCPController::_fristConnect,    this, &CcTcpClient::fristConnect);


}

CcTcpClient::~CcTcpClient()
{
    disConnetWorker();
}

// 接收心跳包 每5秒连一次
void CcTcpClient::threadStart()
{
    // CcTcpClient is moved to its worker thread after construction, so the
    // connection timer must be created here to give it the correct affinity.
    if (!_connectTimer) {
        _connectTimer = new QTimer(this);
        _connectTimer->setSingleShot(true);
        QObject::connect(_connectTimer, &QTimer::timeout, this, &CcTcpClient::connectionTimedOut);
    }
}

//视频因为此程序而卡
void CcTcpClient::connectHandle()
{
    _setConnected(_tcpSocket && _tcpSocket->state() == QAbstractSocket::ConnectedState);
}


void CcTcpClient::fristConnect() {
    connetWorker(_controller->tcpServerIP(), _controller->tcpServerPort(), _controller->tcpLocalIP());
}

///--ok
void CcTcpClient::_socketError()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket || socket != _tcpSocket) {
        return;
    }

    qWarning().noquote() << tr("TCP socket error: %1").arg(socket->errorString());
    if (_connectTimer) {
        _connectTimer->stop();
    }
    _destroySocket(socket);
    _setConnected(false);
}

void CcTcpClient::socketDisconnected()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket || socket != _tcpSocket) {
        return;
    }

    qDebug() << "Socket disconnected";
    if (_connectTimer) {
        _connectTimer->stop();
    }
    _destroySocket(socket);
    _setConnected(false);
}

void CcTcpClient::socketConnected()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket || socket != _tcpSocket) {
        return;
    }

    if (_connectTimer) {
        _connectTimer->stop();
    }
    qInfo().noquote() << tr("TCP connected from %1:%2 to %3:%4")
                            .arg(socket->localAddress().toString())
                            .arg(socket->localPort())
                            .arg(socket->peerAddress().toString())
                            .arg(socket->peerPort());
    _setConnected(true);
}

void CcTcpClient::connectionTimedOut()
{
    if (!_tcpSocket || _tcpSocket->state() == QAbstractSocket::ConnectedState) {
        return;
    }

    qWarning().noquote() << tr("TCP connection timed out after %1 ms").arg(kConnectionTimeoutMs);
    _destroySocket(_tcpSocket);
    _setConnected(false);
}


///--ok--qml 中连接和断开的按钮
bool CcTcpClient::connetWorker(QString ip, int port, QString localIp)
{

    //先验证ip 和 端口：
    ip = ip.trimmed();
    if (!ip.isEmpty() && port > 0 && port <= 65535) {
//        qDebug("ip len is: %d", _tcpServerIP.length());  //13
    }
    else {
//        qDebug("ip or port format error!!!");
        _setConnected(false);
//        setIsConnected(false);
        return false;
    }

    localIp = localIp.trimmed();

    if (_tcpSocket) {
        const QAbstractSocket::SocketState previousState = _tcpSocket->state();
        if (previousState == QAbstractSocket::ConnectedState) {
            qDebug() << "connect called while already connected";
            _setConnected(true);
            return true;
        }

        qDebug().noquote() << tr("Discarding TCP socket in state %1 before reconnecting")
                                  .arg(static_cast<int>(previousState));
        if (_connectTimer) {
            _connectTimer->stop();
        }
        _destroySocket(_tcpSocket);
    }

    Q_ASSERT(_tcpSocket == nullptr);

    _tcpSocket = new QTcpSocket(this);
    // Explicitly bypass application and system proxies for direct hardware control links
    _tcpSocket->setProxy(QNetworkProxy::NoProxy);

    if (!_connectTimer) {
        threadStart();
    }
    _connectTimer->start(kConnectionTimeoutMs);

    if (!localIp.isEmpty()) {
        QHostAddress localAddress;
        if (localAddress.setAddress(localIp)) {
            if (!_tcpSocket->bind(localAddress, 0, QAbstractSocket::ShareAddress | QAbstractSocket::ReuseAddressHint)) {
                qWarning().noquote() << tr("Failed to bind TCP local IP %1: %2, falling back to automatic route")
                                        .arg(localIp, _tcpSocket->errorString());
                // Recreate clean socket for automatic routing
                delete _tcpSocket;
                _tcpSocket = new QTcpSocket(this);
                _tcpSocket->setProxy(QNetworkProxy::NoProxy);
            } else {
                qInfo().noquote() << tr("Successfully bound TCP local IP: %1").arg(localIp);
            }
        } else {
            qWarning().noquote() << tr("Invalid TCP local IP address: %1, falling back to automatic route").arg(localIp);
        }
    }

    // Connect signals after bind so bind failure does not trigger error slots prematurely
    QObject::connect(_tcpSocket, &QIODevice::readyRead, this, &CcTcpClient::readData);
    QObject::connect(_tcpSocket, &QTcpSocket::connected, this, &CcTcpClient::socketConnected);
    QObject::connect(_tcpSocket, &QTcpSocket::disconnected, this, &CcTcpClient::socketDisconnected);

#if QT_VERSION < QT_VERSION_CHECK(5, 15, 0)
    QObject::connect(_tcpSocket, static_cast<void (QTcpSocket::*)(QAbstractSocket::SocketError)>(&QTcpSocket::error),
                     this, &CcTcpClient::_socketError);  //连接错误发送提示
#else
    QObject::connect(_tcpSocket, &QAbstractSocket::errorOccurred, this, &CcTcpClient::_socketError);
#endif

    qInfo().noquote() << tr("Starting TCP connection to %1:%2 from %3")
                            .arg(ip)
                            .arg(port)
                            .arg(localIp.isEmpty() ? tr("automatic route") : localIp);
    QHostAddress serverAddress;
    if (serverAddress.setAddress(ip)) {
        // Use the address overload for literal IPv4/IPv6 addresses. This
        // bypasses host-name lookup and immediately starts the TCP attempt.
        _tcpSocket->connectToHost(serverAddress, static_cast<quint16>(port));
    } else {
        _tcpSocket->connectToHost(ip, static_cast<quint16>(port));
    }

    // The request has been accepted. Actual success is reported only from
    // socketConnected(), without blocking the worker event loop.
    return true;
}

///--ok--qml 断开
bool CcTcpClient::disConnetWorker(void)
{
    if (_connectTimer) {
        _connectTimer->stop();
    }
    if (_tcpSocket) {
        _destroySocket(_tcpSocket);
        qDebug() << "Close TCP socke";
    }
    _setConnected(false);
    return  true;
}

////-----------------------------数据收发-----------------------------------///
//4.1 接收服务器数据 (socket->readAll())
void CcTcpClient::readData()
{
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket || socket != _tcpSocket) {
        return;
    }

    const QByteArray buffer = socket->readAll();
    if (!buffer.isEmpty()) {
        emit ReceiveParse(buffer);
    }
}

void CcTcpClient::_destroySocket(QTcpSocket* socket)
{
    if (!socket) {
        return;
    }

    if (socket == _tcpSocket) {
        _tcpSocket = nullptr;
    }
    QObject::disconnect(socket, nullptr, this, nullptr);
    socket->abort();
    socket->deleteLater();
}

void CcTcpClient::_setConnected(bool connected)
{
    if (_connected == connected) {
        return;
    }

    _connected = connected;
    emit _isConnectedWorker(_connected);
}

bool CcTcpClient::sendData(const QString info)
{
    if(!_tcpSocket)
    {
        qDebug()<< "_tcpSocket is null";
        return false;
    }
    QByteArray data = info.toUtf8();
    _tcpSocket->write(data);
    _tcpSocket->flush();

    qDebug()  << QString("[data] : %1").arg(QString::fromUtf8(data));
    return true;
}



void CcTcpClient::sendXYWorker(int x, int y)
{
    if(x>4096 || x<1) {
        qDebug() << QString("x error: %1").arg(x)   ;
        return  ;
    }
    if(y>2160 || y<1) {
        qDebug() << QString("y error: %1").arg(y)   ;
        return  ;
    }

    unsigned char  data[13];

    data[0] = 0x68;  data[1] = 0x01; data[2] = 0x68;  data[3] = 0x07;
    data[4] = static_cast<uchar>(x & 0xff) ;
    data[5] = static_cast<uchar>(x>>8 & 0xff) ;
    data[6] = static_cast<uchar>(y & 0xff) ;
    data[7] = static_cast<uchar>(y>>8 & 0xff) ;
    data[8] = 0x00;

    if(_tcpSocket) {
//         const char * data = info.toUtf8().data();
        _tcpSocket->write((const char *)data);
        _tcpSocket->flush();
    }
    else {
        qDebug()  << "please open tcp!!!";
    }
}

///---清除跟踪，什么都不操作
///cmd :5 开启方向
///     data 5下 6 前  3  4
///cmd: 3 发送小滑块的值 [1~100]
void CcTcpClient::seedDataWorker(int cmd, int data) {

    ///--清除跟踪
    QByteArray add;
    add.resize(9);
    add[0] = 0x68;  add[1] = 0x01; add[2] = 0x68;
    add[3] = 0x01;  add[4] = 0x00; add[5] = 0x00;
    add[6] = 0x00; add[7] = 0x00;  add[8] = 0x00;

    if(cmd == 5) {
        add[3] = 0x05;
        add[4] = static_cast<char>(data);
        add[8] = 0x68;
    }
    else if(cmd == 3) {
        if(data>100 || data<1)      return;
        add[3] = 0x03;
        add[4] = data;
        add[8] = 0x68;
    }
    else if(cmd ==10) {
        add[3] = 0x10;
        add[4] = data;
    }

    if(_tcpSocket) {
        _tcpSocket->write(add);
        _tcpSocket->flush();
    }
    else {
        qDebug()  << "please open tcp!!!";
    }

}

bool CcTcpClient::sendDataAdd(void) {
    QByteArray add;
    qint64 ret = 0;
    _add +=5;
    if(_add > 100) {_add = 0;}

    add.resize(9);
    add[0] = 0x68;
    add[1] = 0x01;
    add[2] = 0x68;
    add[3] = 0x03;
    add[4] = _add;
    add[5] = 0x00;
    add[6] = 0x00;
    add[7] = 0x00;
    add[8] = 0x68;

    if(_tcpSocket) {
        ret = _tcpSocket->write(add);
        _tcpSocket->flush();
        qDebug()  << "ret" << ret;
    }
    else {
//        qDebug()  << "please open tcp!!!";
        return true;
    }
    return ret == -1;
}


///--发送写函数
void CcTcpClient::writeData(const char *data, qint64 len) {
    if(_tcpSocket) {
        _tcpSocket->write(data, len);
        _tcpSocket->flush();
        //qDebug()  << "add" <<add.toHex();
    }
    else {
        qDebug()  << "please open tcp!!!";
    }
//  qDebug() << "!!! writeData() Function Qthread id is" << QThread::currentThread();
}

void CcTcpClient::writeBytes(QByteArray data) {
    if(_tcpSocket) {
        _tcpSocket->write(data);
        _tcpSocket->flush();
    }
    else {
        qDebug()  << "please open tcp!!!";
    }
}

const char* TCPController::_groupKey =    "ccTcpClient";
const char* TCPController::_ipKey =       "tcpServerIP";
const char* TCPController::_portKey =     "tcpServerPort";
const char* TCPController::_localIpKey =  "localIp";

///----------------------------
TCPController::TCPController(QObject* parent, const QString& settingsGroup, const QString& defaultIP, int defaultPort)
    : QObject         (parent)
    , _settingsGroup  (settingsGroup)
    , _defaultIP      (defaultIP)
    , _defaultPort    (defaultPort)
{
    //配置tcp ip
    QSettingsInit();

    _tcpClient = new CcTcpClient(this);
    _workerThread = new QThread(this);

    // 调用 moveToThread 将该任务交给 workThread
    _tcpClient->moveToThread(_workerThread);

//    qDebug() << "Controller Qthread id is" << QThread::currentThread();

    connect(_workerThread, &QThread::finished,      _tcpClient,  &QObject::deleteLater);
//    connect(_tcpClient,    &CcTcpClient::ReceiveParse,this,&TCPController::ReceiveParseController);
    connect(this,    &TCPController::sendDataController, _tcpClient, &CcTcpClient::writeData);
    connect(this,    &TCPController::sendBytesController, _tcpClient, &CcTcpClient::writeBytes);
    connect(this,    &TCPController::sendTextController, _tcpClient, &CcTcpClient::sendData);
    connect(this,    &TCPController::sendXYController,   _tcpClient, &CcTcpClient::sendXYWorker);

    //可以重建一个配置类，包括ip port 连接状态
    QObject::connect(_tcpClient, &CcTcpClient::_isConnectedWorker,    this, &TCPController::isConnectedController);
    connect(this,    &TCPController::connetController, _tcpClient, &CcTcpClient::connetWorker);
    connect(this,    &TCPController::disConnetController, _tcpClient, &CcTcpClient::disConnetWorker);

//    connect(this,    &TCPController::configConnectedController, _tcpClient, &CcTcpClient::seedDataWorker);
    _workerThread->start();
    emit _initThreadWorker();
}

void TCPController::QSettingsInit() {

    QSettings settings;
    settings.beginGroup(_settingsGroup.isEmpty() ? QString::fromLatin1(_groupKey) : _settingsGroup);
    _tcpServerIPController =  settings.value(_ipKey).toString();
    _tcpServerPortControler = settings.value(_portKey).toInt();
    _tcpLocalIPController = settings.value(_localIpKey).toString().trimmed();
//    qDebug() << QString("get init1 ip: %1, port: %2").arg(_tcpServerIP).arg(_tcpServerPortControler);
    //第一次更新数据，如果表中没有数据的话
    if(_tcpServerIPController.length() < 1) {
        _tcpServerIPController = _defaultIP.isEmpty() ? QStringLiteral("192.168.144.202") : _defaultIP;
        settings.setValue(_ipKey, _tcpServerIPController);
    }
    if(_tcpServerPortControler < 1) {
        _tcpServerPortControler = _defaultPort > 0 ? _defaultPort : 8890;
        settings.setValue(_portKey, _tcpServerPortControler);
    }
//    qDebug() << QString("get init2 ip: %1, port: %2").arg(_tcpServerIPController).arg(_tcpServerPort);
    tcpServerIPChanged(_tcpServerIPController);
    tcpServerPortChanged(_tcpServerPortControler);
    tcpLocalIPChanged(_tcpLocalIPController);
}


void TCPController::sendData(const char* uc, int len) {
    sendBytes(QByteArray(uc, len));
}

void TCPController::sendBytes(const QByteArray& bytes) {
    emit sendBytesController(bytes);
}

void TCPController::sendBytesQml(const QByteArray& bytes) {
    sendBytes(bytes);
}

void TCPController::sendXYQml(int x, int y) {
    emit sendXYController(x,y);
}

void TCPController::sendTextQml(const QString& text) {
    emit sendTextController(text);
}

void TCPController::sendDataQml(int cmd, int dir) {
//    emit sendDataController(cmd, dir);
}

void TCPController::connectQml(QString ip, int port) {
    emit connetController(ip, port, _tcpLocalIPController);
}

void TCPController::disConnectQml(void) {
    emit disConnetController();
}

void TCPController::isConnectedController(bool isConnect) {
    if(_isConnectedController != isConnect) {
        _isConnectedController = isConnect;
        emit isConnectedChanged(_isConnectedController);
    }
}

void TCPController::setIsConnected(const bool isConnected) {

    if(_isConnectedController != isConnected) {
        _isConnectedController = isConnected;
        emit isConnectedChanged(_isConnectedController);
    }
}

void TCPController::setTcpServerPort(const int port) {

    if(_tcpServerPortControler != port) {
        _tcpServerPortControler = port;
        QSettings settings;
        settings.beginGroup(_settingsGroup.isEmpty() ? QString::fromLatin1(_groupKey) : _settingsGroup);
        settings.setValue(_portKey, _tcpServerPortControler);
        ///不能以下的调用方式，因为是两个线程
//        _tcpClient->connect(_tcpServerIPController, _tcpServerPortControler);
    }
}

void TCPController::setTcpServerIP (const QString ip) {
    if(_tcpServerIPController != ip) {
        _tcpServerIPController = ip;
        QSettings settings;
        settings.beginGroup(_settingsGroup.isEmpty() ? QString::fromLatin1(_groupKey) : _settingsGroup);
        settings.setValue(_ipKey, _tcpServerIPController);
    }
}

void TCPController::setTcpLocalIP(const QString ip) {
    const QString trimmedIp = ip.trimmed();
    if (_tcpLocalIPController != trimmedIp) {
        _tcpLocalIPController = trimmedIp;
        QSettings settings;
        settings.beginGroup(_settingsGroup.isEmpty() ? QString::fromLatin1(_groupKey) : _settingsGroup);
        settings.setValue(_localIpKey, _tcpLocalIPController);
        emit tcpLocalIPChanged(_tcpLocalIPController);
    }
}

void TCPController::setTcpClient   (CcTcpClient  *tcpClient) {
    if(tcpClient != _tcpClient)
    {
    }
}

void TCPController::null() {
}

TCPController::~TCPController() {
    _workerThread->quit();
    _workerThread->wait();
}

//
void TCPController::ReceiveParseController(const QByteArray &buf){
    unsigned char* p;
    p = (unsigned char*)buf.data();

    if((buf[0] == 0x68)
    && (buf[1] == 0x01)
    && (buf[2] == 0x68)
    && (buf[3] == 0x06)) {
        int tmp16 = /* ( static_cast<int>*/(p[8]<<8) | p[9];
//        qDebug("tmp16 is %d", tmp16);
        if(tmp16 > 65536-18000) {
            tmp16 = (65536 - 18000 - tmp16) + 100;// 180000 - (65536 - tmp16);
        }
        else if(tmp16 <= 18000){
            tmp16 = 18000 - tmp16;
        }
        _gimbalPitch =  static_cast<qreal>(tmp16) / 100.0;
        //gimbalPitch:  -120 ~  -90 ~  0 ~ 60
        emit gimbalPitchChanged(_gimbalPitch);
    }
}

