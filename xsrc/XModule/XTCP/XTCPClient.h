//#ifndef TcpServerController_H
//#define TcpServerController_H

#ifndef CcTcpClient_H
#define CcTcpClient_H

#include <QObject>
#include <QByteArray>
#include <QString>

//#include <QTcpServer>           //监听套接字
//#include <QTcpSocket>           //通信套接字
//#include <QAbstractSocket>

#include <qtimer.h>
#include <QMetaEnum>

#include <QtNetwork>
#include "qloggingcategory.h"

class VideoManager;

class TCPController;

class CcTcpClient : public QObject
{
    Q_OBJECT

public:
    /*explicit*/ CcTcpClient(QObject *parent = nullptr);
    CcTcpClient(TCPController* controller);

//    CcTcpClient(void);
    ~CcTcpClient();


    ///--连接和断开的接口
//    Q_INVOKABLE bool    connect(QString ip,  int port);
//    Q_INVOKABLE bool    disConnetWorker          (void);


    ///--具体的发送和接收函数
//    Q_INVOKABLE bool    start               (uint16_t port, QHostAddress addr = QHostAddress::AnyIPv4);
    Q_INVOKABLE bool    sendData            (const QString info);
//    Q_INVOKABLE bool    sendValue           (char value);
    Q_INVOKABLE bool    sendDataAdd         (void);
//    Q_INVOKABLE bool    sendClearXY         (void);
//    void ReceiveParse(const QByteArray &buf);
    bool                 _connected = false;
signals:
    ///--信号
    void isConnectedChanged      (const bool isConnect);
    void tcpServerPortChanged    (const int port);
    void tcpServerIPChanged      (const QString ip);
    void ReceiveParse(QByteArray buf);
    void _isConnectedWorker(bool isConnect);


public slots:
    void threadStart(void);
    void connectHandle(void);
    void fristConnect(void);
    void seedDataWorker(int cmd, int dir);
    void sendXYWorker  (int x, int y);
//    void IPPortWorker();
    bool connetWorker(QString ip, int port, QString localIp);
    bool disConnetWorker          (void);

    void writeData(const char *data, qint64 len);
    void writeBytes(QByteArray data);


private slots:
    void socketConnected();
    void socketDisconnected();
    void connectionTimedOut();
    void _socketError();
    void readData();
//    void connectHandle(void);

private:
    void _destroySocket(QTcpSocket* socket);
    void _setConnected(bool connected);

    ///--
    ///
    TCPController* _controller = nullptr;
//    int                  _tcpServerPort = 0;
//    QString              _tcpServerIP = "";         //服务器IP
    QTcpSocket*         _tcpSocket = nullptr;
    VideoManager*       _videoManager = nullptr;

    QTimer*              _connectTimer = nullptr;
    QTimer*              _sendDataAddTimer = nullptr;
    char _add = 0;
    int                             _dir = 0;

};


class TCPController : public QObject
{
    Q_OBJECT
public:
    TCPController(QObject *parent = nullptr,
                  const QString& settingsGroup = QStringLiteral("ccTcpClient"),
                  const QString& defaultIP = QStringLiteral("192.168.144.202"),
                  int defaultPort = 8890);
    ~TCPController();

    ///--tcpClient
    Q_PROPERTY(CcTcpClient  *tcpClient      READ tcpClient    WRITE  setTcpClient       NOTIFY tcpClientChanged)
    CcTcpClient*  tcpClient   () { return _tcpClient; }
    void setTcpClient   (CcTcpClient  *tcpClient);

    ///--gimbalPitch
    Q_PROPERTY(qreal        gimbalPitch      READ gimbalPitch    NOTIFY gimbalPitchChanged)
    qreal    gimbalPitch  () const { return _gimbalPitch; }

    ///--Base
    Q_PROPERTY(bool         isConnected      READ isConnected    WRITE  setIsConnected       NOTIFY isConnectedChanged)
    Q_PROPERTY(int          tcpServerPort    READ tcpServerPort  WRITE  setTcpServerPort     NOTIFY tcpServerPortChanged)
    Q_PROPERTY(QString      tcpServerIP      READ tcpServerIP    WRITE  setTcpServerIP       NOTIFY tcpServerIPChanged)
    Q_PROPERTY(QString      tcpLocalIP       READ tcpLocalIP     WRITE  setTcpLocalIP        NOTIFY tcpLocalIPChanged)
    ///--READ
    bool    isConnected   () const { return _isConnectedController; }
    int    tcpServerPort   () const {return _tcpServerPortControler; }
    QString  tcpServerIP   () const { return _tcpServerIPController; }
    QString  tcpLocalIP    () const { return _tcpLocalIPController; }
    ///--WRITE
    void setTcpServerPort    (const int port);
    void setTcpServerIP      (const QString ip);
    void setTcpLocalIP       (const QString ip);
    void setIsConnected      (const bool);


    ///--
    void null() ;
    void QSettingsInit(void);
    Q_INVOKABLE void sendDataQml(int cmd, int dir);
    Q_INVOKABLE void sendTextQml(const QString& text);
    Q_INVOKABLE void sendXYQml(int x, int y);
    Q_INVOKABLE void connectQml(QString ip, int port);
    Q_INVOKABLE void disConnectQml(void);
    Q_INVOKABLE void sendBytesQml(const QByteArray& bytes);

    //start_cch_20230316
    void sendData(const char* uc, int len);
    void sendBytes(const QByteArray& bytes);
    CcTcpClient*    _tcpClient = nullptr;

signals:
    ///--信号
    void tcpClientChanged      (CcTcpClient  *tcpClient);
    void _initThreadWorker          (void);
    void _fristConnect              (void);
    void gimbalPitchChanged      (qreal pitch);
    void sendDataController(const char *data, qint64 len);
    void sendBytesController(QByteArray bytes);
    void sendTextController(QString text);
    void sendXYController(int x, int y);

    bool connetController(QString tcpServerIP, int tcpServerPort, QString localIP);
    bool disConnetController( void);

    void configConnectedController(bool _isConnectedController);

    void isConnectedChanged      (const bool isConnect);
    void tcpServerPortChanged    (const int port);
    void tcpServerIPChanged      (const QString ip);
    void tcpLocalIPChanged       (const QString ip);


private slots:
    void ReceiveParseController(const QByteArray &buf);
    void isConnectedController(bool isConnect);


private:
    QThread*        _workerThread = nullptr;

    qreal            _gimbalPitch = -90.0 ;

    int                  _tcpServerPortControler = 0;
    QString              _tcpServerIPController = "";         //服务器IP
    QString              _tcpLocalIPController;
    bool                 _isConnectedController = false;
    QString              _settingsGroup;
    QString              _defaultIP;
    int                  _defaultPort = 0;

    QByteArray          _sbuf ;
    static const char* _groupKey;
    static const char* _ipKey;
    static const char* _portKey;
    static const char* _localIpKey;
};


#endif
