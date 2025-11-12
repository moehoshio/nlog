#include <neko/log/nlog.hpp>
#include <iostream>

int main() {
    try {
        // Test basic logging
        neko::log::info("NekoLog test - info message");
        neko::log::warn("NekoLog test - warning message");
        neko::log::error("NekoLog test - error message");
        
        // Test with source location
        neko::log::debug("NekoLog test - debug message with auto source location");
        
        std::cout << "NekoLog test passed!" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Test failed: " << e.what() << std::endl;
        return 1;
    }
}
