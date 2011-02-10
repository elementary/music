#! /usr/bin/env python

#A waf build script for BeatBox. To build BeatBox run:
#'./waf configure'
#'./waf build'
#
# And to run simply:
#'./BeatBox'

import Build
import Task
import Node

APPNAME = 'BeatBox'
VERSION = '0.1'
VALAC_VERSION = '0.11.5'

top = '.'
out = 'build'

PACKAGES = '--pkg gtk+-2.0 --pkg gee-1.0 --pkg gstreamer-0.10 --pkg taglib_c --pkg gio-2.0 --pkg sqlheavy-0.1 --pkg webkit-1.0 --pkg libxml-2.0 --pkg gconf-2.0 --pkg gnet-2.0'
SOURCE_EASY = '../BeatBox.vala ../src/*.vala ../src/LastFM/*.vala ../src/Widgets/*.vala ../src/Dialogs/*.vala ../src/Objects/*.vala'
SOURCES = '../BeatBox.vala ../src/DataBaseManager.vala ../src/FileOperator.vala ../src/LibraryManager.vala ../src/LibraryWindow.vala ../src/Settings.vala ../src/StreamPlayer.vala ../src/Dialogs/NotImportedWindow.vala ../src/Dialogs/PlaylistNameWindow.vala ../src/Dialogs/PreferencesWindow.vala ../src/Dialogs/SmartPlaylistEditor.vala ../src/Dialogs/SongEditor.vala ../src/LastFM/LastFM.vala ../src/LastFM/LastFMAlbumInfo.vala ../src/LastFM/LastFMArtistInfo.vala ../src/LastFM/LastFMImage.vala ../src/LastFM/LastFMTag.vala ../src/LastFM/LastFMTrackInfo.vala ../src/Objects/Playlist.vala ../src/Objects/SmartPlaylist.vala ../src/Objects/SmartQuery.vala ../src/Objects/Song.vala'
 

def check_pkg (ctx, name, version=''):
	ctx.check_cfg (package=name, args='--cflags --libs', atleast_version=version, mandatory=True)

def configure(ctx):
	print('->configuring beatbox in ' + ctx.path.abspath())
	print('NOTE: Must have valac version ' + VALAC_VERSION + ' or greater installed')
	check_pkg(ctx, 'gtk+-2.0', '2.16.0')
	check_pkg(ctx, 'gee-1.0', '0.5.3')
	check_pkg(ctx, 'gstreamer-0.10', '0.10')
	check_pkg(ctx, 'taglib_c', '1.6.3')
	check_pkg(ctx, 'gio-2.0', '2.26.0')
	check_pkg(ctx, 'sqlheavy-0.1', '0.0')
	check_pkg(ctx, 'webkit-1.0', '1.2.6')
	check_pkg(ctx, 'libxml-2.0', '2.7.7')
	check_pkg(ctx, 'gconf-2.0', '2.31.91')
	check_pkg(ctx, 'gnet-2.0', '2.0.8')
	#check_pkg(ctx, 'libnotify', '0.5.0')

def build(bld):
	bld(rule = 'valac ' + PACKAGES + ' --thread ' + SOURCE_EASY)

