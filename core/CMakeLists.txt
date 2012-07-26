add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

vala_precompile(VALA_C
    PluginManager.vala
    Settings.vala
    EqualizerPreset.vala
    LibraryWindowInterface.vala
    Media.vala
    Utils/TimeUtils.vala
    Utils/String.vala
    Utils/Numeric.vala
    Utils/CompareFunctionHolder.vala

PACKAGES
    gtk+-3.0
    libpeas-1.0
    peas-gtk
    gee-1.0
    granite
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    GENERATE_VAPI
    noise-core
    GENERATE_HEADER
    noise-core
)
add_definitions(${DEPS_CFLAGS})
link_directories(${LIB_PATHS})
add_library(noise-core SHARED ${VALA_C})
target_link_libraries(noise-core ${DEPS_LIBRARIES})
install (TARGETS noise-core DESTINATION lib)
