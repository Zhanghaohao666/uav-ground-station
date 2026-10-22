// UI literals use Unicode escapes so MSVC source/PCH code pages cannot corrupt Chinese.
#include "ActivationDialog.h"
#include <QApplication>
#include <QClipboard>
#include <QFile>
#include <QFileDialog>
#include <QHBoxLayout>
#include <QLabel>
#include <QJsonDocument>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QTimer>
#include <QVBoxLayout>

namespace NexusLicense {
ActivationDialog::ActivationDialog(const Store& store, QWidget* parent)
    : QDialog(parent), _store(store)
{
    setObjectName(QStringLiteral("offlineActivationDialog"));
    setWindowTitle(QStringLiteral("NexusGround \u2014 \u79bb\u7ebf\u6388\u6743\u6fc0\u6d3b"));
    setMinimumWidth(620);
    auto* layout = new QVBoxLayout(this);
    auto* intro = new QLabel(QStringLiteral("\u8bf7\u5c06\u672c\u673a\u673a\u5668\u7801\u6216\u6388\u6743\u7533\u8bf7\u6587\u4ef6\u53d1\u7ed9\u7ba1\u7406\u5458\uff0c\u6536\u5230\u6388\u6743\u6587\u4ef6\u540e\u70b9\u51fb\u201c\u5bfc\u5165\u6388\u6743\u201d\u3002\n\u6388\u6743\u5b8c\u6210\u540e\u53ef\u79bb\u7ebf\u4f7f\u7528\uff0c\u65e0\u9700\u8fde\u63a5\u4e92\u8054\u7f51\u3002"), this);
    intro->setObjectName(QStringLiteral("licenseInstructions"));
    intro->setWordWrap(true);
    layout->addWidget(intro);
    auto* code = new QPlainTextEdit(this);
    code->setObjectName(QStringLiteral("machineCode"));
    code->setReadOnly(true);
    code->setPlainText(store.machine());
    code->setMaximumHeight(90);
    layout->addWidget(code);
    auto* requestRow = new QHBoxLayout;
    auto* copy = new QPushButton(QStringLiteral("\u590d\u5236\u673a\u5668\u7801"), this);
    copy->setObjectName(QStringLiteral("copyMachineCode"));
    connect(copy, &QPushButton::clicked, this, [this]() { QApplication::clipboard()->setText(_store.machine()); });
    requestRow->addWidget(copy);
    auto* request = new QPushButton(QStringLiteral("\u5bfc\u51fa\u6388\u6743\u7533\u8bf7"), this);
    request->setObjectName(QStringLiteral("exportLicenseRequest"));
    connect(request, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getSaveFileName(this, QStringLiteral("\u4fdd\u5b58\u6388\u6743\u7533\u8bf7"),
            QStringLiteral("NexusGround.ngreq"), QStringLiteral("\u6388\u6743\u7533\u8bf7 (*.ngreq)"));
        if (path.isEmpty()) return;
        QString error;
        if (!_store.exportRequest(path, &error)) _status->setText(QStringLiteral("\u7533\u8bf7\u5bfc\u51fa\u5931\u8d25\uff1a") + error);
        else _status->setText(QStringLiteral("\u7533\u8bf7\u5df2\u5bfc\u51fa\uff0c\u8bf7\u53d1\u9001\u7ed9\u7ba1\u7406\u5458\u3002"));
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
    auto* importButton = new QPushButton(QStringLiteral("\u5bfc\u5165\u6388\u6743"), this);
    importButton->setObjectName(QStringLiteral("importLicense"));
    connect(importButton, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, QStringLiteral("\u9009\u62e9\u7ba1\u7406\u5458\u7b7e\u53d1\u7684\u6388\u6743"),
            QString(), QStringLiteral("\u6388\u6743\u6587\u4ef6 (*.nglic);;\u6240\u6709\u6587\u4ef6 (*)"));
        if (path.isEmpty()) return;
        const Result result = _store.importFile(path);
        refresh(result.valid ? result : _store.current());
        if (result.valid) accept();
        else _status->setText(result.error);
    });
    row->addWidget(importButton);
    row->addStretch();
    auto* quit = new QPushButton(QStringLiteral("\u9000\u51fa"), this);
    quit->setObjectName(QStringLiteral("cancelActivation"));
    connect(quit, &QPushButton::clicked, this, &QDialog::reject);
    row->addWidget(quit);
    _enter = new QPushButton(QStringLiteral("\u8fdb\u5165\u5730\u9762\u7ad9"), this);
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
        ? QStringLiteral("\u5df2\u6388\u6743\uff1a%1\n\u6388\u6743\u7f16\u53f7\uff1a%2\n\u6709\u6548\u671f\uff1a%3").arg(result.customer, result.serial,
            result.expires.isValid() ? result.expires.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"))
                                     : QStringLiteral("\u6c38\u4e45"))
        : result.error);
}

QJsonObject ActivationDialog::diagnosticTexts() const
{
    QJsonObject texts;
    texts.insert(QStringLiteral("windowTitle"), windowTitle());
    for (const char* name : {"licenseInstructions", "licenseStatus"})
        texts.insert(QString::fromLatin1(name), findChild<QLabel*>(QString::fromLatin1(name))->text());
    for (const char* name : {"copyMachineCode", "exportLicenseRequest", "importLicense", "cancelActivation", "enterGroundStation"})
        texts.insert(QString::fromLatin1(name), findChild<QPushButton*>(QString::fromLatin1(name))->text());
    return texts;
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
                // Inspect actual production widget strings, not a separate test
                // binary whose compiler charset settings may differ.
                const auto texts = QJsonDocument(dialog.diagnosticTexts()).toJson(QJsonDocument::Compact);
                report.write("activation_texts_utf8_base64=" + texts.toBase64() + "\n");
                const bool saved = dialog.grab().save(reportPath + QStringLiteral(".png"));
                report.write(saved ? "activation_screenshot_saved=true\n" : "activation_screenshot_saved=false\n");
            }
        });
    }
    const bool accepted = dialog.exec() == QDialog::Accepted && store.current().valid;
    QApplication::setQuitOnLastWindowClosed(quitOnClose);
    return accepted;
}
}
