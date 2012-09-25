pkg_check_modules(LASTFM_DEPS libxml-2.0 json-glib-1.0 libsoup-2.4)

if (LASTFM_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${LASTFM_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${LASTFM_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${LASTFM_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core ${CMAKE_BINARY_DIR}/src)
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    LAST_FM_VALA_C
        LastFM.vala
        Core.vala
        Settings.vala
        AlbumInfo.vala
        Tag.vala
        TrackInfo.vala
        ArtistInfo.vala
        SimilarMedia.vala
        SimilarMediaView.vala
        SimilarMediaWidget.vala
        SimilarViewWrapper.vala
        PreferencesSection.vala
    PACKAGES
        ${DEPS_PACKAGES}
        libxml-2.0
        json-glib-1.0
        libsoup-2.4
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(lastfm MODULE ${LAST_FM_VALA_C})

target_link_libraries(lastfm ${DEPS_LIBRARIES})
install(TARGETS lastfm DESTINATION ${PLUGIN_DIR}/LastFM/)
install(FILES lastfm.plugin DESTINATION ${PLUGIN_DIR}/LastFM/)
add_dependencies(lastfm ${SRC_TARGET})

add_subdirectory(schemas)

else ()

message("-- Last.fm plugin disabled")

endif ()
