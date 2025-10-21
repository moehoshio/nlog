/**
 * @file example_module.cpp
 * @brief Example demonstrating C++20 module usage with NekoLog
 * 
 * To build with modules:
 * cmake -B build -DNEKO_LOG_USE_MODULES=ON
 * cmake --build build
 */

// Use C++20 module instead of header
import neko.log;

#include <thread>
#include <chrono>

int main() {
    using namespace neko;
    
    // Set main thread name
    log::setCurrentThreadName("MainThread");
    
    // Set log level
    log::setLevel(log::Level::Debug);
    
    // Basic logging
    log::info("Application started");
    log::debug("Debug information");
    log::warn("This is a warning");
    log::error("This is an error");
    
    // Formatted logging
    SrcLocInfo loc;
    int port = 8080;
    std::string service = "WebServer";
    log::info(loc, "Starting {} on port {}", service, port);
    
    // Multi-threaded logging
    std::thread worker([&]() {
        log::setCurrentThreadName("WorkerThread");
        log::info("Worker thread started");
        
        for (int i = 0; i < 3; ++i) {
            log::info(loc, "Processing task {}", i + 1);
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
        
        log::info("Worker thread finished");
    });
    
    worker.join();
    
    // Add file appender
    log::addFileAppender("app.log", true);
    log::info("Log will now also be written to app.log");
    
    // Flush all logs
    log::flushLog();
    log::info("Application finished");
    
    return 0;
}
