$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
$testBuild = Join-Path $build 'board-maintenance'
New-Item -ItemType Directory -Force $testBuild | Out-Null
Push-Location $testBuild
try {
    & qmake "$source/tests/board_maintenance/maintenance.pro" 'CONFIG+=release'
    if ($LASTEXITCODE -ne 0) { throw 'SSH maintenance qmake failed' }
    & jom -j2
    if ($LASTEXITCODE -ne 0) { throw 'SSH maintenance native build failed' }
    $env:QT_QPA_PLATFORM = 'windows'
    $env:QT_QUICK_BACKEND = 'software'
    $env:NEXUS_TEST_SSH = Join-Path $env:GCS_SSH_ROOT 'ssh.exe'
    $env:NEXUS_MAINTENANCE_SCREENSHOT = Join-Path $build 'board-maintenance.png'
    $resultsFile = Join-Path $build 'board-maintenance-results.xml'
    & "$testBuild/release/maintenance_tests.exe" '-o' "$resultsFile,xml"
    if ($LASTEXITCODE -ne 0) { throw 'SSH plans, actual QML panel or real portable SSH config parsing failed' }
    [xml]$results = Get-Content $resultsFile -Raw -Encoding utf8 -ErrorAction Stop
    if ($results.SelectNodes('/TestCase/TestFunction/Incident[@type="pass"]').Count -lt 12 -or
        $results.SelectNodes('/TestCase/TestFunction/Incident[@type="fail"]').Count -gt 0) {
        throw 'Maintenance test results are incomplete or failed'
    }
} finally {
    Remove-Item Env:QT_QPA_PLATFORM, Env:QT_QUICK_BACKEND, Env:NEXUS_TEST_SSH, Env:NEXUS_MAINTENANCE_SCREENSHOT -ErrorAction SilentlyContinue
    Pop-Location
}
