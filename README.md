# 无人机地面站

当前源码标签：**v1.01.09-dual-control — 独立算法板控制与公共视频地址修复**。基于用户提供的 `v1.01.09_fix_gimbal_tcp` Qt/QGroundControl 工程。

**本仓库提供源码，不提供已经构建或验收的 Windows EXE。** 发布标签用于区分实际源码快照；未修改程序内部原有版本号。这些标签是在 2026-09-30 整理导入，表中日期为原快照日期，不代表当日已发布 GitHub。

## 版本导航

| 标签 | 原快照日期 | 主要内容 |
|---|---|---|
| [v1.01.09-base](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-base) | 2026-09-28 | 原始五路地面站 |
| [v1.01.09-mk22-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-mk22-ir) | 2026-09-29 | 算法板红外默认地址 |
| [v1.01.09-on-demand](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-on-demand) | 2026-09-29 | 五路按需拉流 |
| [v1.01.09-gimbal-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-gimbal-ir) | 2026-09-29 | 六路视频与云台红外 |
| [v1.01.09-profiles](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-profiles) | 2026-09-30 | 云台 / 算法板一键视频方案 |
| [v1.01.09-board-recording](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-board-recording) | 2026-10-08 | 板端多路录像与实际状态 |
| [v1.01.09-dual-control](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-dual-control) | 2026-10-08 | 默认地址修复、独立云台/算法板控制 |

查看 [完整变化记录](CHANGELOG.md)、[已知问题](project-docs/KNOWN_ISSUES.md) 和 [构建、接线与使用说明](project-docs/BUILD_AND_USAGE.md)。GitHub Releases 每个版本可下载对应 Source code (zip)。最新开发源码在 main。

## 当前版本内容

- 右侧“载荷控制”内有“云台控制”“算法板控制”两个独立入口，默认 `192.168.2.36:9000` / `:9001`；地址、端口、连接、反馈及日志分别保存。各自点击连接，可同时连接。
- 点选/框选按实际 `/algorithm` 或 `/gimbal` 流地址选择控制器；D455i、下视原始视频、前视原始预览、红外只预览，不发送跟踪命令。算法板面板不显示云台运动按钮。
- 下视/D455i 默认 `/board` / `/rgb`。启动及切方案修正为空或误填成已知主控其他流的公共地址；保留正确地址、自定义地址和手动开关。“下视/D455默认”按钮可明确恢复公共 MK22 地址。
- 新增“板端录像”：单选/多选、开始/追加、停止所选/全部、真实状态及保存目录；配套主控 v1.3.0，104 已安装。
- 录像和预览独立；关闭窗口、切方案、断网、退出地面站均不停止录像。首次连接用主控 IP 和独立连接码。
- 保存到主控 `/data/uav-recordings`，原电脑本地录像保留。见 [使用说明](project-docs/BOARD_RECORDING.md)。

- 视频页新增“云台方案”“算法板方案”按钮，自动替换载荷地址与标题并拉取新流。
- 下视 MIPI 与 D455i 的正确地址、手动开关选择和接收器对象保持不变。
- 云台方案显示 4 路；算法板方案显示 5 路；多余窗口关闭并隐藏。
- 记住方案和实际配置；再次点击按钮恢复该方案的默认 MK22 载荷地址。
- 载荷全屏时切方案回到多画面；公共相机全屏则保持全屏，退出后展示新载荷画面。
- 视频方案不切换板端运行模式；同时选择对应控制面板，不改动或自动连接两个独立控制通道。

验证：Qt 视频逻辑与地址路由 32 项、生产 TCP 双控制器与实际控制面板 6 项、板端录像控制器 8 项及录像 QML 面板 3 项通过，各含初始化/清理。104 已完成此前板端录像实测及算法控制通道被动回传检查；本版新增控制 UI 使用本机真实 TCP 测试服务验证，没有向在用板卡发送测试动作。完整 Windows EXE 尚未构建。

## 板端部署

配套仓库：[uav-board-deploy](https://github.com/Zhanghaohao666/uav-board-deploy)。地面站视频方案与板端运行模式分别管理；测试主控可以保持 dual 并行。

## 上游与公开副本

原始 QGroundControl README 保存在 [README_UPSTREAM.md](README_UPSTREAM.md)，许可证及第三方声明保留原文件。此仓库不代表上游官方发布。

Android 签名文件、旧摄像头 URL 中的口令及第三方测试私钥未进入公开历史；原始本地压缩包保留。因此公开源码不是原 ZIP 的逐字节副本。原上游 CI 移至 `.github/upstream-workflows/` 仅供参考，避免误触发旧项目的打包/上传任务；不会自动生成 Windows 安装包。
