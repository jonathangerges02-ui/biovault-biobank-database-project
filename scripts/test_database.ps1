param(
    [switch]$KeepDatabase
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $projectRoot

docker compose up -d database

$healthy = $false
for ($attempt = 1; $attempt -le 30; $attempt++) {
    $status = docker inspect --format='{{.State.Health.Status}}' biovault-postgres 2>$null
    if ($status -eq 'healthy') {
        $healthy = $true
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    throw 'PostgreSQL container did not become healthy within 60 seconds.'
}

docker compose exec -T database psql -U biobank -d biobank -f /project/sql/setup.sql
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/test_constraints.sql
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/queries.sql

Write-Host 'Database setup, acceptance tests, and demonstration queries all passed.'

if (-not $KeepDatabase) {
    docker compose down
}
