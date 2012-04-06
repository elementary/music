add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
vala_precompile(VALA_C
        Podcasts.vala
    PACKAGES
        granite
        noise
        noise-core
        libxml-2.0
        gee-1.0
        gstreamer-0.10
        libnotify
        libgpod-1.0
        gstreamer-interfaces-0.10
        gstreamer-pbutils-0.10
        gstreamer-cdda-0.10
        libpeas-1.0
        libsoup-2.4
    OPTIONS
        --vapidir=${CMAKE_SOURCE_DIR}/vapi
        --vapidir=${CMAKE_BINARY_DIR}/core/
        --vapidir=${CMAKE_BINARY_DIR}/src/
    )
add_library(noise-podcasts MODULE ${VALA_C})

target_link_libraries (noise-podcasts ${NORMAL_LIBRARIES})
install(TARGETS noise-podcasts DESTINATION lib/noise/plugins/podcasts/)
install(FILES podcasts.plugin DESTINATION lib/noise/plugins/podcasts/)
add_dependencies(noise-podcasts noise)
