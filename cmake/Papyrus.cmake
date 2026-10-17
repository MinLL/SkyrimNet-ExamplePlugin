# add_papyrus_scripts(<target> SOURCE_DIR <dir> OUTPUT_DIR <dir>)
#
# Compiles every .psc in SOURCE_DIR to .pex in OUTPUT_DIR, against PAPYRUS_HEADER_DIRS
# (vanilla/SKSE/PapyrusUtil headers and the SkyrimNet SDK). Headers are read, never compiled.

function(add_papyrus_scripts target)
    cmake_parse_arguments(ARG "" "SOURCE_DIR;OUTPUT_DIR" "" ${ARGN})

    file(GLOB _sources CONFIGURE_DEPENDS "${ARG_SOURCE_DIR}/*.psc")
    if(NOT _sources)
        message(FATAL_ERROR "${target}: no .psc files in ${ARG_SOURCE_DIR}")
    endif()

    set(_header_args "")
    set(_header_files "")
    foreach(_dir IN LISTS PAPYRUS_HEADER_DIRS)
        list(APPEND _header_args -h "${_dir}")
        file(GLOB _found CONFIGURE_DEPENDS "${_dir}/*.psc")
        list(APPEND _header_files ${_found})
    endforeach()

    set(_stamp "${CMAKE_CURRENT_BINARY_DIR}/${target}.stamp")
    add_custom_command(
        OUTPUT "${_stamp}"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${ARG_OUTPUT_DIR}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${ARG_OUTPUT_DIR}"
        COMMAND "${PAPYRUS_COMPILER}" compile -nocache ${_header_args} -i "${ARG_SOURCE_DIR}" -o "${ARG_OUTPUT_DIR}"
        COMMAND "${CMAKE_COMMAND}" -E touch "${_stamp}"
        DEPENDS ${_sources} ${_header_files}
        COMMENT "Compiling Papyrus scripts in ${ARG_SOURCE_DIR}"
        VERBATIM)
    add_custom_target(${target} DEPENDS "${_stamp}")
endfunction()
