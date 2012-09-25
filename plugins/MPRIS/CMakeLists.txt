pkg_check_modules(MPRIS_DEPS dbusmenu-glib-0.4 indicate-0.7)

if (MPRIS_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${MPRIS_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${MPRIS_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${MPRIS_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    MPRIS_VALA_C
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

add_library(mpris MODULE ${MPRIS_VALA_C})
target_link_libraries(mpris ${DEPS_LIBRARIES})
install(TARGETS mpris DESTINATION ${PLUGIN_DIR}/MPRIS/)
install(FILES mpris.plugin DESTINATION ${PLUGIN_DIR}/MPRIS/)
add_dependencies(mpris noise)

else ()

message("-- MPRIS plugin disabled")

endif ()
