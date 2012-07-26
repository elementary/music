find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16.0" MINIMUM)
include(ValaPrecompile)
set(DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR "${CMAKE_INSTALL_PREFIX}/share/noise")
set(GETTEXT_PACKAGE "noise")
set(RELEASE_NAME "Luna")
set(VERSION "1.0")
set(VERSION_INFO "Pre-Release")
configure_file(${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

vala_precompile(VALA_C
    ${CMAKE_SOURCE_DIR}/src/config.vala

    Icons.vala
    LibraryWindow.vala
    LibraryManager.vala
    FileOperator.vala

    Noise.vala

    Utils/UI.vala
    Utils/PixbufUtils.vala
    Utils/Search.vala
    Utils/Icon.vala

    Devices/Device.vala
    Devices/NetworkDevice.vala
    Devices/DeviceManager.vala
    Devices/DevicePreferences.vala

    Objects/SmartQuery.vala
    Objects/SmartPlaylist.vala
    Objects/LyricFetcher.vala
    Objects/SoundMenuIntegration.vala
    Objects/MediaKeyListener.vala
    Objects/MPRIS.vala
    Objects/Playlist.vala
    Objects/MediaInfo.vala
    Objects/AlbumInfo.vala
    Objects/ArtistInfo.vala
    Objects/TrackInfo.vala

    Widgets/SidebarPaned.vala
    Widgets/NavigationArrows.vala
    Widgets/SmartAlbumRenderer.vala
    Widgets/TopDisplay.vala
    Widgets/InfoPanel.vala
    Widgets/EmbeddedAlert.vala
    Widgets/SimpleOptionChooser.vala
    Widgets/PresetList.vala
    Widgets/SideBar.vala
    Widgets/SideTreeView.vala
    Widgets/BottomStatusBar.vala
    Widgets/RatingWidget.vala
    Widgets/SpaceWidget.vala
    Widgets/FixedBin.vala
    Widgets/FastView/FastGrid.vala
    Widgets/FastView/FastGridModel.vala
    Widgets/FastView/FastList.vala
    Widgets/FastView/FastListModel.vala

    DataBase/DataBaseManager.vala
    DataBase/DataBaseUpdater.vala

    GStreamer/Video.vala
    GStreamer/Equalizer.vala
    GStreamer/Pipeline.vala
    GStreamer/GStreamerTagger.vala
    GStreamer/ReplayGain.vala
    GStreamer/Streamer.vala

    Views/ViewContainer.vala

    Views/Wrappers/ViewWrapper.vala
    Views/Wrappers/MusicViewWrapper.vala
    Views/Wrappers/HistoryViewWrapper.vala
    Views/Wrappers/QueueViewWrapper.vala
    Views/Wrappers/DeviceViewWrapper.vala
    Views/Wrappers/NetworkDeviceViewWrapper.vala
    Views/Wrappers/PlaylistViewWrapper.vala

    Views/DeviceView.vala
    Views/DeviceSummaryWidget.vala

    Views/ContentView.vala

    # ALBUM VIEW
    Views/GridView/GridLayout.vala
    Views/GridView/GridView.vala
    Views/GridView/PopupListView.vala

    # LIST VIEW
    Views/ListView/ListView.vala
    Views/ListView/ColumnBrowser/BrowserColumnModel.vala
    Views/ListView/ColumnBrowser/BrowserColumn.vala
    Views/ListView/ColumnBrowser/ColumnBrowser.vala
    Views/ListView/ColumnBrowser/MusicColumnBrowser.vala

    Views/ListView/Lists/TreeViewSetup.vala
    Views/ListView/Lists/CellDataFunctionHelper.vala
    Views/ListView/Lists/GenericList.vala
    Views/ListView/Lists/MusicListView.vala

    Dialogs/EqualizerWindow.vala
    Dialogs/SmartPlaylistEditor.vala
    Dialogs/PreferencesWindow.vala
    Dialogs/InstallGstreamerPluginsDialog.vala
    Dialogs/MediaEditor.vala
    Dialogs/PlaylistNameWindow.vala
    Dialogs/FileNotFoundDialog.vala
    Dialogs/RemoveFilesDialog.vala
    Dialogs/NotImportedWindow.vala
    Dialogs/SetMusicFolderConfirmation.vala
    Dialogs/TransferFromDeviceDialog.vala
    Dialogs/SyncWarningDialog.vala

PACKAGES
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
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    libpeas-1.0
    noise-core
    ${ADD_PKG}
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/core/
    --target-glib=2.32
    --define=USE_GRANITE_DECORATED_WINDOW
    #--define=HAVE_SMART_ALBUM_COLUMN
    #--define=GTK_ICON_VIEW_BUG_IS_FIXED
    ${ADD_OPTIONS}
GENERATE_VAPI
    noise
GENERATE_HEADER
    noise
)
include_directories(${CMAKE_BINARY_DIR}/core)
add_executable(noise ${VALA_C})
link_directories(${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})
add_definitions(${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS})
target_link_libraries(noise ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES})
target_link_libraries(noise noise-core)
install(TARGETS noise RUNTIME DESTINATION bin)

