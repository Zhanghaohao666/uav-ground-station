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

class RecordingTests : public QObject {
    Q_OBJECT
    QTemporaryDir settings;
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("UavRecorderTests");QCoreApplication::setApplicationName("BoardControl");
        QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
    }
    void init() { QSettings().clear(); }
    void startMultipleAndStopUseBoardAPIAndActualStatus() {
        FakeBoard server;XBoardRecordingController c;
        QVERIFY(c.configure(server.address(),QString(64,'a'),true));QTRY_VERIFY(c.connected());
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
        XBoardRecordingController c;c.configure(server.address(),QString(64,'b'),false);QTRY_VERIFY(!c.busy());
        QVERIFY(!c.connected());QCOMPARE(c.errorText(),QStringLiteral("连接码不正确"));
        QVERIFY(c.status().isEmpty());
    }
    void changingBoardDoesNotAcceptOldResponse() {
        FakeBoard oldBoard,newBoard;oldBoard.delay=true;XBoardRecordingController c;
        c.configure(oldBoard.address(),QString(64,'a'),false);QTRY_COMPARE(oldBoard.requests.size(),1);
        QVERIFY(c.configure(newBoard.address(),QString(64,'b'),false));QTRY_VERIFY(c.connected());
        QCOMPARE(c.address(),newBoard.address());QCOMPARE(newBoard.requests.size(),1);
    }
    void closingClientNeverStopsRecording() {
        FakeBoard server;
        { XBoardRecordingController c;c.configure(server.address(),QString(64,'a'),false);QTRY_VERIFY(c.connected()); }
        QTest::qWait(30);QCOMPARE(server.requests.size(),1);QVERIFY(server.requests.first().startsWith("GET /v1/status "));
    }
    void rapidClicksDoNotSendDuplicateAction() {
        FakeBoard server;XBoardRecordingController c;c.configure(server.address(),QString(64,'a'),false);QTRY_VERIFY(c.connected());
        server.delay=true;c.startSelected({"board"});c.startSelected({"board"});c.stopAll();QTRY_COMPARE(server.requests.size(),2);
    }
    void explicitRememberAndInvalidEndpoint() {
        FakeBoard server;
        { XBoardRecordingController c;QVERIFY(!c.configure("127.0.0.1/evil",QString(64,'a'),true));QVERIFY(!c.configure(server.address(),"dev",true));
          QVERIFY(c.configure(server.address(),QString(64,'a'),true));QTRY_VERIFY(c.connected()); }
        { XBoardRecordingController c;QCOMPARE(c.connectionCode(),QString(64,'a'));c.configure(server.address(),QString(64,'a'),false);QTRY_VERIFY(c.connected()); }
        XBoardRecordingController c;QVERIFY(c.connectionCode().isEmpty());QVERIFY(!c.rememberConnection());
    }
};
QTEST_GUILESS_MAIN(RecordingTests)
#include "recording_tests.moc"
