cmake_minimum_required(VERSION 3.14)
project(NekoLog VERSION 1.0 LANGUAGES CXX)

# ================
# === Config ====
# ================

# NekoLog project specific options
option(NEKO_LOG_BUILD_TESTS "Neko Log Build tests" ON)
option(NEKO_LOG_AUTO_FETCH_DEPS "Neko Log Automatically fetch dependencies" ON)
option(NEKO_LOG_USE_MODULES "Neko Log Use C++20 modules" OFF)

find_package(GTest QUIET)

# Print configuration summary
message(STATUS "Start configuration Neko Log...")
message(STATUS "")
message(STATUS "NekoLog configuration summary:")
message(STATUS "  - CMake version: ${CMAKE_VERSION}")
message(STATUS "")
message(STATUS "  - Neko Log Auto fetch deps: ${NEKO_LOG_AUTO_FETCH_DEPS}")
message(STATUS "  - Neko Log Build tests: ${NEKO_LOG_BUILD_TESTS}")
message(STATUS "  - Neko Log Use modules: ${NEKO_LOG_USE_MODULES}")
message(STATUS "")
message(STATUS "Dependency summary:")
message(STATUS "  - GTest : ${GTest_FOUND} version : ${GTest_VERSION}")
message(STATUS "")

if(NEKO_LOG_AUTO_FETCH_DEPS)
    include(FetchContent)

    FetchContent_Declare(
        NekoSchema
        GIT_REPOSITORY https://github.com/moehoshio/NekoSchema.git
        GIT_TAG        main
    )
    FetchContent_MakeAvailable(NekoSchema)

    if(NOT GTEST_FOUND AND NEKO_LOG_BUILD_TESTS)
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

if(NEKO_LOG_USE_MODULES)
    # Module-based library (wrapper module)
    add_library(NekoLog)
    add_library(Neko::Log ALIAS NekoLog)
    
    target_sources(NekoLog
        PUBLIC
            FILE_SET CXX_MODULES FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/include/neko/log/nlog.ixx
    )
    
    target_include_directories(NekoLog PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )
    
    # Dependencies
    target_link_libraries(NekoLog PUBLIC NekoSchema)
    target_compile_features(NekoLog PUBLIC cxx_std_20)
    
    # Enable C++20 modules
    set_target_properties(NekoLog PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
    )
else()
    # Traditional header-only library
    add_library(NekoLog INTERFACE)
    add_library(Neko::Log ALIAS NekoLog)

    target_include_directories(NekoLog INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )

    # Dependencies
    target_link_libraries(NekoLog INTERFACE NekoSchema)
    target_compile_features(NekoLog INTERFACE cxx_std_20)
endif()

# ================
# ==== Tests =====
# ================

if(NEKO_LOG_BUILD_TESTS)
    enable_testing()
    message(STATUS "NekoLog tests enabled (NEKO_LOG_BUILD_TESTS=ON)")

    if (NOT GTEST_FOUND AND NOT NEKO_LOG_AUTO_FETCH_DEPS)
        message(STATUS "GTest is required for building tests but was not found.")
        message(FATAL_ERROR "Please enable -DNEKO_LOG_AUTO_FETCH_DEPS=ON or install GTest and make it discoverable by CMake. e.g -DCMAKE_PREFIX_PATH=</path/to/googletest>")
    endif()

    add_executable(nlog_test tests/nlog_test.cpp)
    target_include_directories(nlog_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_link_libraries(nlog_test PRIVATE NekoLog GTest::gtest GTest::gtest_main)
    target_compile_features(nlog_test PRIVATE cxx_std_20)

    include(GoogleTest)
    gtest_discover_tests(nlog_test)
    
    # Module test (if modules are enabled)
    if(NEKO_LOG_USE_MODULES)
        add_executable(nlog_module_test tests/nlog_module_test.cpp)
        target_link_libraries(nlog_module_test PRIVATE NekoLog GTest::gtest GTest::gtest_main)
        target_compile_features(nlog_module_test PRIVATE cxx_std_20)
        
        set_target_properties(nlog_module_test PROPERTIES
            CXX_STANDARD 20
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS OFF
        )
        
        gtest_discover_tests(nlog_module_test)
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
    PATTERN "*.ixx"
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
    NAMESPACE Neko::
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
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/NekoLogConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NekoLog
)

message(STATUS "Neko Log End of configuration")