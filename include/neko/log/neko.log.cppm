// =====================
// === Global Module ===
// =====================

module;

// ====================
// = Standard Library =
// ====================

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

// =====================
// = Module Interface ==
// =====================

export module neko.log;

import neko.schema;

// Control header files to not import dependencies (dependencies are declared and imported by the cppm)
#define NEKO_LOG_ENABLE_MODULE true

export {
    #include "nlog.hpp"
}