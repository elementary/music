include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../core
    ../src
    ../plugins
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/noise.desktop.in
        ${CMAKE_BINARY_DIR}/data/noise-original.desktop.in
    APPDATA_FILES
        ../data/io.elementary.noise.appdata.xml.in)
