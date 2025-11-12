# Package Manager Installation Guide

This document provides detailed instructions for installing NekoLog using various package managers.

## Table of Contents

- [CMake](#cmake)
- [Conan](#conan)
- [vcpkg](#vcpkg)
- [xmake](#xmake)

## CMake

### Using FetchContent (Recommended)

Add to your `CMakeLists.txt`:

```cmake
include(FetchContent)

FetchContent_Declare(
    NekoLog
    GIT_REPOSITORY https://github.com/moehoshio/NekoLog.git
    GIT_TAG        v1.0.0  # Or main for latest
)
FetchContent_MakeAvailable(NekoLog)

target_link_libraries(your_target PRIVATE Neko::Log)
```

### Using find_package

If NekoLog is installed on your system:

```cmake
find_package(NekoLog 1.0 REQUIRED CONFIG)
target_link_libraries(your_target PRIVATE Neko::Log)
```

### Manual Installation

```bash
# Clone and build
git clone https://github.com/moehoshio/NekoLog.git
cd NekoLog
cmake -B build -DNEKO_LOG_BUILD_TESTS=OFF
cmake --install build --prefix /usr/local

# Then use find_package in your project
```

## Conan

### Method 1: Using conanfile.txt

Create `conanfile.txt`:

```ini
[requires]
nekolog/1.0.0

[generators]
CMakeDeps
CMakeToolchain
```

Install and build:

```bash
conan install . --output-folder=build --build=missing
cmake -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake
cmake --build build
```

### Method 2: Using conanfile.py

```python
from conan import ConanFile

class YourProject(ConanFile):
    requires = "nekolog/1.0.0"
    generators = "CMakeDeps", "CMakeToolchain"
```

Then:

```bash
conan install . --output-folder=build --build=missing
cmake -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake
cmake --build build
```

### Creating Your Own Package

To create a Conan package from source:

```bash
conan create . --build=missing
```

## vcpkg

### Installation

1. Add as an overlay port:

```bash
git clone https://github.com/moehoshio/NekoLog.git
vcpkg install nekolog --overlay-ports=NekoLog/ports/nekolog
```

2. Or add to your vcpkg registry (for vcpkg maintainers):

Copy the `ports/nekolog` directory to your vcpkg ports directory.

### Using in CMake

With vcpkg toolchain:

```bash
cmake -B build -DCMAKE_TOOLCHAIN_FILE=[vcpkg-root]/scripts/buildsystems/vcpkg.cmake
```

In `CMakeLists.txt`:

```cmake
find_package(NekoLog CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE Neko::Log)
```

### Using vcpkg.json (Manifest Mode)

Create `vcpkg.json` in your project:

```json
{
  "dependencies": [
    "nekolog"
  ]
}
```

## xmake

### Installation

Add to your `xmake.lua`:

```lua
add_requires("nekolog")

target("your_target")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("nekolog")
```

### Configuration Options

```lua
add_requires("nekolog", {configs = {modules = true}})  -- Enable C++20 modules
add_requires("nekolog", {configs = {tests = true}})    -- Build with tests
```

### Build

```bash
xmake
```

## Common Issues

### Dependency Not Found

NekoLog depends on NekoSchema. Make sure it's available:

- **Conan**: Should auto-fetch dependencies
- **vcpkg**: Install `nekoschema` first or add to dependencies
- **xmake**: Add `add_requires("nekoschema")`
- **CMake**: Set `NEKO_LOG_AUTO_FETCH_DEPS=ON` (default)

### C++20 Modules

To enable C++20 modules support:

- **CMake**: `-DNEKO_LOG_USE_MODULES=ON`
- **Conan**: Set config `use_modules=True`
- **xmake**: Set config `modules = true`

Note: Modules support requires a compatible compiler (MSVC 19.28+, GCC 11+, Clang 16+).

## Verifying Installation

Create a test file:

```cpp
#include <neko/log/nlog.hpp>

int main() {
    neko::log::info("NekoLog is working!");
    return 0;
}
```

Compile and run to verify the installation.
