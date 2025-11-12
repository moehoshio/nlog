# NekoLog Publishing Helper Scripts

# This directory contains helper scripts for publishing NekoLog to package managers

## Scripts

- `prepare-release.ps1` - PowerShell script to prepare a GitHub release
- `calculate-hashes.ps1` - Calculate SHA256/SHA512 for releases
- `test-conan.ps1` - Test Conan package locally
- `test-vcpkg.ps1` - Test vcpkg port locally

## Usage

### Before Publishing

1. Ensure all tests pass
2. Update version numbers in all files
3. Create a git tag
4. Run preparation scripts

### Creating a Release

```powershell
# PowerShell
.\scripts\prepare-release.ps1 -Version "1.0.0"
```

This will:
- Create a git tag
- Calculate all necessary hashes
- Generate release notes template
- Show next steps

### Testing Packages Locally

```powershell
# Test Conan package
.\scripts\test-conan.ps1

# Test vcpkg port
.\scripts\test-vcpkg.ps1
```
