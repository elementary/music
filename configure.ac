#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.54])

dnl ===========================================================================

m4_define(glib_minver,                 2.28.0)
#m4_define(gnome_desktop_minver,        2.91.0)
#m4_define(pango_minver,                1.1.2)
#m4_define(gtk_minver,                  3.0.3)
#m4_define(xml_minver,                  2.4.7)
#m4_define(appindicator_minver,         0.0.2)

AC_INIT([beatbox], [0.1], [https://launchpad.net/marlin])

dnl ===========================================================================

AC_CONFIG_SRCDIR([src])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

GLIB_GSETTINGS

AM_INIT_AUTOMAKE([1.9 tar-ustar])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AM_MAINTAINER_MODE
AM_PROG_VALAC([0.11.5])
AS_IF([test -z "$VALAC"], [AC_MSG_ERROR(["No valac compiler found."])])

AC_SUBST([ACLOCAL_AMFLAGS], ["\${ACLOCAL_FLAGS}"])

AC_SUBST(GLIB_REQUIRED, [glib_minver])
#AC_SUBST(GNOME_DESKTOP_REQUIRED, [gnome_desktop_minver])
#AC_SUBST(PANGO_REQUIRED, [pango_minver])
#AC_SUBST(GTK_REQUIRED, [gtk_minver])
#AC_SUBST(XML_REQUIRED, [xml_minver])

# Checks for programs.
AC_C_BIGENDIAN
AC_C_CONST
AC_PROG_CC
AM_PROG_CC_C_O
AC_HEADER_STDC
AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AM_DISABLE_STATIC
AC_LIBTOOL_WIN32_DLL
AM_PROG_LIBTOOL
AC_PATH_PROG(PKG_CONFIG, pkg-config, no)

# Checks for libraries.
#AC_CHECK_LIB(m, floor)

#	gthread-2.0
#   pango			>= pango_minver

PKG_CHECK_MODULES(ALL, [
	gtk+-2.0		>= 2.16.0
	glib-2.0		>= glib_minver
	gio-2.0	
	gee-1.0	
	gstreamer-0.10	>= 0.10
	sqlheavy-0.1
	webkit-1.0		>= 1.2.5
	libxml-2.0		>= 2.7.7
	gconf-2.0		>= 2.31.91
	unique-1.0
	libnotify
])
dnl ===========================================================================

GETTEXT_PACKAGE=beatbox
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",
                   [the gettext translation domain])

AM_GLIB_GNU_GETTEXT
GLIB_DEFINE_LOCALEDIR(GNOMELOCALEDIR)

IT_PROG_INTLTOOL([0.40.1])

dnl ===========================================================================

# Checks for header files.
AC_CHECK_HEADERS([float.h stdlib.h string.h])

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.
AC_CHECK_FUNCS([strrchr])

dnl ==========================================================================

#AC_PATH_PROG(GLIB_GENMARSHAL, glib-genmarshal)

dnl ==========================================================================

dnl Turn on the additional warnings last, so -Werror doesn't affect other tests.

AC_ARG_ENABLE(more-warnings,
AC_HELP_STRING([--enable-more-warnings], [Maximum compiler warnings]),
set_more_warnings="$enableval",[
if test -f $srcdir/CVSVERSION; then
	is_cvs_version=true
	set_more_warnings=yes
else
	set_more_warnings=no
fi
])
AC_MSG_CHECKING(for more warnings, including -Werror)
if test "$GCC" = "yes" -a "$set_more_warnings" != "no"; then
	AC_MSG_RESULT(yes)
	WARNING_CFLAGS="\
	-Wall \
	-Wmissing-declarations -Wmissing-prototypes \
	-Wnested-externs -Wpointer-arith \
	-Wcast-align \
	-Werror"

	for option in -Wstrict-aliasing=0 -Wno-pointer-sign; do
		SAVE_CFLAGS="$CFLAGS"
		CFLAGS="$CFLAGS $option"
		AC_MSG_CHECKING([whether gcc understands $option])
		AC_TRY_COMPILE([], [],
			has_option=yes,
			has_option=no,)
		if test $has_option = yes; then
		   	WARNING_CFLAGS="$WARNING_CFLAGS $option"
		fi
		AC_MSG_RESULT($has_option)
		CFLAGS="$SAVE_CFLAGS"
		unset has_option
		unset SAVE_CFLAGS
	done
	unset option
else
	AC_MSG_RESULT(no)
fi

dnl ===========================================================================
dnl AS_AC_EXPAND(DATADIR, $datadir)

dnl DBUS_SERVICES_DIR="$DATADIR/dbus-1/services"
dnl AC_SUBST(DBUS_SERVICES_DIR)
dnl AC_DEFINE_UNQUOTED(DBUS_SERVICES_DIR, "$DBUS_SERVICES_DIR", [Where services dir for DBUS is])

dnl look for dbus service dir
DBUSSERVICEDIR=`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`
AC_ARG_WITH([dbus-services],
        AC_HELP_STRING([--with-dbus-services=DBUS_SERVICES],
        [specify a directory to store dbus service files.]),
    [
                DBUSSERVICEDIR=$withval
    ]
)
AC_SUBST(DBUSSERVICEDIR)

dnl ===========================================================================

dnl core beatbox
CORE_MODULES="glib-2.0 gio-2.0 gtk+-2.0 gee-1.0 gstreamer-0.10 taglib_c sqlheavy-0.1 webkit-1.0 libxml-2.0 gconf-2.0 libnotify unique-1.0"
CORE_CFLAGS="`$PKG_CONFIG --cflags $CORE_MODULES` $x_cflags $WARNING_CFLAGS"
AC_SUBST(CORE_CFLAGS)
CORE_LIBS="`$PKG_CONFIG --libs $CORE_MODULES` $x_libs"
AC_SUBST(CORE_LIBS)

DISABLE_DEPRECATED_CFLAGS="-DG_DISABLE_DEPRECATED -DGTK_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED"
AC_SUBST(DISABLE_DEPRECATED_CFLAGS)

dnl Multimedia keys
AC_CHECK_HEADERS([X11/XF86keysym.h])

dnl ==========================================================================

AC_CONFIG_FILES([
Makefile
src/Makefile
images/Makefile
data/Makefile
po/Makefile.in
])
AC_OUTPUT

dnl ==========================================================================
echo "
beatbox-$VERSION:

	prefix:                 ${prefix}
	source code location:	${srcdir}
	compiler:               ${CC}
"
