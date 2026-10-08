#include <QtTest>
#include <QSettings>
#include <QTemporaryDir>
#include <QTcpServer>
#include <QTcpSocket>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include "XGimbalTcpController.h"
#include "XAlgorithmTcpController.h"

class Endpoint : public QObject {
public:
    QTcpServer server;
    QPointer<QTcpSocket> socket;
    QByteArray received;
    Endpoint() {
        if (!server.listen(QHostAddress::LocalHost)) qFatal("Cannot bind test server");
        connect(&server,&QTcpServer::newConnection,this,[this] {
            socket=server.nextPendingConnection();
            connect(socket,&QTcpSocket::readyRead,this,[this]{received+=socket->readAll();});
        });
    }
    void connectController(TCPController& c) { c.connectQml("127.0.0.1",server.serverPort()); }
};

class PayloadTests : public QObject {
    Q_OBJECT
    QTemporaryDir settings;
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("UavPayloadTests");QCoreApplication::setApplicationName("IndependentControls");
        QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
        qmlRegisterType<XGimbalTcpController>("PayloadTests",1,0,"GimbalController");
        qmlRegisterType<XAlgorithmTcpController>("PayloadTests",1,0,"AlgorithmController");
        auto path=QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../xsrc/XUI/XPayloadControlPanel.qml");
        qmlRegisterType(QUrl::fromLocalFile(path),"PayloadTests",1,0,"ControlPanel");
    }
    void init() { QSettings().clear(); }
    void defaultsSettingsAndOldSharedPortAreIndependent() {
        { XGimbalTcpController g;XAlgorithmTcpController a;
          QCOMPARE(g.tcpServerIP(),QString("192.168.2.36"));QCOMPARE(g.tcpServerPort(),9000);
          QCOMPARE(a.tcpServerIP(),QString("192.168.2.36"));QCOMPARE(a.tcpServerPort(),9001);
          g.setTcpServerIP("192.168.1.104");g.setTcpServerPort(9001);
          a.setTcpServerIP("192.168.10.2");a.setTcpServerPort(9000); }
        { XGimbalTcpController g;XAlgorithmTcpController a;
          QCOMPARE(g.tcpServerIP(),QString("192.168.1.104"));QCOMPARE(g.tcpServerPort(),9000);
          QCOMPARE(a.tcpServerIP(),QString("192.168.10.2"));QCOMPARE(a.tcpServerPort(),9000);
          a.setTcpServerPort(12345);QCOMPARE(g.tcpServerPort(),9000); }
    }
    void twoProductionSocketsSendCommandsOnlyToTheirOwnTargets() {
        Endpoint cloud,algorithm;XGimbalTcpController g;XAlgorithmTcpController a;
        cloud.connectController(g);algorithm.connectController(a);
        QTRY_VERIFY(g.isConnected() && a.isConnected());QTRY_VERIFY(cloud.socket && algorithm.socket);
        a.trackXY(960,540);QTRY_COMPARE(algorithm.received,QByteArray::fromHex("aa010400c0031c02"));
        QCOMPARE(cloud.received.size(),0);
        g.trackId(123);QTRY_COMPARE(cloud.received,QByteArray::fromHex("aa0204007b000000"));
        QCOMPARE(algorithm.received,QByteArray::fromHex("aa010400c0031c02"));
        a.disConnectQml();QTRY_VERIFY(!a.isConnected());QVERIFY(g.isConnected());
        g.unlockTracking();QTRY_VERIFY(cloud.received.endsWith(QByteArray::fromHex("aa030000")));
    }
    void incomingTargetsStatusesAndLogsNeverCross() {
        Endpoint cloud,algorithm;XGimbalTcpController g;XAlgorithmTcpController a;
        cloud.connectController(g);algorithm.connectController(a);QTRY_VERIFY(g.isConnected() && a.isConnected());
        QTRY_VERIFY(cloud.socket && algorithm.socket);
        cloud.socket->write(QByteArray::fromHex("aa800e000300000000000000000000000000"));
        // Fragment an algorithm report and append a target list, as on the real TCP stream.
        auto feedback=QByteArray::fromHex("aa800e000200000000000000000000000001aa810d00016400320014000a002a000000");
        algorithm.socket->write(feedback.left(3));algorithm.socket->flush();QTest::qWait(10);algorithm.socket->write(feedback.mid(3));
        QTRY_COMPARE(a.targetCount(),1);QTRY_COMPARE(g.trackerStatus(),3);QCOMPARE(a.trackerStatus(),2);
        QCOMPARE(a.targets().first().toMap()["id"].toInt(),42);QVERIFY(g.targets().isEmpty());
        a.trackId(42);QTRY_VERIFY(a.logText().contains("42"));QVERIFY(!g.logText().contains("42"));
        a.disConnectQml();QTRY_VERIFY(!a.isConnected());QVERIFY(a.targets().isEmpty());QCOMPARE(g.trackerStatus(),3);
    }
    void actualAlgorithmAndGimbalPanelsUseDistinctControllers() {
        Endpoint cloud,algorithm;QQmlEngine engine;QQmlComponent component(&engine);
        component.setData(R"(import QtQuick 2.15
import QtQuick.Controls 2.15
import PayloadTests 1.0
ApplicationWindow {
    width: 800; height: 900; visible: true
    GimbalController { id: g; objectName: "gimbalController" }
    AlgorithmController { id: a; objectName: "algorithmController" }
    ControlPanel { objectName: "algorithmPanel"; width: 390; height: 890; controller: a; trackingInputMode: 2 }
    ControlPanel { objectName: "gimbalPanel"; x: 400; width: 390; height: 890; controller: g; gimbalControls: true }
})",QUrl());
        QScopedPointer<QObject> root(component.create());QVERIFY2(root,qPrintable(component.errorString()));
        auto g=root->findChild<XGimbalTcpController*>("gimbalController");auto a=root->findChild<XAlgorithmTcpController*>("algorithmController");QVERIFY(g && a);
        auto ap=root->findChild<QQuickItem*>("algorithmPanel");auto gp=root->findChild<QQuickItem*>("gimbalPanel");QVERIFY(ap && gp);
        auto af=ap->findChild<QQuickItem*>("controlPort");auto gf=gp->findChild<QQuickItem*>("controlPort");QVERIFY(af && gf);
        QCOMPARE(af->property("text").toString(),QString("9001"));QCOMPARE(gf->property("text").toString(),QString("9000"));
        QVERIFY(!ap->findChild<QQuickItem*>("gimbalMotionControls")->isVisible());QVERIFY(gp->findChild<QQuickItem*>("gimbalMotionControls")->isVisible());
        auto track=ap->findChild<QQuickItem*>("trackTargetID");QVERIFY(track);QVERIFY(!track->isEnabled());
        cloud.connectController(*g);algorithm.connectController(*a);QTRY_VERIFY(g->isConnected() && a->isConnected());
        QTRY_VERIFY(track->isEnabled());ap->findChild<QQuickItem*>("trackingTargetID")->setProperty("text","42");
        QVERIFY(QMetaObject::invokeMethod(track,"clicked"));QTRY_COMPARE(algorithm.received,QByteArray::fromHex("aa0204002a000000"));QVERIFY(cloud.received.isEmpty());
        algorithm.received.clear();
        QVERIFY(QMetaObject::invokeMethod(ap->findChild<QQuickItem*>("enableDetection"),"clicked"));
        QTRY_COMPARE(algorithm.received,QByteArray::fromHex("aa05010001"));QVERIFY(cloud.received.isEmpty());
        algorithm.socket->write(QByteArray::fromHex("aa810d00016400320014000a002a000000"));
        QTRY_VERIFY(ap->findChild<QQuickItem*>("currentTargetIDs")->property("text").toString().contains("42"));
        auto reset=ap->findChild<QQuickItem*>("resetControlEndpoint");QVERIFY(reset);QVERIFY(QMetaObject::invokeMethod(reset,"clicked"));
        QTRY_VERIFY(!a->isConnected());QVERIFY(g->isConnected());QCOMPARE(a->tcpServerPort(),9001);QCOMPARE(a->tcpServerIP(),QString("192.168.2.36"));
        QCOMPARE(af->property("text").toString(),QString("9001"));
    }
};
QTEST_MAIN(PayloadTests)
#include "payload_tests.moc"
