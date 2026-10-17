param([Parameter(Mandatory=$true)][string]$Package,
      [Parameter(Mandatory=$true)][string]$Probe,
      [Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$names = @('GST_PLUGIN_PATH', 'GST_PLUGIN_PATH_1_0', 'GST_PLUGIN_SYSTEM_PATH', 'GST_PLUGIN_SYSTEM_PATH_1_0',
           'GST_PLUGIN_SCANNER', 'GST_PLUGIN_SCANNER_1_0', 'GST_REGISTRY', 'GST_REGISTRY_1_0', 'QGC_GST_REGISTRY')
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$probeInPackage = Join-Path $Package 'environment_probe.exe'
Copy-Item $Probe $probeInPackage
$server = $null
try {
    $server = Start-Process python -ArgumentList @('-u', "$env:GITHUB_WORKSPACE/tests/video_transport/rtsp_fixture.py") `
        -PassThru -RedirectStandardOutput "$OutputDirectory/server.log" -RedirectStandardError "$OutputDirectory/server-error.log"
    Start-Sleep 2
    if ($server.HasExited) { throw 'Local RTSP fixture failed to start' }
    $oldRegistry = Join-Path $OutputDirectory 'other-application-registry.bin'
    'Other application registry: do not modify' | Set-Content $oldRegistry
    $oldHash = (Get-FileHash $oldRegistry).Hash
    foreach ($transport in @('tcp', 'udp')) {
        foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, 'C:/missing-other-gstreamer', 'Process') }
        Remove-Item Env:QGC_GST_REGISTRY -ErrorAction SilentlyContinue
        $env:GST_REGISTRY = $oldRegistry
        $env:GST_REGISTRY_1_0 = $oldRegistry
        # Export the production C++ helper's result, not an equivalent PS policy.
        $raw = & $probeInPackage $Package "$OutputDirectory/cache"
        if ($LASTEXITCODE -ne 0) { throw 'Production environment helper failed' }
        $raw | Set-Content "$OutputDirectory/environment-$transport.json"
        $configured = ($raw -join "`n") | ConvertFrom-Json
        if ($configured.GST_PLUGIN_PATH_1_0.Replace('\', '/') -ne ($Package.Replace('\', '/') + '/gstreamer-plugins')) {
            throw 'Inherited versioned plugin path was not replaced'
        }
        if ($configured.GST_REGISTRY_1_0 -eq $oldRegistry) { throw 'Shared registry was not isolated' }
        foreach ($property in $configured.PSObject.Properties) {
            [Environment]::SetEnvironmentVariable($property.Name, $property.Value, 'Process')
        }
        & python "$env:GITHUB_WORKSPACE/tests/video_transport/decode_bundle.py" $Package --transport $transport `
            *> "$OutputDirectory/decode-$transport.log"
        if ($LASTEXITCODE -ne 0) { throw "Portable native decoding failed: $transport" }
        if (-not (Test-Path $configured.GST_REGISTRY_1_0)) { throw 'Application registry was not created' }
        if ((Get-FileHash $oldRegistry).Hash -ne $oldHash) { throw 'Another application registry was modified' }
    }
} finally {
    if ($server -and -not $server.HasExited) { Stop-Process -Id $server.Id -Force }
    Remove-Item $probeInPackage -ErrorAction SilentlyContinue
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
