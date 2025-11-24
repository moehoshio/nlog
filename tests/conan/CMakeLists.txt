cmake_minimum_required(VERSION 3.20)
project(ConanIntegrationTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the NekoLog package
find_package(NekoLog REQUIRED)

# Create test executable
add_executable(conan_test test.cpp)

# Link NekoLog library
target_link_libraries(conan_test PRIVATE Neko::Log)

# Enable testing
enable_testing()
add_test(NAME conan_test COMMAND conan_test)
