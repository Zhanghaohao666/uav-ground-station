param([Parameter(Mandatory=$true)][string]$Package)
$ErrorActionPreference = 'Stop'
$out = Join-Path $env:RUNNER_TEMP 'video-repro'
New-Item -ItemType Directory -Force $out | Out-Null
$server = Start-Process python -ArgumentList @('-u', "$env:GITHUB_WORKSPACE/tests/video_transport/rtsp_fixture.py") -PassThru -RedirectStandardOutput "$out/server.log" -RedirectStandardError "$out/server-error.log"
try {
    Start-Sleep 2
    if ($server.HasExited) { throw 'RTSP fixture did not start' }
    foreach ($script in @('video-diagnostics.ps1', 'repro-video.ps1')) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile("$env:GITHUB_WORKSPACE/tools/windows/$script", [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count) { throw "PowerShell parse error in $script : $parseErrors" }
    }
    $env:GST_PLUGIN_PATH_1_0 = "$Package/gstreamer-plugins"
    $env:GST_PLUGIN_SYSTEM_PATH_1_0 = "$Package/gstreamer-plugins"
    $env:GST_PLUGIN_SCANNER_1_0 = "$Package/gst-plugin-scanner.exe"
    $env:GST_REGISTRY_1_0 = "$out/gst-registry.bin"
    foreach ($transport in @('tcp', 'udp')) {
        & python "$env:GITHUB_WORKSPACE/tests/video_transport/decode_bundle.py" $Package --transport $transport *> "$out/native-$transport.log"
        if ($LASTEXITCODE -ne 0) { throw "Packaged native decode failed: $transport" }
    }
    foreach ($renderer in @('default', 'desktop', 'software')) {
        $dir = Join-Path $out $renderer
        New-Item -ItemType Directory -Force $dir | Out-Null
        # Hosted runner only: this application explicitly uses INI, not registry.
        $settingsDir = Join-Path $env:APPDATA 'QGroundControl.org'
        New-Item -ItemType Directory -Force $settingsDir | Out-Null
        @'
[General]
SettingsVersion=9
[Video]
videoSource=RTSP Video Stream
streamEnabled=true
rtspUrl=rtsp://127.0.0.1:18554/test
forceVideoDecoder=1
[VideoDemand]
requestedStreamMask=1
'@ | Set-Content "$settingsDir/NexusGround.ini" -Encoding utf8NoBOM
        $env:QGC_CI_STDERR_LOG = '1'
        $env:QT_FORCE_STDERR_LOGGING = '1'
        $env:QSG_INFO = '1'
        $env:QT_LOGGING_RULES = 'VideoManagerLog.debug=true;VideoReceiverLog.debug=true;GStreamerLog.debug=true'
        $env:GST_DEBUG = '3'
        $env:GST_DEBUG_NO_COLOR = '1'
        $env:GST_DEBUG_FILE = "$dir/gstreamer.log"
        $env:QGC_CI_STARTUP_REPORT = "$dir/startup-report.log"
        if ($renderer -eq 'default') { Remove-Item Env:QT_OPENGL -ErrorAction SilentlyContinue }
        else { $env:QT_OPENGL = $renderer }
        $process = Start-Process "$Package/NexusGround.exe" -WorkingDirectory $Package -PassThru -RedirectStandardOutput "$dir/stdout.log" -RedirectStandardError "$dir/stderr.log"
        try {
            Start-Sleep 40
            $process.Refresh()
            @{renderer=$renderer; exited=$process.HasExited; exit_code=$process.ExitCode} | ConvertTo-Json | Set-Content "$dir/process.json"
        } finally {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
        }
        Get-ChildItem (Join-Path $env:USERPROFILE 'Documents') -Filter QGCConsole.log -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Copy-Item $_.FullName "$dir/console.log" -Force }
        Copy-Item "$settingsDir/NexusGround.ini" "$dir/settings.ini" -Force
        $log = Get-Content "$dir/stderr.log" -Raw
        @{
            stream_started = $log -match 'VideoReceiverLog: Started '
            decoded_frame_seen = $log -match '(?m)^VideoReceiverLog: Decoding started\s*$'
            sink_bound = $log -match 'video sink bound'
            main_event_loop_alive = Test-Path "$dir/startup-report.log"
        } | ConvertTo-Json | Set-Content "$dir/video-result.json"
    }
} finally {
    if (-not $server.HasExited) { Stop-Process -Id $server.Id -Force }
}
