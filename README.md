# 无人机地面站

当前功能版本：**v1.01.16-lidar-record — E1X 雷达与视频板端录制**。

Windows 运行包在 [对应 Release](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.16-lidar-record) 提供；编译与验收状态以发布说明为准。完整解压到新目录后运行 `NexusGround.exe`，保留全部文件、`ssh` 子目录及 `NexusBoardAskpass.exe`。原电脑上的有效激活继续使用。

视频页打开“数据录制”：自动使用 dev/dev 连接主控，可修改 IP；分别控制视频和 E1X 车载激光雷达的开始、停止。视频保存在 `/data/uav-recordings`，雷达原始点云保存在 `/data/uav-lidar`，关闭地面站后已开始的任务继续运行。停止全部视频不会停止雷达。雷达未连接、数据盘不足或板端功能缺失均提示原因。

雷达录制需要配套新版主控后端、E1X SDK 和 J16 网络配置；不会自动启动雷达采集，也不把原始点云经 MK22 回传。当前雷达未连接，历史样本回放和软件回归不代表本次实时长录已验收。详见 [板端数据录制说明](project-docs/BOARD_RECORDING.md)。

保留 MK22 云台/算法板两套方案、单路高清与多路按需低码率、独立双控制、固定 dev/dev 自动 SSH 和一键服务维护。视频和算法处理程序不因本次地面站录制功能更新而改变；[板卡维护说明](project-docs/BOARD_MAINTENANCE.md)。

## 版本导航

| 标签 | 日期 | 主要内容 |
|---|---|---|
| [v1.01.16-lidar-record](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.16-lidar-record) | 2026-10-23 | E1X 点云板端录制、独立开停、状态/容量/保存目录 |
| [v1.01.15-auto-connect-rc3](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.15-auto-connect-rc3) | 2026-10-23 | dev 自动登录、自动提权、录像无需粘贴连接码 |
| [v1.01.14-board-maintenance-rc1](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.14-board-maintenance-rc1) | 2026-10-22 | 离线 SSH 终端、主控跳转、分路恢复及录像连接码提示 |
| [v1.01.13-activation-code-rc1](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.13-activation-code-rc1) | 2026-10-22 | 粘贴激活码、自动保存、管理员生成与复制；兼容旧授权 |
| [v1.01.12-offline-license-rc4](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.12-offline-license-rc4) | 2026-10-22 | 激活中文修复、双代码页和正式窗口文字检查 |
| [v1.01.12-offline-license-rc2](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.12-offline-license-rc2) | 2026-10-22 | 离线机器码授权及独立签发工具（窗口乱码，请用 rc4） |
| [v1.01.11-adaptive-rc1](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.11-adaptive-rc1) | 2026-10-21 | 单路高清、多路按需低码率 |
| [v1.01.09-base](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-base) | 2026-09-28 | 原始五路地面站 |
| [v1.01.09-mk22-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-mk22-ir) | 2026-09-29 | 算法板红外默认地址 |
| [v1.01.09-on-demand](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-on-demand) | 2026-09-29 | 五路按需拉流 |
| [v1.01.09-gimbal-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-gimbal-ir) | 2026-09-29 | 六路视频与云台红外 |
| [v1.01.09-profiles](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-profiles) | 2026-09-30 | 云台 / 算法板一键视频方案 |
| [v1.01.09-board-recording](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-board-recording) | 2026-10-08 | 板端多路录像与实际状态 |
| [v1.01.09-dual-control](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-dual-control) | 2026-10-08 | 默认地址修复、独立云台/算法板控制 |
| [v1.01.09-windows](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-windows) | 2026-10-12 | 首次 Windows x64 完整包、自动编译及启动检查 |

查看 [完整变化记录](CHANGELOG.md)、[已知问题](project-docs/KNOWN_ISSUES.md) 和 [构建、接线与使用说明](project-docs/BUILD_AND_USAGE.md)。GitHub Releases 每个版本可下载对应 Source code (zip)。最新开发源码在 main。

## 当前版本内容

- 右侧“载荷控制”内有“云台控制”“算法板控制”两个独立入口，默认 `192.168.2.36:9000` / `:9001`；地址、端口、连接、反馈及日志分别保存。各自点击连接，可同时连接。
- 点选/框选按实际 `/algorithm` 或 `/gimbal` 流地址选择控制器；D455i、下视原始视频、前视原始预览、红外只预览，不发送跟踪命令。算法板面板不显示云台运动按钮。
- 下视/D455i 默认 `/board` / `/rgb`。启动及切方案修正为空或误填成已知主控其他流的公共地址；保留正确地址、自定义地址和手动开关。默认统一使用 MK22 地址，页面仅保留两套载荷方案按钮。
- 新增“板端录像”：单选/多选、开始/追加、停止所选/全部、真实状态及保存目录；配套主控 v1.3.0，104 已安装。
- 录像和预览独立；关闭窗口、切方案、断网、退出地面站均不停止录像。新版只需主控 IP，自动完成 SSH 和录像连接。
- 保存到主控 `/data/uav-recordings`，原电脑本地录像保留。见 [使用说明](project-docs/BOARD_RECORDING.md)。

- 视频页“云台方案”“算法板方案”按钮替换载荷地址与标题，并保留手动打开的通道；若载荷全关，则只开启新方案主画面。
- 下视 MIPI 与 D455i 的正确地址、手动开关选择和接收器对象保持不变。
- 云台方案显示 4 路；算法板方案显示 5 路；多余窗口关闭并隐藏。
- 记住方案和实际配置；再次点击按钮恢复该方案的默认 MK22 载荷地址。
- 载荷全屏时切方案回到多画面；公共相机全屏则保持全屏，退出后展示新载荷画面。
- 视频方案不切换板端运行模式；同时选择对应控制面板，不改动或自动连接两个独立控制通道。

验证：Qt 视频逻辑与地址路由 32 项、生产 TCP 双控制器与实际控制面板 6 项、板端录像控制器 8 项及录像 QML 面板 3 项通过，各含初始化/清理。104 已完成此前板端录像实测及算法控制通道被动回传检查；新增控制 UI 使用本机真实 TCP 测试服务验证。2026-10-12 的 [Windows 构建](https://github.com/Zhanghaohao666/uav-ground-station/actions/runs/38196731143) 已通过完整编译、RTSP/H264 插件检查及 Qt 主窗口创建/可见/30 秒存活检查，实际 Windows 电脑上的板端拉流、控制和 MK22 联调仍需现场验收。

## 板端部署

配套仓库：[uav-board-deploy](https://github.com/Zhanghaohao666/uav-board-deploy)。地面站视频方案与板端运行模式分别管理；测试主控可以保持 dual 并行。

## 上游与公开副本

原始 QGroundControl README 保存在 [README_UPSTREAM.md](README_UPSTREAM.md)，许可证及第三方声明保留原文件。此仓库不代表上游官方发布。

Android 签名文件、旧摄像头 URL 中的口令及第三方测试私钥未进入公开历史；原始本地压缩包保留。因此公开源码不是原 ZIP 的逐字节副本。原上游 CI 移至 `.github/upstream-workflows/` 仅供参考。新的 Windows 工作流只在手动触发时编译、打包并检查启动，上传完整 ZIP，不生成安装器。
