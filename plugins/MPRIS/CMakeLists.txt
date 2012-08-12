pkg_check_modules (MPRIS_DEPS REQUIRED dbusmenu-glib-0.4 indicate-0.7)

set (NORMAL_CFLAGS ${NORMAL_CFLAGS} ${MPRIS_DEPS_CFLAGS})
set (NORMAL_LIBRARIES ${NORMAL_LIBRARIES} ${MPRIS_DEPS_LIBRARIES})
set (NORMAL_LINK_DIRS ${NORMAL_LINK_DIRS} ${MPRIS_DEPS_LIBRARY_DIRS})

vala_precompile(VALA_C
        Plugin.vala
        MPRIS.vala
        SoundMenuIntegration.vala
    PACKAGES
        glib-2.0
        Indicate-0.7
        Dbusmenu-0.4
        gtk+-3.0
        gio-2.0
        gio-unix-2.0
        granite
        gee-1.0
        gstreamer-0.10
        libnotify
        libpeas-1.0
        noise
        noise-core
        gstreamer-0.10
        gstreamer-interfaces-0.10
        gstreamer-pbutils-0.10
        gstreamer-cdda-0.10
    OPTIONS
        --vapidir=${CMAKE_SOURCE_DIR}/vapi
        --vapidir=${CMAKE_BINARY_DIR}/core/
        --vapidir=${CMAKE_BINARY_DIR}/src/
    )

add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
add_library (mpris MODULE ${VALA_C})
target_link_libraries (mpris ${NORMAL_LIBRARIES})
install(TARGETS mpris DESTINATION ${PLUGIN_DIR}/MPRIS/)
install(FILES mpris.plugin DESTINATION ${PLUGIN_DIR}/MPRIS/)
add_dependencies(mpris noise)
