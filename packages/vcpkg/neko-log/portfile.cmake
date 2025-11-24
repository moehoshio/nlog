vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO moehoshio/NekoLog
    REF v1.0.5
    SHA512 5a8f19ed365fbdbb310cd18ee24e9471aba82b5913c94d70ad79712b302820e4bc746a12b3c8ec7fc5827b13fea2ed9a2434622f0bd14d923430c6bfaedd8378
    HEAD_REF main
)

set(VCPKG_BUILD_TYPE release)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DNEKO_LOG_BUILD_TESTS=OFF
        -DNEKO_LOG_AUTO_FETCH_DEPS=OFF
        -DNEKO_LOG_ENABLE_MODULE=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/NekoLog PACKAGE_NAME nekolog)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")