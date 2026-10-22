#pragma once
#include "OfflineLicense.h"
#include <QDialog>

class QLabel;
class QPushButton;
namespace NexusLicense {
class ActivationDialog : public QDialog {
    Q_OBJECT
public:
    explicit ActivationDialog(const Store& store, QWidget* parent = nullptr);
    QJsonObject diagnosticTexts() const;
private:
    void refresh(const Result& result);
    Store _store;
    QLabel* _status;
    QPushButton* _enter;
};

bool ensureActivated();
}
