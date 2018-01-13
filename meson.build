project('io.elementary.music', 'vala', 'c')

app_name = 'io.elementary.music'
short_name = 'music'
version = '0.4.2'
version_info = '' # Describes the version
release_name = 'juno'

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
pkg_datadir = join_paths(datadir, short_name)
plugindir = join_paths(prefix, get_option('libdir'), short_name, 'plugins')
icondir = join_paths(datadir, short_name, 'icons')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')
add_global_arguments('-DGETTEXT_PACKAGE="io.elementary.music"', language:'c')

subdir('core')

executable (
    'io.elementary.music',
    'src/Application.vala',
    'src/LibraryWindow.vala',
    'src/PlaybackManager.vala',
    'src/FileOperator.vala',
    'src/Objects/MediaKeyListener.vala',
    'src/Objects/HistoryPlaylist.vala',
    'src/Objects/MPRIS.vala',
    'src/LocalBackend/LocalLibrary.vala',
    'src/LocalBackend/LocalMedia.vala',
    'src/LocalBackend/LocalSmartPlaylist.vala',
    'src/LocalBackend/LocalStaticPlaylist.vala',
    'src/LocalBackend/DevicePreferences.vala',
    'src/Widgets/AlbumListGrid.vala',
    'src/Widgets/TopDisplay.vala',
    'src/Widgets/SimpleOptionChooser.vala',
    'src/Widgets/PresetList.vala',
    'src/Widgets/SourceListView.vala',
    'src/Widgets/StatusBar.vala',
    'src/Widgets/RatingWidget.vala',
    'src/Widgets/ViewSelector.vala',
    'src/Widgets/EqualizerPopover.vala',
    'src/Widgets/FastView/TileView/TileRenderer.vala',
    'src/Widgets/FastView/TileView/TileView.vala',
    'src/Widgets/FastView/FastGrid.vala',
    'src/Widgets/FastView/FastGridModel.vala',
    'src/Widgets/FastView/FastList.vala',
    'src/Widgets/FastView/FastListModel.vala',
    'src/DataBase.vala',
    'src/GStreamer/GStreamerTagger.vala',
    'src/GStreamer/CoverImport.vala',
    'src/GStreamer/Streamer.vala',
    'src/Views/ViewContainer.vala',
    'src/Views/Wrappers/ViewWrapper.vala',
    'src/Views/Wrappers/MusicViewWrapper.vala',
    'src/Views/Wrappers/DeviceViewWrapper.vala',
    'src/Views/Wrappers/PlaylistViewWrapper.vala',
    'src/Views/DeviceView.vala',
    'src/Views/DeviceSummaryWidget.vala',
    'src/Views/ContentView.vala',
    'src/Views/ViewTextOverlay.vala',
    'src/Views/GridView.vala',
    'src/Views/ListView/ListView.vala',
    'src/Views/ListView/ColumnBrowser/BrowserColumnModel.vala',
    'src/Views/ListView/ColumnBrowser/BrowserColumn.vala',
    'src/Views/ListView/ColumnBrowser/ColumnBrowser.vala',
    'src/Views/ListView/ColumnBrowser/MusicColumnBrowser.vala',
    'src/Views/ListView/Lists/ListColumn.vala',
    'src/Views/ListView/Lists/TreeViewSetup.vala',
    'src/Views/ListView/Lists/CellDataFunctionHelper.vala',
    'src/Views/ListView/Lists/GenericList.vala',
    'src/Views/ListView/Lists/MusicListView.vala',
    'src/Dialogs/SmartPlaylistEditor.vala',
    'src/Dialogs/PreferencesWindow.vala',
    'src/Dialogs/InstallGstreamerPluginsDialog.vala',
    'src/Dialogs/MediaEditor.vala',
    'src/Dialogs/FileNotFoundDialog.vala',
    'src/Dialogs/RemoveFilesDialog.vala',
    'src/Dialogs/NotImportedWindow.vala',
    'src/Dialogs/SetMusicFolderConfirmation.vala',
    'src/Dialogs/SyncWarningDialog.vala',
    dependencies : [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gee-0.8'),
        dependency('libpeas-1.0'),
        dependency('libpeas-gtk-1.0'),
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-pbutils-1.0'),
        dependency('gstreamer-tag-1.0'),
        dependency('zeitgeist-2.0'),
        dependency('libgda-5.0'),
        dependency('taglib_c'),
        core,
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')

subdir('po')
subdir('data')
