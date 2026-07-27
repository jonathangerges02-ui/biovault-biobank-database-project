param(
    [switch]$PostgreSQL
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $projectRoot

if ($PostgreSQL) {
    $env:BIOBANK_DATABASE_URL = 'postgresql://biobank:biobank_dev@localhost:55432/biobank'
} else {
    Remove-Item Env:BIOBANK_DATABASE_URL -ErrorAction SilentlyContinue
}

python -m src.app
