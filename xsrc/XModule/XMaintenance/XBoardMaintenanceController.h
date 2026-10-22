#pragma once
#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QStringList>

#include "BoardSsh.h"

// Independent interactive terminals using the fixed dev/dev board profile.
class XBoardMaintenanceController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap configuration READ configuration NOTIFY changed)
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
public:
    explicit XBoardMaintenanceController(QObject* parent = nullptr);
    QVariantMap configuration() const { return _config; }
    QString statusText() const { return _status; }
    Q_INVOKABLE bool configure(const QString& mainHost, int mainPort, const QString& mainUser,
                              const QString& algorithmHost, int algorithmPort, const QString& algorithmUser,
                              bool viaMain);
    Q_INVOKABLE QVariantList actions(const QString& board) const;
    Q_INVOKABLE QString commandFor(const QString& board, const QString& action) const;
    Q_INVOKABLE bool openTerminal(const QString& board, const QString& action = QStringLiteral("shell"));
    Q_INVOKABLE void copyCommand(const QString& board, const QString& action);
    // Shared with isolated tests; does not connect or launch anything.
    BoardSshLaunch launchPlan(const QString& board, const QString& action, const QString& sshProgram,
                             const QString& directory, QString* error) const;
    static QString quotePowerShell(const QString& value);
    static QString windowsScript(const BoardSshLaunch& plan);
protected:
    virtual QString sshProgram() const;
    virtual QString askpassProgram() const;
    virtual QString stateDirectory() const;
    virtual bool startTerminal(const BoardSshLaunch& plan, QString* error);
signals:
    void changed();
private:
    bool validConfiguration(const QVariantMap& value) const;
    QVariantMap _config;
    QString _status;
};
