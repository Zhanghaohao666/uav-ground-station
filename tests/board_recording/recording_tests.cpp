#include <QtTest>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSettings>
#include <QTemporaryDir>
#include "XBoardRecordingController.h"

#include "fake_board.h"
#include "test_controller.h"
#include <cstdio>
#include <QFile>
#include <QStandardPaths>

class RecordingTests : public QObject {
    Q_OBJECT
    QTemporaryDir settings;
private slots:
    void initTestCase() {
        QStandardPaths::setTestModeEnabled(true);
        QCoreApplication::setOrganizationName("UavRecorderTests");QCoreApplication::setApplicationName("BoardControl");
        QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
    }
    void init() { QSettings().clear(); }
    void startMultipleAndStopUseBoardAPIAndActualStatus() {
        FakeBoard server;TestRecordingController c;
        QVERIFY(c.configure(server.address()));QTRY_VERIFY(c.connected());
        QCOMPARE(c.status().value("streams").toList()[0].toMap().value("phase").toString(),QString("waiting"));
        c.startSelected({"board","preview"});QTRY_VERIFY(!c.busy());QCOMPARE(server.requests.size(),2);
        QVERIFY(server.requests[1].startsWith("POST /v1/start "));
        QVERIFY(server.requests[1].contains("Authorization: Bearer "+QByteArray(64,'a')));
        const auto body=server.requests[1].mid(server.requests[1].indexOf("\r\n\r\n")+4);
        QCOMPARE(QJsonDocument::fromJson(body).object()["streams"].toArray(),QJsonArray({"board","preview"}));
        // Acknowledgement with no frames must remain waiting.
        QCOMPARE(c.status().value("streams").toList()[0].toMap().value("phase").toString(),QString("waiting"));
        c.stopSelected({"preview"});QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().startsWith("POST /v1/stop "));
        c.stopAll();QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().contains("[\"all\"]"));
    }
    void authenticationAndServerFailuresAreNotSuccess() {
        FakeBoard server;server.code=401;server.response=QJsonDocument(QJsonObject{{"ok",false},{"error",QStringLiteral("连接码不正确")}}).toJson();
        TestRecordingController c;c.configure(server.address());QTRY_VERIFY(!c.busy());
        QVERIFY(!c.connected());QCOMPARE(c.errorText(),QStringLiteral("连接码不正确"));
        QVERIFY(c.status().isEmpty());
    }
    void changingBoardDoesNotAcceptOldResponse() {
        FakeBoard oldBoard,newBoard;oldBoard.delay=true;TestRecordingController c;
        c.configure(oldBoard.address());QTRY_COMPARE(oldBoard.requests.size(),1);
        QVERIFY(c.configure(newBoard.address()));QTRY_VERIFY(c.connected());
        QCOMPARE(c.address(),newBoard.address());QCOMPARE(newBoard.requests.size(),1);
    }
    void closingClientNeverStopsRecording() {
        FakeBoard server;
        { TestRecordingController c;c.configure(server.address());QTRY_VERIFY(c.connected()); }
        QTest::qWait(30);QCOMPARE(server.requests.size(),1);QVERIFY(server.requests.first().startsWith("GET /v1/status "));
    }
    void rapidClicksDoNotSendDuplicateAction() {
        FakeBoard server;TestRecordingController c;c.configure(server.address());QTRY_VERIFY(c.connected());
        server.delay=true;c.startSelected({"board"});c.startSelected({"board"});c.stopAll();QTRY_COMPARE(server.requests.size(),2);
    }
    void lidarUsesIndependentCommandsAndActualDataState() {
        FakeBoard server;server.setLidar(FakeBoard::lidarStatus());TestRecordingController c;
        QVERIFY(c.configure(server.address()));QTRY_VERIFY(c.connected());
        server.setLidar(FakeBoard::lidarStatus("starting",true,true));
        c.startLidar();QTRY_VERIFY(!c.busy());
        QVERIFY(server.requests.last().startsWith("POST /v1/lidar/start "));
        auto body=server.requests.last().mid(server.requests.last().indexOf("\r\n\r\n")+4);
        QCOMPARE(QJsonDocument::fromJson(body).object(),QJsonObject{});
        QCOMPARE(c.status().value("lidar").toMap().value("phase").toString(),QString("starting"));
        const int count=server.requests.size();c.startLidar();QCOMPARE(server.requests.size(),count);
        server.setLidar(FakeBoard::lidarStatus("recording",true,true));c.refresh();QTRY_VERIFY(!c.busy());
        QCOMPARE(c.status().value("lidar").toMap().value("phase").toString(),QString("recording"));
        c.stopAll();QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().startsWith("POST /v1/stop "));
        QVERIFY(server.requests.last().contains("[\"all\"]"));
        QVERIFY(c.status().value("lidar").toMap().value("active").toBool());
        server.setLidar(FakeBoard::lidarStatus("stopped"));c.stopLidar();QTRY_VERIFY(!c.busy());
        QVERIFY(server.requests.last().startsWith("POST /v1/lidar/stop "));
        body=server.requests.last().mid(server.requests.last().indexOf("\r\n\r\n")+4);
        QCOMPARE(QJsonDocument::fromJson(body).object(),QJsonObject{});
        QVERIFY(!c.status().value("lidar").toMap().value("active").toBool());
    }
    void oldBackendAndOfflineLidarDoNotBreakVideoRecording() {
        FakeBoard server;TestRecordingController c;c.configure(server.address());QTRY_VERIFY(c.connected());
        QVERIFY(!c.status().contains("lidar"));
        c.startLidar();c.stopLidar();QCOMPARE(server.requests.size(),1);
        c.startSelected({"board"});QTRY_VERIFY(!c.busy());QCOMPARE(server.requests.size(),2);
        QVERIFY(server.requests.last().startsWith("POST /v1/start "));
        server.setLidar(FakeBoard::lidarStatus("idle",false));c.refresh();QTRY_VERIFY(!c.busy());
        const int count=server.requests.size();c.startLidar();QCOMPARE(server.requests.size(),count);
        server.setLidar(FakeBoard::lidarStatus("starting",false,true));c.refresh();QTRY_VERIFY(!c.busy());
        c.stopLidar();QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().startsWith("POST /v1/lidar/stop "));
    }
    void malformedLidarStatusCannotClaimRecording_data() {
        QTest::addColumn<QJsonObject>("lidar");
        auto lidar=FakeBoard::lidarStatus("recording",true,true);
        auto bad=lidar;bad["phase"]="unknown";QTest::newRow("unknown-phase")<<bad;
        bad=lidar;bad["active"]=false;QTest::newRow("recording-not-active")<<bad;
        bad=lidar;bad["bytes"]=0;QTest::newRow("recording-without-data")<<bad;
        bad=lidar;bad["bytes"]=-3;QTest::newRow("negative-bytes")<<bad;
        bad=lidar;bad["available"]="true";QTest::newRow("string-bool")<<bad;
        bad=lidar;bad.remove("phase");QTest::newRow("missing-phase")<<bad;
        QTest::newRow("empty-object")<<QJsonObject{};
    }
    void malformedLidarStatusCannotClaimRecording() {
        QFETCH(QJsonObject,lidar);FakeBoard server;server.setLidar(lidar);TestRecordingController c;
        c.configure(server.address());QTRY_VERIFY(c.connected());
        QVERIFY(c.status().value("lidar").toMap().value("malformed").toBool());
        QVERIFY(!c.status().value("lidar").toMap().value("supported").toBool());
        c.startLidar();c.stopLidar();QCOMPARE(server.requests.size(),1);
        c.startSelected({"board"});QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().startsWith("POST /v1/start "));
    }
    void delayedLidarCommandTimeoutNeverReplaysAfterReconnect() {
        FakeBoard server;server.setLidar(FakeBoard::lidarStatus());TestRecordingController c;
        c.configure(server.address());QTRY_VERIFY(c.connected());
        server.delay=true;c.startLidar();QTRY_COMPARE(server.requests.size(),2);QVERIFY(c.busy());
        auto reply=c.findChild<QNetworkReply*>();QVERIFY(reply);
        auto timeout=reply->findChild<QTimer*>();QVERIFY(timeout);
        QVERIFY(QMetaObject::invokeMethod(timeout,"timeout"));QTRY_VERIFY(!c.busy());
        QVERIFY(!c.connected());QVERIFY(c.status().isEmpty());
        server.delay=false;server.setLidar(FakeBoard::lidarStatus("recording",true,true));c.refresh();
        QTRY_VERIFY(c.connected());QCOMPARE(server.requests.size(),3);
        QVERIFY(server.requests.last().startsWith("GET /v1/status "));
        QCOMPARE(c.status().value("lidar").toMap().value("phase").toString(),QString("recording"));
    }
    void malformedGlobalPollClearsStaleLidarAndRecoveryOnlyReadsStatus() {
        FakeBoard server;server.setLidar(FakeBoard::lidarStatus("recording",true,true));TestRecordingController c;
        c.configure(server.address());QTRY_VERIFY(c.connected());const auto healthy=server.response;
        server.response="{\"ok\":true,\"status\":{\"api_version\":1}}";c.refresh();QTRY_VERIFY(!c.busy());
        QVERIFY(!c.connected());QVERIFY(c.status().isEmpty());
        server.response=healthy;c.refresh();QTRY_VERIFY(c.connected());
        QVERIFY(server.requests.last().startsWith("GET /v1/status "));QCOMPARE(server.requests.size(),3);
    }
    void changingBoardWhileLidarStartPendingDoesNotReuseState() {
        FakeBoard first,second;first.setLidar(FakeBoard::lidarStatus());TestRecordingController c;
        c.configure(first.address());QTRY_VERIFY(c.connected());first.delay=true;c.startLidar();
        QTRY_COMPARE(first.requests.size(),2);QVERIFY(c.configure(second.address()));QTRY_VERIFY(c.connected());
        QVERIFY(!c.status().contains("lidar"));QCOMPARE(second.requests.size(),1);
        QVERIFY(second.requests.first().startsWith("GET /v1/status "));
    }
    void closingClientNeverStopsActiveLidar() {
        FakeBoard server;server.setLidar(FakeBoard::lidarStatus("recording",true,true));
        { TestRecordingController c;c.configure(server.address());QTRY_VERIFY(c.connected()); }
        QTest::qWait(30);QCOMPARE(server.requests.size(),1);QVERIFY(server.requests.first().startsWith("GET /v1/status "));
    }
    void actualAutomaticSshBootstrapAndRecordingHttp() {
        const auto fixture=qEnvironmentVariable("NEXUS_SSH_FIXTURE");if(fixture.isEmpty())QSKIP("Real SSH fixture not enabled");
        QFile file(fixture);QVERIFY(file.open(QIODevice::ReadOnly));const auto ports=QJsonDocument::fromJson(file.readAll()).object();
        QSettings().setValue("BoardMaintenance/mainHost","127.0.0.1");
        QSettings().setValue("BoardMaintenance/mainPort",ports["main_port"].toInt());
        FakeBoard server;XBoardRecordingController c;QVERIFY(c.configure(server.address()));
        QTRY_VERIFY_WITH_TIMEOUT(!c.busy(),22000);QVERIFY2(c.connected(),qPrintable(c.errorText()));
        QVERIFY(server.requests.first().contains("Authorization: Bearer "+QByteArray(64,'a')));
        c.startSelected({"board"});QTRY_VERIFY(!c.busy());QVERIFY(server.requests.last().startsWith("POST /v1/start "));
        QVERIFY(!QSettings().contains("BoardRecording/code"));
    }
    void onlyAddressIsRememberedAndOldManualCodeIsRemoved() {
        FakeBoard server;QSettings().setValue("BoardRecording/code",QString(64,'b'));
        { TestRecordingController c;QVERIFY(!c.configure("127.0.0.1/evil"));QVERIFY(!c.configure("127.0.0.1?evil"));
          QVERIFY(c.configure(server.address()));QTRY_VERIFY(c.connected()); }
        TestRecordingController c;QCOMPARE(c.address(),server.address());
        QVERIFY(!QSettings().contains("BoardRecording/code"));
        QVERIFY(!QSettings().contains("BoardRecording/remember"));
        QVERIFY(!c.connected());QCOMPARE(c.bootstrapCount,0);
        c.configure(server.address());QTRY_VERIFY(c.connected());QCOMPARE(c.bootstrapCount,1);
    }
    void bootstrapFailureDoesNotClaimConnectionOrSendHttp() {
        FakeBoard server;TestRecordingController c;c.mode="fail";c.configure(server.address());
        QTRY_VERIFY(!c.busy());QVERIFY(!c.connected());QVERIFY(!c.errorText().isEmpty());QVERIFY(server.requests.isEmpty());
        c.startSelected({"board"});QTest::qWait(30);QVERIFY(server.requests.isEmpty());
    }
    void replacementBoardDiscardsInFlightCredentialAndGetsNewConnection() {
        FakeBoard oldBoard,newBoard;TestRecordingController c;c.mode="delay";c.configure(oldBoard.address());QVERIFY(c.busy());
        c.mode="ok";c.configure(newBoard.address());QTRY_VERIFY(c.connected());
        QCOMPARE(c.address(),newBoard.address());QVERIFY(oldBoard.requests.isEmpty());QCOMPARE(newBoard.requests.size(),1);
        QCOMPARE(c.bootstrapCount,2);
    }

};
int main(int argc,char** argv) {
    if(argc==3 && QByteArray(argv[1])=="--fetch-test-credential") {
        if(QByteArray(argv[2])=="fail")return 1;
        if(QByteArray(argv[2])=="delay")QThread::msleep(500);
        std::fputs((QByteArray(64,'a')+"\n").constData(),stdout);return 0;
    }
    QCoreApplication app(argc,argv);RecordingTests test;return QTest::qExec(&test,argc,argv);
}
#include "recording_tests.moc"
