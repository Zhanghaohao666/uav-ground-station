#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <cstdio>
#include "../../src/VideoReceiver/PortableGStreamerEnvironment.h"

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    if (app.arguments().size() != 3) {
        return 2;
    }
    app.setApplicationVersion("packaged-environment-probe-v1");
    PortableGStreamerEnvironment::configure(app.arguments()[1], app.arguments()[2]);
    QJsonObject environment;
    for (const char* name : {"GST_PLUGIN_PATH", "GST_PLUGIN_PATH_1_0",
                             "GST_PLUGIN_SYSTEM_PATH", "GST_PLUGIN_SYSTEM_PATH_1_0",
                             "GST_PLUGIN_SCANNER", "GST_PLUGIN_SCANNER_1_0",
                             "GST_REGISTRY", "GST_REGISTRY_1_0"}) {
        environment[QString::fromLatin1(name)] = qEnvironmentVariable(name);
    }
    const QByteArray json = QJsonDocument(environment).toJson(QJsonDocument::Compact);
    std::fwrite(json.constData(), 1, size_t(json.size()), stdout);
    std::fputc('\n', stdout);
    return 0;
}
