$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force backups | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
docker compose exec -T mysql sh -c 'MYSQL_PWD="$(cat /run/secrets/db_password)" mysqldump -u blog --single-transaction --no-tablespaces blog > /tmp/blog.sql'
if ($LASTEXITCODE -ne 0) { throw 'DB dump failed' }
docker compose cp mysql:/tmp/blog.sql "backups/blog-$stamp.sql"
if ($LASTEXITCODE -ne 0) { throw 'DB copy failed' }
docker compose exec -T mysql rm /tmp/blog.sql
docker compose exec -T wordpress sh -c 'mkdir -p wp-content/uploads; tar -czf /tmp/wp-content.tgz -C /var/www/html wp-content/uploads'
if ($LASTEXITCODE -ne 0) { throw 'Uploads archive failed' }
docker compose cp wordpress:/tmp/wp-content.tgz "backups/uploads-$stamp.tgz"
if ($LASTEXITCODE -ne 0) { throw 'Uploads copy failed' }
docker compose exec -T wordpress rm /tmp/wp-content.tgz
Write-Host "Backup ready in backups/ ($stamp). Store securely with configuration and secrets."
