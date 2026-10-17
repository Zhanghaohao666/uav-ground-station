#pragma once

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#ifdef Q_OS_WIN
#include <qt_windows.h>
#include <cstdlib>
#endif

// Configure before gst_init_check(). The Windows portable application must not
// use another application's 1.0 plugin paths, scanner or shared registry.
namespace PortableGStreamerEnvironment {

inline void setPath(const char* name, const QString& value)
{
#ifdef Q_OS_WIN
    // Qt 5 qputenv() uses _putenv_s(), which treats UTF-8 bytes as the current
    // Windows code page. Keep both the CRT (Qt) and Win32 (GLib/scanner) views
    // in Unicode; the user's package and profile directories contain Chinese.
    const QString key = QString::fromLatin1(name);
    const auto wideKey = reinterpret_cast<const wchar_t*>(key.utf16());
    const auto wideValue = reinterpret_cast<const wchar_t*>(value.utf16());
    const bool crtOk = _wputenv_s(wideKey, wideValue) == 0;
    const bool win32Ok = SetEnvironmentVariableW(wideKey, wideValue) != 0;
    if (!crtOk || !win32Ok) {
        qWarning() << "Cannot set portable GStreamer environment:" << key;
    }
#else
    qputenv(name, value.toUtf8());
#endif
}

inline QString configure(const QString& packageDirectory, const QString& cacheDirectory)
{
    const QString package = QDir(packageDirectory).absolutePath();
    const QString plugins = package + QStringLiteral("/gstreamer-plugins");
    for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                             "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0"}) {
        setPath(name, plugins);
    }
    const QString scanner = package + QStringLiteral("/gst-plugin-scanner.exe");
    for (const char* name : {"GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0"}) {
        setPath(name, scanner);
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
    setPath("GST_REGISTRY", registry);
    setPath("GST_REGISTRY_1_0", registry);
    return registry;
}

} // namespace PortableGStreamerEnvironment
