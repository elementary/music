# check http://elementaryos.org/docs/developer-guide/cmake/simple-project

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)
project(noise)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

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
    taglib_c #TODO: remove
    gio-2.0
    libxml-2.0
    libnotify
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
    set (SQLHEAVY_CFLAGS ${SQLHEAVY2_CFLAGS})
    set (SQLHEAVY_LIBRARY_DIRS ${SQLHEAVY2_LIBRARY_DIRS})
    set (SQLHEAVY_LIBRARIES ${SQLHEAVY2_LIBRARIES})
else()
    pkg_check_modules (SQLHEAVY REQUIRED sqlheavy-0.1)
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.1)
    message("-- Will use sqlheavy-0.1")
endif()


pkg_check_modules(DBUS_MENU dbusmenu-glib-0.4)
if(${DBUS_MENU_FOUND})
set(ADD_PKG ${ADD_PKG}
        Dbusmenu-0.4)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_DBUSMENU)
message("-- DBus Menu enabled")
else()
message("-- DBus Menu disabled")
endif()

pkg_check_modules(GUPNP gupnp-1.0)
if(${GUPNP_FOUND})
set(ADD_PKG ${ADD_PKG}
        gupnp-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS})
message("-- UPnP Plugin enabled")
else()
message("-- UPnP Plugin disabled")
set(GUPNP_FOUND 0)
endif()

pkg_check_modules(GUPNP_AV gupnp-av-1.0)
if(${GUPNP_AV_FOUND})
set(ADD_PKG ${ADD_PKG}
        gupnp-av-1.0)
set(ADD_OPTIONS ${ADD_OPTIONS})
message("-- UPnP Plugin enabled")
else()
message("-- UPnP Plugin disabled")
set(GUPNP_AV_FOUND 0)
endif()

pkg_check_modules(INDICATE indicate-0.7)
if(${INDICATE_FOUND})
set(ADD_PKG ${ADD_PKG}
        Indicate-0.7)
set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_INDICATE)
message("-- Indicate enabled")
else()
message("-- Indicate disabled")
endif()

set (NORMAL_CFLAGS ${DEPS_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS} ${GUPNP_CFLAGS} ${GUPNP_AV_CFLAGS})
set (NORMAL_LIBRARIES ${DEPS_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES} ${GUPNP_LIBRARIES} ${GUPNP_AV_LIBRARIES})
set (NORMAL_LINK_DIRS ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${GUPNP_LIBRARY_DIRS} ${GUPNP_AV_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})

set(PLUGIN_DIR "${CMAKE_INSTALL_PREFIX}/lib/noise/plugins")
set(ICON_DIR "${CMAKE_INSTALL_PREFIX}/share/noise/icons/hicolor")

add_subdirectory(src)
add_subdirectory(vapi)
add_subdirectory(core)
add_subdirectory(data)
add_subdirectory(schemas)

option (BUILD_PLUGINS "Whether to build plugins or not." ON)
if (BUILD_PLUGINS)
    message("-- Plugins will be built")
    add_subdirectory(plugins)
else()
    message("-- Plugins will NOT be built")
endif ()

add_subdirectory(po)
add_subdirectory(images)
