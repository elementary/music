vala_precompile(VALA_C
    PluginManager.vala
PACKAGES
    gtk+-3.0
    libpeas-1.0
    peas-gtk
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
GENERATE_VAPI
    beatbox-core
GENERATE_HEADER
    beatbox-core
)
add_definitions(${DEPS_CFLAGS})
link_directories(${LIB_PATHS})
add_library(beatbox-core SHARED ${VALA_C})
target_link_libraries(beatbox-core ${DEPS_LIBRARIES})
