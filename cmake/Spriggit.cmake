# add_spriggit_plugin(<target> SOURCE_DIR <dir> OUTPUT <file.esp>)
#
# Builds an .esp from its Spriggit text form. The reverse (after editing the .esp in xEdit or the
# Creation Kit) is scripts/spriggit-sync.ps1. Spriggit downloads its serializer from NuGet on first
# use, so the first build needs the internet and the .NET SDK.

function(add_spriggit_plugin target)
    cmake_parse_arguments(ARG "" "SOURCE_DIR;OUTPUT" "" ${ARGN})

    file(GLOB_RECURSE _sources CONFIGURE_DEPENDS "${ARG_SOURCE_DIR}/*.json")
    if(NOT _sources)
        message(FATAL_ERROR "${target}: no Spriggit files in ${ARG_SOURCE_DIR}")
    endif()

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        COMMAND "${SPRIGGIT_CLI}" convert-to-plugin -i "${ARG_SOURCE_DIR}" -o "${ARG_OUTPUT}"
        DEPENDS ${_sources}
        COMMENT "Building ${ARG_OUTPUT} from Spriggit source"
        VERBATIM)
    add_custom_target(${target} DEPENDS "${ARG_OUTPUT}")
endfunction()
