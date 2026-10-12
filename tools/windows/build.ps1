$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
New-Item -ItemType Directory -Force -Path $build | Out-Null
Push-Location $build
try {
    # Keep the full source tag in APP_VERSION_STR. Windows file VERSION must
    # contain only numbers, unlike our descriptive Git tags.
    & qmake -r "$source\abdgcs.pro" 'CONFIG+=release' 'CONFIG+=StableBuild' `
        -after 'VERSION=1.1.9' 'QMAKE_CXXFLAGS_WARN_ON-=/WX' 'QMAKE_CFLAGS_WARN_ON-=/WX' `
        2>&1 | Tee-Object -FilePath "$build\qmake.log"
    if ($LASTEXITCODE -ne 0) { throw "qmake 失败：$LASTEXITCODE" }
    if (-not (Select-String "$build\qmake.log" -Pattern 'Including support for video streaming' -Quiet)) {
        throw '未启用 GStreamer 视频支持，拒绝生成没有视频功能的运行包'
    }
    & jom -j4 2>&1 | Tee-Object -FilePath "$build\build.log"
    if ($LASTEXITCODE -ne 0) { throw "编译失败：$LASTEXITCODE" }
    if (-not (Test-Path "$build\staging\NexusGround.exe")) { throw '未生成 NexusGround.exe' }
} finally { Pop-Location }
