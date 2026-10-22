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
