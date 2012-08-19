include(Translations)
add_translations_directory("noise")
add_translations_catalog(${GETTEXT_PACKAGE}
    ../src/
    ../core/
    ../plugins/
)
