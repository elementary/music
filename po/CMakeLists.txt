include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../core
    ../src
    ../plugins
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/io.elementary.music.desktop
    APPDATA_FILES
        ../data/io.elementary.music.appdata.xml.in)
