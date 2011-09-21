#! /usr/bin/env python

#A waf build script for BeatBox. To build BeatBox run:
#'./waf configure'
#'./waf build'
#
# And to run simply:
#'./BeatBox'

import os
import sys
import Build
import Utils
import Task
import Node
from TaskGen import extension, feature

APPNAME = 'beatbox'
VERSION = '0.1'
VALAC_VERSION = '0.11.6'

out = 'build'

def options (opt):
	opt.tool_options('compiler_c')
	opt.tool_options('gnu_dirs')

def check_pkg (ctx, name, lib_name, version='', mandatory=True):
	ctx.check_cfg (package=name, uselib_store=lib_name, args='--cflags --libs', atleast_version=version, mandatory=mandatory)
	return ctx.env['HAVE_' + lib_name]

def configure(ctx):
	ctx.check_tool('compiler_cc gnu_dirs')
	
	ctx.check_tool('vala')
	if ctx.env['VALAC_VERSION'][1] < 12:
		if ctx.env['VALAC_VERSION'][1] < 11 or ctx.env['VALAC_VERSION'][2] < 6:
			print('valac >= 0.11.6 required')
			sys.exit(1)
         
	ctx.check_tool('gnu_dirs')
	check_pkg(ctx, 'gtk+-3.0', 'GTK', '3.0')
	#check_pkg(ctx, 'gdk-x11-2.0', 'GDK_X11', '2.0')
	check_pkg(ctx, 'gee-1.0', 'GEE', '0.5.3')
	check_pkg(ctx, 'gstreamer-0.10', 'GSTREAMER', '0.10')
	check_pkg(ctx, 'gstreamer-interfaces-0.10', 'GSTREAMER_INTERFACES', '0.10')
	check_pkg(ctx, 'gstreamer-pbutils-0.10', 'GSTREAMER_PBUTILS', '0.10')
	check_pkg(ctx, 'gstreamer-cdda-0.10', 'GSTREAMER_CDDA', '0.10')
	check_pkg(ctx, 'taglib_c', 'TAGLIB', '1.6.3')
	check_pkg(ctx, 'gio-2.0', 'GIO', '2.26.0')
	check_pkg(ctx, 'sqlheavy-0.1', 'SQLHEAVY', '0.0')
	check_pkg(ctx, 'libxml-2.0', 'LIBXML', '2.7.7')
	check_pkg(ctx, 'gconf-2.0', 'GCONF', '2.31.91')
	#check_pkg(ctx, 'libnotify4', 'LIBNOTIFY', '0.0.0')
	#check_pkg(ctx, 'unique-1.0', 'UNIQUE', '0.9')
	check_pkg(ctx, 'libsoup-2.4', 'SOUP', '2.25.2')
	check_pkg(ctx, 'json-glib-1.0', 'JSON', '0.10')
	#check_pkg(ctx, 'webkit-1.0', 'WEBKIT', '0.0')
	#check_pkg(ctx, 'gnome-vfs-2.0', 'GVFS', '0.0')
	check_pkg(ctx, 'gio-unix-2.0', 'GIO_UNIX', '0.0')

	check_pkg(ctx, 'zeitgeist-1.0', 'ZEITGEIST', '0.3.10', mandatory=False)
	if ctx.env['HAVE_ZEITGEIST']:
            ctx.env.append_value ('CFLAGS', '-D HAVE_ZEITGEIST')
	else:
		print ('Building without zeitgeist-1.0 (used to provide event logging).')

	check_pkg(ctx, 'indicate-0.5', 'INDICATE', '0.5.0', mandatory=False)
	if ctx.env['HAVE_INDICATE']:
		ctx.env.append_value ('CFLAGS', '-D HAVE_INDICATE')
	else:
		print ('Building without indicate-0.5 (used to show Sound Menu).')

	check_pkg(ctx, 'dbusmenu-glib-0.4', 'DBUSMENU', '0.4.3', mandatory=False)
	if ctx.env['HAVE_DBUSMENU']:
		ctx.env.append_value ('CFLAGS', '-D HAVE_DBUSMENU')
	else:
		print ('Building without dbusmenu-glib-0.4 (used to show Sound Menu).')

	check_pkg(ctx, 'dbusmenu-gtk3-0.4', 'DBUSMENUGTK', '0.4.3', mandatory=False)
	if ctx.env['HAVE_DBUSMENUGTK']:
		ctx.env.append_value ('CFLAGS', '-D HAVE_DBUSMENUGTK')
	else:
		print ('Building without dbusmenu-gtk3-0.4 (used to show Sound Menu).')

