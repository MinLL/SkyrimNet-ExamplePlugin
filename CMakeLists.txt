cmake_minimum_required(VERSION 3.25)

project(SkyrimNetPluginExamples VERSION 1.0.0 LANGUAGES NONE)

option(BUILD_CPP_EXAMPLE "Build the C++ SKSE example (needs MSVC and vcpkg)" OFF)
set(TOOLS_DIR "${CMAKE_SOURCE_DIR}/external-tools" CACHE PATH "Where scripts/fetch-tools.ps1 put the tools")
set(DIST_DIR "${CMAKE_SOURCE_DIR}/dist" CACHE PATH "Where each example is staged as an installable mod folder")
set(DEPLOY_DIR "" CACHE PATH "Optional: also copy each example here after building (e.g. your MO2 mods folder)")

set(SKYRIMNET_SDK_DIR "${CMAKE_SOURCE_DIR}/sdk")
set(PAPYRUS_HEADER_DIRS
    "${CMAKE_SOURCE_DIR}/third_party/papyrus-headers"
    "${SKYRIMNET_SDK_DIR}/papyrus")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(Tools)
include(Papyrus)
include(Spriggit)
include(Example)

add_subdirectory(examples/01-papyrus-basics)
add_subdirectory(examples/02-papyrus-context)

if(BUILD_CPP_EXAMPLE)
    enable_language(C CXX)
    add_subdirectory(examples/03-cpp-native)
endif()
