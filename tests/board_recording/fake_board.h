#pragma once
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
class FakeBoard : public QTcpServer {
public:
    QList<QByteArray> requests;
    QByteArray response;
    int code=200;
    bool delay=false;
    FakeBoard() {
        if (!listen(QHostAddress::LocalHost)) qFatal("Cannot listen");
        response=QJsonDocument(QJsonObject{{"ok",true},{"status",QJsonObject{
            {"api_version",1},{"storage",QJsonObject{{"mounted",true},{"free_bytes",1e11},{"error",""}}},
            {"streams",QJsonArray{QJsonObject{{"key","board"},{"phase","waiting"}}}},
            {"session",QJsonObject{{"path","/data/uav-recordings/test"}}}}}}).toJson();
        connect(this,&QTcpServer::newConnection,this,[this]() {
            while(hasPendingConnections()) {
                auto socket=nextPendingConnection();
                connect(socket,&QTcpSocket::disconnected,socket,&QObject::deleteLater);
                connect(socket,&QTcpSocket::readyRead,socket,[this,socket]() {
                    QByteArray data=socket->property("data").toByteArray()+socket->readAll();
                    socket->setProperty("data",data);
                    int at=data.indexOf("\r\n\r\n");if(at<0)return;
                    int length=0;for(const auto& line:data.left(at).split('\n'))
                        if(line.toLower().startsWith("content-length:"))length=line.mid(15).trimmed().toInt();
                    if(data.size()<at+4+length || socket->property("handled").toBool())return;
                    socket->setProperty("handled",true);requests.append(data);
                    if(delay)return;
                    socket->write("HTTP/1.1 "+QByteArray::number(code)+" Result\r\nContent-Type: application/json\r\nContent-Length: "+QByteArray::number(response.size())+"\r\nConnection: close\r\n\r\n"+response);
                    socket->disconnectFromHost();
                });
            }
        });
    }
    QString address() const { return "127.0.0.1:"+QString::number(serverPort()); }
};
