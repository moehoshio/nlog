cmake_minimum_required(VERSION 3.14)
project(NekoLog VERSION 1.0 LANGUAGES CXX)

option(NEKO_AUTO_FETCH_DEPS "Automatically fetch dependencies" ON)

option(NEKO_BUILD_TESTS "Build tests" ON)

if(NEKO_AUTO_FETCH_DEPS)

    include(FetchContent)

    FetchContent_Declare(
        NekoSchema
        GIT_REPOSITORY https://github.com/moehoshio/NekoSchema.git
        GIT_TAG        main
    )
    FetchContent_MakeAvailable(NekoSchema)

    # Google Test for unit testing
    if(NEKO_BUILD_TESTS)
        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG        release-1.16.0
        )
        # For Windows: Prevent overriding the parent project's compiler/linker settings
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
    endif()

endif(NEKO_AUTO_FETCH_DEPS)


add_library(NekoLog INTERFACE)
add_library(Neko::Log ALIAS NekoLog)

target_include_directories(NekoLog INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Dependencies
target_link_libraries(NekoLog INTERFACE NekoSchema)

target_compile_features(NekoLog INTERFACE cxx_std_20)

if(MSVC)
    target_compile_options(NekoLog INTERFACE /Zc:__cplusplus)
endif()

# Tests
if(NEKO_BUILD_TESTS)
    enable_testing()

    add_executable(nlog_test_app tests/nlog_test.cpp)
    target_include_directories(nlog_test_app PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_link_libraries(nlog_test_app PRIVATE NekoLog gtest_main)
    target_compile_features(nlog_test_app PRIVATE cxx_std_20)

    if(MSVC)
        target_compile_options(nlog_test_app PRIVATE /Zc:__cplusplus)
    endif()
    
    add_test(NAME nlog_test_app COMMAND nlog_test_app)
endif()