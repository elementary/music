set(CORE_LIB_VERSION 0.1)
set(CORE_LIB_SOVERSION 0)

set(CORE_SOURCE
    PluginManager.vala
    Settings.vala
    EqualizerPreset.vala
    Player.vala
    LibraryWindowInterface.vala
    Media.vala
    Utils/FileUtils.vala
    Utils/TimeUtils.vala
    Utils/String.vala
    Utils/Numeric.vala
    Utils/UI.vala
    Utils/CompareFunctionHolder.vala
    Utils/Utils.vala
    Utils/Threads.vala
)

set(CORE_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS})

vala_precompile(
    CORE_VALA_C
        ${CORE_SOURCE}
    PACKAGES
        ${CORE_PACKAGES}
    OPTIONS
        ${CORE_VALAC_OPTIONS}
    GENERATE_VAPI
        ${CORE_LIBRARY_NAME}
    GENERATE_HEADER
        ${CORE_LIBRARY_NAME}
)

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
add_library(${CORE_LIBRARY_NAME} SHARED ${CORE_VALA_C})

set_target_properties(${CORE_LIBRARY_NAME} PROPERTIES
    VERSION ${CORE_LIB_VERSION}
    SOVERSION ${CORE_LIB_SOVERSION}
)

target_link_libraries(${CORE_LIBRARY_NAME} ${DEPS_LIBRARIES})

install (TARGETS ${CORE_LIBRARY_NAME} DESTINATION lib)
