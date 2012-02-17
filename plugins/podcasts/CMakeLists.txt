add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
vala_precompile(VALA_C
        Podcasts.vala
    PACKAGES
        granite
        beatbox
        beatbox-core
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
add_library(beatbox-podcasts MODULE ${VALA_C})

target_link_libraries (beatbox-podcasts ${NORMAL_LIBRARIES})
install(TARGETS beatbox-podcasts DESTINATION lib/beatbox/plugins/podcasts/)
install(FILES podcasts.plugin DESTINATION lib/beatbox/plugins/podcasts/)
add_dependencies(beatbox-podcasts beatbox)
