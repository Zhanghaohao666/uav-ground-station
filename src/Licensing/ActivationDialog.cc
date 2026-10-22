// Explicit UTF-8 byte escapes avoid Qt 5/MSVC wide-literal code-page conversions.
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
    setWindowTitle(QString::fromUtf8("\x4e\x65\x78\x75\x73\x47\x72\x6f\x75\x6e\x64\x20\xe2\x80\x94\x20\xe7\xa6\xbb\xe7\xba\xbf\xe6\x8e\x88\xe6\x9d\x83\xe6\xbf\x80\xe6\xb4\xbb"));
    setMinimumWidth(620);
    auto* layout = new QVBoxLayout(this);
    auto* intro = new QLabel(QString::fromUtf8("\xe8\xaf\xb7\xe5\xb0\x86\xe6\x9c\xac\xe6\x9c\xba\xe6\x9c\xba\xe5\x99\xa8\xe7\xa0\x81\xe6\x88\x96\xe6\x8e\x88\xe6\x9d\x83\xe7\x94\xb3\xe8\xaf\xb7\xe6\x96\x87\xe4\xbb\xb6\xe5\x8f\x91\xe7\xbb\x99\xe7\xae\xa1\xe7\x90\x86\xe5\x91\x98\xef\xbc\x8c\xe6\x94\xb6\xe5\x88\xb0\xe6\x8e\x88\xe6\x9d\x83\xe6\x96\x87\xe4\xbb\xb6\xe5\x90\x8e\xe7\x82\xb9\xe5\x87\xbb\xe2\x80\x9c\xe5\xaf\xbc\xe5\x85\xa5\xe6\x8e\x88\xe6\x9d\x83\xe2\x80\x9d\xe3\x80\x82\x0a\xe6\x8e\x88\xe6\x9d\x83\xe5\xae\x8c\xe6\x88\x90\xe5\x90\x8e\xe5\x8f\xaf\xe7\xa6\xbb\xe7\xba\xbf\xe4\xbd\xbf\xe7\x94\xa8\xef\xbc\x8c\xe6\x97\xa0\xe9\x9c\x80\xe8\xbf\x9e\xe6\x8e\xa5\xe4\xba\x92\xe8\x81\x94\xe7\xbd\x91\xe3\x80\x82"), this);
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
    auto* copy = new QPushButton(QString::fromUtf8("\xe5\xa4\x8d\xe5\x88\xb6\xe6\x9c\xba\xe5\x99\xa8\xe7\xa0\x81"), this);
    copy->setObjectName(QStringLiteral("copyMachineCode"));
    connect(copy, &QPushButton::clicked, this, [this]() { QApplication::clipboard()->setText(_store.machine()); });
    requestRow->addWidget(copy);
    auto* request = new QPushButton(QString::fromUtf8("\xe5\xaf\xbc\xe5\x87\xba\xe6\x8e\x88\xe6\x9d\x83\xe7\x94\xb3\xe8\xaf\xb7"), this);
    request->setObjectName(QStringLiteral("exportLicenseRequest"));
    connect(request, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getSaveFileName(this, QString::fromUtf8("\xe4\xbf\x9d\xe5\xad\x98\xe6\x8e\x88\xe6\x9d\x83\xe7\x94\xb3\xe8\xaf\xb7"),
            QStringLiteral("NexusGround.ngreq"), QString::fromUtf8("\xe6\x8e\x88\xe6\x9d\x83\xe7\x94\xb3\xe8\xaf\xb7\x20\x28\x2a\x2e\x6e\x67\x72\x65\x71\x29"));
        if (path.isEmpty()) return;
        QString error;
        if (!_store.exportRequest(path, &error)) _status->setText(QString::fromUtf8("\xe7\x94\xb3\xe8\xaf\xb7\xe5\xaf\xbc\xe5\x87\xba\xe5\xa4\xb1\xe8\xb4\xa5\xef\xbc\x9a") + error);
        else _status->setText(QString::fromUtf8("\xe7\x94\xb3\xe8\xaf\xb7\xe5\xb7\xb2\xe5\xaf\xbc\xe5\x87\xba\xef\xbc\x8c\xe8\xaf\xb7\xe5\x8f\x91\xe9\x80\x81\xe7\xbb\x99\xe7\xae\xa1\xe7\x90\x86\xe5\x91\x98\xe3\x80\x82"));
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
    auto* importButton = new QPushButton(QString::fromUtf8("\xe5\xaf\xbc\xe5\x85\xa5\xe6\x8e\x88\xe6\x9d\x83"), this);
    importButton->setObjectName(QStringLiteral("importLicense"));
    connect(importButton, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, QString::fromUtf8("\xe9\x80\x89\xe6\x8b\xa9\xe7\xae\xa1\xe7\x90\x86\xe5\x91\x98\xe7\xad\xbe\xe5\x8f\x91\xe7\x9a\x84\xe6\x8e\x88\xe6\x9d\x83"),
            QString(), QString::fromUtf8("\xe6\x8e\x88\xe6\x9d\x83\xe6\x96\x87\xe4\xbb\xb6\x20\x28\x2a\x2e\x6e\x67\x6c\x69\x63\x29\x3b\x3b\xe6\x89\x80\xe6\x9c\x89\xe6\x96\x87\xe4\xbb\xb6\x20\x28\x2a\x29"));
        if (path.isEmpty()) return;
        const Result result = _store.importFile(path);
        refresh(result.valid ? result : _store.current());
        if (result.valid) accept();
        else _status->setText(result.error);
    });
    row->addWidget(importButton);
    row->addStretch();
    auto* quit = new QPushButton(QString::fromUtf8("\xe9\x80\x80\xe5\x87\xba"), this);
    quit->setObjectName(QStringLiteral("cancelActivation"));
    connect(quit, &QPushButton::clicked, this, &QDialog::reject);
    row->addWidget(quit);
    _enter = new QPushButton(QString::fromUtf8("\xe8\xbf\x9b\xe5\x85\xa5\xe5\x9c\xb0\xe9\x9d\xa2\xe7\xab\x99"), this);
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
        ? QString::fromUtf8("\xe5\xb7\xb2\xe6\x8e\x88\xe6\x9d\x83\xef\xbc\x9a\x25\x31\x0a\xe6\x8e\x88\xe6\x9d\x83\xe7\xbc\x96\xe5\x8f\xb7\xef\xbc\x9a\x25\x32\x0a\xe6\x9c\x89\xe6\x95\x88\xe6\x9c\x9f\xef\xbc\x9a\x25\x33").arg(result.customer, result.serial,
            result.expires.isValid() ? result.expires.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"))
                                     : QString::fromUtf8("\xe6\xb0\xb8\xe4\xb9\x85"))
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
