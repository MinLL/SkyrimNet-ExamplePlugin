#pragma once

#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>

#include <nlohmann/json.hpp>

#include <algorithm>
#include <cstdint>
#include <functional>
#include <mutex>
#include <span>
#include <string>
#include <unordered_map>

namespace logger = SKSE::log;
using namespace std::literals;
