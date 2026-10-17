#pragma once

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>

// Configure before gst_init_check(). The Windows portable application must not
// use another application's 1.0 plugin paths, scanner or shared registry.
namespace PortableGStreamerEnvironment {

inline QString configure(const QString& packageDirectory, const QString& cacheDirectory)
{
    const QString package = QDir(packageDirectory).absolutePath();
    const QByteArray plugins = (package + QStringLiteral("/gstreamer-plugins")).toUtf8();
    for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                             "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0"}) {
        qputenv(name, plugins);
    }
    const QByteArray scanner = (package + QStringLiteral("/gst-plugin-scanner.exe")).toUtf8();
    for (const char* name : {"GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0"}) {
        qputenv(name, scanner);
    }

    // Diagnostics can explicitly request a new registry inside their log folder.
    // Ordinary launches always isolate the cache by package and build/runtime.
    QString registry = qEnvironmentVariable("QGC_GST_REGISTRY");
    if (registry.isEmpty()) {
        const QFileInfo runtime(package + QStringLiteral("/gstreamer-1.0-0.dll"));
        const QByteArray identity = package.toUtf8() + '\n'
            + QCoreApplication::applicationVersion().toUtf8() + '\n'
            + QByteArray::number(runtime.size()) + '\n'
            + QByteArray::number(runtime.lastModified().toMSecsSinceEpoch());
        const QString key = QString::fromLatin1(
            QCryptographicHash::hash(identity, QCryptographicHash::Sha256).toHex().left(24));
        registry = QDir(cacheDirectory).absoluteFilePath(
            QStringLiteral("gstreamer-portable-v1/%1/registry.bin").arg(key));
    }
    if (!QDir().mkpath(QFileInfo(registry).absolutePath())) {
        qWarning() << "Cannot create portable GStreamer registry directory:" << registry;
    }
    const QByteArray registryPath = registry.toUtf8();
    qputenv("GST_REGISTRY", registryPath);
    qputenv("GST_REGISTRY_1_0", registryPath);
    return registry;
}

} // namespace PortableGStreamerEnvironment
