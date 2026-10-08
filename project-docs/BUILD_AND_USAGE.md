# 构建与使用

## 构建

使用原项目 Windows Qt 5.15、对应编译器及 GStreamer 开发/运行环境，打开根目录 `abdgcs.pro`，重新运行 qmake 并完整构建，再按原部署方式打包 Qt/QML/GStreamer 依赖。只复制源码到旧 EXE 旁不会生效。新版使用 Qt.labs.settings，打包时包含对应 QML 模块。

当前 Linux 工作环境缺少 location、positioning、quickcontrols2、svg、texttospeech、multimedia、serialport 等完整 Qt 模块及 GStreamer 开发库，完整应用尚未构建。隔离视频逻辑测试不能替代完整编译。源码目录已包含原快照第三方目录，原 Android 签名文件没有公开；Android 发布需要自己的签名配置。

## 视频地址（MK22 默认主控 192.168.2.36）

| 视频 | RTSP 地址 |
|---|---|
| 下视 MIPI | rtsp://192.168.2.36:8554/board |
| D455i 彩色 | rtsp://192.168.2.36:8554/rgb |
| 前视算法 | rtsp://192.168.2.36:8554/algorithm |
| 前视原始预览 | rtsp://192.168.2.36:8554/preview |
| 算法板红外 | rtsp://192.168.2.36:8554/infrared |
| 云台可见光 | rtsp://192.168.2.36:8555/gimbal |
| 云台红外 | rtsp://192.168.2.36:8556/gimbal_ir |

Wi-Fi 调试时替换主机为实际主控 Wi-Fi IP。两块主控同时接同一网段须使用不同 IP；方案按钮默认载荷地址是 `.36`，其他地址要在各窗口设置中调整。

## 按版本使用

原始/红外默认地址版没有按需机制。on-demand 及之后版本：Open/Close 单独开关；全屏停止其他隐藏流，退出恢复之前选择。隐藏视频页面也会停止接收。

gimbal-ir 版增加第六路。profiles 版在视频页顶部提供“云台方案”“算法板方案”：只停止并替换第 3～6 路，前两路地址/选择不变；云台 4 窗口、算法板 5 窗口。再次点击按钮恢复默认载荷地址并打开新方案载荷画面。公共相机全屏会保留，退出全屏后才显示新载荷流；载荷全屏时切换会返回多画面。

从旧版升级首次保留已有自定义布局/地址，主动点击方案才应用载荷预设。之后记住方案、实际地址及窗口开关。dual-control 版启动及切方案会修正公共相机空地址，以及 `192.168.2.36` / `192.168.1.104:8554` 下误填的其他已知流路径；保留正确和其他自定义地址。修正地址只让原先开启的一路重新拉流，不打开原先关闭的公共相机。

如果 D455i 和前视预览显示同一画面，D455i 应填写 `/rgb`，预览应填写 `/preview`。视频页“下视/D455默认”按钮可将前两路明确恢复为表中的 MK22 地址；窗口开关保持不变。

## 云台与算法板独立控制

右侧选择“载荷控制”，再选择“云台控制”或“算法板控制”：

| 控制入口 | 默认 IP | 默认 TCP 端口 | 对应算法输入 |
|---|---|---|---|
| 云台控制 | 192.168.2.36 | 9000 | `/gimbal` 云台可见光 |
| 算法板控制 | 192.168.2.36 | 9001 | `/algorithm` 前视检测跟踪 |

两个入口各自点击“连接”，可同时连接。地址、端口、状态、目标列表和日志独立；Wi-Fi 调试可将 IP 改为 `192.168.1.104`。各自“恢复默认”会断开该控制连接并恢复表中的地址，需重新点击连接，不影响另一入口。

切换视频方案会选择对应控制面板，不重建已有控制连接。双击或框选画面时根据实际视频路径使用正确控制器，与当前显示哪个控制面板无关。下视 MIPI、D455i、前视原始预览和红外都不发送跟踪命令。点选需命中检测框，ID 跟踪需使用面板显示的当前目标 ID；未连接或过期 ID 不代表已经执行。

算法板面板提供检测开关、点选/框选/ID、停止跟踪、状态及日志；云台另有回中、下视90°、角度设置、锁定和方向控制。此次修改不安装新算法、不修改板端端口，也不会发送板卡网络配置命令。

## 回归

新增板端录像见 [BOARD_RECORDING.md](BOARD_RECORDING.md)。新源文件、类型注册和 QML 资源已接入根工程；需要重新 qmake 并完整编译。

含 `tests/video_demand` 的版本可在 Qt 5 Core/Test/Quick/QML 开发环境执行：

```sh
cd tests/video_demand
python3 generate_test_source.py
qmake demand.pro
make -j2
QT_QPA_PLATFORM=offscreen ./demand_tests -o results.txt,txt
```

生成器从本标签生产代码提取真实方法体，视频接收器和 QGC 外部依赖使用替身。GitHub 的轻量检查只运行此类测试，不构建整个地面站，也不生成 EXE。现场还需验证公共视频连续、载荷地址对应、快速切换、全屏恢复和控制目标。

`tests/payload_controls` 直接编译生产 TCP 客户端、云台及算法控制器，连接两个独立本机 TCP 服务；同时加载实际 `XPayloadControlPanel.qml` 验证端口、指令、状态隔离和按钮。使用 Qt5 Quick Controls2/Layouts 运行库，执行：

```sh
cd tests/payload_controls
qmake payload.pro
make -j2
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./payload_tests
```
