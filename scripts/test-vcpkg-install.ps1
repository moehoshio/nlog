# Quick test for vcpkg port installation only

param(
    [string]$VcpkgRoot = $env:VCPKG_ROOT
)

$ErrorActionPreference = "Stop"

if (-not $VcpkgRoot) {
    Write-Error "vcpkg not found. Please set VCPKG_ROOT environment variable"
    exit 1
}

if (-not (Test-Path $VcpkgRoot)) {
    Write-Error "vcpkg directory not found at: $VcpkgRoot"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quick vcpkg Installation Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent $PSScriptRoot
$portDir = Join-Path $rootDir "ports\nekolog"

Write-Host "NekoLog root: $rootDir" -ForegroundColor Gray
Write-Host "vcpkg root: $VcpkgRoot" -ForegroundColor Gray
Write-Host "Port directory: $portDir" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $portDir)) {
    Write-Error "Port directory not found at: $portDir"
    exit 1
}

Set-Location $VcpkgRoot

Write-Host "[1/2] Removing existing nekolog installation..." -ForegroundColor Yellow
& ".\vcpkg.exe" remove nekolog --recurse 2>$null

Write-Host "[2/2] Installing nekolog with overlay port..." -ForegroundColor Yellow
& ".\vcpkg.exe" install nekolog --overlay-ports=$portDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "vcpkg installation failed!"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Test Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NekoLog has been successfully installed via vcpkg." -ForegroundColor Cyan
Write-Host "The package is ready for use in projects." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Full integration test requires NekoSchema to be available." -ForegroundColor Yellow
Write-Host "Once NekoSchema is published, the Config file will use it automatically." -ForegroundColor Yellow
Write-Host ""
