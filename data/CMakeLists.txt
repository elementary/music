include (Translations)

# We need to create two temporary desktop files in order to have all translations available.
set (APP_NAME "Music")
configure_file(noise.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/noise.desktop.in)
set (APP_NAME "Noise")
configure_file(noise.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/noise-original.desktop.in)
if (BUILD_FOR_ELEMENTARY)
    configure_file_translation(${CMAKE_CURRENT_BINARY_DIR}/noise.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/noise.desktop ${CMAKE_SOURCE_DIR}/po/)
else ()
    configure_file_translation(${CMAKE_CURRENT_BINARY_DIR}/noise-original.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/noise.desktop ${CMAKE_SOURCE_DIR}/po/)
endif ()

configure_file_translation(${CMAKE_CURRENT_SOURCE_DIR}/noise.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/noise.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/noise.appdata.xml DESTINATION share/appdata)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/noise.desktop DESTINATION share/applications)
