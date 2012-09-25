add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    ANDROID_VALA_C
        Android.vala
        AndroidDevice.vala
        AndroidDeviceManager.vala
    PACKAGES
        ${DEPS_PACKAGES}
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(android-device MODULE ${ANDROID_VALA_C})

target_link_libraries (android-device ${DEPS_LIBRARIES})
install(TARGETS android-device DESTINATION ${PLUGIN_DIR}/Android-Device/)
install(FILES android-device.plugin DESTINATION ${PLUGIN_DIR}/Android-Device/)
add_dependencies(android-device ${SRC_TARGET})
