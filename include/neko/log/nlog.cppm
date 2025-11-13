/**
 * @file nlog.cppm
 * @brief neko logging module - C++20 module wrapper
 * @author moehoshio
 * @copyright Copyright (c) 2025 Hoshi
 * @license MIT OR Apache-2.0
 */

// Global module fragment - include all headers before module declaration
module;

// Standard library headers
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

// NekoSchema headers
#include <neko/schema/exception.hpp>
#include <neko/schema/srcLoc.hpp>
#include <neko/schema/types.hpp>

// Module declaration
export module neko.log;

// Export the neko log namespace from header
export {
    #include "nlog.hpp"
}