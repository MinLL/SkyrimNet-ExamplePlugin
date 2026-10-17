# skyrimnet_example(NAME <ModName>
#                   LAYER_DIR <dir>            # layer/<author>.<slug>, holds manifest.json
#                   [SCRIPTS_DIR <dir>]        # Papyrus sources
#                   [SPRIGGIT_DIR <dir>]       # Spriggit source of <ModName>.esp
#                   [DLL_TARGET <target>])     # SKSE plugin
#
# Stages an installable mod folder at ${DIST_DIR}/<ModName>, zips it next to it, and copies it to
# ${DEPLOY_DIR}/<ModName> when DEPLOY_DIR is set. The staged layout is exactly what a user installs:
#
#   <ModName>.esp
#   Scripts/*.pex
#   Source/Scripts/*.psc
#   SKSE/Plugins/<dll>
#   SKSE/Plugins/SkyrimNet/external/<author>.<slug>/...

function(skyrimnet_example)
    cmake_parse_arguments(ARG "" "NAME;LAYER_DIR;SCRIPTS_DIR;SPRIGGIT_DIR;DLL_TARGET" "" ${ARGN})
    set(name "${ARG_NAME}")
    set(stage "${DIST_DIR}/${name}")
    set(layer_dir "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_LAYER_DIR}")
    get_filename_component(layer_id "${layer_dir}" NAME)

    # SkyrimNet rejects a layer whose folder name differs from its manifest id. Fail here instead.
    file(READ "${layer_dir}/manifest.json" _manifest)
    string(JSON _manifest_id GET "${_manifest}" "id")
    if(NOT _manifest_id STREQUAL layer_id)
        message(FATAL_ERROR "${name}: layer folder '${layer_id}' must equal manifest id '${_manifest_id}'")
    endif()

    file(GLOB_RECURSE layer_files CONFIGURE_DEPENDS "${layer_dir}/*")
    set(deps ${layer_files})
    set(commands
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${stage}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${stage}"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory "${layer_dir}"
                "${stage}/SKSE/Plugins/SkyrimNet/external/${layer_id}")

    if(ARG_SPRIGGIT_DIR)
        set(esp "${CMAKE_CURRENT_BINARY_DIR}/${name}.esp")
        add_spriggit_plugin(${name}_esp SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_SPRIGGIT_DIR}" OUTPUT "${esp}")
        list(APPEND deps "${esp}")
        list(APPEND commands COMMAND "${CMAKE_COMMAND}" -E copy "${esp}" "${stage}/${name}.esp")
    endif()

    if(ARG_SCRIPTS_DIR)
        set(scripts_src "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_SCRIPTS_DIR}")
        set(pex_dir "${CMAKE_CURRENT_BINARY_DIR}/pex")
        add_papyrus_scripts(${name}_scripts SOURCE_DIR "${scripts_src}" OUTPUT_DIR "${pex_dir}")
        list(APPEND deps "${CMAKE_CURRENT_BINARY_DIR}/${name}_scripts.stamp")
        list(APPEND commands
            COMMAND "${CMAKE_COMMAND}" -E copy_directory "${pex_dir}" "${stage}/Scripts"
            COMMAND "${CMAKE_COMMAND}" -E copy_directory "${scripts_src}" "${stage}/Source/Scripts")
    endif()

    if(ARG_DLL_TARGET)
        list(APPEND deps ${ARG_DLL_TARGET})
        list(APPEND commands
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${stage}/SKSE/Plugins"
            COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:${ARG_DLL_TARGET}>" "${stage}/SKSE/Plugins/")
    endif()

    list(APPEND commands
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${DIST_DIR}/${name}.zip"
        COMMAND "${CMAKE_COMMAND}" -E chdir "${stage}"
                "${CMAKE_COMMAND}" -E tar cf "${DIST_DIR}/${name}.zip" --format=zip .)
    if(DEPLOY_DIR)
        list(APPEND commands
            COMMAND "${CMAKE_COMMAND}" -E rm -rf "${DEPLOY_DIR}/${name}"
            COMMAND "${CMAKE_COMMAND}" -E copy_directory "${stage}" "${DEPLOY_DIR}/${name}")
    endif()

    set(stamp "${CMAKE_CURRENT_BINARY_DIR}/${name}_stage.stamp")
    add_custom_command(
        OUTPUT "${stamp}"
        ${commands}
        COMMAND "${CMAKE_COMMAND}" -E touch "${stamp}"
        DEPENDS ${deps}
        COMMENT "Staging ${name} in ${stage}"
        VERBATIM)
    add_custom_target(${name}_mod ALL DEPENDS "${stamp}")
    if(ARG_SCRIPTS_DIR)
        add_dependencies(${name}_mod ${name}_scripts)
    endif()
    if(ARG_SPRIGGIT_DIR)
        add_dependencies(${name}_mod ${name}_esp)
    endif()
endfunction()
