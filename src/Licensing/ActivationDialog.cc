// Explicit UTF-8 byte escapes avoid Qt 5/MSVC wide-literal code-page conversions.
#include "ActivationDialog.h"
#include <QApplication>
#include <QClipboard>
#include <QFile>
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
    auto* intro = new QLabel(QString::fromUtf8("\xe5\xa4\x8d\xe5\x88\xb6\xe6\x9c\xac\xe6\x9c\xba\xe6\x9c\xba\xe5\x99\xa8\xe7\xa0\x81\xe5\x8f\x91\xe7\xbb\x99\xe7\xae\xa1\xe7\x90\x86\xe5\x91\x98\xef\xbc\x8c\xe6\x94\xb6\xe5\x88\xb0\xe6\xbf\x80\xe6\xb4\xbb\xe7\xa0\x81\xe5\x90\x8e\xe7\xb2\x98\xe8\xb4\xb4\xe5\x88\xb0\xe4\xb8\x8b\xe6\x96\xb9\xe5\xb9\xb6\xe7\x82\xb9\xe5\x87\xbb\xe2\x80\x9c\xe6\xbf\x80\xe6\xb4\xbb\xe2\x80\x9d\xe3\x80\x82\x0a\xe5\x8f\xaa\xe9\x9c\x80\xe6\xbf\x80\xe6\xb4\xbb\xe4\xb8\x80\xe6\xac\xa1\xef\xbc\x8c\xe4\xb8\x8b\xe6\xac\xa1\xe6\x89\x93\xe5\xbc\x80\xe7\x9b\xb4\xe6\x8e\xa5\xe8\xbf\x9b\xe5\x85\xa5\xe5\x9c\xb0\xe9\x9d\xa2\xe7\xab\x99\xef\xbc\x8c\xe6\x97\xa0\xe9\x9c\x80\xe8\x81\x94\xe7\xbd\x91\xe3\x80\x82"), this);
    intro->setObjectName(QStringLiteral("licenseInstructions"));
    intro->setWordWrap(true);
    layout->addWidget(intro);
    auto* machineLabel = new QLabel(QString::fromUtf8("\xe6\x9c\xac\xe6\x9c\xba\xe6\x9c\xba\xe5\x99\xa8\xe7\xa0\x81"), this);
    machineLabel->setObjectName(QStringLiteral("machineCodeLabel"));
    layout->addWidget(machineLabel);
    auto* machine = new QPlainTextEdit(this);
    machine->setObjectName(QStringLiteral("machineCode"));
    machine->setReadOnly(true);
    machine->setPlainText(store.machine());
    machine->setMaximumHeight(65);
    layout->addWidget(machine);
    auto* copy = new QPushButton(QString::fromUtf8("\xe5\xa4\x8d\xe5\x88\xb6\xe6\x9c\xba\xe5\x99\xa8\xe7\xa0\x81"), this);
    copy->setObjectName(QStringLiteral("copyMachineCode"));
    connect(copy, &QPushButton::clicked, this, [this]() { QApplication::clipboard()->setText(_store.machine()); });
    auto* copyRow = new QHBoxLayout;
    copyRow->addWidget(copy);
    copyRow->addStretch();
    layout->addLayout(copyRow);
    auto* activationLabel = new QLabel(QString::fromUtf8("\xe6\xbf\x80\xe6\xb4\xbb\xe7\xa0\x81"), this);
    activationLabel->setObjectName(QStringLiteral("activationCodeLabel"));
    layout->addWidget(activationLabel);
    _activationCode = new QPlainTextEdit(this);
    _activationCode->setObjectName(QStringLiteral("activationCode"));
    _activationCode->setPlaceholderText(QString::fromUtf8("\xe5\xb0\x86\xe7\xae\xa1\xe7\x90\x86\xe5\x91\x98\xe5\x8f\x91\xe6\x9d\xa5\xe7\x9a\x84\xe5\xae\x8c\xe6\x95\xb4\xe6\xbf\x80\xe6\xb4\xbb\xe7\xa0\x81\xe7\xb2\x98\xe8\xb4\xb4\xe5\x88\xb0\xe8\xbf\x99\xe9\x87\x8c\xef\xbc\x88\x4e\x47\x41\x43\x31\x2e\x20\xe5\xbc\x80\xe5\xa4\xb4\xef\xbc\x89"));
    _activationCode->setMinimumHeight(100);
    _activationCode->setMaximumHeight(150);
    layout->addWidget(_activationCode);
    _status = new QLabel(this);
    _status->setObjectName(QStringLiteral("licenseStatus"));
    _status->setTextFormat(Qt::PlainText);
    _status->setWordWrap(true);
    _status->setTextInteractionFlags(Qt::TextSelectableByMouse);
    layout->addWidget(_status);
    auto* row = new QHBoxLayout;
    auto* activate = new QPushButton(QString::fromUtf8("\xe6\xbf\x80\xe6\xb4\xbb"), this);
    activate->setObjectName(QStringLiteral("activateLicense"));
    activate->setEnabled(false);
    activate->setDefault(true);
    connect(_activationCode, &QPlainTextEdit::textChanged, this, [this, activate]() {
        const auto text = _activationCode->toPlainText();
        activate->setEnabled(isMachineCode(_store.machine()) && !text.trimmed().isEmpty() && text.size() <= 16384);
    });
    connect(activate, &QPushButton::clicked, this, [this]() {
        const Result result = _store.activateCode(_activationCode->toPlainText());
        refresh(result.valid ? result : _store.current());
        if (result.valid) {
            _activationCode->clear();
            accept();
        } else {
            _status->setText(result.error);
            _activationCode->setFocus();
        }
    });
    row->addWidget(activate);
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
    refresh(store.current());
}

