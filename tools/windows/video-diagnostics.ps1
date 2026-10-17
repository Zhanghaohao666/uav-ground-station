param([switch]$Compatible)
$ErrorActionPreference = 'Stop'
$package = $PSScriptRoot
$exe = Join-Path $package 'NexusGround.exe'
if (-not (Test-Path $exe)) { throw 'Extract these files beside NexusGround.exe, then run the CMD file.' }
if (Get-Process NexusGround -ErrorAction SilentlyContinue) { throw 'Close all NexusGround windows before starting video diagnostics.' }
$mode = if ($Compatible) { 'compatible' } else { 'normal' }
$logDir = Join-Path $package ('video-diagnostics\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $mode)
New-Item -ItemType Directory -Force $logDir | Out-Null
$plugins = Join-Path $package 'gstreamer-plugins'
$scanner = Join-Path $package 'gst-plugin-scanner.exe'
if (-not (Test-Path $plugins) -or -not (Test-Path $scanner)) { throw 'Incomplete Windows package: GStreamer plugins or scanner are missing.' }
# Use the bundled plugins and a fresh per-run registry, without editing settings
# or the user's machine-wide environment. Versioned names take precedence.
foreach ($name in @('GST_PLUGIN_PATH', 'GST_PLUGIN_PATH_1_0', 'GST_PLUGIN_SYSTEM_PATH', 'GST_PLUGIN_SYSTEM_PATH_1_0')) {
    [Environment]::SetEnvironmentVariable($name, $plugins, 'Process')
}
foreach ($name in @('GST_PLUGIN_SCANNER', 'GST_PLUGIN_SCANNER_1_0')) {
    [Environment]::SetEnvironmentVariable($name, $scanner, 'Process')
}
$env:GST_REGISTRY = Join-Path $logDir 'gst-registry.bin'
$env:GST_REGISTRY_1_0 = $env:GST_REGISTRY
$env:QGC_GST_REGISTRY = $env:GST_REGISTRY
$env:GST_DEBUG = '3'
$env:GST_DEBUG_NO_COLOR = '1'
$env:GST_DEBUG_FILE = Join-Path $logDir 'gstreamer.log'
$env:QT_FORCE_STDERR_LOGGING = '1'
$env:QGC_CI_STDERR_LOG = '1'
$env:QSG_INFO = '1'
if ($Compatible) {
    # The bundled qmlglsink uses WGL on Windows; ANGLE is not supported by it.
    $env:QT_OPENGL = 'desktop'
    $env:GST_GL_PLATFORM = 'wgl'
    $env:GST_PLUGIN_FEATURE_RANK = 'avdec_h264:512,avdec_h265:512'
}
$summary = [ordered]@{
    mode = $mode
    started_at = (Get-Date).ToString('o')
    executable_sha256 = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
    executable = $exe
    qt_opengl = $env:QT_OPENGL
    gst_gl_platform = $env:GST_GL_PLATFORM
    video_plugins = @()
}
foreach ($plugin in @('rtspsrc', 'rtph264depay', 'h264parse', 'avdec_h264', 'glupload', 'glcolorconvert')) {
    & "$package\gst-inspect-1.0.exe" $plugin *> (Join-Path $logDir ("plugin-" + $plugin + '.log'))
    $summary.video_plugins += @{name=$plugin; exit_code=$LASTEXITCODE}
}
if (Test-Path "$package\BUILD_INFO.json") { Copy-Item "$package\BUILD_INFO.json" $logDir }
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $logDir 'summary.json') -Encoding UTF8
Write-Host "Mode: $mode"
Write-Host "Logs: $logDir"
Write-Host 'Open ONE video using the same RTSP URL that works in the old version.'
Write-Host 'After about 30 seconds, close NexusGround normally.'
$process = Start-Process $exe -WorkingDirectory $package -ArgumentList '--logging:VideoAllLog' -PassThru `
    -RedirectStandardOutput (Join-Path $logDir 'application-stdout.log') `
    -RedirectStandardError (Join-Path $logDir 'application-stderr.log')
$process.WaitForExit()
$summary.exit_code = $process.ExitCode
$summary.finished_at = (Get-Date).ToString('o')
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $logDir 'summary.json') -Encoding UTF8
Write-Host "Finished. Logs: $logDir"
