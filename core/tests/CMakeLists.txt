configure_file (config.vala.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
vala_precompile (CORE_VALA_C ${CORE_LIBRARY_NAME}_tests
  Tests.vala
  ${CMAKE_CURRENT_BINARY_DIR}/config.vala
  PACKAGES
  ${CORE_PACKAGES}
  ${CORE_LIBRARY_NAME}
  OPTIONS
  ${BASIC_VALAC_OPTIONS}
  --vapidir=${CMAKE_CURRENT_BINARY_DIR}/../
)

add_executable (${CORE_LIBRARY_NAME}_tests
    ${CORE_VALA_C})

add_definitions (${CORE_DEPS_CFLAGS})
link_directories (${CORE_DEPS_LIBRARY_DIRS})


target_link_libraries (${CORE_LIBRARY_NAME}_tests ${CORE_DEPS_LIBRARIES})
target_link_libraries (${CORE_LIBRARY_NAME}_tests ${CORE_LIBRARY_NAME})
