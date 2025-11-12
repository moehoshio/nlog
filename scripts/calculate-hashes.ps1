# Calculate hashes for NekoLog release

param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$tagName = "v$Version"
$repoUrl = "https://github.com/moehoshio/NekoLog"
$archiveUrl = "$repoUrl/archive/refs/tags/$tagName.tar.gz"

Write-Host "Calculating hashes for NekoLog $Version..." -ForegroundColor Cyan
Write-Host "Downloading from: $archiveUrl" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing
    $stream = [System.IO.MemoryStream]::new($response.Content)
    
    # Calculate SHA256
    Write-Host "Calculating SHA256..." -ForegroundColor Yellow
    $sha256 = Get-FileHash -InputStream $stream -Algorithm SHA256
    $stream.Position = 0
    
    # Calculate SHA512
    Write-Host "Calculating SHA512..." -ForegroundColor Yellow
    $sha512 = Get-FileHash -InputStream $stream -Algorithm SHA512
    
    $stream.Close()
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Hashes for NekoLog $Version" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "For Conan (conandata.yml):" -ForegroundColor Cyan
    Write-Host "sha256: `"$($sha256.Hash.ToLower())`"" -ForegroundColor White
    Write-Host ""
    Write-Host "For vcpkg (portfile.cmake):" -ForegroundColor Cyan
    Write-Host "SHA512 $($sha512.Hash.ToLower())" -ForegroundColor White
    Write-Host ""
    Write-Host "For xmake (xmake.lua):" -ForegroundColor Cyan
    Write-Host "add_versions(`"$Version`", `"$($sha256.Hash.ToLower())`")" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Error "Failed to download or calculate hashes: $_"
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. The GitHub release $tagName exists" -ForegroundColor Gray
    Write-Host "2. The archive is downloadable at: $archiveUrl" -ForegroundColor Gray
    exit 1
}
