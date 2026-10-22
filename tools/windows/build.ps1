$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
New-Item -ItemType Directory -Force -Path $build | Out-Null
# Compile the same environment setup used by the production EXE, and exercise
# conflicting inherited paths plus fresh/warm application caches.
foreach ($test in @('environment', 'probe')) {
    $testBuild = Join-Path $build ("video-$test")
    New-Item -ItemType Directory -Force $testBuild | Out-Null
    Push-Location $testBuild
    try {
        & qmake "$source\tests\video_environment\$test.pro" 'CONFIG+=release'
        if ($LASTEXITCODE -ne 0) { throw "Video environment qmake failed: $test" }
        & jom -j2
        if ($LASTEXITCODE -ne 0) { throw "Video environment build failed: $test" }
        if ($test -eq 'environment') {
            $resultsFile = Join-Path $build 'video-environment-results.xml'
            & "$testBuild\release\environment_tests.exe" '-o' "$resultsFile,xml"
            if ($LASTEXITCODE -ne 0) { throw 'Video environment regression failed' }
            if (-not (Test-Path $resultsFile -PathType Leaf)) { throw 'Video environment test did not produce results' }
            [xml]$results = Get-Content $resultsFile -Raw -ErrorAction Stop
            if ($results.SelectNodes('/TestCase/TestFunction').Count -lt 6 -or
                $results.SelectNodes('/TestCase/TestFunction/Incident[@type="fail"]').Count -gt 0) {
                throw 'Video environment test results are incomplete or contain failures'
            }
        }
    } finally { Pop-Location }
}

$receiverBuild = Join-Path $build 'video-receiver'
New-Item -ItemType Directory -Force $receiverBuild | Out-Null
Push-Location $receiverBuild
$fixture = $null
try {
    & qmake "$source\tests\video_receiver_native\receiver.pro" 'CONFIG+=release'
    if ($LASTEXITCODE -ne 0) { throw 'Native receiver qmake failed' }
    & jom -j2
    if ($LASTEXITCODE -ne 0) { throw 'Native receiver build failed' }
    $fixture = Start-Process python -ArgumentList @('-u', "$source/tests/video_transport/rtsp_fixture.py") -PassThru `
        -RedirectStandardOutput "$build/receiver-fixture.log" -RedirectStandardError "$build/receiver-fixture-error.log"
    Start-Sleep 2
    if ($fixture.HasExited) { throw 'Receiver RTSP fixture failed' }
    $env:UAV_TEST_RTSP_URL = 'rtsp://127.0.0.1:18554/test'
    $receiverResults = Join-Path $build 'video-receiver-results.xml'
    & "$receiverBuild\release\receiver_tests.exe" '-o' "$receiverResults,xml"
    if ($LASTEXITCODE -ne 0) { throw 'Actual receiver or decoded-queue regression failed' }
    if (-not (Test-Path $receiverResults -PathType Leaf)) { throw 'Receiver test results missing' }
    [xml]$nativeResults = Get-Content $receiverResults -Raw -ErrorAction Stop
    if ($nativeResults.SelectNodes('/TestCase/TestFunction').Count -lt 5 -or
        $nativeResults.SelectNodes('/TestCase/TestFunction/Incident[@type="fail"]').Count -gt 0) {
        throw 'Actual receiver test results incomplete or failed'
    }
} finally {
    Remove-Item Env:UAV_TEST_RTSP_URL -ErrorAction SilentlyContinue
    if ($fixture -and -not $fixture.HasExited) { Stop-Process -Id $fixture.Id -Force }
    Pop-Location
}

Push-Location $build
try {
    # Keep the full source tag in APP_VERSION_STR. Windows file VERSION must
    # contain only numbers, unlike our descriptive Git tags.
    & qmake -r "$source\abdgcs.pro" 'CONFIG+=release' 'CONFIG+=StableBuild' `
        -after 'VERSION=1.1.14' 'QMAKE_CXXFLAGS_WARN_ON-=/WX' 'QMAKE_CFLAGS_WARN_ON-=/WX' `
        2>&1 | Tee-Object -FilePath "$build\qmake.log"
    if ($LASTEXITCODE -ne 0) { throw "qmake 失败：$LASTEXITCODE" }
    if (-not (Select-String "$build\qmake.log" -Pattern 'Including support for video streaming' -Quiet)) {
        throw '未启用 GStreamer 视频支持，拒绝生成没有视频功能的运行包'
    }
    & jom -j4 2>&1 | Tee-Object -FilePath "$build\build.log"
    if ($LASTEXITCODE -ne 0) { throw "编译失败：$LASTEXITCODE" }
    if (-not (Test-Path "$build\staging\NexusGround.exe")) { throw '未生成 NexusGround.exe' }
} finally { Pop-Location }
