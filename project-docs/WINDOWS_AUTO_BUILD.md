# Windows 一键生成运行包

仓库提供手动触发的 **Windows 可运行包** 工作流，在 GitHub 的 Windows 机器上准备 Qt 5.15.2、Visual Studio x64 和 GStreamer 1.18.6，编译根工程 `abdgcs.pro`。你的电脑不需要安装 Qt 或编译器。

第一次完整编译和 Qt 主窗口启动检查已通过，直接使用可下载 [v1.01.09-windows 固定版本](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-windows) 中的 Windows ZIP。此附件独立于 Actions 的 30 天临时文件保留期；[成功运行记录](https://github.com/Zhanghaohao666/uav-ground-station/actions/runs/38196731143) 对应构建提交 `d00cb39a3e0ba760d3ec751fed5d1a861082651e`。

2026-10-15：已收到同一电脑、同一 RTSP 地址下旧版可以播放而该运行包没有画面的反馈，现场故障尚未确认修复。新增 [视频诊断工具（约 3 KB，不含 EXE）](https://github.com/Zhanghaohao666/uav-ground-station/releases/download/v1.01.09-windows/NexusGround-Video-Diagnostics_20261015.zip)，完整解压到 `NexusGround.exe` 同目录后，按附件说明运行正常诊断或原生 OpenGL＋软件解码入口。日志保存在 EXE 旁的 `video-diagnostics`。工具不修改板端服务，也不是新编译的修复版。

[Windows 复现实验](https://github.com/Zhanghaohao666/uav-ground-station/actions/runs/38709949893) 使用原运行包 DLL，通过 TCP、UDP 各接收并解码 10 帧生成的测试画面；实际 EXE 的出图验证未通过，测试环境存在图形后端限制。该结果不能代替现场 Windows/MK22 的播放验收。

2026-10-18：用户确认普通诊断入口能播放，退出后直接运行同目录 EXE 仍无视频，排除了同时运行和快捷方式指向其他目录的情况。候选源码 `v1.01.09-windows-startup-rc1` 将本包插件路径、扫描器及独立缓存配置内置到 Windows EXE。完整构建后请解压到新目录并直接运行 EXE；是否消除现场黑屏以用户实测为准，不能仅根据原生解码或启动检查判定。

## 点击运行和下载

1. 登录 GitHub，打开 [Windows 可运行包](https://github.com/Zhanghaohao666/uav-ground-station/actions/workflows/windows-package.yml)。
2. 点右侧 **Run workflow**，分支选 **main**，再点绿色 **Run workflow**。
3. 打开刚出现的运行记录，等待所有步骤变绿。如果失败，打开红色步骤查看原因；失败记录不会上传运行包。
4. 在运行记录底部 **Artifacts** 下载 **NexusGround-Windows-x64**。需要处于 GitHub 登录状态；文件保留 30 天，可再次运行重新生成。
5. 将 ZIP 完整解压到新目录，保留原版，关闭旧程序后运行里面的 `NexusGround.exe`。DLL、QML 和视频插件必须一起保留。

参考 [GitHub 手动运行说明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow) 和 [下载构建产物说明](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)。

## 版本和检查范围

运行包内 `BUILD_INFO.json` 记录实际源码版本、完整提交号、构建时间和运行链接，不能仅根据原有界面版本号判断是否是新版。每次手动运行构建所选分支当时的源码；原源码标签不会被改写。

流程检查视频支持已启用、关键 RTSP/H264 插件存在、Qt/QML 文件齐全，并短暂启动完整 EXE。编译和启动检查成功不等于已验收 Windows 上的实际板端拉流、跟踪指令、MK22 链路或长时间录像。

此流程不连接板子、不修改板端程序，不包含连接码或登录密码；源码和旧版本继续保留。构建日志单独保留 14 天。

首次使用可在视频页点“算法板方案”或“云台方案”。D455i 是 `/rgb`，下视是 `/board`；右侧载荷控制默认云台 `192.168.2.36:9000`、算法板 `192.168.2.36:9001`。Wi-Fi 调试要将主控 IP 改为 `192.168.1.104`。板端录像使用你自己的连接码，不能用构建服务的环境代替现场连接设置。
