#pragma once
#include <QString>
#include <QUrl>

// Canonical settings always retain the HD address. Only these paired UAV relay
// mounts have on-demand low streams; arbitrary camera URLs stay untouched.
inline QString uavPlaybackUri(const QString& configured, bool multiple)
{
    if (!multiple) return configured;
    QUrl url(configured);
    if (url.scheme() != QStringLiteral("rtsp")) return configured;
    const QString path = url.path();
    const bool known =
        (url.port() == 8554 &&
         (path == "/board" || path == "/rgb" || path == "/algorithm" ||
          path == "/preview" || path == "/infrared")) ||
        (url.port() == 8555 && path == "/gimbal") ||
        (url.port() == 8556 && path == "/gimbal_ir");
    if (!known) return configured;
    url.setPath(path + QStringLiteral("_low"));
    return url.toString();
}
