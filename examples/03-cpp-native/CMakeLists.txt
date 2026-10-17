find_package(directxtk CONFIG REQUIRED)  # CommonLibSSE's config expects it found first
find_package(CommonLibSSE CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)

add_commonlibsse_plugin(ExampleNative
    NAME "ExampleNative"
    AUTHOR "SkyrimNet Examples"
    VERSION ${PROJECT_VERSION}
    USE_ADDRESS_LIBRARY
    SOURCES
        src/main.cpp
        src/SkyrimNetBridge.cpp
        src/Actions.cpp
        src/Decorators.cpp
        src/Events.cpp
        src/Worker.cpp)

target_compile_features(ExampleNative PRIVATE cxx_std_23)
target_compile_definitions(ExampleNative PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
target_compile_options(ExampleNative PRIVATE /W4 /permissive- /utf-8)
target_include_directories(ExampleNative PRIVATE src "${SKYRIMNET_SDK_DIR}/cpp")
target_precompile_headers(ExampleNative PRIVATE src/PCH.h)
target_link_libraries(ExampleNative PRIVATE CommonLibSSE::CommonLibSSE nlohmann_json::nlohmann_json)

skyrimnet_example(
    NAME       ExampleNative
    LAYER_DIR  layer/example.cpp-native
    DLL_TARGET ExampleNative)
