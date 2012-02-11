find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.14.0" MINIMUM)
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

find_package(PkgConfig)
pkg_check_modules(DEPS
    REQUIRED
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
    sqlheavy-0.1
    libxml-2.0
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    libgpod-1.0
    clutter-gtk-1.0)

# Check if we have sqlheavy-0.2
if(${SQLHEAVY_USE_2})
    pkg_check_modules(SQLHEAVY sqlheavy-0.2)
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.2)
    message("-- Will use sqlheavy-0.2")
else()
    set(ADD_PKG ${ADD_PKG} sqlheavy-0.1)
    pkg_check_modules(SQLHEAVY sqlheavy-0.1)
    message("-- Will use sqlheavy-0.1")
endif()

pkg_check_modules(ZEITGEIST zeitgeist-1.0)
if(${ZEITGEIST_FOUND})
    set(ADD_PKG ${ADD_PKG}
                zeitgeist-1.0)
    set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_ZEITGEIST)
    message("-- Zeitgeist enabled")
else()
    message("-- Zeitgeist disabled")
endif()

pkg_check_modules(DBUS_MENU dbusmenu-glib-0.4)
if(${DBUS_MENU_FOUND})
    set(ADD_PKG ${ADD_PKG}
        Dbusmenu-0.4)
    set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_DBUSMENU)
    message("-- DBus Menu enabled")
else()
    message("-- DBus Menu disabled")
endif()

pkg_check_modules(INDICATE indicate-0.6)
if(${INDICATE_FOUND})
    set(ADD_PKG ${ADD_PKG}
        Indicate-0.6)
    set(ADD_OPTIONS ${ADD_OPTIONS}
        --define=HAVE_INDICATE)
    message("-- Indicate enabled")
else()
    message("-- Indicate disabled")
endif()

vala_precompile(VALA_C
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
    Icons.vala
    LibraryWindow.vala
    LibraryManager.vala
    Objects/TreeViewSetup.vala
    Objects/SmartQuery.vala
    Objects/EqualizerPreset.vala
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
    Widgets/CoverArtImage.vala
    Widgets/SideBar.vala
    Widgets/SideTreeView.vala
    Widgets/MillerColumns/MillerModel.vala
    Widgets/MillerColumns/MillerColumn.vala
    Widgets/RatingWidget.vala
    Widgets/DeviceBar.vala
    Widgets/SpaceWidget.vala
    Widgets/Welcome.vala
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
    GStreamer/Ripper.vala
    GStreamer/Equalizer.vala
    GStreamer/Pipeline.vala
    GStreamer/CDRipper.vala
    GStreamer/GStreamerTagger.vala
    GStreamer/ReplayGain.vala
    GStreamer/Streamer.vala
    Views/ViewWrapper.vala
    Views/CDRomViewWrapper.vala
    Views/DeviceViewWrapper.vala
    Views/DeviceView.vala
    Views/ContentView.vala
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
    #    Views/External/ListView/ExternalMusicTreeView.vala
    #    Views/External/ListView/ExternalMusicTreeModel.vala
    #    Views/External/ExternalViewWrapper.vala
    Settings.vala
    Dialogs/EqualizerWindow.vala
    Dialogs/PresetNameWindow.vala
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
    Dialogs/RemoveFromLibraryDialog.vala
    #Dialogs/RemoveFilesDialog.vala
    Dialogs/SetMusicFolderConfirmation.vala
    Dialogs/TransferFromDeviceDialog.vala
    Dialogs/SyncWarningDialog.vala
    ${CMAKE_SOURCE_DIR}/src/config.vapi
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    ${ADD_OPTIONS}
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
    clutter-gtk-1.0
    ${ADD_PKG}
)

add_executable(beatbox ${VALA_C})
link_directories(${ZEITGEIST_LIBRARY_DIRS} ${SQLHEAVY_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})
add_definitions(${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS} ${SQLHEAVY_CFLAGS})
target_link_libraries(beatbox ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${SQLHEAVY_LIBRARIES} ${INDICATE_LIBRARIES})

install(TARGETS beatbox RUNTIME DESTINATION bin)
