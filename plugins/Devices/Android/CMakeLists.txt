add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
vala_precompile(VALA_C
        Android.vala
        AndroidDevice.vala
        AndroidDeviceManager.vala
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
        peas-gtk
        libpeas-1.0
        libsoup-2.4
    OPTIONS
        --target-glib=2.32
        --vapidir=${CMAKE_SOURCE_DIR}/vapi
        --vapidir=${CMAKE_BINARY_DIR}/core/
        --vapidir=${CMAKE_BINARY_DIR}/src/
    )
add_library(android-device MODULE ${VALA_C})

target_link_libraries (android-device ${NORMAL_LIBRARIES})
install(TARGETS android-device DESTINATION ${PLUGIN_DIR}/Android-Device/)
install(FILES android-device.plugin DESTINATION ${PLUGIN_DIR}/Android-Device/)
add_dependencies(android-device noise)
