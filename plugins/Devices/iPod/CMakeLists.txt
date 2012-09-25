pkg_check_modules(GPOD libgpod-1.0)

if (GPOD_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${GPOD_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${GPOD_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${GPOD_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    IPOD_VALA_C
        iPod.vala
        iPodDevice.vala
        iPodDeviceManager.vala
        iPodMediaHelper.vala
        iPodPlaylistHelper.vala
    PACKAGES
        ${DEPS_PACKAGES}
        libgpod-1.0
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(ipod-device MODULE ${IPOD_VALA_C})

target_link_libraries (ipod-device ${DEPS_LIBRARIES})
install(TARGETS ipod-device DESTINATION ${PLUGIN_DIR}/iPod-Device/)
install(FILES ipod-device.plugin DESTINATION ${PLUGIN_DIR}/iPod-Device/)
add_dependencies(ipod-device ${SRC_TARGET})

else ()

message("-- iPod plugin disabled")

endif ()
