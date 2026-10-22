#pragma once

#include <QByteArray>
#include <QDateTime>
#include <QJsonObject>
#include <QString>

namespace NexusLicense {
struct PublicKey {
    QByteArray modulus;
    QByteArray exponent;
    QByteArray pem;
    QString id;
};

struct Result {
    bool valid = false;
    QString error;
    QString customer;
    QString serial;
    QDateTime expires;
};

PublicKey trustedKey();
QString machineCode();
bool isMachineCode(const QString& value);
QJsonObject activationRequest(const QString& machine);
Result verify(const QByteArray& envelope, const QString& machine,
              const QDateTime& now, const PublicKey& key = trustedKey());
Result verifyActivationCode(const QString& code, const QString& machine,
                            const QDateTime& now, const PublicKey& key = trustedKey());
QString defaultLicensePath();

// The key and location can be injected by isolated tests, never by a runtime
// setting or a customer-supplied license. Production always uses trustedKey().
class Store {
public:
    Store(const QString& path = defaultLicensePath(), const QString& machine = machineCode(),
          const PublicKey& key = trustedKey());
    Result current() const;
    Result activateCode(const QString& code) const;
    Result importFile(const QString& source) const;
    bool exportRequest(const QString& path, QString* error) const;
    QString machine() const { return _machine; }
    QString path() const { return _path; }
private:
    Result install(const QByteArray& envelope) const;
    QString _path;
    QString _machine;
    PublicKey _key;
};
}
