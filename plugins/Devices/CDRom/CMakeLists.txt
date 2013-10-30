add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME cdrom-device)
vala_precompile(CDROM_VALA_C ${TARGET_NAME}
    CDRom.vala
    CDRomDevice.vala
    CDRomDeviceManager.vala
    CDDA.vala
    CDRipper.vala
    CDPlayer.vala
    CDViewWrapper.vala
    CDView.vala
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${CDROM_VALA_C})
target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/CDRom-Device/)
install(FILES cdrom-device.plugin DESTINATION ${PLUGIN_DIR}/CDRom-Device/)
