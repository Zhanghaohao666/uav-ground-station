$ErrorActionPreference = 'Stop'
$downloads = Join-Path $env:RUNNER_TEMP 'gcs-downloads'
New-Item -ItemType Directory -Force -Path $downloads | Out-Null

function Get-VerifiedFile([string]$Uri, [string]$Name, [string]$Sha256) {
    $path = Join-Path $downloads $Name
    Invoke-WebRequest -Uri $Uri -OutFile $path -TimeoutSec 300 -MaximumRetryCount 2 -RetryIntervalSec 5
    $actual = (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Sha256) { throw "下载校验失败：$Name" }
    return $path
}

$base = 'https://gstreamer.freedesktop.org/data/pkg/windows/1.18.6/msvc'
$packages = @(
    @('gstreamer-1.0-msvc-x86_64-1.18.6.msi', '77947cc415531bd1a83d713c82b0faeff4d17cab16c4c6c328a4482b75cbcc3d'),
    @('gstreamer-1.0-devel-msvc-x86_64-1.18.6.msi', '033513fc9cc3e8cd14fe58251f654ba419e0c2bf4edba076a6885064c22633ec')
)
foreach ($package in $packages) {
    $name, $sha = $package
    $file = Get-VerifiedFile "$base/$name" $name $sha
    $log = Join-Path $downloads ($name + '.log')
    $process = Start-Process msiexec.exe -ArgumentList @(
        '/i', ('"' + $file + '"'), '/qn', '/norestart',
        'ADDLOCAL=ALL', 'INSTALLDIR=C:\gstreamer',
        '/l*v', ('"' + $log + '"')
    ) -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) { throw "安装 $name 失败：$($process.ExitCode)" }
}
$gst = 'C:\gstreamer\1.0\msvc_x86_64'
foreach ($file in @('bin\gst-inspect-1.0.exe', 'include\gstreamer-1.0\gst\gst.h', 'lib\gstreamer-1.0.lib')) {
    if (-not (Test-Path (Join-Path $gst $file))) { throw "GStreamer 文件缺失：$file" }
}
"GCS_GST_ROOT=$gst" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
"$gst\bin" | Out-File $env:GITHUB_PATH -Append -Encoding utf8

$jomUri = 'https://download.qt.io/official_releases/jom/jom_1_1_4.zip'
$jom = Get-VerifiedFile $jomUri 'jom_1_1_4.zip' 'd533c1ef49214229681e90196ed2094691e8c4a0a0bef0b2c901debcb562682b'
$jomDir = Join-Path $env:RUNNER_TEMP 'gcs-jom'
Expand-Archive -Path $jom -DestinationPath $jomDir -Force
if (-not (Test-Path "$jomDir\jom.exe")) { throw 'JOM 解压失败' }
"$jomDir" | Out-File $env:GITHUB_PATH -Append -Encoding utf8

# Offline client only: no SSH server, service installation, or generated keys.
$sshVersion = '10.4.0.0p1-Preview'
$sshArchive = Get-VerifiedFile "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$sshVersion/OpenSSH-Win64.zip" `
    "OpenSSH-Win64-$sshVersion.zip" 'b67ff8becd203502190ec42ac7787c24c2cd3325ed7700485fe7a1c83d2a7957'
$sshExtract = Join-Path $env:RUNNER_TEMP 'gcs-ssh-extract'
$sshRoot = Join-Path $env:RUNNER_TEMP 'gcs-ssh-client'
Expand-Archive -Path $sshArchive -DestinationPath $sshExtract -Force
New-Item -ItemType Directory -Force $sshRoot | Out-Null
foreach ($name in @('ssh.exe', 'ssh-keygen.exe', 'libcrypto.dll', 'LICENSE.txt', 'NOTICE.txt')) {
    Copy-Item "$sshExtract/OpenSSH-Win64/$name" $sshRoot -Force
}
& "$sshRoot/ssh.exe" -V
if ($LASTEXITCODE -ne 0) { throw 'Portable OpenSSH client did not start' }
"GCS_SSH_ROOT=$sshRoot" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
