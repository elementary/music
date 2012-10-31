add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    AUDIOPLAYER_VALA_C
        AudioPlayer.vala
        AudioPlayerDevice.vala
        AudioPlayerDeviceManager.vala
    PACKAGES
        ${DEPS_PACKAGES}
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(audioplayer-device MODULE ${AUDIOPLAYER_VALA_C})

target_link_libraries (audioplayer-device ${DEPS_LIBRARIES})
install(TARGETS audioplayer-device DESTINATION ${PLUGIN_DIR}/AudioPlayer-Device/)
install(FILES audioplayer-device.plugin DESTINATION ${PLUGIN_DIR}/AudioPlayer-Device/)
add_dependencies(audioplayer-device ${SRC_TARGET})
