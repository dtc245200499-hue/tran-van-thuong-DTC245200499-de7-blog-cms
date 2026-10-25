$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
& "$PSScriptRoot/init.ps1"
docker compose config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Compose validation failed' }
docker compose up -d --wait --wait-timeout 300
if ($LASTEXITCODE -ne 0) { throw 'Startup failed. Check docker compose ps and logs.' }
docker compose --profile tools run --rm seed
if ($LASTEXITCODE -ne 0) { throw 'WordPress initialization failed' }
Write-Host 'Website http://localhost:8080 | DB tool http://localhost:8081 | Grafana http://localhost:3000'
