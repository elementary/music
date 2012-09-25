pkg_check_modules(GUPNP gupnp-1.0 gupnp-av-1.0 gssdp-1.0)

if (GUPNP_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${GUPNP_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${GUPNP_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${GUPNP_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    VALA_C
        UPnP.vala
        UPnPDevice.vala
        UPnPDeviceManager.vala
    PACKAGES
        ${DEPS_PACKAGES}
        gupnp-1.0
        gupnp-av-1.0
        gssdp-1.0
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(upnp MODULE ${VALA_C})
target_link_libraries (upnp ${DEPS_LIBRARIES})
add_dependencies(upnp ${SRC_TARGET})

install(TARGETS upnp DESTINATION ${PLUGIN_DIR}/UPnP/)
install(FILES upnp.plugin DESTINATION ${PLUGIN_DIR}/UPnP/)

else ()

message("-- UPnP plugin disabled")

endif ()
