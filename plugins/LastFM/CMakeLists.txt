find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)
set(DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR "${CMAKE_INSTALL_PREFIX}/share/noise")
set(GETTEXT_PACKAGE "noise")
set(RELEASE_NAME "Luna")
set(VERSION "1.0")
set(VERSION_INFO "Pre-Release")
configure_file(${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${NORMAL_LINK_DIRS})
vala_precompile(VALA_C
        LastFM.vala
        Core.vala
        Settings.vala
        AlbumInfo.vala
        Image.vala
        Icons.vala
        Tag.vala
        TrackInfo.vala
        ArtistInfo.vala
        SimilarMedia.vala
        SimilarMediaView.vala
        SimilarMediaWidget.vala
        SimilarViewWrapper.vala
    PACKAGES
        glib-2.0
        gtk+-3.0
        granite
        noise
        noise-core
        libxml-2.0
        json-glib-1.0
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
add_library(lastfm MODULE ${VALA_C})

target_link_libraries (lastfm ${NORMAL_LIBRARIES})
install(TARGETS lastfm DESTINATION ${PLUGIN_DIR}/LastFM/)
install(FILES lastfm.plugin DESTINATION ${PLUGIN_DIR}/LastFM/)
add_dependencies(lastfm noise)

add_subdirectory(schemas)