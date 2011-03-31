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
VALAC_VERSION = '0.11.5'

out = 'build'

def options (opt):
	opt.tool_options('compiler_c')
	opt.tool_options('gnu_dirs')

def check_pkg (ctx, name, lib_name, version=''):
	ctx.check_cfg (package=name, uselib_store=lib_name, args='--cflags --libs', atleast_version=version, mandatory=True)

def configure(ctx):
	ctx.check_tool('compiler_cc gnu_dirs')
	
	ctx.check_tool('vala')
	if ctx.env['VALAC_VERSION'][1] < 10 or ctx.env['VALAC_VERSION'][2] < 6:
         print('valac >= 0.11.6 required')
         sys.exit(1)
         
	ctx.check_tool('gnu_dirs')
	check_pkg(ctx, 'gtk+-2.0', 'GTK', '2.16.0')
	check_pkg(ctx, 'gee-1.0', 'GEE', '0.5.3')
	check_pkg(ctx, 'gstreamer-0.10', 'GSTREAMER', '0.10')
	check_pkg(ctx, 'taglib_c', 'TAGLIB', '1.6.3')
	check_pkg(ctx, 'gio-2.0', 'GIO', '2.26.0')
	check_pkg(ctx, 'sqlheavy-0.1', 'SQLHEAVY', '0.0')
	check_pkg(ctx, 'webkit-1.0', 'WEBKIT', '1.2.5')
	check_pkg(ctx, 'libxml-2.0', 'LIBXML', '2.7.7')
	check_pkg(ctx, 'gconf-2.0', 'GCONF', '2.31.91')
	check_pkg(ctx, 'libnotify', 'LIBNOTIFY', '0.5.0')
	check_pkg(ctx, 'unique-1.0', 'UNIQUE', '0.9')
	check_pkg(ctx, 'dbus-glib-1', 'DBUS', '0.5')

def build(bld):
	bld.install_files ('${PREFIX}/share/applications', '/data/' + APPNAME + '.desktop')
	
	bld.install_files ('${PREFIX}/share/icons/hicolor/scalable/apps',
                       '/images/beatbox.svg')
                       
	bld.program(
		packages      = 'gtk+-2.0 gee-1.0 gstreamer-0.10 taglib_c gio-2.0 sqlheavy-0.1 webkit-1.0 libxml-2.0 gconf-2.0 libnotify gnet-2.0 unique-1.0 dbus-glib-1',
		target        = APPNAME,
		uselib        = 'GIO GOBJECT GEE GSTREAMER TAGLIB GIO SQLHEAVY LIBXML GCONF GNET GTHREAD LIBNOTIFY INDICATE UNIQUE WEBKIT DBUS',
		source        =  bld.path.ant_glob(('*.vala', 'src/*.vala', 'src/Dialogs/*.vala', 'src/LastFM/*.vala', 'src/Objects/*.vala', 'src/Widgets/*.vala')) 
		)
	

