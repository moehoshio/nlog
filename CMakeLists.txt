cmake_minimum_required(VERSION 3.14)
project(NekoLog VERSION 1.0 LANGUAGES CXX)

option(NEKO_AUTO_FETCH_DEPS "Automatically fetch dependencies" ON)
option(NEKO_BUILD_TESTS "Build tests" ON)

find_package(GTest QUIET)

# Print configuration summary
message(STATUS "NekoFunction configuration summary:")
message(STATUS "  - CMake version: ${CMAKE_VERSION}")
message(STATUS "")
message(STATUS "  - Neko Auto fetch deps: ${NEKO_AUTO_FETCH_DEPS}")
message(STATUS "  - Neko Build tests: ${NEKO_BUILD_TESTS}")
message(STATUS "")
message(STATUS "Dependency summary:")
message(STATUS "  - GoogleTest support: ${GTest_FOUND}")


if(NEKO_AUTO_FETCH_DEPS)
    include(FetchContent)

    FetchContent_Declare(
        NekoSchema
        GIT_REPOSITORY https://github.com/moehoshio/NekoSchema.git
        GIT_TAG        main
    )
    FetchContent_MakeAvailable(NekoSchema)

    if(NOT GTest_FOUND AND NEKO_BUILD_TESTS)
        message(STATUS "GTest not found. Fetching GoogleTest...")

        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG        release-1.12.1
        )
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
    endif()

endif(NEKO_AUTO_FETCH_DEPS)

# Main library target
add_library(NekoLog INTERFACE)
add_library(Neko::Log ALIAS NekoLog)

target_include_directories(NekoLog INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Dependencies
target_link_libraries(NekoLog INTERFACE NekoSchema)
target_compile_features(NekoLog INTERFACE cxx_std_20)

# Tests
if(NEKO_BUILD_TESTS)
    enable_testing()
    message(STATUS "NekoLog tests enabled")

    if (NOT NEKO_AUTO_FETCH_DEPS AND NOT GTest_FOUND)
        message(FATAL_ERROR "GTest is required for building tests. Please enable NEKO_AUTO_FETCH_DEPS or install GTest manually.")
    endif()

    add_executable(nlog_test tests/nlog_test.cpp)
    target_include_directories(nlog_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_link_libraries(nlog_test PRIVATE NekoLog gtest_main)
    target_compile_features(nlog_test PRIVATE cxx_std_20)

    include(GoogleTest)
    gtest_discover_tests(nlog_test)
else()
    message(STATUS "NekoLog tests disabled (NEKO_BUILD_TESTS=OFF)")
endif()