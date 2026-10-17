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
        const QString registry = PortableGStreamerEnvironment::configure(package, dir.path() + "/cache");
        for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                                 "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0"}) {
            QCOMPARE(qgetenv(name), (package + "/gstreamer-plugins").toUtf8());
        }
        for (const char* name : {"GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0"}) {
            QCOMPARE(qgetenv(name), (package + "/gst-plugin-scanner.exe").toUtf8());
        }
        QVERIFY(registry != shared);
        QCOMPARE(qgetenv("GST_REGISTRY"), registry.toUtf8());
        QCOMPARE(qgetenv("GST_REGISTRY_1_0"), registry.toUtf8());
        QVERIFY(QDir(QFileInfo(registry).absolutePath()).exists());
        QVERIFY(sentinel.open(QIODevice::ReadOnly));
        QCOMPARE(sentinel.readAll(), QByteArray("old application's cache"));
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
        qputenv("QGC_GST_REGISTRY", registry.toUtf8());
        qputenv("QT_OPENGL", "test-renderer-unchanged");
        qputenv("GST_PLUGIN_FEATURE_RANK", "test-decoder-unchanged");
        QCOMPARE(PortableGStreamerEnvironment::configure(dir.path(), dir.path() + "/cache"), registry);
        QCOMPARE(qgetenv("GST_REGISTRY_1_0"), registry.toUtf8());
        QCOMPARE(qgetenv("QT_OPENGL"), QByteArray("test-renderer-unchanged"));
        QCOMPARE(qgetenv("GST_PLUGIN_FEATURE_RANK"), QByteArray("test-decoder-unchanged"));
    }
};

QTEST_GUILESS_MAIN(EnvironmentTests)
#include "environment_tests.moc"
