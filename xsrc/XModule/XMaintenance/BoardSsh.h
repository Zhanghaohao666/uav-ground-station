#pragma once
#include <QMap>
#include <QProcessEnvironment>
#include <QStringList>
#include <QVariantMap>
struct BoardSshLaunch {
    QString program;
    QStringList arguments;
    QString title;
    QString workingDirectory;
    QString askpassDirectory;
    QMap<QString, QString> environment;
};
namespace BoardSsh {
QString clientProgram();
QString askpassProgram();
QString stateDirectory();
QString shellQuote(QString value);
bool validHost(const QString& host);
BoardSshLaunch plan(const QVariantMap& config, const QString& role, const QString& client,
                    const QString& askpass, const QString& directory, QString* error, bool terminal = true);
QProcessEnvironment environment(const BoardSshLaunch& plan);
QString sudoFunction();
}
