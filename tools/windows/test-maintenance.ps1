$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
$helperBuild = Join-Path $build 'board-askpass'
$testBuild = Join-Path $build 'board-maintenance'
$fixture = Join-Path $build 'ssh-fixture.json'
New-Item -ItemType Directory -Force $helperBuild, $testBuild | Out-Null
Push-Location $helperBuild
try {
    & qmake "$source/tools/board-askpass/askpass.pro" 'CONFIG+=release'
    if ($LASTEXITCODE -ne 0) { throw 'Automatic SSH helper qmake failed' }
    & jom -j2
    if ($LASTEXITCODE -ne 0) { throw 'Automatic SSH helper build failed' }
} finally { Pop-Location }
$helper = Join-Path $helperBuild 'release/NexusBoardAskpass.exe'
"GCS_ASKPASS_BIN=$helper" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
& python -m pip install --disable-pip-version-check 'paramiko==3.5.1'
if ($LASTEXITCODE -ne 0) { throw 'Cannot install isolated SSH fixture dependency' }
$fixtureProcess = Start-Process python -ArgumentList @("$source/tests/board_maintenance/ssh_fixture.py", '--output', $fixture) -PassThru `
    -RedirectStandardOutput "$build/ssh-fixture-stdout.log" -RedirectStandardError "$build/ssh-fixture-stderr.log"
try {
    for ($attempt = 0; $attempt -lt 50 -and -not (Test-Path $fixture); $attempt++) { Start-Sleep -Milliseconds 200 }
    if (-not (Test-Path $fixture)) { throw 'Loopback SSH fixture did not start' }
    $env:QT_QPA_PLATFORM = 'windows'; $env:QT_QUICK_BACKEND = 'software'
    $env:NEXUS_TEST_SSH = Join-Path $env:GCS_SSH_ROOT 'ssh.exe'
    $env:NEXUS_TEST_ASKPASS = $helper; $env:NEXUS_SSH_FIXTURE = $fixture
    $env:NEXUS_MAINTENANCE_SCREENSHOT = Join-Path $build 'board-maintenance.png'
    Push-Location $testBuild
    try {
        & qmake "$source/tests/board_maintenance/maintenance.pro" 'CONFIG+=release'
        if ($LASTEXITCODE -ne 0) { throw 'SSH maintenance qmake failed' }
        & jom -j2
        if ($LASTEXITCODE -ne 0) { throw 'SSH maintenance native build failed' }
        $resultsFile = Join-Path $build 'board-maintenance-results.xml'
        & "$testBuild/release/maintenance_tests.exe" '-o' "$resultsFile,xml"
        if ($LASTEXITCODE -ne 0) { throw 'Actual SSH auto-login/jump, QML or config parsing failed' }
        [xml]$results = Get-Content $resultsFile -Raw -Encoding utf8
        if ($results.SelectNodes('/TestCase/TestFunction/Incident[@type="pass"]').Count -lt 13 -or
            $results.SelectNodes('/TestCase/TestFunction/Incident[@type="fail" or @type="skip"]').Count -gt 0) { throw 'Maintenance checks incomplete' }
    } finally { Pop-Location }
    foreach ($kind in @('recording', 'ui')) {
        $recBuild = Join-Path $build "board-recording-$kind"
        New-Item -ItemType Directory -Force $recBuild | Out-Null
        Push-Location $recBuild
        try {
            & qmake "$source/tests/board_recording/$kind.pro" 'CONFIG+=release'
            if ($LASTEXITCODE -ne 0) { throw 'Recorder qmake failed' }
            & jom -j2
            if ($LASTEXITCODE -ne 0) { throw 'Recorder native build failed' }
            Copy-Item $helper "$recBuild/release/" -Force
            Copy-Item $env:GCS_SSH_ROOT "$recBuild/release/ssh" -Recurse -Force
            $testExe = if ($kind -eq 'recording') { 'recording_tests.exe' } else { 'recording_ui_tests.exe' }
            $env:UAV_RECORD_UI_SCREENSHOT = Join-Path $build 'board-recording.png'
            & "$recBuild/release/$testExe" '-o' "$build/board-recording-$kind-results.xml,xml"
            if ($LASTEXITCODE -ne 0) { throw "Recorder $kind tests failed" }
        } finally { Pop-Location }
    }
} finally {
    if (-not $fixtureProcess.HasExited) { Stop-Process -Id $fixtureProcess.Id -Force }
    Remove-Item Env:QT_QPA_PLATFORM, Env:QT_QUICK_BACKEND, Env:NEXUS_TEST_SSH, Env:NEXUS_TEST_ASKPASS, Env:NEXUS_SSH_FIXTURE, Env:NEXUS_MAINTENANCE_SCREENSHOT, Env:UAV_RECORD_UI_SCREENSHOT -ErrorAction SilentlyContinue
}
