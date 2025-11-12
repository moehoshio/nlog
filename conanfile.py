from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import copy


class NekoLogConan(ConanFile):
    name = "nekolog"
    version = "1.0.0"
    license = "MIT OR Apache-2.0"
    author = "Hoshi <moehoshio>"
    url = "https://github.com/moehoshio/NekoLog"
    description = "An easy-to-use, modern, lightweight, and efficient C++20 logging library"
    topics = ("logging", "cpp20", "header-only", "async")
    settings = "os", "compiler", "build_type", "arch"
    options = {
        "build_tests": [True, False],
        "use_modules": [True, False],
    }
    default_options = {
        "build_tests": False,
        "use_modules": False,
    }
    exports_sources = "CMakeLists.txt", "cmake/*", "include/*", "tests/*", "LICENSE", "readme.md"
    no_copy_source = True

    def requirements(self):
        # NekoSchema will be automatically fetched via FetchContent when NEKO_LOG_AUTO_FETCH_DEPS=ON
        # Once NekoSchema is published to Conan, uncomment the line below:
        # self.requires("nekoschema/1.0")
        pass

    def build_requirements(self):
        if self.options.build_tests:
            self.test_requires("gtest/1.14.0")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self)
        tc.variables["NEKO_LOG_BUILD_TESTS"] = self.options.build_tests
        tc.variables["NEKO_LOG_USE_MODULES"] = self.options.use_modules
        # Enable auto-fetch to get NekoSchema via FetchContent until it's published to Conan
        tc.variables["NEKO_LOG_AUTO_FETCH_DEPS"] = True
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE", src=self.source_folder, dst=self.package_folder / "licenses")
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "NekoLog")
        self.cpp_info.set_property("cmake_target_name", "Neko::Log")
        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []
        # NekoSchema dependency is handled via FetchContent in CMakeLists.txt
        # Once NekoSchema is published to Conan, uncomment:
        # self.cpp_info.requires = ["nekoschema::nekoschema"]
