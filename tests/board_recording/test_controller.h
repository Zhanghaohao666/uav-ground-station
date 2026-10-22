#pragma once
#include "XBoardRecordingController.h"
#include <QCoreApplication>
class TestRecordingController : public XBoardRecordingController {
    Q_OBJECT
public:
    explicit TestRecordingController(QObject* parent=nullptr) : XBoardRecordingController(parent) {}
    QString mode="ok";
    mutable int bootstrapCount=0;
protected:
    BoardSshLaunch connectionPlan(QString*) const override {
        ++bootstrapCount;
        BoardSshLaunch p;p.program=QCoreApplication::applicationFilePath();p.arguments=QStringList{"--fetch-test-credential",mode};return p;
    }
};
