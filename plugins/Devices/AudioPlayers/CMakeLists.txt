add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME audioplayer-device)

vala_precompile(AUDIOPLAYER_VALA_C ${TARGET_NAME}
    AudioPlayer.vala
    AudioPlayerDevice.vala
    AudioPlayerDeviceManager.vala
    AudioPlayerLibrary.vala
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${AUDIOPLAYER_VALA_C})

target_link_libraries (${TARGET_NAME} ${DEPS_LIBRARIES})
install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/AudioPlayer-Device/)
install(FILES audioplayer-device.plugin DESTINATION ${PLUGIN_DIR}/AudioPlayer-Device/)
add_dependencies(${TARGET_NAME} ${SRC_TARGET})
