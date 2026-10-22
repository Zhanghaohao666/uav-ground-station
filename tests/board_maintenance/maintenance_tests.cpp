#include <QtTest>
#include <QGuiApplication>
#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickWindow>
#include <QQuickItem>
#include <QSettings>
#include <QStandardPaths>
#include <QTemporaryDir>
#include "XBoardMaintenanceController.h"

class FakeMaintenance : public XBoardMaintenanceController {
    Q_OBJECT
public:
    explicit FakeMaintenance(QObject* parent=nullptr) : XBoardMaintenanceController(parent) {}
    QTemporaryDir directory;
    QList<BoardSshLaunch> launched;
protected:
    QString sshProgram() const override { return QCoreApplication::applicationFilePath(); }
    QString stateDirectory() const override { return directory.path(); }
    bool startTerminal(const BoardSshLaunch& p, QString*) override { launched << p; return true; }
};
class MaintenanceTests : public QObject {
    Q_OBJECT
    QTemporaryDir settings;
    QObject* findVisual(QQuickItem* item, const QString& name) {
        if (item->objectName()==name) return item;
        for (auto child:item->childItems()) if(auto found=findVisual(child,name)) return found;
        return nullptr;
    }
    QString read(const QString& path) { QFile f(path); if (!f.open(QIODevice::ReadOnly)) return {}; return QString::fromUtf8(f.readAll()); }
private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("UavMaintenanceTests"); QCoreApplication::setApplicationName("Isolated");
        QSettings::setDefaultFormat(QSettings::IniFormat); QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
        qmlRegisterType<FakeMaintenance>("MaintenanceTests",1,0,"MaintenanceController");
        qmlRegisterType(QUrl("qrc:/maintenance/XBoardMaintenanceDialog.qml"),"MaintenanceTests",1,0,"MaintenanceDialog");
    }
    void init() { QSettings().clear(); }
    void defaultsAndPersistenceWithoutPasswords() {
        FakeMaintenance c;
        QCOMPARE(c.configuration()["mainHost"].toString(),QString("192.168.2.36"));
        QCOMPARE(c.configuration()["algorithmHost"].toString(),QString("192.168.10.2"));
        QVERIFY(c.configuration()["viaMain"].toBool());
        QVERIFY(c.configure("192.168.1.104",2222,"operator","192.168.10.3",22,"dev",false));
        FakeMaintenance restored;
        QCOMPARE(restored.configuration(),c.configuration());
        QCOMPARE(QSettings().allKeys().size(),7);
        for (const auto& key:QSettings().allKeys()) QVERIFY(!key.contains("password",Qt::CaseInsensitive) && !key.contains("token"));
    }
    void malformedEndpointsDoNotReplaceConfiguration() {
        FakeMaintenance c;const auto original=c.configuration();
        for (const auto& host:{QString("-oProxyCommand=bad"),QString("192.168.2.36\nHost *"),QString("127.0.0.1;touch pwn"),QString(""),QString("a/b"),QString("x\"y")})
            QVERIFY(!c.configure(host,22,"dev","192.168.10.2",22,"dev",true));
        QVERIFY(!c.configure("192.168.2.36",0,"dev","192.168.10.2",22,"dev",true));
        QVERIFY(!c.configure("192.168.2.36",22,"dev;evil","192.168.10.2",22,"dev",true));
        QCOMPARE(c.configuration(),original);QVERIFY(QSettings().allKeys().isEmpty());
    }
    void jumpPlanPreservesPtyAndStrictHostKeys() {
        FakeMaintenance c;QString error;
        auto p=c.launchPlan("algorithm","shell",QCoreApplication::applicationFilePath(),c.directory.path(),&error);
        QVERIFY2(!p.program.isEmpty(),qPrintable(error));
        QCOMPARE(p.arguments.size(),4);QCOMPARE(p.arguments[2],QString("-tt"));QCOMPARE(p.arguments[3],QString("nexus-algorithm"));
        auto config=read(p.arguments[1]);
        QVERIFY(config.contains("ProxyJump nexus-main"));QVERIFY(config.contains("StrictHostKeyChecking ask"));
        QVERIFY(config.contains("ForwardAgent no"));QVERIFY(!config.contains("StrictHostKeyChecking no"));
        QVERIFY(config.contains("HostName 192.168.10.2"));QVERIFY(config.contains("HostName 192.168.2.36"));
        QVERIFY(config.contains("User dev"));QVERIFY(!config.contains("password",Qt::CaseInsensitive));
        auto other=c.launchPlan("main","shell",p.program,c.directory.path(),&error);QCOMPARE(other.arguments[1],p.arguments[1]);
    }
    void changedRouteGetsOwnConfigAndDirectModeHasNoJump() {
        FakeMaintenance c;QString error;
        auto before=c.launchPlan("algorithm","shell",QCoreApplication::applicationFilePath(),c.directory.path(),&error);
        QVERIFY(c.configure("192.168.1.104",22,"dev","192.168.10.2",22,"dev",false));
        auto after=c.launchPlan("algorithm","shell",before.program,c.directory.path(),&error);
        QVERIFY(before.arguments[1]!=after.arguments[1]);
        QVERIFY(!read(after.arguments[1]).contains("ProxyJump"));QVERIFY(read(before.arguments[1]).contains("ProxyJump"));
    }
    void catalogueAndRecoveryCommandsRemainIndependent() {
        FakeMaintenance c;QString error;
        QCOMPARE(c.actions("main").size(),9);QCOMPARE(c.actions("algorithm").size(),6);
        QCOMPARE(c.commandFor("main","switch-menu"),QString("uav-switch"));
        QCOMPARE(c.commandFor("main","recording-code"),QString("sudo cat /etc/uav-record-api/token"));
        QCOMPARE(c.commandFor("algorithm","restart-preview"),QString("sudo systemctl restart uav-front-preview.service"));
        QVERIFY(c.commandFor("main","restart-algorithm").isEmpty());
        QVERIFY(!c.openTerminal("algorithm","unknown"));QVERIFY(c.launched.isEmpty());
        QVERIFY(!c.openTerminal("unknown","shell"));QVERIFY(c.launched.isEmpty());
        QVERIFY(c.openTerminal("algorithm","restart-preview"));QCOMPARE(c.launched.size(),1);
        auto remote=c.launched[0].arguments.last();
        QVERIFY(remote.contains("sudo systemctl restart uav-front-preview.service"));QVERIFY(remote.contains("exec bash -il"));
        QVERIFY(!remote.contains("uav-front-algorithm"));QVERIFY(!remote.contains("--save-default"));
        QVERIFY(!remote.contains("--password"));
    }
    void noClientOrUnwritableStateFailsWithoutLaunch() {
        FakeMaintenance c;QString error;
        QVERIFY(c.launchPlan("main","shell","",c.directory.path(),&error).program.isEmpty());QVERIFY(!error.isEmpty());
        QFile file(c.directory.path()+"/regular-file");QVERIFY(file.open(QIODevice::WriteOnly));file.write("sentinel");file.close();
        QVERIFY(c.launchPlan("main","shell",QCoreApplication::applicationFilePath(),file.fileName()+"/subdir",&error).program.isEmpty());
    }
    void powershellQuotesPathsAndRemoteArgumentsLiterally() {
        BoardSshLaunch plan;
        plan.program="C:/Users/O'Brien & $()/ssh.exe";
        plan.arguments=QStringList{"-F","C:/space dir/one.conf","-tt","nexus-main","bash -lc 'echo $HOME; exec bash -il'"};
        const auto script=XBoardMaintenanceController::windowsScript(plan);
        QVERIFY(script.contains("'C:/Users/O''Brien & $()/ssh.exe'"));
        QVERIFY(script.contains("'bash -lc ''echo $HOME; exec bash -il'''"));
        QVERIFY(script.contains("[Console]::OutputEncoding"));QVERIFY(!script.contains("Invoke-Expression"));
    }
    void realSshParsesUnicodePathAndJumpConfigurationOffline() {
        QString ssh=qEnvironmentVariable("NEXUS_TEST_SSH");if(ssh.isEmpty())ssh=QStandardPaths::findExecutable("ssh");
        QVERIFY2(!ssh.isEmpty(),"Real SSH client required for config parsing regression");
        FakeMaintenance c;QString error;
        const QString folder=c.directory.path()+QString::fromUtf8("/\xe4\xb8\xad\xe6\x96\x87 O'Brien space");
        auto plan=c.launchPlan("algorithm","shell",ssh,folder,&error);QVERIFY2(!plan.program.isEmpty(),qPrintable(error));
        QProcess process;process.start(ssh,{"-F",plan.arguments[1],"-G","nexus-algorithm"});
        QVERIFY(process.waitForFinished(15000));QCOMPARE(process.exitCode(),0);
        const auto text=QString::fromUtf8(process.readAllStandardOutput());
        QVERIFY(text.contains("hostname 192.168.10.2"));QVERIFY(text.contains("proxyjump nexus-main"));
        QVERIFY(text.contains("user dev"));QVERIFY(text.contains("stricthostkeychecking ask"));
    }
    void copyCommandDoesNotOpenOrExecute() {
        FakeMaintenance c;c.copyCommand("main","switch-menu");QCOMPARE(QGuiApplication::clipboard()->text(),QString("uav-switch"));
        QVERIFY(c.launched.isEmpty());
    }
    void realQmlPanelRoutesTerminalsAndConfirmsRestarts() {
        QQmlEngine engine;QQmlComponent component(&engine);
        component.setData(R"(import QtQuick 2.15
import QtQuick.Controls 2.15
import MaintenanceTests 1.0
ApplicationWindow { width: 1050; height: 900; visible: true
 MaintenanceController { id: c; objectName: "controller" }
 MaintenanceDialog { objectName: "dialog"; controller: c }
})",QUrl());
        QScopedPointer<QObject> root(component.create());QVERIFY2(root,qPrintable(component.errorString()));
        auto controller=root->findChild<FakeMaintenance*>("controller");QVERIFY(controller);
        auto dialog=root->findChild<QObject*>("dialog");QVERIFY(dialog);QVERIFY(QMetaObject::invokeMethod(dialog,"open"));QTest::qWait(200);
        auto main=root->findChild<QObject*>("openMainTerminal");QVERIFY(main);QVERIFY(QMetaObject::invokeMethod(main,"clicked"));
        QCOMPARE(controller->launched.size(),1);QCOMPARE(controller->launched.last().arguments.last(),QString("nexus-main"));
        auto target=root->findChild<QObject*>("maintenanceTarget");QVERIFY(target);target->setProperty("currentIndex",1);QTest::qWait(100);
        auto list=root->findChild<QObject*>("maintenanceActions");QVERIFY(list);
        QVERIFY(QMetaObject::invokeMethod(list,"positionViewAtIndex",Q_ARG(int,1),Q_ARG(int,0)));
        QTest::qWait(200);
        auto window=qobject_cast<QQuickWindow*>(root.data());QVERIFY(window);
        auto earlySnapshot=qEnvironmentVariable("NEXUS_MAINTENANCE_SCREENSHOT");
        if(!earlySnapshot.isEmpty()) window->grabWindow().save(earlySnapshot);
        QObject* button=nullptr;
        QTRY_VERIFY((button=findVisual(window->contentItem(),"runMaintenance_restart-algorithm")));
        QVERIFY(QMetaObject::invokeMethod(button,"clicked"));QCOMPARE(controller->launched.size(),1);
        auto prompt=root->findChild<QObject*>("maintenanceRestartPrompt");QVERIFY(prompt);
        QVERIFY(QMetaObject::invokeMethod(prompt,"accept"));QCOMPARE(controller->launched.size(),2);
        QVERIFY(controller->launched.last().arguments.last().contains("uav-front-algorithm.service"));
        auto snapshot=qEnvironmentVariable("NEXUS_MAINTENANCE_SCREENSHOT");
        if(!snapshot.isEmpty()) { QTest::qWait(200);auto window=qobject_cast<QQuickWindow*>(root.data());QVERIFY(window);auto image=window->grabWindow(); if(!image.isNull()) QVERIFY(image.save(snapshot)); else qInfo("Platform did not provide a Quick window screenshot; QML interaction tests still ran"); }
        QVERIFY(QMetaObject::invokeMethod(dialog,"close"));QCOMPARE(controller->launched.size(),2);
    }
};
QTEST_MAIN(MaintenanceTests)
#include "maintenance_tests.moc"
