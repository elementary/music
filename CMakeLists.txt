# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required(VERSION 2.6)
cmake_policy(VERSION 2.6)
project(noise)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(PkgConfig)
pkg_check_modules(DEPS
    REQUIRED
    glib-2.0
    gtk+-3.0
    gdk-x11-3.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-cdda-0.10
    taglib_c
    gio-2.0
    libxml-2.0
    libnotify # FIXME should be a soft dependency
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    libpeas-gtk-1.0
    libpeas-1.0)

# Check if we have sqlheavy-0.2
pkg_check_modules(SQLHEAVY2 sqlheavy-0.2)
if(${SQLHEAVY2_FOUND})
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.2)
    message("-- Will use sqlheavy-0.2")
    set(SQLHEAVY_CFLAGS ${SQLHEAVY2_CFLAGS})
    set(SQLHEAVY_LIBRARY_DIRS ${SQLHEAVY2_LIBRARY_DIRS})
    set(SQLHEAVY_LIBRARIES ${SQLHEAVY2_LIBRARIES})
else()
    pkg_check_modules(SQLHEAVY REQUIRED sqlheavy-0.1)
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.1)
    message("-- Will use sqlheavy-0.1")
endif()


set(NORMAL_CFLAGS ${DEPS_CFLAGS} ${SQLHEAVY_CFLAGS})
set(NORMAL_LIBRARIES ${DEPS_LIBRARIES} ${SQLHEAVY_LIBRARIES})
set(NORMAL_LINK_DIRS ${DEPS_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS})


find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)

set(DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR "${CMAKE_INSTALL_PREFIX}/share/noise")
set(GETTEXT_PACKAGE "noise")
set(RELEASE_NAME "Luna-Beta-1")
set(VERSION "1.0")
set(VERSION_INFO "Pre-Release")
set(PLUGIN_DIR "${CMAKE_INSTALL_PREFIX}/lib/noise/plugins")
set(ICON_DIR "${CMAKE_INSTALL_PREFIX}/share/noise/icons")
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory(core)
add_subdirectory(src)
add_subdirectory(data)
add_subdirectory(schemas)
add_subdirectory(po)

option(BUILD_PLUGINS "Whether to build plugins or not." ON)
if(BUILD_PLUGINS)
    message("-- Plugins will be built")
    add_subdirectory(plugins)
else()
    message("-- Plugins will NOT be built")
endif()

add_subdirectory(images)
