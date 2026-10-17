#include <QtTest>
#include <QTemporaryDir>
#include "../../src/VideoReceiver/PortableGStreamerEnvironment.h"

class EnvironmentTests : public QObject {
    Q_OBJECT
private slots:
    void init() {
        qunsetenv("QGC_GST_REGISTRY");
        QCoreApplication::setApplicationVersion("build-one");
    }

    void inheritedEnvironmentAndSharedCacheAreIsolated() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString package = dir.path() + QString::fromUtf8("/地面站 NexusGround");
        const QString shared = dir.path() + "/shared-registry.bin";
        QFile sentinel(shared);
        QVERIFY(sentinel.open(QIODevice::WriteOnly));
        sentinel.write("old application's cache");
        sentinel.close();
        for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                                 "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0",
                                 "GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0"}) {
            qputenv(name, "/another/application/missing");
        }
        qputenv("GST_REGISTRY", shared.toUtf8());
        qputenv("GST_REGISTRY_1_0", shared.toUtf8());
        const QString registry = PortableGStreamerEnvironment::configure(package, dir.path() + QString::fromUtf8("/缓存 cache"));
        for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                                 "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0"}) {
            QCOMPARE(qEnvironmentVariable(name), package + "/gstreamer-plugins");
#ifdef Q_OS_WIN
            wchar_t actual[32768];
            const QString key = QString::fromLatin1(name);
            QVERIFY(GetEnvironmentVariableW(reinterpret_cast<const wchar_t*>(key.utf16()), actual, 32768) > 0);
            QCOMPARE(QString::fromWCharArray(actual), package + "/gstreamer-plugins");
#endif
        }
        for (const char* name : {"GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0"}) {
            QCOMPARE(qEnvironmentVariable(name), package + "/gst-plugin-scanner.exe");
        }
        QVERIFY(registry != shared);
        QCOMPARE(qEnvironmentVariable("GST_REGISTRY"), registry);
        QCOMPARE(qEnvironmentVariable("GST_REGISTRY_1_0"), registry);
        QVERIFY(QDir(QFileInfo(registry).absolutePath()).exists());
        QVERIFY(sentinel.open(QIODevice::ReadOnly));
        QCOMPARE(sentinel.readAll(), QByteArray("old application's cache"));
    }

    void unicodeSetterSurvivesWindowsCodePageConversion() {
        const QString value = QString::fromUtf8("C:/Users/陶文兵/地面站/缓存");
        qputenv("QGC_TEST_VIDEO_PATH", value.toUtf8());
        qInfo() << "Legacy UTF-8/narrow setter preserved Unicode:"
                << (qEnvironmentVariable("QGC_TEST_VIDEO_PATH") == value);
        PortableGStreamerEnvironment::setPath("QGC_TEST_VIDEO_PATH", value);
        QCOMPARE(qEnvironmentVariable("QGC_TEST_VIDEO_PATH"), value);
        qunsetenv("QGC_TEST_VIDEO_PATH");
    }

    void restartReusesOwnCacheButDifferentBuildAndFolderDoNot() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString root = dir.path() + "/cache";
        const QString first = PortableGStreamerEnvironment::configure(dir.path() + "/package", root);
        QFile registry(first);
        QVERIFY(registry.open(QIODevice::WriteOnly));
        registry.write("warm cache");
        registry.close();
        QCOMPARE(PortableGStreamerEnvironment::configure(dir.path() + "/package", root), first);
        QVERIFY(registry.open(QIODevice::ReadOnly));
        QCOMPARE(registry.readAll(), QByteArray("warm cache"));
        QCoreApplication::setApplicationVersion("build-two");
        QVERIFY(PortableGStreamerEnvironment::configure(dir.path() + "/package", root) != first);
        QCoreApplication::setApplicationVersion("build-one");
        QVERIFY(PortableGStreamerEnvironment::configure(dir.path() + "/other-package", root) != first);
    }

    void diagnosticsCanChooseTheirRegistryWithoutChangingRendererOrDecoder() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString registry = dir.path() + "/logs/registry.bin";
        PortableGStreamerEnvironment::setPath("QGC_GST_REGISTRY", registry);
        qputenv("QT_OPENGL", "test-renderer-unchanged");
        qputenv("GST_PLUGIN_FEATURE_RANK", "test-decoder-unchanged");
        QCOMPARE(PortableGStreamerEnvironment::configure(dir.path(), dir.path() + "/cache"), registry);
        QCOMPARE(qEnvironmentVariable("GST_REGISTRY_1_0"), registry);
        QCOMPARE(qgetenv("QT_OPENGL"), QByteArray("test-renderer-unchanged"));
        QCOMPARE(qgetenv("GST_PLUGIN_FEATURE_RANK"), QByteArray("test-decoder-unchanged"));
    }
};

QTEST_GUILESS_MAIN(EnvironmentTests)
#include "environment_tests.moc"
