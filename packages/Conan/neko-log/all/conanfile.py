from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.files import copy
import os


class NekoLogConan(ConanFile):
    name = "neko-log"
    version = "1.0.7"
    license = "MIT OR Apache-2.0"
    author = "moehoshio"
    url = "https://github.com/moehoshio/NekoLog"
    description = "An easy-to-use, lightweight, and efficient C++20 logging library."
    topics = ("c++20", "header-only", "logging", "library", "neko")
    
    settings = "os", "compiler", "build_type", "arch"
    options = {
        "enable_module": [True, False],
    }
    default_options = {
        "enable_module": False,
    }
    
    # Header-only library
    package_type = "header-library"
    no_copy_source = True
    
    exports_sources = "CMakeLists.txt", "include/*", "tests/*", "LICENSE", "README.md"

    # def requirements(self):
        # self.test_requires("neko-schema/*")
    
    def layout(self):
        cmake_layout(self)
    
    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["NEKO_LOG_BUILD_TESTS"] = False
        tc.variables["NEKO_LOG_ENABLE_MODULE"] = self.options.enable_module
        # Automatically fetch NekoSchema until it is available in Conan
        tc.variables["NEKO_LOG_AUTO_FETCH_DEPS"] = True
        tc.variables["NEKO_SCHEMA_BUILD_TESTS"] = False
        tc.generate()
        
        deps = CMakeDeps(self)
        deps.generate()
    
    def build(self):
        cmake = CMake(self)
        cmake.configure()

    def package(self):
        copy(self, "LICENSE", src=self.source_folder, dst=os.path.join(self.package_folder, "licenses"))
        copy(self, "*.hpp", src=os.path.join(self.source_folder, "include"), dst=os.path.join(self.package_folder, "include"))
        copy(self, "*.cppm", src=os.path.join(self.source_folder, "include"), dst=os.path.join(self.package_folder, "include"))
        
        cmake = CMake(self)
        cmake.install()
    
    def package_info(self):
        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []
        
        # Set the CMake package file name to match the official CMake config
        self.cpp_info.set_property("cmake_file_name", "NekoLog")
        
        # Main header-only target
        self.cpp_info.components["NekoLog"].set_property("cmake_target_name", "Neko::Log")
        self.cpp_info.components["NekoLog"].includedirs = ["include"]
        self.cpp_info.components["NekoLog"].requires = []
        
        # C++20 requirements
        self.cpp_info.components["NekoLog"].cxxflags = []
        
        # Module support (if enabled)
        if self.options.enable_module:
            self.cpp_info.components["NekoLogModule"].set_property("cmake_target_name", "Neko::Log::Module")
            self.cpp_info.components["NekoLogModule"].includedirs = ["include"]
    
    def package_id(self):
        self.info.clear()


