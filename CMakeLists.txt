# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required(VERSION 2.6)
cmake_policy(VERSION 2.6)
project(noise)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set(GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set(RELEASE_NAME "Luna-Beta-1")
set(VERSION "1.0")
set(VERSION_INFO "Pre-Release")

set(DATADIR ${CMAKE_INSTALL_PREFIX}/share)
set(PKG_DATADIR ${DATADIR}/${CMAKE_PROJECT_NAME})
set(ICON_DIR ${DATADIR}/${CMAKE_PROJECT_NAME}/icons)
set(PLUGIN_DIR ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_PROJECT_NAME}/plugins)

add_definitions("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")

set(SRC_TARGET ${CMAKE_PROJECT_NAME})
set(CORE_LIBRARY_NAME ${SRC_TARGET}-core)

set(CORE_PACKAGES
    glib-2.0
    gio-2.0
    gee-1.0
    libpeas-1.0
    libpeas-gtk-1.0
    gtk+-3.0
    granite
)

set(DEPS_PACKAGES
    ${CORE_LIBRARY_NAME}
    ${CORE_PACKAGES}
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-tag-0.10
    taglib_c
)


find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
    glib-2.0>=2.32
    gio-2.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-tag-0.10
    gstreamer-pbutils-0.10
    taglib_c
    gtk+-3.0>=3.4.2
    granite
    libpeas-gtk-1.0
    libpeas-1.0
)

#
# SQLHeavy: Use version 0.2 if it is available; otherwise, fall back to 0.1
#
pkg_check_modules(SQLHEAVY2 QUIET sqlheavy-0.2)
if (SQLHEAVY2_FOUND)
    message("-- Will use sqlheavy-0.2")
    set(DEPS_PACKAGES ${DEPS_PACKAGES} sqlheavy-0.2)
    set(SQLHEAVY_CFLAGS ${SQLHEAVY2_CFLAGS})
    set(SQLHEAVY_LIBRARY_DIRS ${SQLHEAVY2_LIBRARY_DIRS})
    set(SQLHEAVY_LIBRARIES ${SQLHEAVY2_LIBRARIES})
else ()
    message("-- Will use sqlheavy-0.1")
    pkg_check_modules(SQLHEAVY REQUIRED sqlheavy-0.1)
    set(DEPS_PACKAGES ${DEPS_PACKAGES} sqlheavy-0.1)
endif ()

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${SQLHEAVY_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${SQLHEAVY_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS})

#
# Libnotify
#
pkg_check_modules(LIBNOTIFY QUIET libnotify)
if (LIBNOTIFY_FOUND)
    message("-- libnotify enabled")

    set(GLOBAL_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS} --define=HAVE_LIBNOTIFY)

    set(DEPS_PACKAGES ${DEPS_PACKAGES} libnotify)

    set(DEPS_CFLAGS ${DEPS_CFLAGS} ${LIBNOTIFY_CFLAGS})
    set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${LIBNOTIFY_LIBRARIES})
    set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${LIBNOTIFY_LIBRARY_DIRS})
else ()
    message("-- libnotify disabled")
endif ()


find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)

set(GLOBAL_VALAC_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/core
    --vapidir=${CMAKE_BINARY_DIR}/src
    --target-glib=2.32
    --thread
)

add_subdirectory(schemas)

add_subdirectory(core)

set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CORE_LIBRARY_NAME})
add_subdirectory(src)

set(DEPS_PACKAGES ${DEPS_PACKAGES} ${SRC_TARGET})
add_subdirectory(plugins)

add_subdirectory(po)
add_subdirectory(data)
add_subdirectory(images)
