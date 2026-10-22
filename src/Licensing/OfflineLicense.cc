// Keep translated error literals independent of the compiler source character set.
#include "OfflineLicense.h"
#include "LicensePublicKey.h"

#include <QCryptographicHash>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QSysInfo>
#include <cstring>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>
#else
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#endif

namespace NexusLicense {
namespace {
constexpr int maxLicenseBytes = 65536;
Result failure(const QString& message) { Result r; r.error = message; return r; }

bool signatureValid(const QByteArray& message, const QByteArray& signature, const PublicKey& key)
{
    if (key.modulus.size() != 384 || key.exponent != QByteArray::fromHex("010001")
            || signature.size() != 384) return false;
#ifdef Q_OS_WIN
    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_KEY_HANDLE publicKey = nullptr;
    if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_RSA_ALGORITHM, nullptr, 0) != 0) return false;
    BCRYPT_RSAKEY_BLOB header = {};
    header.Magic = BCRYPT_RSAPUBLIC_MAGIC;
    header.BitLength = 3072;
    header.cbPublicExp = static_cast<ULONG>(key.exponent.size());
    header.cbModulus = static_cast<ULONG>(key.modulus.size());
    QByteArray blob(reinterpret_cast<const char*>(&header), sizeof(header));
    blob += key.exponent;
    blob += key.modulus;
    bool valid = false;
    if (BCryptImportKeyPair(algorithm, nullptr, BCRYPT_RSAPUBLIC_BLOB, &publicKey,
            reinterpret_cast<PUCHAR>(blob.data()), static_cast<ULONG>(blob.size()), 0) == 0) {
        QByteArray hash = QCryptographicHash::hash(message, QCryptographicHash::Sha256);
        BCRYPT_PSS_PADDING_INFO padding = { BCRYPT_SHA256_ALGORITHM, 32 };
        valid = BCryptVerifySignature(publicKey, &padding,
            reinterpret_cast<PUCHAR>(hash.data()), static_cast<ULONG>(hash.size()),
            reinterpret_cast<PUCHAR>(const_cast<char*>(signature.constData())),
            static_cast<ULONG>(signature.size()), BCRYPT_PAD_PSS) == 0;
        BCryptDestroyKey(publicKey);
    }
    BCryptCloseAlgorithmProvider(algorithm, 0);
    return valid;
#else
    BIO* bio = BIO_new_mem_buf(key.pem.constData(), key.pem.size());
    EVP_PKEY* publicKey = bio ? PEM_read_bio_PUBKEY(bio, nullptr, nullptr, nullptr) : nullptr;
    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    EVP_PKEY_CTX* rsa = nullptr;
    bool valid = publicKey && ctx && EVP_PKEY_bits(publicKey) == 3072
        && EVP_DigestVerifyInit(ctx, &rsa, EVP_sha256(), nullptr, publicKey) == 1
        && EVP_PKEY_CTX_set_rsa_padding(rsa, RSA_PKCS1_PSS_PADDING) == 1
        && EVP_PKEY_CTX_set_rsa_mgf1_md(rsa, EVP_sha256()) == 1
        && EVP_PKEY_CTX_set_rsa_pss_saltlen(rsa, 32) == 1
        && EVP_DigestVerify(ctx, reinterpret_cast<const unsigned char*>(signature.constData()),
                            signature.size(), reinterpret_cast<const unsigned char*>(message.constData()),
                            message.size()) == 1;
    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(publicKey);
    BIO_free(bio);
    return valid;
#endif
}

QByteArray strictBase64(const QJsonValue& value)
{
    if (!value.isString()) return {};
    const QByteArray encoded = value.toString().toLatin1();
    const QByteArray decoded = QByteArray::fromBase64(encoded);
    return decoded.toBase64() == encoded ? decoded : QByteArray();
}

QDateTime timestamp(const QJsonValue& value)
{
    if (!value.isString()) return {};
    const QString text = value.toString();
    if (!QRegularExpression(QStringLiteral("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")).match(text).hasMatch()) return {};
    const QDateTime time = QDateTime::fromString(text, Qt::ISODate);
    return time.isValid() && time.toUTC().toString(Qt::ISODate) == text ? time : QDateTime();
}

#ifdef Q_OS_WIN
// SMBIOS type 1 UUID. Read directly: no shell, WMI process, network or admin rights.
QByteArray hardwareUuid()
{
    constexpr DWORD rsmb = 0x52534D42;
    const UINT size = GetSystemFirmwareTable(rsmb, 0, nullptr, 0);
    if (size < 8 || size > 1024 * 1024) return {};
    QByteArray raw(static_cast<int>(size), '\0');
    if (GetSystemFirmwareTable(rsmb, 0, raw.data(), size) != size) return {};
    const auto* bytes = reinterpret_cast<const unsigned char*>(raw.constData());
    quint32 length = 0;
    std::memcpy(&length, bytes + 4, sizeof(length));
    if (length > size - 8) return {};
    const int end = 8 + static_cast<int>(length);
    for (int pos = 8; pos + 4 <= end;) {
        const int type = bytes[pos];
        const int len = bytes[pos + 1];
        if (len < 4 || pos + len > end) break;
        if (type == 1 && len >= 24) {
            const QByteArray uuid = raw.mid(pos + 8, 16);
            if (uuid != QByteArray(16, '\0') && uuid != QByteArray(16, char(0xff))) return uuid;
        }
        pos += len;
        while (pos + 1 < end && (bytes[pos] || bytes[pos + 1])) ++pos;
        pos += 2;
        if (type == 127) break;
    }
    return {};
}
#endif
}

