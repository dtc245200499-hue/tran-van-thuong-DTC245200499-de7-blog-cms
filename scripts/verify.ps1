$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
function Check($condition, $message) { if (-not $condition) { throw $message }; Write-Host "PASS $message" }
$response = Invoke-WebRequest http://localhost:8080 -UseBasicParsing
Check ($response.StatusCode -eq 200) 'Website responds 200'
Check ($response.Content -match 'campus') 'Custom theme active'
Check ($response.Headers['X-Content-Type-Options'] -eq 'nosniff') 'Nginx security header'
Invoke-WebRequest http://localhost:8080/hanh-trinh-docker-compose/ -UseBasicParsing | Out-Null
try { Invoke-WebRequest http://localhost:8080/xmlrpc.php -UseBasicParsing | Out-Null; throw 'Expected 403' } catch { Check ($_.Exception.Response.StatusCode.value__ -eq 403) 'XML-RPC denied' }
Invoke-WebRequest http://localhost:8081 -UseBasicParsing | Out-Null
Check ((Invoke-RestMethod http://localhost:3000/api/health).database -eq 'ok') 'Grafana database healthy'
$targets = (Invoke-RestMethod http://localhost:9090/api/v1/targets).data.activeTargets
Check ($targets.Count -eq 6) 'Six Prometheus scrape targets'
Check (@($targets | Where-Object health -ne 'up').Count -eq 0) 'All Prometheus targets UP'
foreach ($metric in @('mysql_up','nginx_up')) {
  $result = (Invoke-RestMethod ("http://localhost:9090/api/v1/query?query=" + $metric)).data.result
  Check ($result.Count -gt 0 -and $result[0].value[1] -eq '1') "$metric = 1"
}
$cpu=(Invoke-RestMethod 'http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total').data.result
Check ($cpu.Count -gt 0) 'Container metrics exist'
$query=[uri]::EscapeDataString('{job="nginx",stream="access"} | json | status = 403')
$logs = $null
for ($i=0; $i -lt 12; $i++) {
  $output = docker compose exec -T grafana sh -c "wget -qO- 'http://loki:3100/loki/api/v1/query_range?query=$query&limit=5'"
  if ($LASTEXITCODE -eq 0) { $logs = $output | ConvertFrom-Json }
  if ($logs -and $logs.data.result.Count -gt 0) { break }
  Start-Sleep -Seconds 5
}
Check ($logs -and $logs.status -eq 'success' -and $logs.data.result.Count -gt 0) 'Loki returns generated 403 request'
Write-Host 'Also perform CRUD, permission checks and screenshots using docs/DEMO.md.'
