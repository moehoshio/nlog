#include <gtest/gtest.h>
#include <neko/log/nlog.hpp>

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
TEST(NLogTest, FileLogging) {
    // Clean up any existing appenders
    log::clearAppenders();
    
    // Add file appender
    const std::string testFile = "test_log.txt";
    log::addFileAppender(testFile, true, std::make_unique<log::DefaultFormatter>());

    // Log messages at different levels
    log::info("This is a test log message to file.");
    log::warn("This is a warning log message to file.");
    log::error("This is an error log message to file.");

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
TEST(NLogTest, ThreadName) {
    // Clear appenders before starting the test
    log::clearAppenders();
    
    // Test thread name functionality by using separate test runs
    std::vector<std::string> thread1Messages;
    std::vector<std::string> thread2Messages;
    std::mutex messagesMutex;
    
    // Test thread 1
    {
        auto testAppender = std::make_unique<TestAppender>();
        TestAppender* appenderPtr = testAppender.get();
        
        log::clearAppenders();
        log::addAppender(std::move(testAppender));
        
        std::thread t1([&thread1Messages, appenderPtr, &messagesMutex] {
            log::setCurrentThreadName("Thread 1");
            log::info("Thread-1 log message");
            log::flushLog();
            
            std::lock_guard<std::mutex> lock(messagesMutex);
            thread1Messages = appenderPtr->getMessages();
        });
        
        t1.join();
    }
    
    // Test thread 2
    {
        auto testAppender = std::make_unique<TestAppender>();
        TestAppender* appenderPtr = testAppender.get();
        
        log::clearAppenders();
        log::addAppender(std::move(testAppender));
        
        std::thread t2([&thread2Messages, appenderPtr, &messagesMutex] {
            log::setCurrentThreadName("Thread 2");
            log::info("Thread-2 log message");
            log::flushLog();
            
            std::lock_guard<std::mutex> lock(messagesMutex);
            thread2Messages = appenderPtr->getMessages();
        });
        
        t2.join();
    }

    // Verify thread names appear in log messages
    ASSERT_FALSE(thread1Messages.empty()) << "Thread 1 should have logged messages";
    ASSERT_FALSE(thread2Messages.empty()) << "Thread 2 should have logged messages";
    
    // Check if any of the thread 1 messages contain the thread name
    bool foundThread1Name = false;
    for (const auto& msg : thread1Messages) {
        if (msg.find("[Thread 1]") != std::string::npos) {
            foundThread1Name = true;
            break;
        }
    }
    
    // Check if any of the thread 2 messages contain the thread name
    bool foundThread2Name = false;
    for (const auto& msg : thread2Messages) {
        if (msg.find("[Thread 2]") != std::string::npos) {
            foundThread2Name = true;
            break;
        }
    }
    
    EXPECT_TRUE(foundThread1Name) << "Thread 1 name not found in log messages. Messages: " 
                                 << (thread1Messages.empty() ? "None" : thread1Messages[0]);
    EXPECT_TRUE(foundThread2Name) << "Thread 2 name not found in log messages. Messages: " 
                                 << (thread2Messages.empty() ? "None" : thread2Messages[0]);
                                 
    // Clean up
    log::clearAppenders();
}

// Log level filtering test
TEST(NLogTest, LogLevelFiltering) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* appenderPtr = testAppender.get();
    
    log::addAppender(std::move(testAppender));

    // Test with Off level - no messages should be logged
    log::setLevel(log::Level::Off);
    
    log::debug("This is a debug message.");
    log::info("This is an info message.");
    log::warn("This is a warning message.");
    log::error("This is an error message.");
    
    log::flushLog();
    
    EXPECT_TRUE(appenderPtr->getMessages().empty()) 
        << "No messages should be logged when level is Off";

    // Reset for next test
    appenderPtr->clear();
    log::setLevel(log::Level::Warn);
    
    log::debug("This debug should not appear");
    log::info("This info should not appear");
    log::warn("This warning should appear");
    log::error("This error should appear");
    
    log::flushLog();
    
    const auto& messages = appenderPtr->getMessages();
    EXPECT_EQ(messages.size(), 2) << "Only warn and error messages should be logged";
    EXPECT_TRUE(appenderPtr->containsMessage("warning should appear"));
    EXPECT_TRUE(appenderPtr->containsMessage("error should appear"));
    
    // Clean up
    log::setLevel(log::Level::Debug);
    log::clearAppenders();
}

