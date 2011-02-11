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
from TaskGen import extension, feature, taskgen_method

APPNAME = 'BeatBox'
VERSION = '0.1'
VALAC_VERSION = '0.11.5'

top = '.'
out = 'build'

PACKAGES = 'gtk+-2.0 gee-1.0 gstreamer-0.10 taglib_c gio-2.0 sqlheavy-0.1 webkit-1.0 libxml-2.0 gconf-2.0'# --pkg gnet-2.0'
SOURCE='''
BeatBox.vala 
/src/DataBaseManager.vala \
/src/FileOperator.vala \
/src/LibraryWindow.vala \
/src/LibraryManager.vala \
/src/Settings.vala \
/src/StreamPlayer.vala \
/src/Dialogs/NotImportedWindow.vala \
/src/Dialogs/PlaylistNameWindow.vala \
/src/Dialogs/PreferencesWindow.vala \
/src/Dialogs/SmartPlaylistEditor.vala \
/src/Dialogs/SongEditor.vala \
/src/LastFM/LastFM.vala \
/src/LastFM/AlbumInfo.vala \
/src/LastFM/ArtistInfo.vala \
/src/LastFM/Image.vala \
/src/LastFM/Tag.vala \
/src/LastFM/TrackInfo.vala \
/src/Objects/Playlist.vala \
/src/Objects/SmartPlaylist.vala \
/src/Objects/SmartQuery.vala \
/src/Objects/Song.vala \
/src/Widgets/AppMenu.vala \
/src/Widgets/ElementaryEntry.vala \
/src/Widgets/ElementaryTreeView.vala \
/src/Widgets/MusicTreeView.vala \
/src/Widgets/SideTreeView.vala \
/src/Widgets/SongInfo.vala \
/src/Widgets/ToolButtonWithMenu.vala \
/src/Widgets/TopDisplay.vala \
'''

def options (opt):
	opt.load('compiler_c')
	opt.tool_options('gnu_dirs')

def check_pkg (ctx, name, version=''):
	ctx.check_cfg (package=name, args='--cflags --libs', atleast_version=version, mandatory=True)

def configure(ctx):
	print('->configuring beatbox in ' + ctx.path.abspath())
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
	#check_pkg(ctx, 'libnotify', '0.5.0')

def build(bld):
	bld.add_subdirs('src')

