$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
$package = Join-Path $env:RUNNER_TEMP 'gcs-package\NexusGround'
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
$info = [ordered]@{
    source_commit = (& git -C $source rev-parse HEAD).Trim()
    source_version = (& git -C $source describe --tags --always).Trim()
    workflow_url = "https://github.com/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID"
    qt_version = '5.15.2'
    gstreamer_version = '1.18.6'
    architecture = 'Windows x64'
    built_at_utc = [DateTime]::UtcNow.ToString('o')
    board_and_mk22_live_tested = $false
}
$info | ConvertTo-Json | Set-Content "$package\BUILD_INFO.json" -Encoding utf8
Copy-Item -Path @("$source\COPYING.md", "$source\CHANGELOG.md") -Destination $package
Copy-Item "$source\project-docs" "$package\使用说明" -Recurse
@'
新版地面站 Windows x64 运行包

请解压整个文件夹，关闭旧地面站后运行 NexusGround.exe。
保留所有 DLL、qml、platforms 和 gstreamer-plugins，不能只复制 EXE。
视频页可选择“云台方案”或“算法板方案”；载荷控制分别连接 9000/9001。
MK22 默认主控 192.168.2.36；Wi-Fi 调试使用 192.168.1.104。
版本和源码提交见 BUILD_INFO.json，功能说明见“使用说明”。
此构建需要现场验证 Windows 视频播放、载荷控制和板端录像。
'@ | Set-Content "$package\请先阅读.txt" -Encoding utf8

# An isolated startup check catches missing DLLs/QML. It is not a live flight test.
$env:QT_OPENGL = 'software'
$env:APPDATA = Join-Path $build 'smoke-appdata'
$env:LOCALAPPDATA = Join-Path $build 'smoke-localappdata'
New-Item -ItemType Directory -Force $env:APPDATA, $env:LOCALAPPDATA | Out-Null
$process = Start-Process $exe -WorkingDirectory $package -ArgumentList '--log-output' `
    -RedirectStandardOutput "$build\startup-stdout.log" -RedirectStandardError "$build\startup-stderr.log" -PassThru
try {
    Start-Sleep -Seconds 20
    $process.Refresh()
    if ($process.HasExited) { throw "启动检查失败，程序提前退出：$($process.ExitCode)" }
    if ($process.MainWindowHandle -eq 0) { throw '启动检查失败：未创建地面站主窗口' }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
$logs = (Get-Content "$build\startup-stdout.log", "$build\startup-stderr.log" -Raw -ErrorAction SilentlyContinue) -join "`n"
if ($logs -match 'QQmlApplicationEngine failed to load component|module "[^"]+" is not installed|Failed to create OpenGL context|unable to find qmlglsink') {
    throw '启动检查发现缺失 QML 模块或渲染初始化失败，请查看日志'
}
"Windows 运行包已生成：$package" | Out-File $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
"源码版本：$($info.source_version)，提交：$($info.source_commit)" | Out-File $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
