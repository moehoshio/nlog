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
Write-Host "[5/5] Updating package manager configuration files..." -ForegroundColor Yellow

if ($sha256.Hash -and $sha512.Hash) {
    $rootDir = Split-Path -Parent $PSScriptRoot
    $filesUpdated = @()
    
    # Update conan-center/conandata.yml
    $conanDataPath = Join-Path $rootDir "conan-center\conandata.yml"
    if (Test-Path $conanDataPath) {
        try {
            $content = Get-Content $conanDataPath -Raw
            # Update or add version entry
            if ($content -match "sources:") {
                $newEntry = @"
  "$Version":
    url: "https://github.com/moehoshio/NekoLog/archive/refs/tags/v$Version.tar.gz"
    sha256: "$($sha256.Hash.ToLower())"
"@
                if ($content -match "`"$Version`":") {
                    # Version exists, update it
                    $content = $content -replace "(?s)`"$Version`":[^`"]*`"[0-9a-fA-F]+`"", "`"$Version`":`r`n    url: `"https://github.com/moehoshio/NekoLog/archive/refs/tags/v$Version.tar.gz`"`r`n    sha256: `"$($sha256.Hash.ToLower())`""
                } else {
                    # Add new version
                    $content = $content -replace "(sources:)", "`$1`r`n$newEntry"
                }
                $content | Set-Content $conanDataPath -NoNewline
                $filesUpdated += "conan-center/conandata.yml"
                Write-Host "  ✓ Updated conan-center/conandata.yml" -ForegroundColor Green
            }
        } catch {
            Write-Warning "  ✗ Failed to update conan-center/conandata.yml: $_"
        }
    }
    
    # Update ports/nekolog/portfile.cmake
    $portfilePath = Join-Path $rootDir "ports\nekolog\portfile.cmake"
    if (Test-Path $portfilePath) {
        try {
            $content = Get-Content $portfilePath -Raw
            $content = $content -replace "REF v[\d\.]+", "REF v$Version"
            $content = $content -replace "SHA512 [0-9a-fA-F]+", "SHA512 $($sha512.Hash)"
            $content | Set-Content $portfilePath -NoNewline
            $filesUpdated += "ports/nekolog/portfile.cmake"
            Write-Host "  ✓ Updated ports/nekolog/portfile.cmake" -ForegroundColor Green
        } catch {
            Write-Warning "  ✗ Failed to update ports/nekolog/portfile.cmake: $_"
        }
    }
    
    # Update xmake.lua
    $xmakePath = Join-Path $rootDir "xmake.lua"
    if (Test-Path $xmakePath) {
        try {
            $content = Get-Content $xmakePath -Raw
            # Update or add version in add_versions
            if ($content -match "add_versions\(`"$Version`"") {
                # Version exists, update hash
                $content = $content -replace "add_versions\(`"$Version`",\s*`"[0-9a-fA-F]+`"\)", "add_versions(`"$Version`", `"$($sha256.Hash)`")"
            } else {
                # Add new version (insert after existing add_versions lines)
                $newVersionLine = "    add_versions(`"$Version`", `"$($sha256.Hash)`")"
                if ($content -match "(add_versions\([^\)]+\))") {
                    $content = $content -replace "(add_versions\([^\)]+\))", "`$1`r`n$newVersionLine"
                }
            }
            $content | Set-Content $xmakePath -NoNewline
            $filesUpdated += "xmake.lua"
            Write-Host "  ✓ Updated xmake.lua" -ForegroundColor Green
        } catch {
            Write-Warning "  ✗ Failed to update xmake.lua: $_"
        }
    }
    
    # Update conan-center/config.yml if needed
    $configPath = Join-Path $rootDir "conan-center\config.yml"
    if (Test-Path $configPath) {
        try {
            $content = Get-Content $configPath -Raw
            if ($content -notmatch "`"$Version`":") {
                # Add new version entry
                $newEntry = @"
  "$Version":
    folder: all
"@
                $content = $content -replace "(versions:)", "`$1`r`n$newEntry"
                $content | Set-Content $configPath -NoNewline
                $filesUpdated += "conan-center/config.yml"
                Write-Host "  ✓ Updated conan-center/config.yml" -ForegroundColor Green
            }
        } catch {
            Write-Warning "  ✗ Failed to update conan-center/config.yml: $_"
        }
    }
    
    Write-Host ""
    if ($filesUpdated.Count -gt 0) {
        Write-Host "Updated $($filesUpdated.Count) file(s):" -ForegroundColor Green
        $filesUpdated | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "  Skipping file updates (hashes not available)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Release Preparation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Tag: $tagName" -ForegroundColor White
if ($sha256.Hash) {
    Write-Host "SHA256: $($sha256.Hash)" -ForegroundColor White
    Write-Host "SHA512: $($sha512.Hash)" -ForegroundColor White
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the updated files:" -ForegroundColor Yellow
Write-Host "   git diff" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Commit the changes:" -ForegroundColor Yellow
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m `"chore: update package configs for v$Version`"" -ForegroundColor Gray
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test packages locally:" -ForegroundColor Yellow
Write-Host "3. Test packages locally:" -ForegroundColor Yellow
Write-Host "   .\scripts\test-conan.ps1" -ForegroundColor Gray
Write-Host "   .\scripts\test-vcpkg.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Submit to package managers:" -ForegroundColor Yellow
Write-Host "   See PUBLISHING_GUIDE.md for detailed instructions" -ForegroundColor Gray
Write-Host ""
Write-Host "Package Manager Repositories:" -ForegroundColor Cyan
Write-Host "  - Conan:  https://github.com/conan-io/conan-center-index" -ForegroundColor Gray
Write-Host "  - vcpkg:  https://github.com/microsoft/vcpkg" -ForegroundColor Gray
Write-Host "  - xmake:  https://github.com/xmake-io/xmake-repo" -ForegroundColor Gray
Write-Host ""
