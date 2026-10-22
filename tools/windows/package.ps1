param([switch]$AllowUnverifiedGui)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
$package = Join-Path $env:RUNNER_TEMP 'gcs-package\地面站 NexusGround'
New-Item -ItemType Directory -Force -Path $package | Out-Null
Copy-Item "$build\staging\*" $package -Recurse -Force
Get-ChildItem $package -Filter '*.pdb' -Recurse | Remove-Item -Force
Get-ChildItem $package -Filter '*.ilk' -Recurse | Remove-Item -Force
$exe = Join-Path $package 'NexusGround.exe'
$qt = Split-Path (Split-Path (Get-Command qmake).Source -Parent) -Parent

# Scan xsrc as well as src: the new video profiles and settings live in xsrc.
& windeployqt --release --compiler-runtime --qmldir $source $exe
if ($LASTEXITCODE -ne 0) { throw "Qt/QML 打包失败：$LASTEXITCODE" }
@'
[Paths]
Prefix=.
Plugins=.
Imports=.
Qml2Imports=.
'@ | Set-Content "$package\qt.conf" -Encoding ascii

# Replace old checked-in runtime DLLs with the CRT matching the CI compiler.
$redist = Join-Path $env:VCINSTALLDIR 'Redist\MSVC'
$crt = Get-ChildItem $redist -Directory | Sort-Object Name -Descending |
    ForEach-Object { Get-ChildItem "$($_.FullName)\x64\Microsoft.VC*.CRT" -Directory -ErrorAction SilentlyContinue } |
    Select-Object -First 1
if (-not $crt) { throw '找不到 Visual Studio x64 运行库' }
Copy-Item "$($crt.FullName)\*.dll" $package -Force

$gst = $env:GCS_GST_ROOT
Copy-Item "$gst\bin\*.dll" $package -Force
Copy-Item "$gst\bin\gst-inspect-1.0.exe" $package -Force
New-Item -ItemType Directory -Force "$package\gstreamer-plugins" | Out-Null
Copy-Item "$gst\lib\gstreamer-1.0\*.dll" "$package\gstreamer-plugins" -Force
# GStreamer needs its scanner even when the application is a portable folder.
$scanner = Get-ChildItem $gst -Filter 'gst-plugin-scanner.exe' -Recurse | Select-Object -First 1
if (-not $scanner) { throw '缺少 GStreamer 插件扫描器' }
Copy-Item $scanner.FullName "$package\gst-plugin-scanner.exe" -Force
# Validate the bundle without relying on Qt/GStreamer installed on the runner.
$env:PATH = ($env:PATH -split ';' | Where-Object {
    $_ -and $_ -notlike "$gst*" -and $_ -notlike "$qt*"
}) -join ';'
foreach ($variable in @('QT_PLUGIN_PATH', 'QT_QPA_PLATFORM_PLUGIN_PATH', 'QML2_IMPORT_PATH', 'QML_IMPORT_PATH', 'GST_PLUGIN_PATH_1_0', 'GST_PLUGIN_SYSTEM_PATH_1_0', 'GST_PLUGIN_SCANNER_1_0')) {
    Remove-Item "Env:$variable" -ErrorAction SilentlyContinue
}
$env:GST_PLUGIN_PATH = "$package\gstreamer-plugins"
$env:GST_PLUGIN_SYSTEM_PATH = "$package\gstreamer-plugins"
$env:GST_PLUGIN_SCANNER = "$package\gst-plugin-scanner.exe"
$env:GST_REGISTRY = Join-Path $build 'gst-registry-test.bin'
foreach ($plugin in @('rtspsrc', 'rtph264depay', 'h264parse', 'avdec_h264')) {
    & "$package\gst-inspect-1.0.exe" $plugin *> "$build\gst-$plugin.log"
    if ($LASTEXITCODE -ne 0) { throw "视频插件检查失败：$plugin" }
}

