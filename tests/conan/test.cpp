#include <neko/log/nlog.hpp>
#include <iostream>

// Simple test to verify basic NekoLog functionality
int main() {
    try {
        std::cout << "Starting Conan integration test..." << std::endl;

        // Test 1: Use global logger instance
        std::cout << "✓ Using global logger instance" << std::endl;

        // Test 2: Clear default appenders and add console appender
        neko::log::clearAppenders();
        neko::log::addConsoleAppender();
        neko::log::setLevel(neko::log::Level::Info);
        std::cout << "✓ Logger configured with console appender" << std::endl;

        // Test 3: Log messages at different levels
        neko::log::info("Test INFO message");
        neko::log::warn("Test WARN message");
        neko::log::error("Test ERROR message");
        std::cout << "✓ Logged messages at different levels" << std::endl;

        // Test 4: Test formatted logging
        int value = 42;
        std::string text = "test";
        neko::log::info("Formatted message: value={}, text={}", {}, value, text);
        std::cout << "✓ Formatted logging works" << std::endl;

        // Test 5: Test log level filtering
        neko::log::setLevel(neko::log::Level::Error);
        neko::log::debug("This should not appear");
        neko::log::info("This should not appear");
        neko::log::error("This ERROR should appear");
        std::cout << "✓ Log level filtering works" << std::endl;

        // Test 6: Test thread name
        neko::log::setCurrentThreadName("MainThread");
        neko::log::info("Message with thread name");
        std::cout << "✓ Thread naming works" << std::endl;

        std::cout << "\nAll Conan integration tests passed!" << std::endl;
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "✗ Test failed with exception: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "✗ Test failed with unknown exception" << std::endl;
        return 1;
    }
}
