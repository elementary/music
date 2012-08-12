
# XXX TODO: set C and library flags, or it won't compile

pkg_check_modules(GUPNP gupnp-1.0)
if(${GUPNP_FOUND})
set(ADD_PKG ${ADD_PKG}
        gupnp-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS})
message("-- UPnP Plugin enabled")
else()
message("-- UPnP Plugin disabled")
set(GUPNP_FOUND 0)
endif()

# TODO: move to the corresponding plugin
pkg_check_modules(GUPNP_AV gupnp-av-1.0)
if(${GUPNP_AV_FOUND})
set(ADD_PKG ${ADD_PKG}
        gupnp-av-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS})
message("-- UPnP Plugin enabled")
else()
message("-- UPnP Plugin disabled")
set(GUPNP_AV_FOUND 0)
endif()

add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
vala_precompile(VALA_C
        UPnP.vala
        UPnPDevice.vala
        UPnPDeviceManager.vala
    PACKAGES
        glib-2.0
        gtk+-3.0
        granite
        noise
        noise-core
        libxml-2.0
        gee-1.0
        gio-unix-2.0
        gstreamer-0.10
        libnotify
        libgpod-1.0
        gstreamer-interfaces-0.10
        gstreamer-pbutils-0.10
        gstreamer-cdda-0.10
        PeasGtk-1.0
        libpeas-1.0
        libsoup-2.4
        gupnp-1.0
        gupnp-av-1.0
        gssdp-1.0
    OPTIONS
        --target-glib=2.32
        --vapidir=${CMAKE_SOURCE_DIR}/vapi
        --vapidir=${CMAKE_BINARY_DIR}/core/
        --vapidir=${CMAKE_BINARY_DIR}/src/
    )
add_library(upnp MODULE ${VALA_C})
add_definitions(${NORMAL_CFLAGS})
link_directories(${NORMAL_LINK_DIRS})
target_link_libraries (upnp ${NORMAL_LIBRARIES})
install(TARGETS upnp DESTINATION ${PLUGIN_DIR}/UPnP/)
install(FILES upnp.plugin DESTINATION ${PLUGIN_DIR}/UPnP/)
add_dependencies(upnp noise)
