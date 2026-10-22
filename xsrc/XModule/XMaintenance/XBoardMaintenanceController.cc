#include "XBoardMaintenanceController.h"
#include <QClipboard>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <vector>
#endif

namespace {
QVariantMap action(const char* id, const QString& label, const QString& command, bool restart = false) {
    return {{"id", id}, {"label", label}, {"command", command}, {"restart", restart}};
}
QVariantList boardActions(const QString& board) {
    if (board == "main") return {
        action("status", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe6\x9c\x8d\xe5\x8a\xa1\xe7\x8a\xb6\xe6\x80\x81\xe5\x92\x8c\xe6\x8e\xa8\xe6\xb5\x81\xe5\x9c\xb0\xe5\x9d\x80"), "python3 /opt/uav-switch/manager.py status"),
        action("switch-menu", QString::fromUtf8("\xe6\x89\x93\xe5\xbc\x80\xe6\x96\xb9\xe6\xa1\x88\xe5\x88\x87\xe6\x8d\xa2\xe8\x8f\x9c\xe5\x8d\x95"), "uav-switch"),
        action("restart-board", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\xe4\xb8\x8b\xe8\xa7\x86\x20\x4d\x49\x50\x49\x20\xe6\x8e\xa8\xe6\xb5\x81"), "sudo systemctl restart uav-switch@board.service", true),
        action("restart-d455", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\x20\x44\x34\x35\x35\x69\x20\xe6\x8e\xa8\xe6\xb5\x81"), "sudo systemctl restart uav-switch@d455.service", true),
        action("restart-relay", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\xe4\xb8\xbb\xe6\x8e\xa7\xe8\xa7\x86\xe9\xa2\x91\xe4\xb8\xad\xe7\xbb\xa7"), "sudo systemctl restart uav-switch@relay.service", true),
        action("video-logs", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe4\xb8\xbb\xe6\x8e\xa7\xe8\xbf\x91\xe6\x9c\x9f\xe6\x8e\xa8\xe6\xb5\x81\xe6\x97\xa5\xe5\xbf\x97"), "sudo journalctl -b -u uav-switch@board.service -u uav-switch@d455.service -u uav-switch@relay.service -n 60 --no-pager"),
        action("recording-status", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe6\x9d\xbf\xe7\xab\xaf\xe5\xbd\x95\xe5\x83\x8f\xe7\x8a\xb6\xe6\x80\x81"), "uav-record status"),
        action("resources", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe7\xbd\x91\xe5\x8f\xa3\xe3\x80\x81\xe5\xad\x98\xe5\x82\xa8\xe5\x92\x8c\xe6\xb8\xa9\xe5\xba\xa6"), "ip -br -4 addr; df -h / /data; for z in /sys/class/thermal/thermal_zone*; do printf '%s ' \"$(cat \"$z/type\")\"; cat \"$z/temp\"; done")
    };
    if (board == "algorithm") return {
        action("status", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe7\xae\x97\xe6\xb3\x95\xe6\x9d\xbf\xe6\x8e\xa8\xe6\xb5\x81\xe6\x9c\x8d\xe5\x8a\xa1\xe7\x8a\xb6\xe6\x80\x81"), "systemctl --no-pager -l status uav-front-algorithm.service uav-front-preview.service mino17-streamer.service"),
        action("restart-algorithm", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\xe6\xa3\x80\xe6\xb5\x8b\xe8\xb7\x9f\xe8\xb8\xaa\xe5\x92\x8c\xe7\xae\x97\xe6\xb3\x95\xe7\x94\xbb\xe9\x9d\xa2"), "sudo systemctl restart uav-front-algorithm.service", true),
        action("restart-preview", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\xe5\x89\x8d\xe8\xa7\x86\xe5\x8e\x9f\xe5\xa7\x8b\xe9\xa2\x84\xe8\xa7\x88"), "sudo systemctl restart uav-front-preview.service", true),
        action("restart-infrared", QString::fromUtf8("\xe9\x87\x8d\xe5\x90\xaf\x20\x4d\x69\x6e\x6f\x31\x37\x20\xe7\xba\xa2\xe5\xa4\x96\xe6\x8e\xa8\xe6\xb5\x81"), "sudo systemctl restart mino17-streamer.service", true),
        action("video-logs", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe7\xae\x97\xe6\xb3\x95\xe6\x9d\xbf\xe8\xbf\x91\xe6\x9c\x9f\xe6\x97\xa5\xe5\xbf\x97"), "sudo journalctl -b -u uav-front-algorithm.service -u uav-front-preview.service -u mino17-streamer.service -n 60 --no-pager"),
        action("resources", QString::fromUtf8("\xe6\x9f\xa5\xe7\x9c\x8b\xe7\xbd\x91\xe5\x8f\xa3\xe3\x80\x81\xe5\xad\x98\xe5\x82\xa8\xe5\x92\x8c\xe6\xb8\xa9\xe5\xba\xa6"), "ip -br -4 addr; df -h / /mnt/data; for z in /sys/class/thermal/thermal_zone*; do printf '%s ' \"$(cat \"$z/type\")\"; cat \"$z/temp\"; done")
    };
    return {};
}
}

XBoardMaintenanceController::XBoardMaintenanceController(QObject* parent) : QObject(parent)
{
    _config = {{"mainHost", "192.168.2.36"}, {"mainPort", 22}, {"mainUser", "dev"},
               {"algorithmHost", "192.168.10.2"}, {"algorithmPort", 22}, {"algorithmUser", "dev"}, {"viaMain", true}};
    QSettings settings;
    settings.beginGroup("BoardMaintenance");
    auto saved = _config;
    for (auto i = saved.begin(); i != saved.end(); ++i) i.value() = settings.value(i.key(), i.value());
    saved["mainUser"] = "dev"; saved["algorithmUser"] = "dev";
    if (validConfiguration(saved)) _config = saved;
}

bool XBoardMaintenanceController::validConfiguration(const QVariantMap& value) const
{
    const QRegularExpression host("^[A-Za-z0-9](?:[A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$");
    const QRegularExpression user("^[A-Za-z_][A-Za-z0-9_.-]{0,63}$");
    for (const QString& prefix : {QString("main"), QString("algorithm")}) {
        if (!host.match(value[prefix + "Host"].toString()).hasMatch()
            || !user.match(value[prefix + "User"].toString()).hasMatch()
            || value[prefix + "Port"].toInt() < 1 || value[prefix + "Port"].toInt() > 65535) return false;
    }
    return value.contains("viaMain");
}

bool XBoardMaintenanceController::configure(const QString& mainHost, int mainPort, const QString& mainUser,
                                            const QString& algorithmHost, int algorithmPort, const QString& algorithmUser,
                                            bool viaMain)
{
    if (mainUser.trimmed() != "dev" || algorithmUser.trimmed() != "dev") return false;
    const QVariantMap value = {{"mainHost", mainHost.trimmed()}, {"mainPort", mainPort}, {"mainUser", "dev"},
        {"algorithmHost", algorithmHost.trimmed()}, {"algorithmPort", algorithmPort}, {"algorithmUser", "dev"}, {"viaMain", viaMain}};
    if (!validConfiguration(value)) {
        _status = QString::fromUtf8("\xe8\xaf\xb7\xe5\xa1\xab\xe5\x86\x99\xe6\x9c\x89\xe6\x95\x88\xe7\x9a\x84\x20\x49\x50\x2f\xe4\xb8\xbb\xe6\x9c\xba\xe5\x90\x8d\xe3\x80\x81\xe7\x94\xa8\xe6\x88\xb7\xe5\x90\x8d\xe5\x92\x8c\x20\x31\xef\xbd\x9e\x36\x35\x35\x33\x35\x20\xe7\xab\xaf\xe5\x8f\xa3\xe3\x80\x82"); emit changed(); return false;
    }
    _config = value;
    QSettings settings;
    settings.beginGroup("BoardMaintenance");
    for (auto i = value.begin(); i != value.end(); ++i) settings.setValue(i.key(), i.value());
    emit changed(); return true;
}
QVariantList XBoardMaintenanceController::actions(const QString& board) const { return boardActions(board); }
QString XBoardMaintenanceController::commandFor(const QString& board, const QString& id) const {
    for (const auto& value : boardActions(board)) {
        auto entry = value.toMap();
        if (entry["id"].toString() == id) return entry["command"].toString();
    }
    return {};
}
QString XBoardMaintenanceController::stateDirectory() const { return BoardSsh::stateDirectory(); }
QString XBoardMaintenanceController::sshProgram() const { return BoardSsh::clientProgram(); }
QString XBoardMaintenanceController::askpassProgram() const { return BoardSsh::askpassProgram(); }
BoardSshLaunch XBoardMaintenanceController::launchPlan(const QString& board, const QString& id, const QString& ssh,
                                                      const QString& directory, QString* error) const {
    const auto command=commandFor(board,id);
    if (id!="shell" && command.isEmpty()) { if(error)*error="Unknown maintenance action"; return {}; }
    auto plan=BoardSsh::plan(_config,board,ssh,askpassProgram(),directory,error);
    if (plan.program.isEmpty()) return plan;
    const QString script=BoardSsh::sudoFunction()+"printf '\\n[NexusGround maintenance]\\n'; "
        +(id=="shell"?QString(":"):command)
        +"; result=$?; printf '\\nCommand finished (exit=%s). Interactive shell follows.\\n' \"$result\"; exec bash -il";
    plan.arguments<<"bash -lc "+BoardSsh::shellQuote(script);
    plan.title=board=="main"?QString::fromUtf8("\x4e\x65\x78\x75\x73\x47\x72\x6f\x75\x6e\x64\x20\xe4\xb8\xbb\xe6\x8e\xa7\x20\x53\x53\x48"):QString::fromUtf8("\x4e\x65\x78\x75\x73\x47\x72\x6f\x75\x6e\x64\x20\xe7\xae\x97\xe6\xb3\x95\xe6\x9d\xbf\x20\x53\x53\x48");
    return plan;
}

QString XBoardMaintenanceController::quotePowerShell(const QString& value) { QString copy = value; return "'" + copy.replace("'", "''") + "'"; }
QString XBoardMaintenanceController::windowsScript(const BoardSshLaunch& plan) {
    QString script = "$ErrorActionPreference='Stop'; [Console]::InputEncoding=[Text.UTF8Encoding]::new($false); "
        "[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); $OutputEncoding=[Console]::OutputEncoding; "
        "Set-Location -LiteralPath " + quotePowerShell(plan.workingDirectory) + "; $env:TERM='xterm-256color'; $env:PATH=" + quotePowerShell(QFileInfo(plan.program).absolutePath() + ";") + "+$env:PATH; & " + quotePowerShell(plan.program);
    for (auto i=plan.environment.begin();i!=plan.environment.end();++i)
        script = "$env:" + i.key() + "=" + quotePowerShell(i.value()) + "; " + script;
    for (const auto& arg : plan.arguments) script += " " + quotePowerShell(arg);
    return script + "; Write-Host ''; Write-Host 'SSH ended. This is local Windows PowerShell. Close this window to finish.'";
}

bool XBoardMaintenanceController::startTerminal(const BoardSshLaunch& plan, QString* error) {
#ifdef Q_OS_WIN
    const QString powershell = qEnvironmentVariable("SystemRoot") + "/System32/WindowsPowerShell/v1.0/powershell.exe";
    const QString script = windowsScript(plan);
    const QByteArray encoded = QByteArray(reinterpret_cast<const char*>(script.utf16()), script.size() * 2).toBase64();
    const QString command = "\"" + QDir::toNativeSeparators(powershell) + "\" -NoLogo -NoProfile -NoExit -EncodedCommand " + QString::fromLatin1(encoded);
    std::wstring mutableCommand = command.toStdWString();
    std::wstring program = QDir::toNativeSeparators(powershell).toStdWString();
    std::wstring title = plan.title.toStdWString();
    STARTUPINFOW startup = {}; startup.cb = sizeof(startup); startup.lpTitle = &title[0];
    PROCESS_INFORMATION process = {};
    if (!CreateProcessW(program.c_str(), &mutableCommand[0], nullptr, nullptr, FALSE,
                        CREATE_NEW_CONSOLE, nullptr, nullptr, &startup, &process)) {
        if (error) *error = QString::fromUtf8("\xe6\x97\xa0\xe6\xb3\x95\xe6\x89\x93\xe5\xbc\x80\x20\x53\x53\x48\x20\xe7\xbb\x88\xe7\xab\xaf\xef\xbc\x8c\x57\x69\x6e\x64\x6f\x77\x73\x20\xe9\x94\x99\xe8\xaf\xaf\xef\xbc\x9a\x25\x31").arg(GetLastError());
        return false;
    }
    CloseHandle(process.hThread); CloseHandle(process.hProcess); return true;
#else
    for (const auto& candidate : {QString("xterm"), QString("konsole"), QString("gnome-terminal")}) {
        const auto terminal = QStandardPaths::findExecutable(candidate);
        if (terminal.isEmpty()) continue;
        QStringList args{candidate == "gnome-terminal" ? "--" : "-e", plan.program}; args += plan.arguments;
        QProcess child; child.setProgram(terminal); child.setArguments(args); child.setWorkingDirectory(plan.workingDirectory); child.setProcessEnvironment(BoardSsh::environment(plan));
        if (child.startDetached()) return true;
    }
    if (error) *error = QString::fromUtf8("\xe6\x9c\xaa\xe6\x89\xbe\xe5\x88\xb0\xe5\x8f\xaf\xe7\x94\xa8\xe7\x9a\x84\xe6\xa1\x8c\xe9\x9d\xa2\xe7\xbb\x88\xe7\xab\xaf\xef\xbc\x8c\xe8\xaf\xb7\xe5\xae\x89\xe8\xa3\x85\x20\x78\x74\x65\x72\x6d\xe3\x80\x81\x4b\x6f\x6e\x73\x6f\x6c\x65\x20\xe6\x88\x96\x20\x47\x4e\x4f\x4d\x45\x20\x54\x65\x72\x6d\x69\x6e\x61\x6c\xe3\x80\x82");
    return false;
#endif
}

bool XBoardMaintenanceController::openTerminal(const QString& board, const QString& id) {
    QString error;
    const auto plan = launchPlan(board, id, sshProgram(), stateDirectory(), &error);
    const bool launched = !plan.program.isEmpty() && startTerminal(plan, &error);
    _status = launched ? QString::fromUtf8("\xe5\xb7\xb2\xe6\x89\x93\xe5\xbc\x80\xe7\xbb\x88\xe7\xab\xaf\xef\xbc\x8c\xe6\xad\xa3\xe5\x9c\xa8\xe4\xbd\xbf\xe7\x94\xa8\x20\x64\x65\x76\x20\xe8\x87\xaa\xe5\x8a\xa8\xe7\x99\xbb\xe5\xbd\x95\xef\xbc\x9b\xe8\xbf\x9e\xe6\x8e\xa5\xe7\xbb\x93\xe6\x9e\x9c\xe4\xbb\xa5\xe7\xbb\x88\xe7\xab\xaf\xe6\x98\xbe\xe7\xa4\xba\xe4\xb8\xba\xe5\x87\x86\xe3\x80\x82") : error;
    emit changed(); return launched;
}
void XBoardMaintenanceController::copyCommand(const QString& board, const QString& id) {
    const auto command = commandFor(board, id);
    if (command.isEmpty()) return;
    QGuiApplication::clipboard()->setText(command);
    _status = QString::fromUtf8("\xe5\x91\xbd\xe4\xbb\xa4\xe5\xb7\xb2\xe5\xa4\x8d\xe5\x88\xb6\xef\xbc\x8c\xe5\x8f\xaf\xe7\xb2\x98\xe8\xb4\xb4\xe5\x88\xb0\xe5\xb7\xb2\xe8\xbf\x9e\xe6\x8e\xa5\xe7\x9a\x84\xe6\x9d\xbf\xe5\x8d\xa1\x20\x53\x53\x48\x20\xe7\xbb\x88\xe7\xab\xaf\xe3\x80\x82\xe8\xaf\xb7\xe7\xa1\xae\xe8\xae\xa4\xe7\x9b\xae\xe6\xa0\x87\xe6\x9d\xbf\xe5\x8d\xa1\xe3\x80\x82"); emit changed();
}
