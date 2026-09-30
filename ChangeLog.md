# NexusGround Ground Station - v1.01.09 ChangeLog

**Release Date**: 2026-09-24  
**Base Version**: v1.01.08  
**Target Architecture**: Windows 10/11 x64 (MSVC 2019/2022 + Qt 5.15.2)

---

## 1. Issues Addressed

1. **Gimbal TCP Control Channel Failed to Connect to `192.168.2.36:9000` (Zero SYN packets sent)**:
   - **Root Cause**: On Windows systems with application or system-wide HTTP/HTTPS proxy configurations (e.g., VPNs, web proxies), Qt's `QTcpSocket` implicitly inherits `QNetworkProxy::applicationProxy()`. Because HTTP proxies do not support raw binary TCP protocols, `QTcpSocket` encountered `QAbstractSocket::UnsupportedSocketOperationError` ("The proxy type is invalid for this operation") and immediately closed the socket before sending any SYN packets.
   - **Fix**: In `XTCPClient.cc` (`CcTcpClient::connetWorker`), explicitly called `_tcpSocket->setProxy(QNetworkProxy::NoProxy);` to bypass all proxies and use direct network routing.

2. **Potential Crash `0xC0000005` on `localIp` Bind Failure**:
   - **Root Cause**: When `errorOccurred` was connected prior to `_tcpSocket->bind(...)`, a bind failure synchronously fired `_socketError()`, destroying `_tcpSocket` and setting it to `nullptr`. The subsequent call to `_tcpSocket->errorString()` caused a null pointer dereference.
   - **Fix**: Reordered signal connections to occur after the bind attempt. Implemented graceful fallback: if binding to `localIp` fails, the socket is cleanly recreated and falls back to system automatic routing with a warning, rather than crashing or terminating the connection attempt.

3. **Version Bump**:
   - Incremented version to `v1.01.09` (date: `20260924`) in `xsrc/XSingletons/XGlobalProperty.qml`.