void ActivationDialog::refresh(const Result& result)
{
    _enter->setEnabled(result.valid);
    _status->setText(result.valid
        ? QString::fromUtf8("\xc3\xa5\xc2\xb7\xc2\xb2\xc3\xa6\xc2\x8e\xc2\x88\xc3\xa6\xc2\x9d\xc2\x83\xc3\xaf\xc2\xbc\xc2\x9a\x25\x31\x0a\xc3\xa6\xc2\x8e\xc2\x88\xc3\xa6\xc2\x9d\xc2\x83\xc3\xa7\xc2\xbc\xc2\x96\xc3\xa5\xc2\x8f\xc2\xb7\xc3\xaf\xc2\xbc\xc2\x9a\x25\x32\x0a\xc3\xa6\xc2\x9c\xc2\x89\xc3\xa6\xc2\x95\xc2\x88\xc3\xa6\xc2\x9c\xc2\x9f\xc3\xaf\xc2\xbc\xc2\x9a\x25\x33").arg(result.customer, result.serial,
            result.expires.isValid() ? result.expires.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"))
                                     : QString::fromUtf8("\xc3\xa6\xc2\xb0\xc2\xb8\xc3\xa4\xc2\xb9\xc2\x85"))
        : result.error);
}

QJsonObject ActivationDialog::diagnosticTexts() const
{
    QJsonObject texts;
    texts.insert(QStringLiteral("windowTitle"), windowTitle());
    for (const char* name : {"licenseInstructions", "machineCodeLabel", "activationCodeLabel", "licenseStatus"})
        texts.insert(QString::fromLatin1(name), findChild<QLabel*>(QString::fromLatin1(name))->text());
    for (const char* name : {"copyMachineCode", "activateLicense", "cancelActivation", "enterGroundStation"})
        texts.insert(QString::fromLatin1(name), findChild<QPushButton*>(QString::fromLatin1(name))->text());
    texts.insert(QStringLiteral("activationCodePlaceholder"), _activationCode->placeholderText());
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
