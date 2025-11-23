/**
 * @file neko.log.cppm
 * @brief C++20 module interface for NekoLog
 * @details This module exports all NekoLog functionality by wrapping the header files.
 *          The original headers are still available for traditional include-based usage.
 */

module;

#if defined(__cpp_lib_modules) && (__cpp_lib_modules >= 202207L)
import std;
#else
// Global module fragment - include headers that should not be exported
#include <format>

#include <chrono>
#include <memory>

#include <atomic>
#include <condition_variable>
#include <mutex>

#include <filesystem>
#include <fstream>
#include <iostream>

#include <sstream>
#include <string>

#include <thread>

#include <queue>
#include <unordered_map>
#include <vector>
#endif

import neko.schema;

export module neko.log;

// Control header files to not import dependencies (dependencies are declared and imported by the cppm)
#define NEKO_LOG_ENABLE_MODULE true

export {
    #include "nlog.hpp"
}
