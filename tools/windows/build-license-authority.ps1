$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$output = Join-Path $env:RUNNER_TEMP 'license-authority'
$build = Join-Path $env:RUNNER_TEMP 'license-authority-build'
New-Item -ItemType Directory -Force $output, $build | Out-Null
& python -m pip install -r "$source/tools/licensing/requirements-build.txt"
if ($LASTEXITCODE -ne 0) { throw 'Cannot install administrator tool packaging dependencies' }
& python -m PyInstaller --noconfirm --clean --onefile --windowed --name NexusLicenseAuthority `
    --distpath $output --workpath "$build/work" --specpath $build `
    "$source/tools/licensing/license_authority.py"
if ($LASTEXITCODE -ne 0) { throw 'Administrator tool packaging failed' }
# No signing secret is available on the public runner. This tool cannot issue
# production licenses until the owner separately selects their local private key.
Copy-Item "$source/tools/licensing/license_authority.py" $output
Copy-Item "$source/tools/licensing/requirements.txt" $output
Copy-Item "$source/project-docs/OFFLINE_LICENSING.md" "$output/使用说明.md"
$process = Start-Process "$output/NexusLicenseAuthority.exe" -PassThru
try {
    Start-Sleep 8
    $process.Refresh()
    if ($process.HasExited) { throw 'Administrator GUI startup failed' }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
if (Get-ChildItem $output -Include '*.private.pem', '*.nglic' -Recurse) {
    throw 'Secret/customer license unexpectedly appeared in administrator build output'
}
