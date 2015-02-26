set (CORE_LIB_VERSION 0.1)
set (CORE_LIB_SOVERSION 0)

######################
# lib PC file
######################
set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$") # You hear that? It's kittens being killed by the gods of cmake

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CONFIG_FILE})
configure_file (${CMAKE_SOURCE_DIR}/core/${CORE_LIBRARY_NAME}.pc.cmake ${CMAKE_BINARY_DIR}/core/${CORE_LIBRARY_NAME}.pc)

message (${CONFIG_FILE})

set (CORE_SOURCE
  ${CONFIG_FILE}
  PluginManager.vala
  Settings.vala
  EqualizerPreset.vala
  Player.vala
  LibraryWindowInterface.vala
  Library.vala
  LibrariesManager.vala
  NotificationManager.vala
  Media.vala
  Album.vala
  Resources.vala
  Devices/Device.vala
  Devices/NetworkDevice.vala
  Devices/DeviceManager.vala
  Devices/DevicePreferences.vala
  Playlists/Playlist.vala
  Playlists/StaticPlaylist.vala
  Playlists/SmartPlaylist.vala
  Playlists/SmartQuery.vala
  Utils/FileUtils.vala
  Utils/TimeUtils.vala
  Utils/String.vala
  Utils/Numeric.vala
  Utils/UI.vala
  Utils/CompareFunctionHolder.vala
  Utils/Utils.vala
  Utils/PlaylistsUtils.vala
  Utils/Icon.vala
  Utils/Icons.vala
  Utils/Search.vala
  Utils/PixbufUtils.vala
  Utils/PixbufCache.vala
  GStreamer/Pipeline.vala
  GStreamer/Equalizer.vala
  GStreamer/Playback.vala
  Widgets/SettingsWidgets.vala
)

if  (BUILD_SHARED_LIBS)
  set (LINK_MODE SHARED)
else ()
  set (LINK_MODE STATIC)
endif ()

vala_precompile (CORE_VALA_C ${CORE_LIBRARY_NAME}
  ${CORE_SOURCE}
  PACKAGES
  ${CORE_PACKAGES}
  OPTIONS
  ${BASIC_VALAC_OPTIONS}
  GENERATE_VAPI
  ${CORE_LIBRARY_NAME}
  GENERATE_HEADER
  ${CORE_LIBRARY_NAME}
)

add_definitions (${CORE_DEPS_CFLAGS})
link_directories (${CORE_DEPS_LIBRARY_DIRS})

add_library (${CORE_LIBRARY_NAME} ${LINK_MODE} ${CORE_VALA_C})

set_target_properties (${CORE_LIBRARY_NAME} PROPERTIES
  OUTPUT_NAME ${CORE_LIBRARY_NAME}
  VERSION ${CORE_LIB_VERSION}
  SOVERSION ${CORE_LIB_SOVERSION}
)

target_link_libraries (${CORE_LIBRARY_NAME} ${CORE_DEPS_LIBRARIES})

if (BUILD_SHARED_LIBS)
  install (TARGETS ${CORE_LIBRARY_NAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
  # Install lib stuffs
  install (FILES ${CMAKE_BINARY_DIR}/core/${CORE_LIBRARY_NAME}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CORE_LIBRARY_NAME}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${CORE_LIBRARY_NAME}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CORE_LIBRARY_NAME}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${CORE_LIBRARY_NAME}/)
endif ()

add_subdirectory (tests)

