cmake_minimum_required(VERSION 3.20)
project(VcpkgIntegrationTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the NekoLog package
find_package(NekoLog REQUIRED)

# Create test executable
add_executable(vcpkg_test test.cpp)

# Link NekoLog library
target_link_libraries(vcpkg_test PRIVATE Neko::Log)

# Enable testing
enable_testing()
add_test(NAME vcpkg_test COMMAND vcpkg_test)
