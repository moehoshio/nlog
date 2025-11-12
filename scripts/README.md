# NekoLog Publishing Helper Scripts

This directory contains helper scripts for publishing NekoLog to package managers.

## Scripts

- `prepare-release.ps1` - **Automated release preparation** (creates tag, calculates hashes, updates configs)
- `calculate-hashes.ps1` - Calculate SHA256/SHA512 for releases
- `verify-configs.ps1` - Verify all package configs are consistent
- `test-conan.ps1` - Test Conan package locally
- `test-vcpkg.ps1` - Test vcpkg port locally
- `diagnose-paths.ps1` - Diagnose path issues

## Usage

### Preparing a Release (Automated) ⭐ Recommended

```powershell
# This will:
# 1. Create and push git tag
# 2. Calculate SHA256/SHA512 hashes
# 3. Automatically update all package configs
# 4. Show next steps
.\scripts\prepare-release.ps1 -Version "1.0.0"
```

The script **automatically updates**:
- ✅ `conan-center/conandata.yml` - SHA256 hash
- ✅ `conan-center/config.yml` - Version entry
- ✅ `ports/nekolog/portfile.cmake` - REF and SHA512
- ✅ `xmake.lua` - Version and SHA256

No manual copy-paste needed!

### Verifying Configurations

```powershell
# Verify all configs are consistent
.\scripts\verify-configs.ps1 -Version "1.0.0"
```

### Testing Packages Locally

```powershell
# Test Conan package
.\scripts\test-conan.ps1

# Test vcpkg port
.\scripts\test-vcpkg.ps1
```

## Complete Release Workflow

```powershell
# 1. Prepare release (automated)
.\scripts\prepare-release.ps1 -Version "1.0.0"

# 2. Verify everything is correct
.\scripts\verify-configs.ps1 -Version "1.0.0"

# 3. Review and commit changes
git diff
git add .
git commit -m "chore: update package configs for v1.0.0"
git push

# 4. Test packages (optional)
.\scripts\test-conan.ps1
.\scripts\test-vcpkg.ps1
```
