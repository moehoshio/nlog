# Test vcpkg port locally

param(
    [string]$VcpkgRoot = $env:VCPKG_ROOT
)

$ErrorActionPreference = "Stop"

if (-not $VcpkgRoot) {
    Write-Error "vcpkg not found. Please set VCPKG_ROOT environment variable or pass -VcpkgRoot parameter"
    exit 1
}

if (-not (Test-Path $VcpkgRoot)) {
    Write-Error "vcpkg directory not found at: $VcpkgRoot"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing NekoLog vcpkg Port" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$portDir = Join-Path $rootDir "ports\nekolog"

Write-Host "vcpkg root: $VcpkgRoot" -ForegroundColor Gray
Write-Host "Port directory: $portDir" -ForegroundColor Gray
Write-Host ""

Set-Location $VcpkgRoot

Write-Host "[1/3] Removing existing nekolog installation..." -ForegroundColor Yellow
& ".\vcpkg.exe" remove nekolog --recurse 2>$null

Write-Host "[2/3] Installing nekolog with overlay port..." -ForegroundColor Yellow
& ".\vcpkg.exe" install nekolog --overlay-ports=$portDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "vcpkg installation failed!"
    exit 1
}

Write-Host ""
Write-Host "[3/3] Creating test project..." -ForegroundColor Yellow

$testDir = Join-Path $env:TEMP "nekolog-vcpkg-test"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir | Out-Null

Set-Location $testDir

@"
cmake_minimum_required(VERSION 3.14)
project(VcpkgTest CXX)

find_package(NekoLog REQUIRED CONFIG)

add_executable(test_app main.cpp)
target_link_libraries(test_app PRIVATE Neko::Log)
target_compile_features(test_app PRIVATE cxx_std_20)
"@ | Out-File -FilePath "CMakeLists.txt" -Encoding utf8

@"
#include <neko/log/nlog.hpp>

int main() {
    neko::log::info("vcpkg package test successful!");
    return 0;
}
"@ | Out-File -FilePath "main.cpp" -Encoding utf8

Write-Host "Building test project..." -ForegroundColor Yellow
cmake -B build -DCMAKE_TOOLCHAIN_FILE="$VcpkgRoot\scripts\buildsystems\vcpkg.cmake"
cmake --build build --config Release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

Write-Host ""
Write-Host "Running test application..." -ForegroundColor Yellow
& ".\build\Release\test_app.exe"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Test application failed!"
    exit 1
}

# Cleanup
Set-Location $rootDir
Remove-Item $testDir -Recurse -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  vcpkg Port Test Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The port is ready to be submitted to microsoft/vcpkg" -ForegroundColor Cyan
Write-Host "See PUBLISHING.md for submission instructions" -ForegroundColor Gray
Write-Host ""
