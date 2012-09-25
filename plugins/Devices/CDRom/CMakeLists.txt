pkg_check_modules(CD_DEPS gstreamer-cdda-0.10)

if (CD_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${CD_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CD_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${CD_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

vala_precompile(
    CDROM_VALA_C
        CDRom.vala
        CDRomDevice.vala
        CDRomDeviceManager.vala
        CDDA.vala
        CDRipper.vala
    PACKAGES
        ${DEPS_PACKAGES}
        gstreamer-cdda-0.10
    OPTIONS
        ${GLOBAL_VALAC_OPTIONS}
)

add_library(cdrom-device MODULE ${CDROM_VALA_C})
target_link_libraries(cdrom-device ${DEPS_LIBRARIES})
add_dependencies(cdrom-device ${SRC_TARGET})

install(TARGETS cdrom-device DESTINATION ${PLUGIN_DIR}/CDRom-Device/)
install(FILES cdrom-device.plugin DESTINATION ${PLUGIN_DIR}/CDRom-Device/)

else ()

message("-- CD-Rom device plugin disabled")

endif ()