def build(bld):
	#install basic desktop file
	bld.install_files('/usr/share/applications', '/data/' + APPNAME + '.desktop')
	
	#install icons
	bld.install_files('/usr/share/icons/hicolor/scalable/apps', '/images/icons/128x128/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/apps', '/images/icons/16x16/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/22x22/apps', '/images/icons/22x22/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/24x24/apps', '/images/icons/24x24/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/32x32/apps', '/images/icons/32x32/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/48x48/apps', '/images/icons/48x48/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/64x64/apps', '/images/icons/64x64/apps/beatbox.svg');
	bld.install_files('/usr/share/icons/hicolor/128x128/apps', '/images/icons/128x128/apps/beatbox.svg');
   	
   	#install media-audio for default album image
	bld.install_files('/usr/share/icons/hicolor/128x128/mimetypes', '/images/icons/128x128/mimes/media-audio.png');
	bld.install_files('/usr/share/icons/hicolor/128x128/mimetypes', '/images/icons/128x128/mimes/drop-album.svg');
   	
   	#shuffle and repeat
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/media-playlist-repeat-active-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/media-playlist-repeat-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/media-playlist-shuffle-active-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/media-playlist-shuffle-symbolic.svg');
	
	#star, not star
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/starred.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/status/not-starred.svg');
	
	#playlist icons
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/mimes/playlist.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/status', '/images/icons/16x16/mimes/playlist-automatic.svg');
	bld.install_files('/usr/share/icons/hicolor/22x22/status', '/images/icons/22x22/mimes/playlist.svg');
	bld.install_files('/usr/share/icons/hicolor/22x22/status', '/images/icons/22x22/mimes/playlist-automatic.svg');
	
	#last fm
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/lastfm-love.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/lastfm-ban.svg');
	
	#view mode icons
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/view-list-column-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/view-list-details-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/view-list-icons-symbolic.svg');
	bld.install_files('/usr/share/icons/hicolor/16x16/actions', '/images/icons/16x16/actions/view-list-video-symbolic.svg');
	
	obj = bld.new_task_gen ('valac', 'program')
	obj.features = 'c cprogram'
	obj.packages = 'gtk+-3.0 gee-1.0 gstreamer-0.10 gstreamer-interfaces-0.10 gstreamer-pbutils-0.10 gstreamer-cdda-0.10 taglib_c gio-2.0 sqlheavy-0.1 libxml-2.0 gconf-2.0 libsoup-2.4 json-glib-1.0 gio-unix-2.0'
	obj.target = APPNAME
	obj.uselib = 'GTK GOBJECT GEE GSTREAMER GSTREAMER_INTERFACES GSTREAMER_PBUTILS GSTREAMER_CDDA TAGLIB GIO SQLHEAVY LIBXML GCONF GTHREAD SOUP JSON GIO_UNIX'
	obj.source =  obj.path.ant_glob(('*.vala', 'src/*.vala', 'src/*.c', 'src/*.h', 'src/DataBase/*.vala', 
									'src/Dialogs/*.vala', 'src/LastFM/*.vala', 'src/Objects/*.vala', 
									'src/Widgets/*.vala', 'src/Views/AlbumView/*.vala', 'src/Views/ListView/*.vala', 
									'src/Widgets/MillerColumns/*.vala', 'src/Store/*.vala', 'src/Store/Widgets/*.vala',
									'src/GStreamer/*.vala', 'src/IO/*.vala', 'src/Views/*.vala'))

	if obj.env['HAVE_ZEITGEIST']:
		obj.packages += ' zeitgeist-1.0'
		obj.uselib += ' ZEITGEIST'
		obj.env.append_value ('VALAFLAGS', '--define=HAVE_ZEITGEIST')

	if obj.env['HAVE_INDICATE']:
		obj.packages += ' Indicate-0.5'
		obj.uselib += ' INDICATE'
		obj.env.append_value ('VALAFLAGS', '--define=HAVE_INDICATE')

	if obj.env['HAVE_DBUSMENUGTK']:
		obj.packages += ' DbusmenuGtk3-0.4'
		obj.uselib += ' DBUSMENUGTK'
		obj.env.append_value ('VALAFLAGS', '--define=HAVE_DBUSMENUGTK')
	if obj.env['HAVE_DBUSMENU']:
		obj.packages += ' Dbusmenu-0.4'
		obj.uselib += ' DBUSMENU'
		obj.env.append_value ('VALAFLAGS', '--define=HAVE_DBUSMENU')
