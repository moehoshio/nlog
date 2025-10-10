# Neko Logging

Neko Logging (nlog) is an easy-to-use, modern, lightweight, and efficient C++20 logging library.

[![License](https://img.shields.io/badge/License-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE)
![Require](https://img.shields.io/badge/%20Require%20-%3E=%20C++%2020-orange.svg)
[![CMake](https://img.shields.io/badge/CMake-3.14+-green.svg)](https://cmake.org/)

## Features

- No Macro
- Header Only (No build/link required)
- Auto SrcLoc (Automatically capture source code location)
- Supports multiple appenders (Console, File, Custom)
- Supports custom formatted log messages
- Supports asynchronous logging
- Thread-safe
- RAII-style scope logging

## Requirements

- C++20 or higher compatible compiler
- CMake 3.14 or higher (if using CMake)

## Quick Start

Configure:
[CMake](#cmake) | [Manual](#manual) | [Tests](#testing)

Example:
[Basic](#basic-example) | [Logging](#logging) | [Level](#level) | [Set Thread Name](#set-thread-name) | [RAII Scope Logging](#raii-scope-logging)

Advanced:
[Appenders](#appenders) | [Formatting Logs](#formatting-logs) | [Asynchronous Logging](#asynchronous-logging) | [Disable Tests](#disable-tests)

### CMake

1. Using CMake's `FetchContent` to include NekoLog in your project:

```cmake
include(FetchContent)

# Add NekoLog to your CMake project
FetchContent_Declare(
    NekoLog
    GIT_REPOSITORY https://github.com/moehoshio/NekoLog.git
    GIT_TAG        main
)
FetchContent_MakeAvailable(NekoLog)

# Add your target and link NekoLog
add_executable(your_target main.cpp)

target_link_libraries(your_target PRIVATE Neko::Log)
```

2. Include the header in your source code

```cpp
#include <neko/log/nlog.hpp>
```

### Manual

When installing manually, you need to manually fetch the dependency [`NekoSchema`](https://github.com/moehoshio/NekoSchema).

After installing the dependency, please continue:

1. Clone or download the repository to your host

```shell
git clone https://github.com/moehoshio/NekoLog.git
```

or

```shell
curl -L -o NekoLog.zip https://github.com/moehoshio/NekoLog/archive/refs/heads/main.zip

unzip NekoLog.zip
```

2. Copy the `include` folder to your include directory

```shell
cp -r NekoLog/include/ /path/to/your/include/
```

3. Include the header in your source code

```cpp
#include <neko/log/nlog.hpp>
```

### Basic Example

Now you can start logging with minimal setup:

```cpp
#include "neko/log/nlog.hpp"

int main() {
    using namespace neko;
    log::setCurrentThreadName("Main Thread"); // Set the current thread name
    log::setLevel(log::Level::Debug); // Set the log level

    log::info("This is an info message.");
    log::debug("This is a debug message.");
    log::warn("This is a warning message.");
    log::error("This is an error message.");
}
```

output:

```log
[2025-09-16 01:53:58.678] [Info] [Main Thread] [main.cpp:9] This is an info message.
[2025-09-16 01:53:58.679] [Debug] [Main Thread] [main.cpp:10] This is a debug message.
[2025-09-16 01:53:58.679] [Warn] [Main Thread] [main.cpp:11] This is a warning message.
[2025-09-16 01:53:58.679] [Error] [Main Thread] [main.cpp:12] This is an error message.
```

## Usage

### Logging

Logging is simple, just like in the example above.
Use the `neko::log::info`, `neko::log::debug`, `neko::log::warn`, and `neko::log::error` functions to log.
Each of these functions has two versions.

Single string:
```cpp
inline void debug(const std::string &message, const neko::SrcLocInfo &location = {});

debug("msg"); // (basic format)... msg
```

And with format arguments (via std::format):
```cpp
    template <typename... Args>
    void debug(const neko::SrcLocInfo &location, std::format_string<Args...> fmt, Args &&...args);

    debug( {} , "Hello , {} . 1 + 1 = {}", "World" , 1 + 1); // (basic format)... Hello , World . 1 + 1 = 2
```
Functions for other levels are the same.

Tip: `SrcLoc` can automatically get the source code location. You just need a default object, which you can generate via `{}` or a default parameter.

### Level

You can set the log level for the logger, which controls which level of logs should be recorded.

For example, if you set `setLevel` to `Info`, only logs of `Info` level and above will be recorded (Debug messages will be discarded).

```cpp
log::setLevel(log::Level::Info);

log::info("Info"); // Outputs Info
log::warn("Warn"); // Outputs Warn
log::debug("Debug"); // More detailed messages will be discarded
```

If needed, you can add more log levels and log with the `log` function.
For example:
```cpp

// nlog.hpp
enum class Level : neko::uint8 {
        Debug = 1, ///< Debug
        Info = 2,  ///< General information
        Warn = 3,  ///< Potential issues
        Error = 4, ///< Error
        lv5 = 5, /// Custom level
        lv6 = 6,
        lv10 = 10,
        Off = 255  ///< Logging off
    };

// main.cpp
using namespace neko;

log::logger.log(log::Level::lv10,"Hello Lv10");
```

### Set Thread Name

You can set the names of different threads in the logs using `neko::log::setCurrentThreadName` and `neko::log::setThreadName`.

Example:
```cpp
using namespace neko;

// Set the current thread
log::setCurrentThreadName("Thread 1");
log::info(""); // ... [Thread 1] ...

// Specify by id
auto id = std::this_thread::get_id();
log::setThreadName(id, "Thread-1");

log::info(""); // ... [Thread-1] ...
```


### Appenders

You can add multiple appenders simultaneously to output logs to different places. By default, appenders for console output and file writing are provided.

#### Logging to a file:
```cpp
// Add a file appender and overwrite the file
log::addFileAppender("app.log", true); 
```

#### Output to console (enabled by default):
```cpp
log::addConsoleAppender(); // Add a console appender
```

#### Custom Appender:

You can easily add your own appender to output to any destination.

Just inherit from `neko::log::IAppender` and override the `append` and `flush` methods for your output.

Example:

```cpp
using namespace neko;

class MyAppender : public log::IAppender {
    public:
    void append(const log::LogRecord &record) override {
        std::unique_ptr<log::IFormatter> formatter = std::make_unique<log::DefaultFormatter>(); // Create a default log formatter
        auto formatted = formatter->format(record); // Format the log

        // Output the string to your target
        yourOutput << formatted;
    }
    
    void flush() override {
        yourOutput.flush();
    }
};

// Add a custom log appender
log::addAppender(std::make_unique<MyAppender>());
```

### Formatting Logs

A formatter is a helper for an appender, used to format logs.
It is independent for each appender, and the appender calls the formatter's method to format the log.
So, it is recommended to have a built-in formatter object when creating a custom appender.

#### Default Formatter

The default formatter's format is:
[date time] [level] [thread] [file:line] [msg]

When constructing it, you can specify a root path to truncate and whether to use the full path. The function is defined as follows:

```cpp
explicit DefaultFormatter(const std::string &rootPath = "", bool useFullPath = false)
```

When `rootPath` is an empty string (default), `file` = `main.cpp`.  
When `rootPath` is a path, e.g., `/to/path/`, and the file is at `/to/path/src/main.cpp`, `file` = `/src/main.cpp`.  
When `useFullPath` is `true`, `rootPath` is ignored, and the full path is always displayed. `file` = `/to/path/src/main.cpp`.  

#### Custom Formatter

Inherit from `neko::log::IFormatter` and override the `format` function.
You need to implement the formatting of the incoming record in the `format` function.

Example:
```cpp
using namespace neko;

class MyFormatter : public log::IFormatter {
    public:
    std::string format(const log::LogRecord &record) override {
        // You can use any method to combine the record format, std::format, ostringstream, etc.
        
        std::ostringstream oss;
        oss << "lv: " << log::levelToString(record.level) << " , msg: "<< record.message ;
        return oss.str();
    }
};

// Create a console appender and specify MyFormatter as the formatter
log::ConsoleAppender consoleAppender(std::make_unique<MyFormatter>());

log::info("Hello");
```

output:
```log
lv: Info , msg: Hello
```

### Asynchronous Logging

By default, logging is written to IO by the logging thread.

For better performance, you can enable asynchronous mode. This lets logs be processed in a background thread.

```cpp
#include "neko/log/nlog.hpp"
#include <thread>
using namespace neko;

int main() {
    // Set to asynchronous mode
    log::setMode(neko::SyncMode::Async);

    // Start the log processing loop (usually in a dedicated thread)
    std::thread logThread([]{ log::runLogLoop(); });

    // Main thread submits logs
    log::info("This will be logged asynchronously.");

    // ... application execution ...

    // Stop the log loop and flush remaining logs
    log::stopLogLoop();
    logThread.join();
}
```

In async mode, logs are not flushed in real-time. It's possible for a log to be submitted before a crash, but not be recorded in time.
It is recommended to disable this during debugging.

Tip: When using asynchronous mode, a thread must be running the `neko::log::runLogLoop()` function.
Otherwise, no logs will be processed.

### RAII Scope Logging

Use `neko::log::autoLog` to automatically log the start and end of a scope.

```cpp
void someFunction() {
    // Logs "Start" when someFunction is entered, and "End" when it is exited
    log::autoLog log("Start", "End"); 
    
    // ... function body ...
}
```

## Testing

You can run the tests to verify that everything is working correctly.

If you haven't configured the build yet, please run:

```shell
cmake -B ./build . -DNEKO_BUILD_TESTS=ON -DNEKO_AUTO_FETCH_DEPS=ON
```

Now, you can build the test files (you must build them manually at least once before running the tests!).

```shell
cmake --build ./build --config Debug
```

Then, you can run the tests with the following commands:

```shell
cd ./build && ctest --output-on-failure
```

If everything is set up correctly, you should see output similar to the following:

```shell
  Test project /path/to/nlog/build
        Start  1: NLogTest.FileLogging
   1/36 Test  #1: NLogTest.FileLogging ................
  .................   Passed    0.02 sec

    # ......

        Start 36: PerformanceTest.ConstexprMapLookupSpeed
  36/36 Test #36: PerformanceTest.ConstexprMapLookupSpeed ..............   Passed    0.02 sec

  100% tests passed, 0 tests failed out of 36

  Total Test time (real) =   0.78 sec
```

### Disable Tests

If you want to disable building and running tests, you can set the following CMake option when configuring your project:

```shell
cmake -B ./build . -DNEKO_BUILD_TESTS=OFF
```

This will skip test targets during the build process.

## License

[License](LICENSE) MIT OR Apache-2.0

## See More

- [NekoLog](https://github.com/moehoshio/NekoLog): An easy-to-use, modern, lightweight, and efficient C++20 logging library.
- [NekoEvent](https://github.com/moehoshio/NekoEvent): A modern easy to use type-safe and high-performance event handling system for C++.
- [NekoSchema](https://github.com/moehoshio/NekoSchema): A lightweight, header-only C++20 schema library.
- [NekoSystem](https://github.com/moehoshio/NekoSystem): A modern C++20 cross-platform system utility library.
- [NekoFunction](https://github.com/moehoshio/NekoFunction): A comprehensive modern C++ utility library that provides practical functions for common programming tasks.
- [NekoThreadPool](https://github.com/moehoshio/NekoThreadPool): An easy to use and efficient C++ 20 thread pool that supports priorities and submission to specific threads.
