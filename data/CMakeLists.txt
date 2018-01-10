include (GSettings)
add_schema ("io.elementary.music.gschema.xml")

include (Translations)

configure_file_translation(${CMAKE_CURRENT_BINARY_DIR}/io.elementary.music.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.music.desktop ${CMAKE_SOURCE_DIR}/po/)

configure_file_translation(${CMAKE_CURRENT_SOURCE_DIR}/io.elementary.music.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.music.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.music.appdata.xml DESTINATION share/metainfo)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.music.desktop DESTINATION share/applications)
