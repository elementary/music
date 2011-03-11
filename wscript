#! /usr/bin/env python

#A waf build script for BeatBox. To build BeatBox run:
#'./waf configure'
#'./waf build'
#
# And to run simply:
#'./BeatBox'

import os
import Build
import Task
import Node
from TaskGen import extension, feature

APPNAME = 'beatbox'
VERSION = '0.1'
VALAC_VERSION = '0.11.5'

top = '.'
out = 'build'

def set_options (opt):
	opt.tool_options('compiler_cc')

def check_pkg (ctx, name, version=''):
	ctx.check_cfg (package=name, args='--cflags --libs', atleast_version=version, mandatory=True)

def configure(ctx):
	#print('->configuring beatbox in ' + ctx.path.abspath())
	ctx.check_tool('compiler_cc')
	ctx.check_tool('vala')
	ctx.check_tool('gnu_dirs')
	check_pkg(ctx, 'gtk+-2.0', '2.16.0')
	check_pkg(ctx, 'gee-1.0', '0.5.3')
	check_pkg(ctx, 'gstreamer-0.10', '0.10')
	check_pkg(ctx, 'taglib_c', '1.6.3')
	check_pkg(ctx, 'gio-2.0', '2.26.0')
	check_pkg(ctx, 'sqlheavy-0.1', '0.0')
	check_pkg(ctx, 'webkit-1.0', '1.2.5')
	check_pkg(ctx, 'libxml-2.0', '2.7.7')
	check_pkg(ctx, 'gconf-2.0', '2.31.91')
	check_pkg(ctx, 'libnotify', '0.5.0')

def build(bld):
	bld.add_subdirs('src src/Objects src/LastFM src/Dialogs src/Widgets')
	bld.add_group()
	
	bld.install_files ('${MDATADIR}/icons/hicolor/scalable/apps',
                       top + '/images/beatbox.svg')	
	