foreach ($file in @('Qt5Core.dll', 'Qt5Quick.dll', 'Qt5Network.dll', 'platforms\qwindows.dll', 'Qt\labs\settings\qmldir')) {
    if (-not (Test-Path (Join-Path $package $file))) { throw "运行包缺少：$file" }
}
& "$source\tools\windows\test-portable-environment.ps1" -Package $package `
    -Probe "$build\video-probe\release\environment_probe.exe" -OutputDirectory "$build\portable-video"

$info = [ordered]@{
    source_commit = (& git -C $source rev-parse HEAD).Trim()
    source_version = (& git -C $source describe --tags --always).Trim()
    workflow_url = "https://github.com/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID"
    qt_version = '5.15.2'
    gstreamer_version = '1.18.6'
    architecture = 'Windows x64'
    built_at_utc = [DateTime]::UtcNow.ToString('o')
    portable_video_environment_isolation = $true
    native_h264_tcp_udp_decoded_frames_each = 10
    customer_pc_direct_exe_playback_verified = $false
    board_and_mk22_live_tested = $false
    offline_license_required = $true
    offline_license_algorithm = 'RSA-3072-PSS-SHA256'
    activation_gate_startup_verified = $false
    activation_ui_chinese_verified = $false
}
$info | ConvertTo-Json | Set-Content "$package\BUILD_INFO.json" -Encoding utf8
Copy-Item -Path @("$source\COPYING.md", "$source\CHANGELOG.md") -Destination $package
Copy-Item "$source\project-docs" "$package\使用说明" -Recurse
Copy-Item -Path @("$source\tools\windows\License-Information.cmd", "$source\tools\windows\Video-Diagnostics.cmd", "$source\tools\windows\Video-Compatible.cmd", "$source\tools\windows\video-diagnostics.ps1") -Destination $package
@'
新版地面站 Windows x64 运行包

请解压整个文件夹，关闭旧地面站后运行 NexusGround.exe。
首次运行会显示离线激活窗口：导出 .ngreq 申请给管理员，收到 .nglic 后导入。
可运行 License-Information.cmd 查看授权信息或续期。
客户运行包不含私钥或管理员签发工具。
保留所有 DLL、qml、platforms 和 gstreamer-plugins，不能只复制 EXE。
视频页可选择“云台方案”或“算法板方案”；载荷控制分别连接 9000/9001。
MK22 默认主控 192.168.2.36；Wi-Fi 调试使用 192.168.1.104。
版本和源码提交见 BUILD_INFO.json，功能说明见“使用说明”。
Windows EXE 已内置本包视频插件路径及独立缓存，无需诊断脚本设置环境。
本包为 MK22 流畅度候选版：120ms 网络缓冲、解码后最多两帧队列。
切方案保留手动开启的通道；没有开启载荷时只开主画面。
请在你的电脑上直接双击 EXE 验证视频，随后进行远距离实测。
若仍无画面，运行随包 Video-Diagnostics.cmd 并保留 video-diagnostics 日志。
此构建仍需现场验证 Windows 视频播放、载荷控制和板端录像。
'@ | Set-Content "$package\请先阅读.txt" -Encoding utf8

# An isolated startup check catches missing DLLs/QML. It is not a live flight test.
$env:QT_OPENGL = 'software'
# Launch the EXE directly with conflicting inherited values. Its own startup
# must isolate these without a diagnostic launcher doing the work for it.
foreach ($variable in @('GST_PLUGIN_PATH', 'GST_PLUGIN_PATH_1_0', 'GST_PLUGIN_SYSTEM_PATH', 'GST_PLUGIN_SYSTEM_PATH_1_0', 'GST_PLUGIN_SCANNER', 'GST_PLUGIN_SCANNER_1_0', 'GST_REGISTRY', 'GST_REGISTRY_1_0')) {
    [Environment]::SetEnvironmentVariable($variable, 'C:/missing-other-gstreamer', 'Process')
}
Remove-Item Env:QGC_GST_REGISTRY -ErrorAction SilentlyContinue
$env:QGC_CI_STDERR_LOG = '1'
$env:QGC_CI_STARTUP_REPORT = Join-Path $build 'startup-report.log'
$env:APPDATA = Join-Path $build 'smoke-appdata'
$env:LOCALAPPDATA = Join-Path $build 'smoke-localappdata'
New-Item -ItemType Directory -Force $env:APPDATA, $env:LOCALAPPDATA | Out-Null
$process = Start-Process $exe -WorkingDirectory $package -ArgumentList '--log-output' `
    -RedirectStandardOutput "$build\startup-stdout.log" -RedirectStandardError "$build\startup-stderr.log" -PassThru
