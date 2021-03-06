project(
  'io.elementary.music',
  'vala', 'c',
  version: '5.1.1'
)

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
plugindir = join_paths(prefix, get_option('libdir'), meson.project_name(), 'plugins')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')
add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DHANDY_USE_UNSTABLE_API'
    ],
    language:'c'
)

subdir('core')
subdir('data')

app_deps = core_deps + [
  core,
  dependency('libgda-5.0'),
  dependency('libhandy-1', version: '>=0.83.0'),
  dependency('taglib_c'),
  dependency('zeitgeist-2.0'),
  meson.get_compiler('vala').find_library('posix'),
  meson.get_compiler('c').find_library('m')
]

app_files = files(
  'src/Application.vala',
  'src/DataBase.vala',
  'src/FileOperator.vala',
  'src/LibraryWindow.vala',
  'src/PlaybackManager.vala',
  'src/Dialogs/FileNotFoundDialog.vala',
  'src/Dialogs/InstallGstreamerPluginsDialog.vala',
  'src/Dialogs/MediaEditor.vala',
  'src/Dialogs/NotImportedDialog.vala',
  'src/Dialogs/PreferencesWindow.vala',
  'src/Dialogs/RemoveFilesDialog.vala',
  'src/Dialogs/SetMusicFolderConfirmation.vala',
  'src/Dialogs/SmartPlaylistEditor.vala',
  'src/Dialogs/SyncWarningDialog.vala',
  'src/GStreamer/CoverImport.vala',
  'src/GStreamer/GStreamerTagger.vala',
  'src/GStreamer/Streamer.vala',
  'src/Interfaces/ViewInterface.vala',
  'src/LocalBackend/DevicePreferences.vala',
  'src/LocalBackend/LocalLibrary.vala',
  'src/LocalBackend/LocalMedia.vala',
  'src/LocalBackend/LocalSmartPlaylist.vala',
  'src/LocalBackend/LocalStaticPlaylist.vala',
  'src/Objects/HistoryPlaylist.vala',
  'src/Objects/MediaKeyListener.vala',
  'src/Objects/MPRIS.vala',
  'src/Views/DeviceSummaryWidget.vala',
  'src/Views/DeviceView.vala',
  'src/Views/AlbumsView.vala',
  'src/Views/ViewStack.vala',
  'src/Views/ListView/ListView.vala',
  'src/Views/ListView/ColumnBrowser/BrowserColumn.vala',
  'src/Views/ListView/ColumnBrowser/BrowserColumnModel.vala',
  'src/Views/ListView/ColumnBrowser/ColumnBrowser.vala',
  'src/Views/ListView/Lists/CellDataFunctionHelper.vala',
  'src/Views/ListView/Lists/GenericList.vala',
  'src/Views/ListView/Lists/ListColumn.vala',
  'src/Views/ListView/Lists/MusicListView.vala',
  'src/Views/ListView/Lists/TreeViewSetup.vala',
  'src/Views/Wrappers/DeviceViewWrapper.vala',
  'src/Views/Wrappers/MusicViewWrapper.vala',
  'src/Views/Wrappers/PlaylistViewWrapper.vala',
  'src/Views/Wrappers/ViewWrapper.vala',
  'src/Widgets/AlbumListGrid.vala',
  'src/Widgets/ContractMenuItem.vala',
  'src/Widgets/EqualizerPopover.vala',
  'src/Widgets/MediaMenu.vala',
  'src/Widgets/PresetList.vala',
  'src/Widgets/SimpleOptionChooser.vala',
  'src/Widgets/SourceListView.vala',
  'src/Widgets/StatusBar.vala',
  'src/Widgets/TopDisplay.vala',
  'src/Widgets/ViewSelector.vala',
  'src/Widgets/FastView/FastGrid.vala',
  'src/Widgets/FastView/FastGridModel.vala',
  'src/Widgets/FastView/FastListModel.vala',
  'src/Widgets/FastView/TileView/TileRenderer.vala',
  'src/Widgets/Rating/RatingCellRenderer.vala',
  'src/Widgets/Rating/RatingMenuItem.vala',
  'src/Widgets/Rating/RatingWidget.vala'
)

app = executable (
    meson.project_name(),
    app_files,
    icon_res,
    dependencies: app_deps,
    install: true
)

# FIXME: make the plugins independant from the app
app_shared_lib = static_library(
    'music-lib',
    app_files,
    dependencies: app_deps
)

app_dep = declare_dependency(
    dependencies: app_deps,
    include_directories: include_directories('.'),
    link_with: app_shared_lib
)

meson.add_install_script('meson/post_install.py')

if get_option('build-plugins')
  plugins = get_option('plugins')
  subdir('plugins')
endif

subdir('po')

if get_option('documentation')
    subdir('docs')
endif
