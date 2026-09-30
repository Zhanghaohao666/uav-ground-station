# 无人机地面站

当前源码标签：**v1.01.09-base — 原始五路地面站**。基于用户提供的 `v1.01.09_fix_gimbal_tcp` Qt/QGroundControl 工程。

**本仓库提供源码，不提供已经构建或验收的 Windows EXE。** 发布标签用于区分实际源码快照；未修改程序内部原有版本号。这些标签是在 2026-09-30 整理导入，表中日期为原快照日期，不代表当日已发布 GitHub。

## 版本导航

| 标签 | 原快照日期 | 主要内容 |
|---|---|---|
| [v1.01.09-base](https://github.com/Zhanghaohao666/uav-ground-station/releases/tag/v1.01.09-base) | 2026-09-28 | 原始五路地面站 |

查看 [完整变化记录](CHANGELOG.md)、[已知问题](project-docs/KNOWN_ISSUES.md) 和 [构建、接线与使用说明](project-docs/BUILD_AND_USAGE.md)。GitHub Releases 每个版本可下载对应 Source code (zip)。最新开发源码在 main。

## 当前版本内容

- 导入用户提供的原始五路地面站源码，作为后续改动的基线。
- 保留现有飞行、视频、云台 TCP 和脚本入口；此标签不表示审查问题已修复。

验证：已做源码审查及部分 TCP 隔离复现，未验收完整 Windows 程序。

## 板端部署

配套仓库：[uav-board-deploy](https://github.com/Zhanghaohao666/uav-board-deploy)。地面站视频方案与板端运行模式分别管理；测试主控可以保持 dual 并行。

## 上游与公开副本

原始 QGroundControl README 保存在 [README_UPSTREAM.md](README_UPSTREAM.md)，许可证及第三方声明保留原文件。此仓库不代表上游官方发布。

Android 签名文件、旧摄像头 URL 中的口令及第三方测试私钥未进入公开历史；原始本地压缩包保留。因此公开源码不是原 ZIP 的逐字节副本。原上游 CI 移至 `.github/upstream-workflows/` 仅供参考，避免误触发旧项目的打包/上传任务；不会自动生成 Windows 安装包。
