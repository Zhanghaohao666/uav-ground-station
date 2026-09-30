# 发布副本处理

所有标签统一执行以下处理，避免凭据进入公开 Git 历史：

- 排除 android/android_release.keystore、VideoReceiverApp/android/android_release.keystore。
- 排除 libs/qmlglsink/gst-plugins-good/tests/files/test-key.pem（第三方测试夹具；相关上游私钥测试不能直接运行）。
- 移除 xsrc 内旧摄像头示例 URL 的用户名/口令部分；保留地址及其余业务代码。
- 排除嵌套 .git 元数据及 Python 缓存；将原 .github/workflows 移至 .github/upstream-workflows。
- 原 README 改名为 README_UPSTREAM.md，新增项目版本、构建、已知问题说明。
- 隔离测试相对路径改为仓库内路径，保持测试用例及生产方法提取方式。

原始归档名称和 SHA-256 记录在 versions.json，用于本地追溯，不代表公开下载与原始 ZIP 相同。原快照日期和 GitHub 导入日期分别记录。历史 gimbal-ir 快照中的板端安装脚本属于当时部署方式；当前板端请使用独立 uav-board-deploy，避免混装。
