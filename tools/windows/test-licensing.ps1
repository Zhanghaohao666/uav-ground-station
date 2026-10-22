$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
New-Item -ItemType Directory -Force $build | Out-Null
& python -m pip install -r "$source/tools/licensing/requirements.txt"
if ($LASTEXITCODE -ne 0) { throw 'Cannot install administrator/test signing dependency' }
& python -m unittest discover -s "$source/tests/licensing" -p 'test_authority.py' -v
if ($LASTEXITCODE -ne 0) { throw 'License authority tests failed' }
$fixtures = Join-Path $build 'disposable-test-fixtures.json'
& python "$source/tests/licensing/make_fixtures.py" $fixtures
if ($LASTEXITCODE -ne 0) { throw 'Cannot generate disposable signing fixtures' }
foreach ($mode in @('utf8', 'ansi')) {
    $testBuild = Join-Path $build ("offline-licensing-$mode")
    New-Item -ItemType Directory -Force $testBuild | Out-Null
    Push-Location $testBuild
    try {
        $qmakeArgs = @("$source/tests/licensing/licensing.pro", 'CONFIG+=release')
        if ($mode -eq 'ansi') { $qmakeArgs += 'CONFIG+=license_ansi_source_test' }
        & qmake @qmakeArgs
        if ($LASTEXITCODE -ne 0) { throw "Offline licensing qmake failed: $mode" }
        & jom -j2
        if ($LASTEXITCODE -ne 0) { throw "Offline licensing build failed: $mode" }
        $env:NEXUS_LICENSE_FIXTURES = $fixtures
        $env:QT_QPA_PLATFORM = 'offscreen'
        $fileName = if ($mode -eq 'utf8') { 'offline-license-results.xml' } else { 'offline-license-ansi-results.xml' }
        $resultFile = Join-Path $build $fileName
        & "$testBuild/release/licensing_tests.exe" '-o' "$resultFile,xml"
        if ($LASTEXITCODE -ne 0) { throw "Offline licensing Windows verification/UI regression failed: $mode" }
        [xml]$results = Get-Content $resultFile -Raw -Encoding utf8 -ErrorAction Stop
        if ($results.SelectNodes('/TestCase/TestFunction').Count -lt 13 -or
            $results.SelectNodes('/TestCase/TestFunction/Incident[@type="fail"]').Count -gt 0) {
            throw "Offline licensing results are incomplete or failed: $mode"
        }
    } finally {
        Remove-Item Env:NEXUS_LICENSE_FIXTURES -ErrorAction SilentlyContinue
        Remove-Item Env:QT_QPA_PLATFORM -ErrorAction SilentlyContinue
        Pop-Location
    }
}
