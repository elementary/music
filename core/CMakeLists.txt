set(CORE_LIB_VERSION 0.1)
set(CORE_LIB_SOVERSION 0)

set(CORE_SOURCE
    PluginManager.vala
    Settings.vala
    EqualizerPreset.vala
    Player.vala
    LibraryWindowInterface.vala
    Media.vala
    Album.vala
    main.vala
    Utils/FileUtils.vala
    Utils/TimeUtils.vala
    Utils/String.vala
    Utils/Numeric.vala
    Utils/UI.vala
    Utils/CompareFunctionHolder.vala
    Utils/Utils.vala
    Utils/Threads.vala
)

if (BUILD_SHARED_LIBS)
    set(LINK_MODE SHARED)
else ()
    set(LINK_MODE STATIC)
endif ()

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

add_definitions(${CORE_DEPS_CFLAGS})
link_directories(${CORE_DEPS_LIBRARY_DIRS})

add_library(${CORE_LIBRARY_NAME} ${LINK_MODE} ${CORE_VALA_C})

set_target_properties(${CORE_LIBRARY_NAME} PROPERTIES
    OUTPUT_NAME ${CORE_LIBRARY_NAME}
    VERSION ${CORE_LIB_VERSION}
    SOVERSION ${CORE_LIB_SOVERSION}
)

target_link_libraries(${CORE_LIBRARY_NAME} ${CORE_DEPS_LIBRARIES})

if (BUILD_SHARED_LIBS)
    install(TARGETS ${CORE_LIBRARY_NAME} DESTINATION lib)
endif ()

