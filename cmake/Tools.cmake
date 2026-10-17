# Finds the tools pinned in tools.json, downloaded by scripts/fetch-tools.ps1.

file(READ "${CMAKE_SOURCE_DIR}/tools.json" _tools_json)

function(_find_pinned_tool key out_var)
    string(JSON _folder GET "${_tools_json}" "${key}" "folder")
    string(JSON _exe GET "${_tools_json}" "${key}" "exe")
    set(_path "${TOOLS_DIR}/${_folder}/${_exe}")
    if(NOT EXISTS "${_path}")
        message(FATAL_ERROR
            "${key} not found at ${_path}.\n"
            "Run scripts/fetch-tools.ps1 (or set TOOLS_DIR to where your tools are).")
    endif()
    set(${out_var} "${_path}" PARENT_SCOPE)
endfunction()

_find_pinned_tool("papyrus-compiler" PAPYRUS_COMPILER)
_find_pinned_tool("spriggit" SPRIGGIT_CLI)

message(STATUS "Papyrus compiler: ${PAPYRUS_COMPILER}")
message(STATUS "Spriggit CLI:     ${SPRIGGIT_CLI}")
