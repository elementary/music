pkg_check_modules(LASTFM_DEPS json-glib-1.0 libsoup-2.4 libaccounts-glib libgsignon-glib)

if (LASTFM_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${LASTFM_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${LASTFM_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${LASTFM_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME lastfm)
vala_precompile(LAST_FM_VALA_C ${TARGET_NAME}
    LastFM.vala
    Core.vala
    Tag.vala
    SimilarMedia.vala
    SimilarMediaView.vala
PACKAGES
    ${DEPS_PACKAGES}
    json-glib-1.0
    libsoup-2.4
    libaccounts-glib
    libgsignon-glib
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${LAST_FM_VALA_C})

target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/LastFM/)
install(FILES lastfm.plugin DESTINATION ${PLUGIN_DIR}/LastFM/)
install(FILES noise-lastfm.application DESTINATION ${CMAKE_INSTALL_PREFIX}/share/accounts/applications/)

else ()

message("-- Last.fm plugin disabled")

endif ()
