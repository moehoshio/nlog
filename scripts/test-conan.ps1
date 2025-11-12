# Test Conan package locally

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing NekoLog Conan Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $rootDir

Write-Host "[1/3] Creating Conan package from source..." -ForegroundColor Yellow
conan create . --build=missing

if ($LASTEXITCODE -ne 0) {
    Write-Error "Conan package creation failed!"
    exit 1
}

Write-Host ""
Write-Host "[2/3] Testing package installation..." -ForegroundColor Yellow

# Create a test project
$testDir = Join-Path $env:TEMP "nekolog-conan-test"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir | Out-Null

Set-Location $testDir

# Create test files
@"
[requires]
nekolog/1.0.0

[generators]
CMakeDeps
CMakeToolchain
"@ | Out-File -FilePath "conanfile.txt" -Encoding utf8

@"
cmake_minimum_required(VERSION 3.14)
project(ConanTest CXX)

find_package(NekoLog REQUIRED CONFIG)

add_executable(test_app main.cpp)
target_link_libraries(test_app PRIVATE Neko::Log)
target_compile_features(test_app PRIVATE cxx_std_20)
"@ | Out-File -FilePath "CMakeLists.txt" -Encoding utf8

@"
#include <neko/log/nlog.hpp>

int main() {
    neko::log::info("Conan package test successful!");
    return 0;
}
"@ | Out-File -FilePath "main.cpp" -Encoding utf8

Write-Host "[3/3] Building test project..." -ForegroundColor Yellow
conan install . --output-folder=build --build=missing

if ($LASTEXITCODE -ne 0) {
    Write-Error "Conan install failed!"
    exit 1
}

cmake -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake
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
Write-Host "  Conan Package Test Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The package is ready to be submitted to conan-center-index" -ForegroundColor Cyan
Write-Host "See PUBLISHING.md for submission instructions" -ForegroundColor Gray
Write-Host ""
