#include "ActivationDialog.h"
#include <QApplication>
#include <QClipboard>
#include <QFile>
#include <QFileDialog>
#include <QHBoxLayout>
#include <QLabel>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QTimer>
#include <QVBoxLayout>

namespace NexusLicense {
ActivationDialog::ActivationDialog(const Store& store, QWidget* parent)
    : QDialog(parent), _store(store)
{
    setObjectName(QStringLiteral("offlineActivationDialog"));
    setWindowTitle(QStringLiteral("NexusGround — 离线授权激活"));
    setMinimumWidth(620);
    auto* layout = new QVBoxLayout(this);
    auto* intro = new QLabel(QStringLiteral("请将本机机器码或授权申请文件发给管理员，收到授权文件后点击“导入授权”。\n授权完成后可离线使用，无需连接互联网。"), this);
    intro->setWordWrap(true);
    layout->addWidget(intro);
    auto* code = new QPlainTextEdit(this);
    code->setObjectName(QStringLiteral("machineCode"));
    code->setReadOnly(true);
    code->setPlainText(store.machine());
    code->setMaximumHeight(90);
    layout->addWidget(code);
    auto* requestRow = new QHBoxLayout;
    auto* copy = new QPushButton(QStringLiteral("复制机器码"), this);
    copy->setObjectName(QStringLiteral("copyMachineCode"));
    connect(copy, &QPushButton::clicked, this, [this]() { QApplication::clipboard()->setText(_store.machine()); });
    requestRow->addWidget(copy);
    auto* request = new QPushButton(QStringLiteral("导出授权申请"), this);
    request->setObjectName(QStringLiteral("exportLicenseRequest"));
    connect(request, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getSaveFileName(this, QStringLiteral("保存授权申请"),
            QStringLiteral("NexusGround.ngreq"), QStringLiteral("授权申请 (*.ngreq)"));
        if (path.isEmpty()) return;
        QString error;
        if (!_store.exportRequest(path, &error)) _status->setText(QStringLiteral("申请导出失败：") + error);
        else _status->setText(QStringLiteral("申请已导出，请发送给管理员。"));
    });
    requestRow->addWidget(request);
    requestRow->addStretch();
    layout->addLayout(requestRow);
    _status = new QLabel(this);
    _status->setObjectName(QStringLiteral("licenseStatus"));
    _status->setTextFormat(Qt::PlainText);
    _status->setWordWrap(true);
    _status->setTextInteractionFlags(Qt::TextSelectableByMouse);
    layout->addWidget(_status);
    auto* row = new QHBoxLayout;
    auto* importButton = new QPushButton(QStringLiteral("导入授权"), this);
    importButton->setObjectName(QStringLiteral("importLicense"));
    connect(importButton, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, QStringLiteral("选择管理员签发的授权"),
            QString(), QStringLiteral("授权文件 (*.nglic);;所有文件 (*)"));
        if (path.isEmpty()) return;
        const Result result = _store.importFile(path);
        refresh(result.valid ? result : _store.current());
        if (result.valid) accept();
        else _status->setText(result.error);
    });
    row->addWidget(importButton);
    row->addStretch();
    auto* quit = new QPushButton(QStringLiteral("退出"), this);
    quit->setObjectName(QStringLiteral("cancelActivation"));
    connect(quit, &QPushButton::clicked, this, &QDialog::reject);
    row->addWidget(quit);
    _enter = new QPushButton(QStringLiteral("进入地面站"), this);
    _enter->setObjectName(QStringLiteral("enterGroundStation"));
    connect(_enter, &QPushButton::clicked, this, [this]() {
        const Result result = _store.current(); // Recheck if the dialog was left open over expiry.
        refresh(result);
        if (result.valid) accept();
    });
    row->addWidget(_enter);
    layout->addLayout(row);
    copy->setEnabled(isMachineCode(store.machine()));
    request->setEnabled(copy->isEnabled());
    refresh(store.current());
}

void ActivationDialog::refresh(const Result& result)
{
    _enter->setEnabled(result.valid);
    _status->setText(result.valid
        ? QStringLiteral("已授权：%1\n授权编号：%2\n有效期：%3").arg(result.customer, result.serial,
            result.expires.isValid() ? result.expires.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"))
                                     : QStringLiteral("永久"))
        : result.error);
}

bool ensureActivated()
{
    Store store;
    if (store.current().valid && !QCoreApplication::arguments().contains(QStringLiteral("--license"))) return true;
    // Closing this preflight dialog must not schedule application shutdown when
    // activation succeeds and the real main window is created afterwards.
    const bool quitOnClose = QApplication::quitOnLastWindowClosed();
    QApplication::setQuitOnLastWindowClosed(false);
    ActivationDialog dialog(store);
    const QString reportPath = qEnvironmentVariable("QGC_CI_STARTUP_REPORT");
    if (!reportPath.isEmpty()) {
        QTimer::singleShot(200, &dialog, [&dialog, reportPath]() {
            QFile report(reportPath);
            if (report.open(QIODevice::WriteOnly | QIODevice::Text)) {
                report.write("activation_required=true\nactivation_dialog_created=true\n");
                report.write(dialog.isVisible() ? "window_visible=true\n" : "window_visible=false\n");
                report.write("main_services_started=false\n");
            }
        });
    }
    const bool accepted = dialog.exec() == QDialog::Accepted && store.current().valid;
    QApplication::setQuitOnLastWindowClosed(quitOnClose);
    return accepted;
}
}