PublicKey trustedKey()
{
    return {QByteArray::fromHex(NexusLicenseKey::modulus), QByteArray::fromHex("010001"),
            QByteArray(NexusLicenseKey::pem), QString::fromLatin1(NexusLicenseKey::id)};
}

QString machineCode()
{
    QByteArray installation;
    QByteArray hardware;
#ifdef Q_OS_WIN
    QSettings registry(QStringLiteral("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography"),
                       QSettings::Registry64Format);
    installation = registry.value(QStringLiteral("MachineGuid")).toString().trimmed().toLower().toUtf8();
    hardware = hardwareUuid();
#else
    installation = QSysInfo::machineUniqueId().trimmed();
    QFile uuid(QStringLiteral("/sys/class/dmi/id/product_uuid"));
    if (uuid.open(QIODevice::ReadOnly)) hardware = uuid.readAll().trimmed().toLower();
#endif
    if (installation.isEmpty()) return {};
    const QByteArray digest = QCryptographicHash::hash(
        QByteArray("NexusGround-machine-v1\0", 23) + installation + '\0' + hardware,
        QCryptographicHash::Sha256).toHex().toUpper();
    QStringList groups;
    for (int i = 0; i < digest.size(); i += 8) groups << QString::fromLatin1(digest.mid(i, 8));
    return QStringLiteral("NGL1-") + groups.join('-');
}

bool isMachineCode(const QString& value)
{
    return QRegularExpression(QStringLiteral("^NGL1(?:-[A-F0-9]{8}){8}$")).match(value).hasMatch();
}

QJsonObject activationRequest(const QString& machine)
{
    return {{"schema", 1}, {"product", "NexusGround"}, {"machine", machine},
            {"key_id", trustedKey().id}, {"app_version", QCoreApplication::applicationVersion()}};
}

Result verify(const QByteArray& bytes, const QString& machine, const QDateTime& now, const PublicKey& key)
{
    if (!isMachineCode(machine)) return failure(QStringLiteral("\u65e0\u6cd5\u8bfb\u53d6\u672c\u673a\u673a\u5668\u7801\uff0c\u8bf7\u8054\u7cfb\u7ba1\u7406\u5458\u3002"));
    if (!now.isValid()) return failure(QStringLiteral("\u7cfb\u7edf\u65f6\u95f4\u65e0\u6548\uff0c\u8bf7\u6821\u51c6\u65f6\u95f4\u3002"));
    if (bytes.isEmpty()) return failure(QStringLiteral("\u5c1a\u672a\u6fc0\u6d3b\uff0c\u8bf7\u5bfc\u5165\u7ba1\u7406\u5458\u7b7e\u53d1\u7684\u6388\u6743\u6587\u4ef6\u3002"));
    if (bytes.size() > maxLicenseBytes) return failure(QStringLiteral("\u6388\u6743\u6587\u4ef6\u8fc7\u5927\u3002"));
    QJsonParseError parse;
    const auto doc = QJsonDocument::fromJson(bytes, &parse);
    if (parse.error != QJsonParseError::NoError || !doc.isObject()) return failure(QStringLiteral("\u6388\u6743\u6587\u4ef6\u683c\u5f0f\u4e0d\u6b63\u786e\u3002"));
    const auto envelope = doc.object();
    if (envelope.value("format").toString() != QStringLiteral("NGLIC-1")
        || envelope.value("algorithm").toString() != QStringLiteral("RSA-PSS-SHA256")
        || envelope.value("key_id").toString() != key.id)
        return failure(QStringLiteral("\u6388\u6743\u6587\u4ef6\u7684\u683c\u5f0f\u6216\u7b7e\u53d1\u5bc6\u94a5\u4e0d\u5339\u914d\u3002"));
    const QByteArray payload = strictBase64(envelope.value("payload"));
    const QByteArray signature = strictBase64(envelope.value("signature"));
    if (payload.isEmpty() || !signatureValid(payload, signature, key))
        return failure(QStringLiteral("\u6388\u6743\u7b7e\u540d\u65e0\u6548\uff0c\u6587\u4ef6\u53ef\u80fd\u5df2\u88ab\u4fee\u6539\u6216\u4e0d\u662f\u7531\u7ba1\u7406\u5458\u7b7e\u53d1\u3002"));
    const auto signedDoc = QJsonDocument::fromJson(payload, &parse);
    if (parse.error != QJsonParseError::NoError || !signedDoc.isObject()) return failure(QStringLiteral("\u6388\u6743\u5185\u5bb9\u683c\u5f0f\u9519\u8bef\u3002"));
    const auto data = signedDoc.object();
    if (data.value("schema") != QJsonValue(1) || data.value("product").toString() != QStringLiteral("NexusGround")
        || data.value("machine").toString() != machine
        || !data.value("features").isArray() || !data.value("features").toArray().contains("ground-station"))
        return failure(QStringLiteral("\u6b64\u6388\u6743\u4e0d\u9002\u7528\u4e8e\u672c\u673a\u6216\u5f53\u524d\u4ea7\u54c1\u3002"));
    const auto issued = timestamp(data.value("issued_at"));
    const auto starts = timestamp(data.value("not_before"));
    const auto expiryValue = data.value("expires_at");
    const auto expiry = timestamp(expiryValue);
    if (!issued.isValid() || !starts.isValid() || (!expiryValue.isNull() && !expiry.isValid())
        || expiryValue.isUndefined() || (expiry.isValid() && (expiry <= starts || expiry <= issued))
        || data.value("customer").toString().trimmed().isEmpty()
        || data.value("license_id").toString().trimmed().isEmpty())
        return failure(QStringLiteral("\u6388\u6743\u4fe1\u606f\u4e0d\u5b8c\u6574\u6216\u65e5\u671f\u65e0\u6548\u3002"));
    if (now < starts || now.addSecs(300) < issued) return failure(QStringLiteral("\u6388\u6743\u5c1a\u672a\u751f\u6548\uff0c\u8bf7\u68c0\u67e5\u7cfb\u7edf\u65f6\u95f4\u3002"));
    if (expiry.isValid() && now >= expiry) return failure(QStringLiteral("\u6388\u6743\u5df2\u5230\u671f\uff0c\u8bf7\u8054\u7cfb\u7ba1\u7406\u5458\u7eed\u671f\u3002"));
    Result result;
    result.valid = true;
    result.customer = data.value("customer").toString();
    result.serial = data.value("license_id").toString();
    result.expires = expiry;
    return result;
}

