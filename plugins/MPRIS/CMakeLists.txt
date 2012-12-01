pkg_check_modules(MPRIS_DEPS dbusmenu-glib-0.4 indicate-0.7)

if (MPRIS_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${MPRIS_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${MPRIS_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${MPRIS_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME mpris)
vala_precompile(MPRIS_VALA_C ${TARGET_NAME}
    Plugin.vala
    MPRIS.vala
    SoundMenuIntegration.vala
PACKAGES
    ${DEPS_PACKAGES}
    Indicate-0.7
    Dbusmenu-0.4
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${MPRIS_VALA_C})
target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/MPRIS/)
install(FILES mpris.plugin DESTINATION ${PLUGIN_DIR}/MPRIS/)
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

else ()

message("-- MPRIS plugin disabled")

endif ()
