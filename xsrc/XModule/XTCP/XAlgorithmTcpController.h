#pragma once
#include "XGimbalTcpController.h"

// Same tracking protocol, independent socket, feedback, log and preferences.
class XAlgorithmTcpController : public XGimbalTcpController
{
    Q_OBJECT
public:
    explicit XAlgorithmTcpController(QObject* parent = nullptr)
        : XGimbalTcpController(parent, QStringLiteral("algorithmTcpClient"),
                               QStringLiteral("192.168.2.36"), 9001) {}
};