// Basic logging functionality test
TEST(NLogTest, BasicLogging) {
    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>();
    auto* appenderPtr = testAppender.get();
    
    log::addAppender(std::move(testAppender));
    log::setLevel(log::Level::Debug);

    // Test all log levels
    log::debug("This is a debug log message.");
    log::info("This is an info log message.");
    log::warn("This is a warning log message.");
    log::error("This is an error log message.");
    
    log::flushLog();
    
    const auto& messages = appenderPtr->getMessages();
    
    // Verify all messages were logged
    EXPECT_EQ(messages.size(), 4) << "All four log messages should be captured";
    
    // Verify content
    EXPECT_TRUE(appenderPtr->containsMessage("debug log message"));
    EXPECT_TRUE(appenderPtr->containsMessage("info log message"));
    EXPECT_TRUE(appenderPtr->containsMessage("warning log message"));
    EXPECT_TRUE(appenderPtr->containsMessage("error log message"));
    
    // Verify log levels appear in formatted output
    EXPECT_TRUE(appenderPtr->containsMessage("[Debug]"));
    EXPECT_TRUE(appenderPtr->containsMessage("[Info]"));
    EXPECT_TRUE(appenderPtr->containsMessage("[Warn]"));
    EXPECT_TRUE(appenderPtr->containsMessage("[Error]"));
    
    log::clearAppenders();
}

// Custom formatter test
TEST(NLogTest, CustomFormatter) {
    class TestFormatter : public log::IFormatter {
    public:
        std::string format(const log::LogRecord &record) override {
            return "[CUSTOM] " + std::string(log::levelToString(record.level)) + ": " + record.message;
        }
    };

    log::clearAppenders();
    
    auto testAppender = std::make_unique<TestAppender>(std::make_unique<TestFormatter>());
    auto* appenderPtr = testAppender.get();
    
    log::addAppender(std::move(testAppender));
    
    log::info("Test message with custom formatter");
    log::flushLog();
    
    const auto& messages = appenderPtr->getMessages();
    ASSERT_FALSE(messages.empty()) << "Should have logged a message";
    
    EXPECT_TRUE(appenderPtr->containsMessage("[CUSTOM]"));
    EXPECT_TRUE(appenderPtr->containsMessage("Info:"));
    EXPECT_TRUE(appenderPtr->containsMessage("Test message with custom formatter"));
    
    log::clearAppenders();
}

// Console appender test
TEST(NLogTest, ConsoleAppender) {
    log::clearAppenders();
    
    // This test just ensures console appender can be created and used without throwing
    log::addAppender(std::make_unique<log::ConsoleAppender>());
    
    EXPECT_NO_THROW({
        log::info("Console test message");
        log::flushLog();
    });
    
    log::clearAppenders();
}

// Test fixture for cleanup
class NLogTestFixture : public ::testing::Test {
protected:
    void SetUp() override {
        log::clearAppenders();
        log::setLevel(log::Level::Debug);
    }
    
    void TearDown() override {
        log::clearAppenders();
        log::setLevel(log::Level::Debug);
        
        // Clean up any test files
        if (std::filesystem::exists("test_log.txt")) {
            std::filesystem::remove("test_log.txt");
        }
    }
};

// Test using fixture
TEST_F(NLogTestFixture, AppenderManagement) {
    // Test adding and clearing appenders
    auto testAppender1 = std::make_unique<TestAppender>();
    auto testAppender2 = std::make_unique<TestAppender>();
    
    log::addAppender(std::move(testAppender1));
    log::addAppender(std::move(testAppender2));
    
    log::info("Test message");
    log::flushLog();
    
    // Clear appenders should not throw
    EXPECT_NO_THROW(log::clearAppenders());
    
    // After clearing, logging should not throw but may not produce output
    EXPECT_NO_THROW({
        log::info("After clear message");
        log::flushLog();
    });
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}