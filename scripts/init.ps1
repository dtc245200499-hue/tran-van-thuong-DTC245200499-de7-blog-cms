$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force secrets | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($name in @('db_password','db_root_password','exporter_password','wp_admin_password','wp_editor_password','grafana_password')) {
  $path = Join-Path (Get-Location) "secrets/$name.txt"
  if (-not (Test-Path -LiteralPath $path)) {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes); $rng.Dispose()
    $value = -join ($bytes | ForEach-Object { $_.ToString('x2') })
    [IO.File]::WriteAllText($path, $value, $utf8)
  }
}
$password = [IO.File]::ReadAllText((Join-Path (Get-Location) 'secrets/exporter_password.txt')).Trim()
if ($password -notmatch '^[a-f0-9]{48}$') { throw 'Invalid exporter secret; expected 48 hex characters' }
$cnf = @('[client]', 'user=exporter', "password=$password", 'host=mysql', 'port=3306') -join [char]10
[IO.File]::WriteAllText((Join-Path (Get-Location) 'secrets/exporter.cnf'), $cnf + [char]10, $utf8)
Write-Host 'Secrets ready. Values are not printed. Never commit secrets/.'
