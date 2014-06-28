pkg_check_modules(ZEITGEIST_DEPS zeitgeist-2.0)

if (ZEITGEIST_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${ZEITGEIST_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${ZEITGEIST_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${ZEITGEIST_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME zeitgeist)
vala_precompile(ZEITGEIST_VALA_C ${TARGET_NAME}
    Zeitgeist.vala
PACKAGES
    ${DEPS_PACKAGES}
    zeitgeist-2.0
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${ZEITGEIST_VALA_C})

target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/Zeitgeist/)
install(FILES zeitgeist.plugin DESTINATION ${PLUGIN_DIR}/Zeitgeist/)

else ()

message("-- Zeitgeist plugin disabled")

endif ()