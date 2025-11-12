# Verify package manager configurations
# This script checks if all package manager configs have consistent version/hash info

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Package Config Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent $PSScriptRoot
$issues = @()
$warnings = @()

# Function to extract version and hash from file
function Get-FileInfo {
    param([string]$FilePath, [string]$Type)
    
    if (-not (Test-Path $FilePath)) {
        return @{ exists = $false }
    }
    
    $content = Get-Content $FilePath -Raw
    $info = @{ exists = $true; versions = @(); hashes = @() }
    
    switch ($Type) {
        "conandata" {
            if ($content -match 'sources:') {
                # Extract all versions
                $matches = [regex]::Matches($content, '"([\d\.]+)":\s*\n\s*url:.*\n\s*sha256:\s*"([0-9a-fA-F]+)"')
                foreach ($match in $matches) {
                    $info.versions += $match.Groups[1].Value
                    $info.hashes += @{
                        version = $match.Groups[1].Value
                        sha256 = $match.Groups[2].Value
                    }
                }
            }
        }
        "portfile" {
            if ($content -match 'REF v([\d\.]+)') {
                $info.versions += $matches[1]
            }
            if ($content -match 'SHA512 ([0-9a-fA-F]+)') {
                $info.hashes += @{ sha512 = $matches[1] }
            }
        }
        "xmake" {
            $matches = [regex]::Matches($content, 'add_versions\("([\d\.]+)",\s*"([0-9a-fA-F]+)"\)')
            foreach ($match in $matches) {
                $info.versions += $match.Groups[1].Value
                $info.hashes += @{
                    version = $match.Groups[1].Value
                    sha256 = $match.Groups[2].Value
                }
            }
        }
        "conanconfig" {
            $matches = [regex]::Matches($content, '"([\d\.]+)":\s*\n\s*folder:')
            foreach ($match in $matches) {
                $info.versions += $match.Groups[1].Value
            }
        }
    }
    
    return $info
}

# Check conan-center/conandata.yml
Write-Host "Checking conan-center/conandata.yml..." -ForegroundColor Yellow
$conanDataPath = Join-Path $rootDir "conan-center\conandata.yml"
$conanData = Get-FileInfo -FilePath $conanDataPath -Type "conandata"
if ($conanData.exists) {
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Versions found: $($conanData.versions -join ', ')" -ForegroundColor Gray
    if ($Version -and $Version -notin $conanData.versions) {
        $issues += "conan-center/conandata.yml missing version $Version"
    }
} else {
    $warnings += "conan-center/conandata.yml not found"
}
Write-Host ""

# Check conan-center/config.yml
Write-Host "Checking conan-center/config.yml..." -ForegroundColor Yellow
$configPath = Join-Path $rootDir "conan-center\config.yml"
$conanConfig = Get-FileInfo -FilePath $configPath -Type "conanconfig"
if ($conanConfig.exists) {
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Versions found: $($conanConfig.versions -join ', ')" -ForegroundColor Gray
    if ($Version -and $Version -notin $conanConfig.versions) {
        $issues += "conan-center/config.yml missing version $Version"
    }
} else {
    $warnings += "conan-center/config.yml not found"
}
Write-Host ""

# Check ports/nekolog/portfile.cmake
Write-Host "Checking ports/nekolog/portfile.cmake..." -ForegroundColor Yellow
$portfilePath = Join-Path $rootDir "ports\nekolog\portfile.cmake"
$portfile = Get-FileInfo -FilePath $portfilePath -Type "portfile"
if ($portfile.exists) {
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Version (REF): $($portfile.versions -join ', ')" -ForegroundColor Gray
    if ($portfile.hashes.Count -gt 0) {
        Write-Host "  SHA512: $($portfile.hashes[0].sha512.Substring(0, 32))..." -ForegroundColor Gray
    }
    if ($Version -and $Version -notin $portfile.versions) {
        $issues += "ports/nekolog/portfile.cmake version mismatch (expected v$Version)"
    }
} else {
    $warnings += "ports/nekolog/portfile.cmake not found"
}
Write-Host ""

# Check xmake.lua
Write-Host "Checking xmake.lua..." -ForegroundColor Yellow
$xmakePath = Join-Path $rootDir "xmake.lua"
$xmake = Get-FileInfo -FilePath $xmakePath -Type "xmake"
if ($xmake.exists) {
    Write-Host "  ✓ File exists" -ForegroundColor Green
    Write-Host "  Versions found: $($xmake.versions -join ', ')" -ForegroundColor Gray
    if ($Version -and $Version -notin $xmake.versions) {
        $issues += "xmake.lua missing version $Version"
    }
} else {
    $warnings += "xmake.lua not found"
}
Write-Host ""

# Check consistency
Write-Host "Checking version consistency..." -ForegroundColor Yellow
$allVersions = @()
$allVersions += $conanData.versions
$allVersions += $conanConfig.versions
$allVersions += $portfile.versions
$allVersions += $xmake.versions
$uniqueVersions = $allVersions | Select-Object -Unique | Sort-Object

if ($uniqueVersions.Count -gt 0) {
    Write-Host "  All versions across files: $($uniqueVersions -join ', ')" -ForegroundColor Gray
    
    # Check if latest version is consistent
    $latestVersion = $uniqueVersions[-1]
    Write-Host "  Latest version: $latestVersion" -ForegroundColor Cyan
    
    $filesWithLatest = @()
    if ($latestVersion -in $conanData.versions) { $filesWithLatest += "conandata.yml" }
    if ($latestVersion -in $conanConfig.versions) { $filesWithLatest += "config.yml" }
    if ($latestVersion -in $portfile.versions) { $filesWithLatest += "portfile.cmake" }
    if ($latestVersion -in $xmake.versions) { $filesWithLatest += "xmake.lua" }
    
    Write-Host "  Files with latest version: $($filesWithLatest -join ', ')" -ForegroundColor Gray
    
    if ($filesWithLatest.Count -lt 4) {
        $issues += "Not all files have the latest version $latestVersion"
    }
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "Issues Found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Please run prepare-release.ps1 again to fix these issues." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    Write-Host ""
    if ($Version) {
        Write-Host "Version $Version is properly configured in all package managers." -ForegroundColor Cyan
    } else {
        Write-Host "All package manager configurations are consistent." -ForegroundColor Cyan
    }
}
Write-Host ""
