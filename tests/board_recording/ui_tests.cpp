#include <QtTest>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlProperty>
#include <QSettings>
#include <QTemporaryDir>
#include "XBoardRecordingController.h"
#include "fake_board.h"

class RecordingUiTests : public QObject {
    Q_OBJECT
    QTemporaryDir settings;
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("UavRecorderUiTests");QCoreApplication::setApplicationName("Panel");
        QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
        qmlRegisterType<XBoardRecordingController>("RecordingTests",1,0,"BoardController");
        const QString qml=QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../../xsrc/XUI/XBoardRecordingDialog.qml");
        qmlRegisterType(QUrl::fromLocalFile(qml),"RecordingTests",1,0,"RecordingDialog");
    }
    void realDialogChoosesStartsAndClosesWithoutStopping() {
        FakeBoard server;
        auto object=QJsonDocument::fromJson(server.response).object();auto status=object["status"].toObject();
        status["streams"]=QJsonArray{
            QJsonObject{{"key","board"},{"label",QStringLiteral("下视 MIPI")},{"available",true},{"requested",true},{"active",true},{"phase","recording"},{"state",QStringLiteral("正在录像")},{"detail",QStringLiteral("本次连接已写入 240 帧")}},
            QJsonObject{{"key","rgb"},{"label",QStringLiteral("D455 彩色")},{"available",true},{"phase","stopped"},{"state",QStringLiteral("未录像")}},
            QJsonObject{{"key","algorithm"},{"label",QStringLiteral("前视算法")},{"available",true},{"phase","stopped"},{"state",QStringLiteral("未录像")}},
            QJsonObject{{"key","preview"},{"label",QStringLiteral("前视预览")},{"available",true},{"phase","stopped"},{"state",QStringLiteral("未录像")}},
            QJsonObject{{"key","infrared"},{"label",QStringLiteral("算法板红外")},{"available",true},{"phase","waiting"},{"state",QStringLiteral("等待视频/重连")}},
            QJsonObject{{"key","gimbal"},{"label",QStringLiteral("云台可见光")},{"available",true},{"phase","stopped"},{"state",QStringLiteral("未录像")}},
            QJsonObject{{"key","gimbal_ir"},{"label",QStringLiteral("云台红外")},{"available",true},{"phase","stopped"},{"state",QStringLiteral("未录像")}}};
        status["storage"]=QJsonObject{{"mounted",true},{"free_bytes",3.97e11},{"reserve_bytes",10737418240.0},{"error",""}};
        object["status"]=status;server.response=QJsonDocument(object).toJson();
        QQmlEngine engine;QQmlComponent component(&engine);
        component.setData(R"(import QtQuick 2.15
import QtQuick.Controls 2.15
import RecordingTests 1.0
ApplicationWindow {
    width: 1000; height: 760; visible: true
    BoardController { id: c; objectName: "controller" }
    RecordingDialog { objectName: "dialog"; controller: c }
})",QUrl());
        QScopedPointer<QObject> root(component.create());
        QVERIFY2(root, qPrintable(component.errorString()));
        auto c=root->findChild<XBoardRecordingController*>("controller");QVERIFY(c);
        auto dialog=root->findChild<QObject*>("dialog");QVERIFY(dialog);
        QVERIFY(c->configure(server.address(),QString(64,'a'),false));QTRY_VERIFY(c->connected());
        QVERIFY(QMetaObject::invokeMethod(dialog,"open"));QTRY_VERIFY(dialog->property("opened").toBool());
        QTRY_VERIFY(!c->busy());
        const int initialRequests=server.requests.size();
        auto start=dialog->findChild<QQuickItem*>("startBoardRecording");QVERIFY(start);QVERIFY(!start->isEnabled());
        QVERIFY(QMetaObject::invokeMethod(dialog,"choose",Q_ARG(QVariant,QString("board")),Q_ARG(QVariant,true)));
        QTRY_VERIFY(start->isEnabled());
        // Emit the button's actual signal, invoking the production QML handler.
        QVERIFY(QMetaObject::invokeMethod(start,"clicked"));QTRY_VERIFY(!c->busy());
        QCOMPARE(server.requests.size(),initialRequests+1);QVERIFY(server.requests.last().startsWith("POST /v1/start "));
        QVERIFY(server.requests.last().contains("[\"board\"]"));
        auto window=qobject_cast<QQuickWindow*>(root.data());QVERIFY(window);
        QTest::qWait(100);
        const QString screenshot=qEnvironmentVariable("UAV_RECORD_UI_SCREENSHOT");
        if (!screenshot.isEmpty()) QVERIFY(window->grabWindow().save(screenshot));
        QVERIFY(QMetaObject::invokeMethod(dialog,"close"));QTest::qWait(50);QCOMPARE(server.requests.size(),initialRequests+1);
    }
};
QTEST_MAIN(RecordingUiTests)
#include "ui_tests.moc"
