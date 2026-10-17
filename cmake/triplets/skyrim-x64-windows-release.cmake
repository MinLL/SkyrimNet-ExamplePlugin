###
# vcpkg triplet for Skyrim x64 Windows release build
###

# Set architecture to x64 for SkyrimNet
set(VCPKG_TARGET_ARCHITECTURE x64)

# Set MSVC runtime to static for release builds
set(VCPKG_CRT_LINKAGE static)

# Set library linkage to static for release builds
set(VCPKG_LIBRARY_LINKAGE static)

# Set vcpkg build type to release
set(VCPKG_BUILD_TYPE release)

# vcpkg ports that should be built as dynamic libraries
set(_skyrimnet_dynamic_ports "ffmpeg")
if(PORT IN_LIST _skyrimnet_dynamic_ports)
    set(VCPKG_CRT_LINKAGE dynamic)
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()
