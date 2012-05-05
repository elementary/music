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
configure_file(${CMAKE_SOURCE_DIR}/src/config.h.cmake ${CMAKE_BINARY_DIR}/src/config.h)
add_definitions(-include config.h)

vala_precompile(VALA_C
    ${CMAKE_SOURCE_DIR}/src/config.vapi

    Icons.vala
    LibraryWindow.vala
    LibraryManager.vala
    FileOperator.vala

    Utils/UI.vala
    Utils/Search.vala
    Utils/PixbufUtils.vala
    Utils/TimeUtils.vala
    Utils/String.vala
    Utils/Numeric.vala
    Utils/Icon.vala

    LastFM/LastFM.vala
    LastFM/AlbumInfo.vala
    LastFM/Image.vala
    LastFM/Tag.vala
    LastFM/TrackInfo.vala
    LastFM/ArtistInfo.vala
    LastFM/SimilarMedia.vala

    Noise.vala

    Devices/DeviceManager.vala
    Devices/Device.vala
    Devices/iPodDevice.vala
    Devices/AndroidDevice.vala
    Devices/CDRomDevice.vala
    Devices/DevicePreferences.vala

    Objects/TreeViewSetup.vala
    Objects/SmartQuery.vala
    Objects/MediaInfo.vala
    Objects/SmartPlaylist.vala
    Objects/LyricFetcher.vala
    Objects/SoundMenuIntegration.vala
    Objects/Media.vala
    Objects/MediaKeyListener.vala
    Objects/MPRIS.vala
    Objects/Playlist.vala

    Widgets/NavigationArrows.vala
    Widgets/GraniteStatusBar.vala
    Widgets/SmartAlbumRenderer.vala
    Widgets/TopDisplay.vala
    Widgets/SimilarMediaView.vala
    Widgets/InfoPanel.vala
    Widgets/WarningLabel.vala
    Widgets/SimpleOptionChooser.vala
    Widgets/PresetList.vala
    Widgets/SideBar.vala
    Widgets/SideTreeView.vala
    Widgets/RatingWidget.vala
    Widgets/SpaceWidget.vala
    Widgets/StatusBar.vala
    Widgets/FastView/FastView.vala
    Widgets/FastView/FastModel.vala

    DataBase/DataBaseManager.vala
    DataBase/DataBaseUpdater.vala

    GStreamer/CDDA.vala
    GStreamer/Video.vala
    GStreamer/Equalizer.vala
    GStreamer/Pipeline.vala
    GStreamer/CDRipper.vala
    GStreamer/GStreamerTagger.vala
    GStreamer/ReplayGain.vala
    GStreamer/Streamer.vala

    Views/ViewWrapper.vala
    Views/SimilarViewWrapper.vala
    Views/DeviceViewWrapper.vala
    Views/DeviceView.vala
    Views/DeviceSummaryWidget.vala
    Views/ContentView.vala

    # ALBUM VIEW
    Views/AlbumView/AlbumIconView.vala
    Views/AlbumView/AlbumViewModel.vala
    Views/AlbumView/AlbumListView.vala

    # LIST VIEW
    Views/CellDataFunctionHelper.vala
    Views/ListView/ListView.vala
    Views/ListView/MillerColumns/MillerModel.vala
    Views/ListView/MillerColumns/MillerColumn.vala

    Views/ListView/Lists/GenericList.vala
    Views/ListView/Lists/MusicListView.vala

    Dialogs/EqualizerWindow.vala
    Dialogs/SmartPlaylistEditor.vala
    Dialogs/PreferencesWindow.vala
    Dialogs/InstallGstreamerPluginsDialog.vala
    Dialogs/SongEditor.vala
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
    libgpod-1.0
    libpeas-1.0
    noise-core
    ${ADD_PKG}
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/core/
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

