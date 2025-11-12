# Minimal test to verify NekoLog Config with FetchContent fallback

$testDir = Join-Path $env:TEMP "nekolog-minimal-test"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir | Out-Null

Set-Location $testDir

Write-Host "Testing NekoLog Config with FetchContent fallback..." -ForegroundColor Cyan
Write-Host ""

# Create minimal CMakeLists.txt
@"
cmake_minimum_required(VERSION 3.14)
project(MinimalTest CXX)

# This should trigger FetchContent for NekoSchema
find_package(NekoLog REQUIRED CONFIG)

message(STATUS "NekoLog found successfully!")
message(STATUS "NekoSchema target exists: `${TARGET NekoSchema}")

add_executable(test_app main.cpp)
target_link_libraries(test_app PRIVATE Neko::Log)
target_compile_features(test_app PRIVATE cxx_std_20)
"@ | Out-File -FilePath "CMakeLists.txt" -Encoding utf8

# Create minimal main.cpp
@"
#include <neko/log/nlog.hpp>

int main() {
    neko::log::info("Test successful!");
    return 0;
}
"@ | Out-File -FilePath "main.cpp" -Encoding utf8

Write-Host "Configuring with CMake..." -ForegroundColor Yellow
cmake -B build -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" 2>&1 | Tee-Object -Variable output

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Configuration output:" -ForegroundColor Yellow
    $output | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Error "CMake configuration failed!"
    Set-Location $PSScriptRoot
    exit 1
}

Write-Host ""
Write-Host "Building..." -ForegroundColor Yellow
cmake --build build --config Release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    Set-Location $PSScriptRoot
    exit 1
}

Write-Host ""
Write-Host "Running test..." -ForegroundColor Yellow
& ".\build\Release\test_app.exe"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Test execution failed!"
    Set-Location $PSScriptRoot
    exit 1
}

# Cleanup
Set-Location $PSScriptRoot
Remove-Item $testDir -Recurse -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  All Tests Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
