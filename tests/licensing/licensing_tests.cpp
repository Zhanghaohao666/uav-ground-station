#include <QtTest>
#include <QApplication>
#include <QClipboard>
#include <QFile>
#include <QJsonDocument>
#include <QLabel>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QSettings>
#include <QTemporaryDir>
#include "../../src/Licensing/ActivationDialog.h"

using namespace NexusLicense;
class LicensingTests : public QObject {
    Q_OBJECT
    QJsonObject fixtures;
    PublicKey key;
    QString machine;
    QDateTime now;
    QByteArray bytes(const QString& name) const {
        return QJsonDocument(fixtures.value(name).toObject()).toJson();
    }
    static QString save(const QString& path, const QByteArray& data) {
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size()) return {};
        return path;
    }
private slots:
    void initTestCase() {
        QFile file(qEnvironmentVariable("NEXUS_LICENSE_FIXTURES"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        fixtures = QJsonDocument::fromJson(file.readAll()).object();
        const auto info = fixtures.value("key").toObject();
        key = {QByteArray::fromHex(info.value("modulus").toString().toLatin1()),
               QByteArray::fromHex(info.value("exponent").toString().toLatin1()),
               info.value("pem").toString().toLatin1(), info.value("id").toString()};
        machine = fixtures.value("machine").toString();
        now = QDateTime::fromString(fixtures.value("now").toString(), Qt::ISODate);
    }
    void validAndPermanent() {
        const auto result = verify(bytes("valid"), machine, now, key);
        QVERIFY2(result.valid, qPrintable(result.error));
        QVERIFY(result.expires.isValid());
        QCOMPARE(result.customer, QString::fromUtf8("\xe6\xb5\x8b\xe8\xaf\x95\xe7\x94\xa8\xe6\x88\xb7\x20\x3c\x73\x63\x72\x69\x70\x74\x3e\x20\x26\x20\xe5\xbc\xa0\xe4\xb8\x89"));
        const auto permanent = verify(bytes("permanent"), machine, now.addYears(20), key);
        QVERIFY(permanent.valid);
        QVERIFY(!permanent.expires.isValid());
    }
    void expiryBoundaryAndClockBeforeIssue() {
        auto result = verify(bytes("valid"), machine, now, key);
        QVERIFY(verify(bytes("valid"), machine, result.expires.addSecs(-1), key).valid);
        QVERIFY(!verify(bytes("valid"), machine, result.expires, key).valid);
        QVERIFY(!verify(bytes("valid"), machine, now.addSecs(-3600), key).valid);
    }
    void signedInvalidPolicies_data() {
        QTest::addColumn<QString>("name");
        for (const auto& name : {"wrong_product", "wrong_machine", "no_feature", "wrong_schema",
                                "bad_date", "no_expiry", "blank_customer", "future", "expired", "foreign"})
            QTest::newRow(name) << QString::fromLatin1(name);
    }
    void signedInvalidPolicies() {
        QFETCH(QString, name);
        const auto result = verify(bytes(name), machine, now, key);
        QVERIFY(!result.valid);
        QVERIFY(!result.error.isEmpty());
    }
    void modifiedPayloadSignatureAndAlgorithm() {
        auto data = fixtures.value("valid").toObject();
        auto payload = QByteArray::fromBase64(data.value("payload").toString().toLatin1());
        payload.replace("ground-station", "other-function");
        data.insert("payload", QString::fromLatin1(payload.toBase64()));
        QVERIFY(!verify(QJsonDocument(data).toJson(), machine, now, key).valid);
        data = fixtures.value("valid").toObject();
        data.insert("signature", QString::fromLatin1(QByteArray(384, '\0').toBase64()));
        QVERIFY(!verify(QJsonDocument(data).toJson(), machine, now, key).valid);
        data = fixtures.value("valid").toObject();
        data.insert("algorithm", "none");
        QVERIFY(!verify(QJsonDocument(data).toJson(), machine, now, key).valid);
        data = fixtures.value("valid").toObject();
        data.insert("payload", data.value("payload").toString() + "!");
        QVERIFY(!verify(QJsonDocument(data).toJson(), machine, now, key).valid);
    }
    void malformedAndOversized() {
        for (const auto& value : {QByteArray(), QByteArray("{bad"), QByteArray("[]"), QByteArray(65537, 'x')})
            QVERIFY(!verify(value, machine, now, key).valid);
        QVERIFY(!verify(bytes("valid"), "", now, key).valid);
        QVERIFY(!verify(bytes("valid"), machine, {}, key).valid);
    }
    void productionKeyDoesNotTrustDisposableTestKey() {
        QVERIFY(trustedKey().id != key.id);
        auto data = fixtures.value("valid").toObject();
        data.insert("key_id", trustedKey().id);
        QVERIFY(!verify(QJsonDocument(data).toJson(), machine, now).valid);
    }
    void atomicImportPersistsAndRejectsWrongComputer() {
        QTemporaryDir temp;
        QVERIFY(temp.isValid());
        const auto license = save(temp.path() + "/source.nglic", bytes("valid"));
        const auto path = temp.path() + QString::fromUtf8("\x2f\xe6\x8e\x88\xe6\x9d\x83\xe7\x9b\xae\xe5\xbd\x95\x2f\x6c\x69\x63\x65\x6e\x73\x65\x2e\x6e\x67\x6c\x69\x63");
        Store store(path, machine, key);
        QVERIFY(!store.current().valid);
        QVERIFY2(store.importFile(license).valid, qPrintable(store.importFile(license).error));
        Store restarted(path, machine, key);
        QVERIFY(restarted.current().valid);
        Store other(path, "NGL1" + QString("-12345678").repeated(8), key);
        QVERIFY(!other.current().valid);
        const auto invalid = save(temp.path() + "/invalid.nglic", bytes("wrong_machine"));
        QVERIFY(!store.importFile(invalid).valid);
        QVERIFY(restarted.current().valid);
        QVERIFY(!store.importFile(temp.path() + "/not-found.nglic").valid);
        QVERIFY(restarted.current().valid);
    }
    void corruptedStoredLicenseAndWriteFailure() {
        QTemporaryDir temp;
        const auto path = save(temp.path() + "/corrupt.nglic", "{oops");
        QVERIFY(!Store(path, machine, key).current().valid);
        const auto parentFile = save(temp.path() + "/regular-file", "sentinel");
        const auto valid = save(temp.path() + "/source.nglic", bytes("valid"));
        QVERIFY(!Store(parentFile + "/license.nglic", machine, key).importFile(valid).valid);
    }
    void requestExportsOnlyHashedIdentity() {
        QTemporaryDir temp;
        const auto path = temp.path() + "/request.ngreq";
        QString error;
        QVERIFY(Store("", machine, key).exportRequest(path, &error));
        QFile file(path);
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto json = QJsonDocument::fromJson(file.readAll()).object();
        QCOMPARE(json.value("machine").toString(), machine);
        QCOMPARE(json.value("key_id").toString(), trustedKey().id);
        QCOMPARE(json.value("product").toString(), QString("NexusGround"));
        QCOMPARE(json.size(), 5);
        QVERIFY(!Store("", "", key).exportRequest(temp.path()+"/invalid", &error));
    }
    void actualIdentityStableAndNoQSettingsDependency() {
        const auto code = machineCode();
        QVERIFY(isMachineCode(code));
        QCoreApplication::setApplicationVersion("different-version");
        QCOMPARE(machineCode(), code);
        QTemporaryDir temp;
        QSettings settings(temp.path() + "/settings.ini", QSettings::IniFormat);
        settings.setValue("activated", true);
        settings.clear();
        QCOMPARE(machineCode(), code);
    }
    void actualDialogTextMatchesUnicodeGolden() {
        QTemporaryDir temp;
        ActivationDialog dialog(Store(temp.path() + "/license.nglic", machine, key));
        const auto expected = fixtures.value("ui_golden").toObject();
        const auto actual = dialog.diagnosticTexts();
        QCOMPARE(actual.size(), expected.size());
        for (const auto& name : expected.keys())
            QCOMPARE(actual.value(name).toString(), expected.value(name).toString());
    }
    void dialogBlocksEnterWithoutLicenseAndAllowsCancel() {
        QTemporaryDir temp;
        ActivationDialog dialog(Store(temp.path() + "/license.nglic", machine, key));
        auto* enter = dialog.findChild<QPushButton*>("enterGroundStation");
        QVERIFY(enter);
        QVERIFY(!enter->isEnabled());
        QCOMPARE(dialog.findChild<QPlainTextEdit*>("machineCode")->toPlainText(), machine);
        dialog.findChild<QPushButton*>("copyMachineCode")->click();
        QCOMPARE(QApplication::clipboard()->text(), machine);
        dialog.findChild<QPushButton*>("cancelActivation")->click();
        QCOMPARE(dialog.result(), int(QDialog::Rejected));
        QVERIFY(!QFile::exists(temp.path() + "/license.nglic"));
    }
    void licensedDialogHasPlainTextAndRechecksBeforeEnter() {
        QTemporaryDir temp;
        const auto path = save(temp.path() + "/license.nglic", bytes("valid"));
        ActivationDialog dialog(Store(path, machine, key));
        auto* enter = dialog.findChild<QPushButton*>("enterGroundStation");
        QVERIFY(enter->isEnabled());
        QCOMPARE(dialog.findChild<QLabel*>("licenseStatus")->textFormat(), Qt::PlainText);
        QFile::remove(path);
        enter->click();
        QVERIFY(!enter->isEnabled());
        QCOMPARE(dialog.result(), int(QDialog::Rejected));
        QVERIFY(!save(path, bytes("valid")).isEmpty());
        ActivationDialog again(Store(path, machine, key));
        again.findChild<QPushButton*>("enterGroundStation")->click();
        QCOMPARE(again.result(), int(QDialog::Accepted));
    }
};
QTEST_MAIN(LicensingTests)
#include "licensing_tests.moc"
