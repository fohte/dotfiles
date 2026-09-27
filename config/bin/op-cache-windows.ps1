param(
  [Parameter(Mandatory = $true)][string]$Reference,
  [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security

$utf8 = New-Object System.Text.UTF8Encoding($false)
$entropy = $utf8.GetBytes("fohte/op-run-cached/v1`n$Reference")
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$key = [BitConverter]::ToString($sha256.ComputeHash($entropy)).Replace('-', '').ToLowerInvariant()
$cacheDir = Join-Path $env:LOCALAPPDATA 'fohte\op-run-cached'
$cachePath = Join-Path $cacheDir "$key.bin"

if (-not $Refresh -and (Test-Path -LiteralPath $cachePath)) {
  try {
    $encrypted = [IO.File]::ReadAllBytes($cachePath)
    $plain = [Security.Cryptography.ProtectedData]::Unprotect(
      $encrypted, $entropy, [Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $value = $utf8.GetString($plain)
    if ($value.Length -gt 0) {
      [Console]::Out.Write($value)
      exit 0
    }
  } catch {
    # A broken cache entry should be replaced from 1Password.
  }
}

$op = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\op.exe'
if (-not (Test-Path -LiteralPath $op)) {
  throw "Windows 1Password CLI not found at $op"
}

$lines = & $op read $Reference
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$value = [string]::Join("`n", [string[]]@($lines)).TrimEnd([char]13, [char]10)
if ($value.Length -eq 0) { throw '1Password returned an empty secret' }

$tempPath = $null
try {
  [IO.Directory]::CreateDirectory($cacheDir) | Out-Null
  $encrypted = [Security.Cryptography.ProtectedData]::Protect(
    $utf8.GetBytes($value), $entropy, [Security.Cryptography.DataProtectionScope]::CurrentUser
  )
  $tempPath = Join-Path $cacheDir "$key.$([Guid]::NewGuid().ToString('N')).tmp"
  [IO.File]::WriteAllBytes($tempPath, $encrypted)
  Move-Item -LiteralPath $tempPath -Destination $cachePath -Force
} catch {
  Write-Warning 'Could not update the encrypted 1Password cache'
} finally {
  if ($tempPath -and (Test-Path -LiteralPath $tempPath)) {
    Remove-Item -LiteralPath $tempPath -Force
  }
}

[Console]::Out.Write($value)
