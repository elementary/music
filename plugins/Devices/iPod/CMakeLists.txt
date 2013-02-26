pkg_check_modules(GPOD libgpod-1.0)

if (GPOD_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${GPOD_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${GPOD_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${GPOD_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME ipod-device)
vala_precompile(IPOD_VALA_C ${TARGET_NAME}
    iPod.vala
    iPodLibrary.vala
    iPodDevice.vala
    iPodDeviceManager.vala
    iPodStreamer.vala
    iPodMediaHelper.vala
    iPodPlaylistHelper.vala
PACKAGES
    ${DEPS_PACKAGES}
    libgpod-1.0
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_library(${TARGET_NAME} MODULE ${IPOD_VALA_C})

target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/iPod-Device/)
install(FILES ipod-device.plugin DESTINATION ${PLUGIN_DIR}/iPod-Device/)
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

else ()

message("-- iPod plugin disabled")

endif ()
