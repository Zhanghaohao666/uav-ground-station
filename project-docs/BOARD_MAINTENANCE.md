# 板卡维护和 SSH 终端

v1.01.14-board-maintenance-rc1 起，视频页顶部增加“板卡维护”。
运行包内带 SSH 客户端；现场无需互联网下载安装，仍需电脑通过 MK22、网线或 Wi-Fi 局域网连通板卡。

## 连接

- MK22 主控：`192.168.2.36:22`，用户 `dev`。
- 算法板：`192.168.10.2:22`，用户 `dev`，默认勾选“经主控 SSH 跳转”。无需给电脑增加算法板网段。
- Wi-Fi 维护时可把主控改成 `192.168.1.104`；算法板地址和经主控跳转保持原样。
- 电脑确实能直接访问算法板时可取消跳转，并填写算法板实际 IP。

v1.01.15 起，点击“打开主控终端”或“打开算法板终端”自动使用固定 `dev / dev` 登录，算法板经主控跳转也自动完成两次认证。
IP、SSH 端口和跳转选择可以修改并记住，用户名固定为 dev。快捷命令和终端内的 sudo 自动使用同一密码，不需要手工输入。
首次连接自动记录主机指纹（accept-new）；已有主机指纹变化时拒绝连接。若原 IP 重刷镜像或更换板卡，应核对设备后单独更新对应指纹，不能关闭指纹校验。
自动密码组件为独立 `NexusBoardAskpass.exe`，只处理 SSH 密码提示；不修改板端 SSH、sudo 配置或部署公钥。

这是独立的交互终端，支持普通 shell 命令、sudo、方向键、Ctrl+C 以及菜单输入。
终端打开不等于 SSH 已连接，实际登录结果和错误在该终端显示。软件不显示未经验证的“已连接”状态。
`exit` 退出远程 shell；SSH 结束后窗口明确提示已经回到本机 Windows PowerShell，可关闭窗口。
关闭地面站或维护面板不会关闭已经打开的独立终端。

## 快捷操作

主控快捷操作包括查看服务状态/流地址、打开 `uav-switch` 菜单、分别重启下视 MIPI、D455i 和主控视频中继、近期日志、录像状态及网口/磁盘/温度。
算法板快捷操作包括服务状态，分别重启检测跟踪、前视预览、Mino17 红外，以及近期日志和资源信息。
点击“终端执行”会登录所选板卡、执行固定命令，然后停留在交互 shell；需要 sudo 时自动完成提权。
重启操作会先确认，对应视频会短暂中断。复制命令不会连接板卡或执行命令。
uav-switch 切换板端运行方案，视频页“云台方案/算法板方案”切换预览地址，两者分别管理。
查看状态不会切换模式；重启快捷操作不改 IP、开机默认方案、相机方向、算法库或录像配置。
主控中继恢复只重启现有中继服务，不启动默认启动方案来覆盖当前临时方案。

常用命令：

```bash
# 主控：原有菜单（只在主控执行）
uav-switch
# 4 看状态与流地址；5 抓帧验证；0 退出，视频继续。
# 1/2/3 切换方案需要按实际网口接线确认，6 保存开机默认。

# 主控：仅查询状态和高清 RTSP 地址
python3 /opt/uav-switch/manager.py status

# 主控：分路恢复
sudo systemctl restart uav-switch@board.service
sudo systemctl restart uav-switch@d455.service
sudo systemctl restart uav-switch@relay.service

# 算法板：分路恢复
sudo systemctl restart uav-front-algorithm.service
sudo systemctl restart uav-front-preview.service
sudo systemctl restart mino17-streamer.service

# 主控：录像状态
uav-record status
```

恢复服务不需要下载软件，也不要求板卡访问互联网。板端原部署必须仍在；镜像被重刷、服务被删除或硬件未供电时，重启服务无法代替重新部署/硬件检查。

## 直接连接录像

打开“板端录像”自动连接上次保存的主控 IP；更换板卡时修改 IP 并点击连接。无需填写或复制录像连接码。
地面站在后台通过 SSH 自动读取该板录像服务凭证，只在内存中用于 API 请求；不会将凭证保存在用户设置或日志中。已有旧版保存的录像码会被移除。
这不会关闭板端 API 的鉴权，也不改变软件的机器码激活。
修改 IP 会取消旧连接和旧凭证，重新从新主控读取，不会把旧请求或开始录像动作自动重放到新板。
默认录像写入主控 `/data/uav-recordings`；关闭窗口或地面站后已启动的录像继续，须明确停止。
“全选可用视频”按所连接主控的实际运行方案选择，不等于地面站此时打开的预览窗口。
新板仍须先完成板端部署，具备 `uav-record-api.service`、SSH dev/dev 和已挂载的数据盘；只修改 IP 不能替代安装这些服务。

## 实现和验证范围

Windows 使用独立 PowerShell 控制台调用包内 SSH，不在视频线程执行 SSH，不通过 9000/9001 跟踪控制端口。
使用 SSH 的标准 ProxyJump/PTY，保留主机密钥校验，无 agent/X11 转发；本地配置不含密码或录像凭证。
按端点生成独立配置，修改连接设置不覆盖已经打开的终端所用配置。

随包的微软客户端来自 [Win32-OpenSSH 官方发布](https://github.com/PowerShell/Win32-OpenSSH/releases/tag/10.4.0.0p1-Preview)，固定 SHA256 校验。
此上游客户端标签是 Preview；这里只分发客户端、所需库、密钥管理工具和许可，不安装 Windows SSH 服务。
SSH 的跳转和 PTY 参数见 [OpenSSH 手册](https://man.openbsd.org/ssh)。原项目第三方许可保留在 `ssh/LICENSE.txt` 和 `ssh/NOTICE.txt`。

测试覆盖输入校验、连接配置保存、跳转和直连、每路重启命令、命令复制、Windows 参数引用、真实 SSH 对中文路径配置的离线解析、实际 QML 面板及重启确认。
实板核对主控/算法板服务，验证跳转登录、状态和主控菜单的 PTY 操作，以 0 退出，没有为测试重启视频服务。
隔离 SSH 服务与正式 SSH 客户端验证固定密码、直连和 ProxyJump，录像控制器验证真实 SSH 取凭证后连接 HTTP 接口。实际 Windows 电脑的现场 MK22 操作仍需使用者验收；自动测试不宣称真实板卡执行了重启。
