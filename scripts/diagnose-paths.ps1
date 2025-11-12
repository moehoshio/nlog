# Diagnostic script to verify paths

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Path Diagnostics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Script Information:" -ForegroundColor Yellow
Write-Host "  PSScriptRoot: $PSScriptRoot" -ForegroundColor Gray
Write-Host "  Current Location: $PWD" -ForegroundColor Gray
Write-Host ""

$rootDir = Split-Path -Parent $PSScriptRoot
Write-Host "Calculated Paths:" -ForegroundColor Yellow
Write-Host "  NekoLog Root: $rootDir" -ForegroundColor Gray
Write-Host "  Ports Directory: $(Join-Path $rootDir 'ports\nekolog')" -ForegroundColor Gray
Write-Host ""

Write-Host "Path Verification:" -ForegroundColor Yellow
Write-Host "  Root exists: $(Test-Path $rootDir)" -ForegroundColor $(if (Test-Path $rootDir) { 'Green' } else { 'Red' })
Write-Host "  Ports exists: $(Test-Path (Join-Path $rootDir 'ports'))" -ForegroundColor $(if (Test-Path (Join-Path $rootDir 'ports')) { 'Green' } else { 'Red' })
Write-Host "  Port nekolog exists: $(Test-Path (Join-Path $rootDir 'ports\nekolog'))" -ForegroundColor $(if (Test-Path (Join-Path $rootDir 'ports\nekolog')) { 'Green' } else { 'Red' })
Write-Host ""

Write-Host "Directory Contents:" -ForegroundColor Yellow
if (Test-Path $rootDir) {
    Write-Host "  Root directory contents:" -ForegroundColor Gray
    Get-ChildItem $rootDir -Name | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
}
Write-Host ""

if (Test-Path (Join-Path $rootDir 'ports')) {
    Write-Host "  Ports directory contents:" -ForegroundColor Gray
    Get-ChildItem (Join-Path $rootDir 'ports') -Name | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
}
Write-Host ""

Write-Host "Environment Variables:" -ForegroundColor Yellow
Write-Host "  VCPKG_ROOT: $env:VCPKG_ROOT" -ForegroundColor Gray
Write-Host ""
