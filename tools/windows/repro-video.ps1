param([Parameter(Mandatory=$true)][string]$Package)
$ErrorActionPreference = 'Stop'
$out = Join-Path $env:RUNNER_TEMP 'video-repro'
New-Item -ItemType Directory -Force $out | Out-Null
$server = Start-Process python -ArgumentList @('-u', "$env:GITHUB_WORKSPACE/tests/video_transport/rtsp_fixture.py") -PassThru -RedirectStandardOutput "$out/server.log" -RedirectStandardError "$out/server-error.log"
try {
    Start-Sleep 2
    if ($server.HasExited) { throw 'RTSP fixture did not start' }
    foreach ($renderer in @('default', 'desktop', 'software')) {
        $dir = Join-Path $out $renderer
        New-Item -ItemType Directory -Force $dir | Out-Null
        # Hosted runner only: a clean profile with an explicitly enabled RTSP stream.
        $key = 'HKCU:\Software\QGroundControl.org\NexusGround'
        Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue
        New-Item "$key\Video" -Force | Out-Null
        New-ItemProperty "$key\Video" videoSource -Value 'RTSP Video Stream' -Force | Out-Null
        New-ItemProperty "$key\Video" streamEnabled -Value 'true' -Force | Out-Null
        New-ItemProperty "$key\Video" rtspUrl -Value 'rtsp://127.0.0.1:18554/test' -Force | Out-Null
        New-ItemProperty "$key\Video" forceVideoDecoder -Value '1' -Force | Out-Null
        $env:QGC_CI_STDERR_LOG = '1'
        $env:QT_LOGGING_TO_CONSOLE = '1'
        $env:QT_LOGGING_RULES = 'VideoManagerLog.debug=true;VideoReceiverLog.debug=true;GStreamerLog.debug=true'
        $env:GST_DEBUG = '3'
        $env:GST_DEBUG_NO_COLOR = '1'
        $env:GST_DEBUG_FILE = "$dir/gstreamer.log"
        $env:QGC_CI_STARTUP_REPORT = "$dir/startup-report.log"
        if ($renderer -eq 'default') { Remove-Item Env:QT_OPENGL -ErrorAction SilentlyContinue }
        else { $env:QT_OPENGL = $renderer }
        $process = Start-Process "$Package/NexusGround.exe" -WorkingDirectory $Package -ArgumentList @('--log-output', '--logging:VideoAllLog') -PassThru -RedirectStandardOutput "$dir/stdout.log" -RedirectStandardError "$dir/stderr.log"
        try {
            Start-Sleep 20
            $process.Refresh()
            @{renderer=$renderer; exited=$process.HasExited; exit_code=$process.ExitCode} | ConvertTo-Json | Set-Content "$dir/process.json"
        } finally {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
        }
        Get-ChildItem (Join-Path $env:USERPROFILE 'Documents') -Filter QGCConsole.log -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Copy-Item $_.FullName "$dir/console.log" -Force }
    }
} finally {
    if (-not $server.HasExited) { Stop-Process -Id $server.Id -Force }
}
