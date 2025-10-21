/**
 * @file nlog_module_test.cpp
 * @brief Test C++20 module version of nlog
 */

#include <gtest/gtest.h>

import neko.log;

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

using namespace neko;

// Test utilities
class TestAppender : public log::IAppender {
private:
    std::vector<std::string> messages;
    std::unique_ptr<log::IFormatter> formatter;

public:
    explicit TestAppender(std::unique_ptr<log::IFormatter> fmt = std::make_unique<log::DefaultFormatter>())
        : formatter(std::move(fmt)) {}

    void append(const log::LogRecord &record) override {
        std::string formatted = formatter->format(record);
        messages.push_back(formatted);
    }

    void flush() override {
        // Nothing to flush for test appender
    }

    const std::vector<std::string>& getMessages() const {
        return messages;
    }

    void clear() {
        messages.clear();
    }

    bool containsMessage(const std::string &substr) const {
        return std::any_of(messages.begin(), messages.end(),
            [&substr](const std::string &msg) {
                return msg.find(substr) != std::string::npos;
            });
    }
};

// File logging test
TEST(NLogModuleTest, FileLogging) {
    // Clean up any existing appenders
    log::clearAppenders();
    
    // Add file appender
    const std::string testFile = "test_log_module.txt";
    log::addFileAppender(testFile, true, std::make_unique<log::DefaultFormatter>());

    // Log messages at different levels
    log::info("This is a test log message to file (module).");
    log::warn("This is a warning log message to file (module).");
    log::error("This is an error log message to file (module).");

    // Ensure logs are written
    log::flushLog();
    log::clearAppenders();

    // Read and verify file contents
    std::ifstream file(testFile);
    ASSERT_TRUE(file.is_open()) << "Failed to open log file for reading";

    std::string line;
    bool foundInfo = false, foundWarn = false, foundError = false;
    
    while (std::getline(file, line)) {
        if (line.find("[Info]") != std::string::npos) {
            foundInfo = true;
        }
        if (line.find("[Warn]") != std::string::npos) {
            foundWarn = true;
        }
        if (line.find("[Error]") != std::string::npos) {
            foundError = true;
        }
    }
    file.close();

    // Clean up test file
    std::filesystem::remove(testFile);

    // Verify all log levels were found
    EXPECT_TRUE(foundInfo) << "Info log entry not found in file";
    EXPECT_TRUE(foundWarn) << "Warn log entry not found in file";
    EXPECT_TRUE(foundError) << "Error log entry not found in file";
}

// Thread name test
TEST(NLogModuleTest, ThreadName) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* testAppenderPtr = testAppender.get();
    log::addAppender(std::move(testAppender));

    // Set main thread name
    log::setCurrentThreadName("MainThread");
    
    // Log from main thread
    log::info("Message from main thread");
    
    // Create a new thread with a custom name
    std::thread workerThread([]() {
        log::setCurrentThreadName("WorkerThread");
        log::info("Message from worker thread");
    });
    
    workerThread.join();
    log::flushLog();

    // Check that thread names appear in messages
    EXPECT_TRUE(testAppenderPtr->containsMessage("MainThread")) 
        << "Main thread name not found in logs";
    EXPECT_TRUE(testAppenderPtr->containsMessage("WorkerThread")) 
        << "Worker thread name not found in logs";

    log::clearAppenders();
}

// Log level test
TEST(NLogModuleTest, LogLevel) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* testAppenderPtr = testAppender.get();
    log::addAppender(std::move(testAppender));

    // Set level to Warn
    log::setLevel(log::Level::Warn);

    // Try to log at different levels
    log::debug("Debug message - should not appear");
    log::info("Info message - should not appear");
    log::warn("Warn message - should appear");
    log::error("Error message - should appear");

    log::flushLog();

    const auto& messages = testAppenderPtr->getMessages();
    
    // Check that only Warn and Error messages are present
    EXPECT_FALSE(testAppenderPtr->containsMessage("Debug message")) 
        << "Debug message should not appear";
    EXPECT_FALSE(testAppenderPtr->containsMessage("Info message")) 
        << "Info message should not appear";
    EXPECT_TRUE(testAppenderPtr->containsMessage("Warn message")) 
        << "Warn message should appear";
    EXPECT_TRUE(testAppenderPtr->containsMessage("Error message")) 
        << "Error message should appear";

    // Reset level
    log::setLevel(log::Level::Debug);
    log::clearAppenders();
}

// Formatted logging test
TEST(NLogModuleTest, FormattedLogging) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* testAppenderPtr = testAppender.get();
    log::addAppender(std::move(testAppender));

    neko::SrcLocInfo loc;
    int value = 42;
    std::string name = "Test";

    // Test formatted logging
    log::info(loc, "Value: {}, Name: {}", value, name);
    log::warn(loc, "Warning code: {:04}", value);
    log::error(loc, "Error at position {}", value);

    log::flushLog();

    // Verify formatted messages
    EXPECT_TRUE(testAppenderPtr->containsMessage("Value: 42, Name: Test")) 
        << "Formatted info message not found";
    EXPECT_TRUE(testAppenderPtr->containsMessage("Warning code: 0042")) 
        << "Formatted warn message not found";
    EXPECT_TRUE(testAppenderPtr->containsMessage("Error at position 42")) 
        << "Formatted error message not found";

    log::clearAppenders();
}

// Multiple appenders test
TEST(NLogModuleTest, MultipleAppenders) {
    log::clearAppenders();
    
    auto testAppender1 = std::make_unique<TestAppender>();
    auto* testAppenderPtr1 = testAppender1.get();
    
    auto testAppender2 = std::make_unique<TestAppender>();
    auto* testAppenderPtr2 = testAppender2.get();
    
    log::addAppender(std::move(testAppender1));
    log::addAppender(std::move(testAppender2));

    // Log a message
    log::info("Message to multiple appenders");
    log::flushLog();

    // Both appenders should have the message
    EXPECT_TRUE(testAppenderPtr1->containsMessage("Message to multiple appenders")) 
        << "First appender didn't receive message";
    EXPECT_TRUE(testAppenderPtr2->containsMessage("Message to multiple appenders")) 
        << "Second appender didn't receive message";

    log::clearAppenders();
}

// Basic API test
TEST(NLogModuleTest, BasicAPI) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* testAppenderPtr = testAppender.get();
    log::addAppender(std::move(testAppender));

    // Test all log levels with simple messages
    log::debug("Debug message");
    log::info("Info message");
    log::warn("Warning message");
    log::error("Error message");

    log::flushLog();

    // Verify all messages were logged
    const auto& messages = testAppenderPtr->getMessages();
    EXPECT_GE(messages.size(), 4) << "Expected at least 4 log messages";
    
    EXPECT_TRUE(testAppenderPtr->containsMessage("Debug message"));
    EXPECT_TRUE(testAppenderPtr->containsMessage("Info message"));
    EXPECT_TRUE(testAppenderPtr->containsMessage("Warning message"));
    EXPECT_TRUE(testAppenderPtr->containsMessage("Error message"));

    log::clearAppenders();
}

// Module import verification test
TEST(NLogModuleTest, ModuleImportVerification) {
    // Simply verify that we can access module exports
    EXPECT_NO_THROW({
        auto level = log::Level::Info;
        const char* levelStr = log::levelToString(level);
        EXPECT_STREQ(levelStr, "Info");
    }) << "Failed to access module exports";
}
