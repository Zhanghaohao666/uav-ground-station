# 无人机地面站

当前源码标签：**v1.01.09-gimbal-ir — 六路视频与云台红外**。基于用户提供的 `v1.01.09_fix_gimbal_tcp` Qt/QGroundControl 工程。

**本仓库提供源码，不提供已经构建或验收的 Windows EXE。** 发布标签用于区分实际源码快照；未修改程序内部原有版本号。这些标签是在 2026-09-30 整理导入，表中日期为原快照日期，不代表当日已发布 GitHub。

## 版本导航

| 标签 | 原快照日期 | 主要内容 |
|---|---|---|
| [v1.01.09-base](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-base) | 2026-09-28 | 原始五路地面站 |
| [v1.01.09-mk22-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-mk22-ir) | 2026-09-29 | 算法板红外默认地址 |
| [v1.01.09-on-demand](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-on-demand) | 2026-09-29 | 五路按需拉流 |
| [v1.01.09-gimbal-ir](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-gimbal-ir) | 2026-09-29 | 六路视频与云台红外 |

查看 [完整变化记录](CHANGELOG.md)、[已知问题](project-docs/KNOWN_ISSUES.md) 和 [构建、接线与使用说明](project-docs/BUILD_AND_USAGE.md)。GitHub Releases 每个版本可下载对应 Source code (zip)。最新开发源码在 main。

## 当前版本内容

- 继承按需拉流，从五路扩展到六路，三列两行。
- 第 6 路默认 rtsp://192.168.2.36:8556/gimbal_ir，独立开关、全屏及改地址。
- 云台红外只预览，禁用选点/框选跟踪；没有新增测温功能。
- 修复自动相机发现逻辑提前返回，避免第 3～6 路手动地址被忽略。

验证：23 项 Qt 隔离测试通过（含初始化/清理），QML/配置检查通过。板端红外实际抓帧验证不等于 Windows 地面站或远距离图传验收。

## 板端部署

配套仓库：[uav-board-deploy](https://github.com/Zhanghaohao666/uav-board-deploy)。地面站视频方案与板端运行模式分别管理；测试主控可以保持 dual 并行。

## 上游与公开副本

原始 QGroundControl README 保存在 [README_UPSTREAM.md](README_UPSTREAM.md)，许可证及第三方声明保留原文件。此仓库不代表上游官方发布。

Android 签名文件、旧摄像头 URL 中的口令及第三方测试私钥未进入公开历史；原始本地压缩包保留。因此公开源码不是原 ZIP 的逐字节副本。原上游 CI 移至 `.github/upstream-workflows/` 仅供参考，避免误触发旧项目的打包/上传任务；不会自动生成 Windows 安装包。
