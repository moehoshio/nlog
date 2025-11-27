cmake_minimum_required(VERSION 3.14)
project(NekoLog VERSION 1.0.7 LANGUAGES CXX)

# ================
# === Config ====
# ================

# NekoLog project specific options
option(NEKO_LOG_BUILD_TESTS "Neko Log Build tests" ON)
option(NEKO_LOG_AUTO_FETCH_DEPS "Neko Log Automatically fetch dependencies" ON)
option(NEKO_LOG_ENABLE_MODULE "Neko Log Enable C++20 module" OFF)

find_package(NekoSchema QUIET)
find_package(GTest QUIET)

# Print configuration summary
message(STATUS "Start configuration Neko Log...")
message(STATUS "")
message(STATUS "NekoLog configuration summary:")
message(STATUS "  - CMake version: ${CMAKE_VERSION}")
message(STATUS "")
message(STATUS "  - Neko Log Auto fetch deps: ${NEKO_LOG_AUTO_FETCH_DEPS}")
message(STATUS "  - Neko Log Build tests: ${NEKO_LOG_BUILD_TESTS}")
message(STATUS "  - Neko Log Enable module: ${NEKO_LOG_ENABLE_MODULE}")
message(STATUS "")
message(STATUS "Dependency summary:")
message(STATUS "  - NekoSchema : ${NekoSchema_FOUND} version : ${NekoSchema_VERSION}")
message(STATUS "  - GTest : ${GTest_FOUND} version : ${GTest_VERSION}")
message(STATUS "")

if(NEKO_LOG_AUTO_FETCH_DEPS)
    include(FetchContent)

    if (NOT NekoSchema_FOUND)
        message(STATUS "NekoSchema Not Found ; Neko Log is Fetching NekoSchema...")
        FetchContent_Declare(
            NekoSchema
            GIT_REPOSITORY https://github.com/moehoshio/NekoSchema.git
            GIT_TAG        main
        )
        set(NEKO_SCHEMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
        if (NEKO_LOG_ENABLE_MODULE)
            set(NEKO_SCHEMA_ENABLE_MODULE ON CACHE BOOL "" FORCE)
        endif()
        FetchContent_MakeAvailable(NekoSchema)
    endif(NOT NekoSchema_FOUND)

    if(NOT GTest_FOUND AND NEKO_LOG_BUILD_TESTS)
        message(STATUS "GTest Not Found ; Neko Log is Fetching GoogleTest...")

        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG        v1.17.0
        )
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
    endif()

endif()

# ================
# = Main target =
# ================

add_library(NekoLog INTERFACE)
add_library(Neko::Log ALIAS NekoLog)

target_include_directories(NekoLog INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Dependencies
target_link_libraries(NekoLog INTERFACE Neko::Schema)
target_compile_features(NekoLog INTERFACE cxx_std_20)


# ================
# = C++20 Module =
# ================

if(NEKO_LOG_ENABLE_MODULE)
    message(STATUS "NekoLog C++20 module enabled (NEKO_LOG_ENABLE_MODULE=ON)")

    # Check CMake version for module support
    if(CMAKE_VERSION VERSION_LESS 3.28)
        message(WARNING "CMake 3.28+ is recommended for full C++20 module support")
    endif()

    add_library(NekoLog_module)
    add_library(Neko::Log::Module ALIAS NekoLog_module)
    
    target_sources(NekoLog_module
        PUBLIC
            FILE_SET CXX_MODULES FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/include/neko/log/neko.log.cppm
    )
    
    target_link_libraries(NekoLog_module PUBLIC Neko::Schema::Module)
    target_compile_features(NekoLog_module PUBLIC cxx_std_20)

    target_include_directories(NekoLog_module PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )
else()
    message(STATUS "NekoLog C++20 module disabled (NEKO_LOG_ENABLE_MODULE=OFF)")
endif()

# ================
# ==== Tests =====
# ================

if(NEKO_LOG_BUILD_TESTS)
    enable_testing()
    message(STATUS "NekoLog tests enabled (NEKO_LOG_BUILD_TESTS=ON)")

    if (NOT GTest_FOUND AND NOT NEKO_LOG_AUTO_FETCH_DEPS)
        message(WARNING "GTest is required for building tests but was not found.")
        message(FATAL_ERROR "Please enable -DNEKO_LOG_AUTO_FETCH_DEPS=ON or install GTest and make it discoverable by CMake. e.g -DCMAKE_PREFIX_PATH=</path/to/googletest>")
    endif()

    add_executable(nlog_test tests/nlog_test.cpp)
    target_include_directories(nlog_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_link_libraries(nlog_test PRIVATE NekoLog GTest::gtest GTest::gtest_main)
    target_compile_features(nlog_test PRIVATE cxx_std_20)

    include(GoogleTest)
    gtest_discover_tests(nlog_test)
    
    # Module test (if modules are enabled)
    if(NEKO_LOG_ENABLE_MODULE)
        if (MSVC)
            message(STATUS "NekoLog module tests enabled (MSVC only)")

            add_executable(nlog_module_test tests/nlog_module_test.cpp)
            target_link_libraries(nlog_module_test PRIVATE Neko::Log::Module GTest::gtest GTest::gtest_main)
            target_compile_features(nlog_module_test PRIVATE cxx_std_20)
            gtest_discover_tests(nlog_module_test)
        else()
            message(STATUS "Skipping NekoLog module tests on non-MSVC toolchains")
        endif()
    endif()
    
else()
    message(STATUS "NekoLog tests disabled (NEKO_LOG_BUILD_TESTS=OFF)")
endif()

# ================
# == Install =====
# ================

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Install headers
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING 
    PATTERN "*.hpp"
    PATTERN "*.cppm"
)

# Install targets
install(TARGETS NekoLog
    EXPORT NekoLogTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILE_SET CXX_MODULES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# Install export targets
install(EXPORT NekoLogTargets
    FILE NekoLogTargets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NekoLog
)

# Create and install Config file
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/NekoLogConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NekoLog
)

# Create and install Version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NekoLog
)

message(STATUS "Neko Log End of configuration")