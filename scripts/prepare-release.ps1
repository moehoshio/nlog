# NekoLog Release Preparation Script
# This script helps prepare a new release

param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NekoLog Release Preparation" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
}

$tagName = "v$Version"
$repoUrl = "https://github.com/moehoshio/NekoLog"
$archiveUrl = "$repoUrl/archive/refs/tags/$tagName.tar.gz"

Write-Host "[1/5] Checking git status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Warning "You have uncommitted changes. Please commit or stash them first."
    git status
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') {
        exit 1
    }
}

Write-Host "[2/5] Creating git tag: $tagName..." -ForegroundColor Yellow
Write-Host "Commands to run:" -ForegroundColor Gray
Write-Host "  git tag -a $tagName -m 'Release $Version'" -ForegroundColor Gray
Write-Host "  git push origin $tagName" -ForegroundColor Gray
Write-Host ""
$createTag = Read-Host "Create and push tag now? (y/N)"
if ($createTag -eq 'y') {
    git tag -a $tagName -m "Release $Version"
    git push origin $tagName
    Write-Host "Tag created and pushed!" -ForegroundColor Green
} else {
    Write-Host "Skipping tag creation. Remember to create it manually!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/5] Waiting for GitHub release to be created..." -ForegroundColor Yellow
Write-Host "Please create a GitHub release at:" -ForegroundColor Cyan
Write-Host "  $repoUrl/releases/new?tag=$tagName" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter after creating the GitHub release"

Write-Host ""
Write-Host "[4/5] Calculating hashes for package managers..." -ForegroundColor Yellow
Write-Host "Downloading archive from: $archiveUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing
    $stream = [System.IO.MemoryStream]::new($response.Content)
    
    # Calculate SHA256
    $sha256 = Get-FileHash -InputStream $stream -Algorithm SHA256
    $stream.Position = 0
    
    # Calculate SHA512
    $sha512 = Get-FileHash -InputStream $stream -Algorithm SHA512
    
    $stream.Close()
    
    Write-Host ""
    Write-Host "Hashes calculated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "SHA256: " -NoNewline -ForegroundColor Cyan
    Write-Host $sha256.Hash
    Write-Host "SHA512: " -NoNewline -ForegroundColor Cyan
    Write-Host $sha512.Hash
    Write-Host ""
    
} catch {
    Write-Warning "Could not download archive. Make sure the GitHub release exists."
    Write-Host "You can calculate hashes manually later using:" -ForegroundColor Gray
    Write-Host "  .\scripts\calculate-hashes.ps1 -Version $Version" -ForegroundColor Gray
    $sha256Hash = "CALCULATE_MANUALLY"
    $sha512Hash = "CALCULATE_MANUALLY"
}

Write-Host ""
Write-Host "[5/5] Generating next steps..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Release Preparation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Update conan-center/conandata.yml:" -ForegroundColor Yellow
Write-Host "   SHA256: $($sha256.Hash)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Update ports/nekolog/portfile.cmake:" -ForegroundColor Yellow
Write-Host "   SHA512: $($sha512.Hash)" -ForegroundColor Gray
Write-Host "   REF: $tagName" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Update xmake.lua:" -ForegroundColor Yellow
Write-Host "   add_versions(`"$Version`", `"$($sha256.Hash)`")" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test packages locally:" -ForegroundColor Yellow
Write-Host "   .\scripts\test-conan.ps1" -ForegroundColor Gray
Write-Host "   .\scripts\test-vcpkg.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Submit to package managers:" -ForegroundColor Yellow
Write-Host "   See PUBLISHING.md for detailed instructions" -ForegroundColor Gray
Write-Host ""
Write-Host "Package Manager Repositories:" -ForegroundColor Cyan
Write-Host "  - Conan:  https://github.com/conan-io/conan-center-index" -ForegroundColor Gray
Write-Host "  - vcpkg:  https://github.com/microsoft/vcpkg" -ForegroundColor Gray
Write-Host "  - xmake:  https://github.com/xmake-io/xmake-repo" -ForegroundColor Gray
Write-Host ""
