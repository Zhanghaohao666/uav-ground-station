$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$build = Join-Path $env:RUNNER_TEMP 'gcs-build'
$testBuild = Join-Path $build 'offline-licensing'
New-Item -ItemType Directory -Force $testBuild | Out-Null
& python -m pip install -r "$source/tools/licensing/requirements.txt"
if ($LASTEXITCODE -ne 0) { throw 'Cannot install administrator/test signing dependency' }
& python -m unittest discover -s "$source/tests/licensing" -p 'test_authority.py' -v
if ($LASTEXITCODE -ne 0) { throw 'License authority tests failed' }
$fixtures = Join-Path $testBuild 'disposable-test-fixtures.json'
& python "$source/tests/licensing/make_fixtures.py" $fixtures
if ($LASTEXITCODE -ne 0) { throw 'Cannot generate disposable signing fixtures' }
Push-Location $testBuild
try {
    & qmake "$source/tests/licensing/licensing.pro" 'CONFIG+=release'
    if ($LASTEXITCODE -ne 0) { throw 'Offline licensing qmake failed' }
    & jom -j2
    if ($LASTEXITCODE -ne 0) { throw 'Offline licensing build failed' }
    $env:NEXUS_LICENSE_FIXTURES = $fixtures
    $env:QT_QPA_PLATFORM = 'offscreen'
    $resultFile = Join-Path $build 'offline-license-results.xml'
    & "$testBuild/release/licensing_tests.exe" '-o' "$resultFile,xml"
    if ($LASTEXITCODE -ne 0) { throw 'Offline licensing native Windows verification/UI regression failed' }
    [xml]$results = Get-Content $resultFile -Raw -ErrorAction Stop
    if ($results.SelectNodes('/TestCase/TestFunction').Count -lt 12 -or
        $results.SelectNodes('/TestCase/TestFunction/Incident[@type="fail"]').Count -gt 0) {
        throw 'Offline licensing results are incomplete or failed'
    }
} finally {
    Remove-Item Env:NEXUS_LICENSE_FIXTURES -ErrorAction SilentlyContinue
    Remove-Item Env:QT_QPA_PLATFORM -ErrorAction SilentlyContinue
    Pop-Location
}
