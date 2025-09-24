#include <algorithm>
#include <fstream>
#include <functional>
#include <iostream>
#include <memory>
#include <ostream>
#include <string>
#include <thread>
#include <vector>

#include <neko/log/nlog.hpp>

using namespace neko;

class TestFormatter : public log::IFormatter {
private:
    static neko::uint64 i;

public:
    std::string format(const log::LogRecord &record) override {
        return "[TestFormatter] [Test-" + std::to_string(++i) + "] " + record.message;
    }
};

neko::uint64 TestFormatter::i = 0;

class CustomAppender : public log::IAppender {
private:
    std::vector<std::string> buffer;

    std::function<void(const std::string &)> outputFunc;
    std::unique_ptr<log::IFormatter> formatter;

public:
    explicit CustomAppender(std::function<void(const std::string &)> outputFunc)
        : outputFunc(outputFunc), formatter(std::make_unique<log::DefaultFormatter>()) {}

    bool find(const std::string &msg) const {
        return std::find(buffer.begin(), buffer.end(), msg) != buffer.end();
    }

    void append(const log::LogRecord &record) override {
        std::string formatted = formatter->format(record);
        outputFunc(formatted);
        buffer.push_back(formatted);
    }

    void flush() override {
        for (const auto &msg : buffer) {
            std::cerr << msg << std::endl;
        }
        buffer.clear();
    }

    void clear() {
        buffer.clear();
    }

    ~CustomAppender() {
        flush();
    }
};

void writeFile_test() {
    log::ConsoleAppender instance(std::make_unique<TestFormatter>());

    instance.append(log::LogRecord(log::Level::Info, "Starting writeFile_test"));

    log::clearAppenders();
    log::addFileAppender("test_log.txt", true, std::make_unique<log::DefaultFormatter>());

    log::info("This is a test log message to file.");
    log::warn("This is a warning log message to file.");
    log::error("This is an error log message to file.");

    log::flushLog();

    log::clearAppenders();
    std::ifstream file("test_log.txt", std::ios::in);
    if (!file.is_open()) {
        instance.append(log::LogRecord(log::Level::Error, "Failed to open log file for reading."));
        throw std::runtime_error("Log message content incorrect.");
    }
    // Read the file and check for [Info], [Warn], [Error] keywords
    std::string line;
    bool foundInfo = false, foundWarn = false, foundError = false;
    while (std::getline(file, line)) {
        if (line.find("[Info]") != std::string::npos) {
            foundInfo = true;
            instance.append(log::LogRecord(log::Level::Warn, "Found Info log entry."));
        }
        if (line.find("[Warn]") != std::string::npos) {
            foundWarn = true;
            instance.append(log::LogRecord(log::Level::Warn, "Found Warn log entry."));
        }
        if (line.find("[Error]") != std::string::npos) {
            foundError = true;
            instance.append(log::LogRecord(log::Level::Warn, "Found Error log entry."));
        }
    }
    if (foundInfo && foundWarn && foundError) {
        instance.append(log::LogRecord(log::Level::Warn, "writeFile_test passed: All log levels found."));
    } else {
        instance.append(log::LogRecord(log::Level::Error, "writeFile_test failed: Missing log levels."));
        throw std::runtime_error("Log message content incorrect.");
    }
    file.close();

    instance.append(log::LogRecord(log::Level::Info, "writeFile_test completed."));
}

void threadName_test() {
    log::ConsoleAppender instance(std::make_unique<TestFormatter>());

    instance.append(log::LogRecord(log::Level::Info, "Starting threadName_test"));

    std::string targetThreadName;

    auto checkThreadName = [&instance, &targetThreadName](const std::string &msg) {        
        if (msg.find(targetThreadName) == std::string::npos) {
            instance.append(log::LogRecord(log::Level::Error, "Thread name " + targetThreadName + " not found in log message."));
            throw std::runtime_error("Log message content incorrect.");
        } else {
            instance.append(log::LogRecord(log::Level::Warn, "Thread name " + targetThreadName + " found in log message."));
        }
    };
    std::thread t1([&] {
        log::clearAppenders();
        targetThreadName = "[Thread 1]";
        log::addAppender(std::make_unique<CustomAppender>(checkThreadName));
        log::setCurrentThreadName("Thread 1");
        log::info("Thread-1 log message");
    });

    t1.join();
    std::thread t2([&] {
        log::clearAppenders();
        targetThreadName = "[Thread 2]";
        log::addAppender(std::make_unique<CustomAppender>(checkThreadName));
        log::setCurrentThreadName("Thread 2");
        log::info("Thread-2 log message");
    });
    t2.join();

    instance.append(log::LogRecord(log::Level::Info, "threadName_test completed."));
}

void logLevel_test(){
    log::ConsoleAppender instance(std::make_unique<TestFormatter>());

    instance.append(log::LogRecord(log::Level::Info, "Starting logLevel_test"));

    log::clearAppenders();

    bool isOK = true;
    auto customAppender = std::make_unique<CustomAppender>([&instance, &isOK](const std::string &msg) {
        isOK = false;
        instance.append(log::LogRecord(log::Level::Error, "Logging is Off but still outputting."));
    });
    customAppender->setLevel(log::Level::Warn);
    log::addAppender(std::move(customAppender));

    log::setLevel(log::Level::Off);

    log::debug("This is a debug message.");
    log::info("This is an info message.");
    log::warn("This is a warning message.");
    log::error("This is an error message.");

    log::flushLog();

    if (isOK) {
        instance.append(log::LogRecord(log::Level::Warn, "logLevel_test passed: No logs were output when level is Off."));
    } else {
        instance.append(log::LogRecord(log::Level::Error, "logLevel_test failed: Some logs were output when level is Off."));
        throw std::runtime_error("Log message content incorrect.");
    }

    log::setLevel(log::Level::Debug);

    log::clearAppenders();

    instance.append(log::LogRecord(log::Level::Info, "logLevel_test completed."));

}

void logging_test() {
    log::ConsoleAppender instance(std::make_unique<TestFormatter>());

    instance.append(log::LogRecord(log::Level::Info, "Starting logging_test"));

    auto checkLogMsg = [&instance](const std::string &msg) {
        if (msg.find("log message") == std::string::npos) {
            instance.append(log::LogRecord(log::Level::Error, "Log message content incorrect."));
            throw std::runtime_error("Log message content incorrect.");
        } else {
            instance.append(log::LogRecord(log::Level::Warn, "Log message content correct."));
        }
    };
    log::info("This is an info log message.");
    log::warn("This is a warning log message.");
    log::error("This is an error log message.");
    log::debug("This is a debug log message.");

    instance.append(log::LogRecord(log::Level::Info, "logging_test completed."));
}

int main() {
    log::clearAppenders();
    log::setLevel(log::Level::Debug);

    log::ConsoleAppender instance(std::make_unique<TestFormatter>());
    
    instance.append(log::LogRecord(log::Level::Info, "Starting all tests"));

    logging_test();
    threadName_test();
    logLevel_test();
    writeFile_test();

    instance.append(log::LogRecord(log::Level::Info, "All tests completed."));
    
    return 0;
}