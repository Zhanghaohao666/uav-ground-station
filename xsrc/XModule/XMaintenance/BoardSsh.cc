#include "BoardSsh.h"
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
namespace BoardSsh {
QString shellQuote(QString value) { return "'" + value.replace("'", "'\\''") + "'"; }
bool validHost(const QString& host) {
    return QRegularExpression("^[A-Za-z0-9](?:[A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$").match(host).hasMatch();
}
QString clientProgram() {
#ifdef Q_OS_WIN
    const auto bundled = QCoreApplication::applicationDirPath() + "/ssh/ssh.exe";
    if (QFileInfo::exists(bundled)) return bundled;
    const auto system = qEnvironmentVariable("SystemRoot") + "/System32/OpenSSH/ssh.exe";
    return QFileInfo::exists(system) ? system : QString();
#else
    return QStandardPaths::findExecutable("ssh");
#endif
}
QString askpassProgram() {
    return QCoreApplication::applicationDirPath() + "/NexusBoardAskpass"
#ifdef Q_OS_WIN
        ".exe"
#endif
        ;
}
QString stateDirectory() { return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/NexusGround/SSH"; }
static QString configQuote(QString value) { return "\"" + value.replace('\\', '/').replace('%', "%%").replace('"', "\\\"") + "\""; }
BoardSshLaunch plan(const QVariantMap& c, const QString& role, const QString& client,
                    const QString& askpass, const QString& directory, QString* error, bool terminal) {
    auto fail = [error](const QString& value) { if(error) *error=value; return BoardSshLaunch{}; };
    if (role != "main" && role != "algorithm") return fail("Invalid SSH target");
    for (const QString& board : {QString("main"), QString("algorithm")})
        if (!validHost(c[board+"Host"].toString()) || c[board+"Port"].toInt()<1 || c[board+"Port"].toInt()>65535)
            return fail("Invalid SSH address or port");
    if (!QFileInfo(client).isFile() || !QFileInfo(askpass).isFile()) return fail(QString::fromUtf8("\xe7\xbc\xba\xe5\xb0\x91\x20\x53\x53\x48\x20\xe8\x87\xaa\xe5\x8a\xa8\xe8\xbf\x9e\xe6\x8e\xa5\xe7\xbb\x84\xe4\xbb\xb6\xef\xbc\x8c\xe8\xaf\xb7\xe5\xae\x8c\xe6\x95\xb4\xe8\xa7\xa3\xe5\x8e\x8b\xe6\x96\xb0\xe7\x89\x88\xe8\xbf\x90\xe8\xa1\x8c\xe5\x8c\x85\xe3\x80\x82"));
    if (!QDir().mkpath(directory)) return fail(QString::fromUtf8("\xe6\x97\xa0\xe6\xb3\x95\xe4\xbf\x9d\xe5\xad\x98\x20\x53\x53\x48\x20\xe8\xbf\x9e\xe6\x8e\xa5\xe9\x85\x8d\xe7\xbd\xae\xef\xbc\x8c\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\xe6\x9c\xac\xe5\x9c\xb0\xe7\x9b\xae\xe5\xbd\x95\xe6\x9d\x83\xe9\x99\x90\xe3\x80\x82"));
    QString config = "Host *\n  ConnectTimeout 10\n  ServerAliveInterval 5\n  ServerAliveCountMax 3\n"
        "  StrictHostKeyChecking accept-new\n  ForwardAgent no\n  ForwardX11 no\n  ClearAllForwardings yes\n"
        "  PreferredAuthentications password\n  PubkeyAuthentication no\n  NumberOfPasswordPrompts 1\n"
        "  UserKnownHostsFile " + configQuote(directory + "/known_hosts") + "\n";
    for (const QString& board : {QString("main"), QString("algorithm")}) {
        config += "Host nexus-"+board+"\n  HostName "+c[board+"Host"].toString()+"\n  Port "+c[board+"Port"].toString()+"\n  User dev\n";
        QString alias="nexus-"+board+"-"+c[board+"Host"].toString()+"-"+c[board+"Port"].toString();
        if (board=="algorithm" && c["viaMain"].toBool()) {
            config+="  ProxyJump nexus-main\n";
            alias+="-via-"+c["mainHost"].toString()+"-"+c["mainPort"].toString();
        }
        config+="  HostKeyAlias "+alias+"\n";
    }
    const QString path=directory+"/connection-"+QString::fromLatin1(QCryptographicHash::hash(config.toUtf8(),QCryptographicHash::Sha256).toHex().left(20))+".conf";
    QSaveFile file(path);if(!file.open(QIODevice::WriteOnly))return fail(QString::fromUtf8("\xe6\x97\xa0\xe6\xb3\x95\xe4\xbf\x9d\xe5\xad\x98\x20\x53\x53\x48\x20\xe8\xbf\x9e\xe6\x8e\xa5\xe9\x85\x8d\xe7\xbd\xae\xef\xbc\x8c\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\xe6\x9c\xac\xe5\x9c\xb0\xe7\x9b\xae\xe5\xbd\x95\xe6\x9d\x83\xe9\x99\x90\xe3\x80\x82"));
    file.setPermissions(QFileDevice::ReadOwner|QFileDevice::WriteOwner);
    const auto bytes=config.toUtf8();if(file.write(bytes)!=bytes.size() || !file.commit())return fail(QString::fromUtf8("\xe6\x97\xa0\xe6\xb3\x95\xe4\xbf\x9d\xe5\xad\x98\x20\x53\x53\x48\x20\xe8\xbf\x9e\xe6\x8e\xa5\xe9\x85\x8d\xe7\xbd\xae\xef\xbc\x8c\xe8\xaf\xb7\xe6\xa3\x80\xe6\x9f\xa5\xe6\x9c\xac\xe5\x9c\xb0\xe7\x9b\xae\xe5\xbd\x95\xe6\x9d\x83\xe9\x99\x90\xe3\x80\x82"));
    BoardSshLaunch result; result.program=client;
    result.workingDirectory=QFileInfo(path).absolutePath();
    // Relative ASCII -F avoids ProxyJump shell quoting of parent directories.
    result.arguments=QStringList{"-F",QFileInfo(path).fileName(),terminal?"-tt":"-T"};
    if (!terminal) result.arguments<<"-n";
    result.arguments<<"nexus-"+role;
    result.environment={{"SSH_ASKPASS",QDir::toNativeSeparators(askpass)}, {"SSH_ASKPASS_REQUIRE","force"}, {"NEXUS_BOARD_AUTO_LOGIN","1"}, {"SSH_ASKPASS_PROMPT",""}};
    return result;
}
QProcessEnvironment environment(const BoardSshLaunch& p) {
    auto result=QProcessEnvironment::systemEnvironment();
    for(auto i=p.environment.begin();i!=p.environment.end();++i)result.insert(i.key(),i.value());
#ifdef Q_OS_WIN
    result.insert("PATH",QDir::toNativeSeparators(QFileInfo(p.program).absolutePath())+";"+result.value("PATH"));
#endif
    return result;
}
// Validate sudo via its password pipe, then execute with the original stdin.
// The exported function also supports sudo commands typed in the interactive shell.
QString sudoFunction() {
    return "sudo() { printf '%s\\n' dev | command sudo -S -p '' -v || return; command sudo \"$@\"; }; export -f sudo; printf '%s\\n' dev | command sudo -S -p '' -v; ";
}
}
