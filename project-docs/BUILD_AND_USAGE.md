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

从旧版升级首次保留已有自定义布局/地址，主动点击方案才应用预设。之后记住方案、实际地址及窗口开关，不在启动时覆盖手动地址。方案按钮只切视频，不会向板卡发送网络配置或控制切换命令。

## 回归

含 `tests/video_demand` 的版本可在 Qt 5 Core/Test/Quick/QML 开发环境执行：

```sh
cd tests/video_demand
python3 generate_test_source.py
qmake demand.pro
make -j2
QT_QPA_PLATFORM=offscreen ./demand_tests -o results.txt,txt
```

生成器从本标签生产代码提取真实方法体，视频接收器和 QGC 外部依赖使用替身。GitHub 的轻量检查只运行此类测试，不构建整个地面站，也不生成 EXE。现场还需验证公共视频连续、载荷地址对应、快速切换、全屏恢复和控制目标。
