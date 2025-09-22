cmake_minimum_required(VERSION 3.14)
project(NekoLog VERSION 1.0 LANGUAGES CXX)

option(NEKO_AUTO_FETCH_DEPS "Automatically fetch dependencies" ON)

if(NEKO_AUTO_FETCH_DEPS)

    include(FetchContent)

    FetchContent_Declare(
        NekoSchema
        GIT_REPOSITORY https://github.com/moehoshio/NekoSchema.git
        GIT_TAG        main
    )
    FetchContent_MakeAvailable(NekoSchema)

target_link_libraries(NekoLog PRIVATE NekoSchema)

endif(NEKO_AUTO_FETCH_DEPS)


add_library(NekoLog INTERFACE)

target_include_directories(NekoLog INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Dependencies
target_link_libraries(NekoLog INTERFACE NekoSchema)

target_compile_features(NekoLog INTERFACE cxx_std_20)