QString defaultLicensePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/NexusGround/Licensing/license.nglic");
}

Store::Store(const QString& path, const QString& machine, const PublicKey& key)
    : _path(path), _machine(machine), _key(key) {}

Result Store::current() const
{
    QFile file(_path);
    if (!file.exists()) return verify({}, _machine, QDateTime::currentDateTimeUtc(), _key);
    if (!file.open(QIODevice::ReadOnly)) return failure(QStringLiteral("\u65e0\u6cd5\u8bfb\u53d6\u5df2\u5b89\u88c5\u7684\u6388\u6743\u6587\u4ef6\uff1a") + file.errorString());
    return verify(file.read(maxLicenseBytes + 1), _machine, QDateTime::currentDateTimeUtc(), _key);
}

Result Store::importFile(const QString& source) const
{
    QFile file(source);
    if (!file.open(QIODevice::ReadOnly)) return failure(QStringLiteral("\u65e0\u6cd5\u6253\u5f00\u6388\u6743\u6587\u4ef6\uff1a") + file.errorString());
    const QByteArray bytes = file.read(maxLicenseBytes + 1);
    const Result result = verify(bytes, _machine, QDateTime::currentDateTimeUtc(), _key);
    if (!result.valid) return result; // Never replace a good license with an invalid import.
    const QString dir = QFileInfo(_path).absolutePath();
    if (!QDir().mkpath(dir)) return failure(QStringLiteral("\u65e0\u6cd5\u521b\u5efa\u6388\u6743\u76ee\u5f55\uff0c\u8bf7\u68c0\u67e5\u76ee\u5f55\u6743\u9650\u3002"));
    QSaveFile target(_path);
    if (!target.open(QIODevice::WriteOnly)) return failure(QStringLiteral("\u65e0\u6cd5\u4fdd\u5b58\u6388\u6743\uff1a") + target.errorString());
    target.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    if (target.write(bytes) != bytes.size() || !target.commit())
        return failure(QStringLiteral("\u6388\u6743\u4fdd\u5b58\u5931\u8d25\uff1a") + target.errorString());
    return current();
}

bool Store::exportRequest(const QString& path, QString* error) const
{
    if (!isMachineCode(_machine)) { if (error) *error = QStringLiteral("\u65e0\u6cd5\u8bfb\u53d6\u673a\u5668\u7801\u3002"); return false; }
    QSaveFile file(path);
    const QByteArray bytes = QJsonDocument(activationRequest(_machine)).toJson();
    if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() || !file.commit()) {
        if (error) *error = file.errorString();
        return false;
    }
    return true;
}
}
