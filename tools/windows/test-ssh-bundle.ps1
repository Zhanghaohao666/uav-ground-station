$ErrorActionPreference = 'Stop'
$source = (Resolve-Path $env:GITHUB_WORKSPACE).Path
$results = Join-Path $env:RUNNER_TEMP 'ssh-bundle-results'
New-Item -ItemType Directory -Force $results | Out-Null
$manifest = Get-ChildItem "$env:RUNNER_TEMP/ssh-customer-artifact" -Filter BUILD_INFO.json -Recurse | Select-Object -First 1
if (-not $manifest) { throw 'Customer artifact manifest missing' }
$directory = Join-Path $env:RUNNER_TEMP "中文 O'Brien 视频包"
Copy-Item $manifest.Directory.FullName $directory -Recurse -Force
$info = Get-Content "$directory/BUILD_INFO.json" -Raw -Encoding utf8 | ConvertFrom-Json
$ssh = Join-Path $directory 'ssh/ssh.exe'
$helper = Join-Path $directory 'NexusBoardAskpass.exe'
if ((Get-FileHash $ssh -Algorithm SHA256).Hash.ToLowerInvariant() -ne $info.ssh_client_sha256 -or
    (Get-FileHash $helper -Algorithm SHA256).Hash.ToLowerInvariant() -ne $info.board_askpass_sha256) { throw 'Packaged binaries do not match build manifest' }
& python -m pip install --disable-pip-version-check 'paramiko==3.5.1'
if ($LASTEXITCODE -ne 0) { throw 'Cannot install loopback fixture dependency' }
$fixture = Join-Path $results 'fixture.json'
$process = Start-Process python -ArgumentList @("$source/tests/board_maintenance/ssh_fixture.py", '--output', $fixture) -PassThru `
    -RedirectStandardOutput "$results/fixture-stdout.log" -RedirectStandardError "$results/fixture-stderr.log"
try {
    for ($attempt=0; $attempt -lt 50 -and -not (Test-Path $fixture); $attempt++) { Start-Sleep -Milliseconds 200 }
    if (-not (Test-Path $fixture)) { throw 'SSH fixture did not start' }
    $ports = Get-Content $fixture -Raw | ConvertFrom-Json
    $knownHosts = (Join-Path $directory 'known_hosts').Replace('\','/')
    @"
Host *
  User dev
  StrictHostKeyChecking accept-new
  UserKnownHostsFile "$knownHosts"
  PreferredAuthentications password
  PubkeyAuthentication no
  NumberOfPasswordPrompts 1
  ConnectTimeout 5
Host nexus-main
  HostName 127.0.0.1
  Port $($ports.main_port)
Host nexus-algorithm
  HostName 127.0.0.1
  Port $($ports.algorithm_port)
  ProxyJump nexus-main
"@ | Set-Content "$directory/connection.conf" -Encoding utf8NoBOM
    $env:SSH_ASKPASS_REQUIRE = 'force'
    $env:SSH_ASKPASS_PROMPT = ''
    $env:NEXUS_BOARD_AUTO_LOGIN = '1'
    $env:PATH = $directory + ';' + (Split-Path $ssh) + ';' + $env:PATH
    if ($info.board_askpass_lookup -ne 'basename-in-private-child-path') { throw 'Customer package does not include the Unicode askpass fix' }
    $modes = @(@{ name='basename'; value='NexusBoardAskpass.exe' })
    $checks = @()
    Push-Location -LiteralPath $directory
    try {
        foreach ($mode in $modes) {
            $env:SSH_ASKPASS = $mode.value
            $good = $true
            foreach ($role in @('main', 'algorithm')) {
                $output = & $ssh '-F' 'connection.conf' '-tt' "nexus-$role" 'nexus-test-auth' 2> "$results/$($mode.name)-$role-stderr.log"
                if ($LASTEXITCODE -ne 0 -or ($output -join "`n").Trim() -ne 'NEXUS_SSH_AUTH_OK') { $good=$false; break }
            }
            $checks += [ordered]@{ mode=$mode.name; passed=$good }
        }
    } finally { Pop-Location }
    $checks | ConvertTo-Json | Set-Content "$results/path-variants.json" -Encoding utf8
    if (-not ($checks | Where-Object { $_.passed })) { throw 'No automatic helper path representation worked' }
    $report = [ordered]@{
        source_commit = $info.source_commit
        source_version = $info.source_version
        exact_customer_artifact = $true
        testing_path_representations = $checks
        bundled_ssh_sha256 = $info.ssh_client_sha256
        bundled_askpass_sha256 = $info.board_askpass_sha256
        chinese_space_apostrophe_bundle_path_verified = $true
        actual_direct_password_and_pty_verified = $true
        actual_proxyjump_password_and_pty_verified = $true
        internet_or_real_boards_used_for_ssh = $false
    }
    $report | ConvertTo-Json | Set-Content "$results/packaged-ssh.json" -Encoding utf8
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    Remove-Item Env:SSH_ASKPASS, Env:SSH_ASKPASS_REQUIRE, Env:SSH_ASKPASS_PROMPT, Env:NEXUS_BOARD_AUTO_LOGIN -ErrorAction SilentlyContinue
}