$guiStartupVerified = $false
$activationGateVerified = $false
$activationChineseVerified = $false
$guiStartupFailure = $null
try {
    Start-Sleep -Seconds 30
    $process.Refresh()
    if ($process.HasExited) { throw "启动检查失败，程序提前退出：$($process.ExitCode)" }
    if (-not (Test-Path $env:QGC_CI_STARTUP_REPORT -PathType Leaf)) {
        throw 'Startup report is missing; a live process alone does not verify the GUI'
    }
    $report = [string](Get-Content $env:QGC_CI_STARTUP_REPORT -Raw -ErrorAction Stop)
    if ([string]::IsNullOrWhiteSpace($report)) { throw 'Startup report is empty' }
    if ($report -notmatch 'activation_required=true' -or
        $report -notmatch 'activation_dialog_created=true' -or
        $report -notmatch 'main_services_started=false' -or
        $report -notmatch 'window_visible=true') {
        throw '未授权的运行包没有正确停留在可见激活窗口，拒绝发布'
    }
    $activationGateVerified = $true
    $textMatch = [regex]::Match($report, '(?m)^activation_texts_utf8_base64=([^\r\n]+)')
    if (-not $textMatch.Success) { throw 'Production activation UI text report is missing' }
    $actualText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($textMatch.Groups[1].Value)) | ConvertFrom-Json
    $expectedText = Get-Content "$source/tests/licensing/activation-ui.zh-CN.json" -Raw -Encoding utf8 | ConvertFrom-Json
    foreach ($property in $expectedText.PSObject.Properties) {
        if ($actualText.($property.Name) -cne $property.Value) {
            throw "Production activation Chinese text mismatch: $($property.Name)"
        }
    }
    if ($report -notmatch 'activation_screenshot_saved=true') {
        throw 'Production activation screenshot was not saved'
    }
    $activationChineseVerified = $true
    # The owner private key is never sent to CI. Native disposable-key tests
    # cover successful activation; this exact production EXE must stay locked.
    # Portable video environment/native decoding are tested separately above.
} catch {
    $guiStartupFailure = $_.Exception.Message
    if (-not $AllowUnverifiedGui) { throw }
    Write-Warning "GUI startup remains unverified on this runner: $guiStartupFailure"
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    Get-ChildItem (Join-Path $env:USERPROFILE 'Documents') -Filter 'QGCConsole.log' -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 | ForEach-Object { Copy-Item $_.FullName "$build\startup-console.log" -Force }
}
$info.activation_gate_startup_verified = $activationGateVerified
$info.activation_ui_chinese_verified = $activationChineseVerified
$info.gui_startup_verified = $guiStartupVerified
$info.gui_startup_failure = $guiStartupFailure
$info.gui_video_frames_verified = $false
$info.allow_unverified_gui_candidate = [bool]$AllowUnverifiedGui
$info.rtsp_network_jitter_ms = 120
$info.decoded_display_queue_max_frames = 2
$info | ConvertTo-Json | Set-Content "$package\BUILD_INFO.json" -Encoding utf8
$logs = (Get-Content "$build\startup-stdout.log", "$build\startup-stderr.log" -Raw -ErrorAction SilentlyContinue) -join "`n"
if ($logs -match 'QQmlApplicationEngine failed to load component|module "[^"]+" is not installed|Failed to create OpenGL context|unable to find qmlglsink') {
    throw '启动检查发现缺失 QML 模块或渲染初始化失败，请查看日志'
}
if (Get-ChildItem $package -Include '*.private.pem', '*.nglic', '*.ngreq' -Recurse) {
    throw 'Customer runtime unexpectedly contains a signing secret or preissued license'
}
# Exercise real native decoding and EXE startup in a Chinese package path,
# then give the downloadable archive its normal top-level directory.
$finalPackage = Join-Path (Split-Path $package -Parent) 'NexusGround'
Move-Item -LiteralPath $package -Destination $finalPackage
$package = $finalPackage
"Windows 运行包已生成：$package" | Out-File $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
"源码版本：$($info.source_version)，提交：$($info.source_commit)" | Out-File $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
