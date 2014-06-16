option (BUILD_PLUGINS "Whether to build plugins or not." ON)

if (BUILD_PLUGINS AND BUILD_SHARED_LIBS)
  message("-- Plugins enabled")

  # Currently, plugins also depend on the code located at src. This will change in the
  # future, in order to allow external plugins (plugins will only have access to the core
  # library).
  set (DEPS_PACKAGES ${DEPS_PACKAGES} ${SRC_TARGET})
  include_directories (${CMAKE_BINARY_DIR}/src)

  add_subdirectory (Devices)
  add_subdirectory (LastFM)
  add_subdirectory (MPRIS)
  add_subdirectory (Zeitgeist)
else ()
  message ("-- Plugins disabled")
endif ()
