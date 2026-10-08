// Explicitly invoked hardware test; never runs in CI. Owns only three streams.
#include <QCoreApplication>
#include <QFile>
#include <QTemporaryDir>
#include <QSettings>
#include <QJsonDocument>
#include <QElapsedTimer>
#include <QtTest>
#include <cstdio>
#include "XBoardRecordingController.h"

static bool wait(XBoardRecordingController& c) {
    QElapsedTimer t;t.start();while(c.busy() && t.elapsed()<95000)QTest::qWait(20);
    if(c.busy() || !c.connected()) { std::fprintf(stderr,"API request failed: %s\n",qPrintable(c.errorText()));return false; }
    return true;
}
static QString phase(const XBoardRecordingController& c,const QString& key) {
    for(const auto& value:c.status().value("streams").toList())if(value.toMap().value("key").toString()==key)return value.toMap().value("phase").toString();
    return {};
}
int main(int argc,char** argv) {
    QCoreApplication app(argc,argv);if(argc!=3)return 2;
    QTemporaryDir settings;QCoreApplication::setOrganizationName("UavLiveCheck");QCoreApplication::setApplicationName("Recording");
    QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,settings.path());
    QFile key(argv[2]);if(!key.open(QIODevice::ReadOnly))return 3;
    int result=0;bool started=false;
    XBoardRecordingController c;if(!c.configure(QString::fromLocal8Bit(argv[1]),QString::fromUtf8(key.readAll()),false) || !wait(c))return 4;
    if(!c.status().value("session").isNull()) { std::fprintf(stderr,"Existing recording session: no live mutation performed\n");return 77; }
    const QStringList own={"board","preview","infrared"};
    started=true;c.startSelected(own);
    if(!wait(c))result=5;
    if(!result) {
        QElapsedTimer t;t.start();
        while(t.elapsed()<15000 && (phase(c,"board")!="recording" || phase(c,"preview")!="recording")) {
            QTest::qWait(1000);c.refresh();if(!wait(c)){result=6;break;}
        }
        if(phase(c,"board")!="recording" || phase(c,"preview")!="recording")result=7;
        std::printf("RECORDING_STATUS=%s\n",QJsonDocument::fromVariant(c.status()).toJson(QJsonDocument::Compact).constData());
    }
    if(!result) {
        QTest::qWait(6000);c.stopSelected({"preview"});if(!wait(c))result=8;
        if(phase(c,"preview")!="stopped" || phase(c,"board")!="recording")result=9;
        std::puts("Single-stream stop kept the other video recording.");
    }
    if(started) { c.stopSelected(own);if(!wait(c))result=10; }
    std::printf("FINAL_STATUS=%s\n",QJsonDocument::fromVariant(c.status()).toJson(QJsonDocument::Compact).constData());
    return result;
}
