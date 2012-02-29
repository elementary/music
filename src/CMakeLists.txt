find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.14.2" MINIMUM)
include(ValaPrecompile)
set(DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set(PKG_DATADIR "${CMAKE_INSTALL_PREFIX}/share/beatbox")
set(ICON_FOLDER "${CMAKE_INSTALL_PREFIX}/share/beatbox/icons/hicolor")
set(GETTEXT_PACKAGE "beatbox")
set(RELEASE_NAME "Acolyte")
set(VERSION "0.3")
set(VERSION_INFO "Pre-Release")
configure_file(${CMAKE_SOURCE_DIR}/src/config.h.cmake ${CMAKE_BINARY_DIR}/src/config.h)
add_definitions(-include config.h)

vala_precompile(VALA_C
    ${CMAKE_SOURCE_DIR}/src/config.vapi
    Icons.vala
    LibraryWindow.vala
    LibraryManager.vala
    FileOperator.vala
    LastFM/LastFM.vala
    LastFM/AlbumInfo.vala
    LastFM/Image.vala
    LastFM/Tag.vala
    LastFM/TrackInfo.vala
    LastFM/ArtistInfo.vala
    LastFM/SimilarMedia.vala
    BeatBox.vala
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
    Objects/PodcastManager.vala
    Objects/Icon.vala
    Widgets/TopDisplay.vala
    Widgets/SimilarMediaView.vala
    Widgets/InfoPanel.vala
    Widgets/WarningLabel.vala
    Widgets/SimpleOptionChooser.vala
    Widgets/PresetList.vala
    Widgets/SideBar.vala
    Widgets/SideTreeView.vala
    Widgets/MillerColumns/MillerModel.vala
    Widgets/MillerColumns/MillerColumn.vala
    Widgets/RatingWidget.vala
    Widgets/SpaceWidget.vala
    Widgets/StatusBar.vala
    DataBase/DataBaseManager.vala
    DataBase/DataBaseUpdater.vala
    Store/Price.vala
    Store/Release.vala
    Store/SearchResult.vala
    Store/Store.vala
    Store/FormatTag.vala
    Store/Widgets/ArtistView.vala
    Store/Widgets/IconView.vala
    Store/Widgets/SearchResultsPage.vala
    Store/Widgets/TrackList.vala
    Store/Widgets/ReleaseRotator.vala
    Store/Widgets/TagLabel.vala
    Store/Widgets/StoreView.vala
    Store/Widgets/AlbumView.vala
    Store/Widgets/ObjectList.vala
    Store/Widgets/SearchList.vala
    Store/Widgets/HomeView.vala
    Store/Widgets/TagGroup.vala
    Store/BasketItem.vala
    Store/XMLParser.vala
    Store/Label.vala
    Store/Basket.vala
    Store/Artist.vala
    Store/Track.vala
    GStreamer/CDDA.vala
    GStreamer/Video.vala
    GStreamer/Equalizer.vala
    GStreamer/Pipeline.vala
    GStreamer/CDRipper.vala
    GStreamer/GStreamerTagger.vala
    GStreamer/ReplayGain.vala
    GStreamer/Streamer.vala
    Views/ViewWrapper.vala
    Views/DeviceViewWrapper.vala
    Views/DeviceView.vala
    Views/ContentView.vala
    Views/ListView/BaseListView.vala
    Views/ListView/BaseListModel.vala
    Views/ListView/SimilarPane.vala
    Views/ListView/MusicTreeModel.vala
    Views/ListView/MusicTreeView.vala
    Views/ListView/PodcastTreeModel.vala
    Views/ListView/PodcastListView.vala
    Views/ListView/RadioListView.vala
    Views/ListView/RadioTreeModel.vala
    Views/CellDataFunctionHelper.vala
    Views/DeviceSummaryWidget.vala
    Views/AlbumView/AlbumViewModel.vala
    Views/AlbumView/AlbumIconView.vala
    Views/AlbumView/AlbumListView.vala
    Dialogs/EqualizerWindow.vala
    Dialogs/SmartPlaylistEditor.vala
    Dialogs/PreferencesWindow.vala
    Dialogs/InstallGstreamerPluginsDialog.vala
    Dialogs/SongEditor.vala
    Dialogs/PodcastEditor.vala
    Dialogs/StationEditor.vala
    Dialogs/PlaylistNameWindow.vala
    Dialogs/FileNotFoundDialog.vala
    Dialogs/RemoveFilesDialog.vala
    Dialogs/NotImportedWindow.vala
    Dialogs/AddPodcastWindow.vala
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
    beatbox-core
    ${ADD_PKG}
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_BINARY_DIR}/core/
    ${ADD_OPTIONS}
GENERATE_VAPI
    beatbox
GENERATE_HEADER
    beatbox
)
include_directories(${CMAKE_BINARY_DIR}/core)
add_executable(beatbox ${VALA_C})
link_directories(${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})
add_definitions(${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS})
target_link_libraries(beatbox ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES})
target_link_libraries(beatbox beatbox-core)
install(TARGETS beatbox RUNTIME DESTINATION bin)
