find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.13.0" MINIMUM)
include(ValaPrecompile)

find_package(PkgConfig)
pkg_check_modules(DEPS
    glib-2.0
    gtk+-3.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-cdda-0.10
    taglib_c
    gio-2.0
    sqlheavy-0.1
    libxml-2.0
    gconf-2.0
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite)

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
    LastFM/SimilarSongs.vala
    BeatBox.vala
    #    Devices/Syncable.vala
    LibraryWindow.vala
    LibraryManager.vala
    Objects/TreeViewSetup.vala
    Objects/SmartQuery.vala
    Objects/EqualizerPreset.vala
    Objects/SongInfo.vala
    Objects/SmartPlaylist.vala
    Objects/LyricFetcher.vala
    Objects/SoundMenuIntegration.vala
    Objects/Song.vala
    Objects/MediaKeyListener.vala
    Objects/MPRIS.vala
    Objects/Playlist.vala
    Widgets/Welcome.vala
    Widgets/TopDisplay.vala
    Widgets/SimilarSongsView.vala
    Widgets/ScrollingLabel.vala
    Widgets/ToolButtonWithMenu.vala
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
    Widgets/AppMenu.vala
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
    Views/DeviceViewWrapper.vala
    Views/ListView/SimilarPane.vala
    Views/ListView/MusicTreeModel.vala
    Views/ListView/MusicTreeView.vala
    Views/CellDataFunctionHelper.vala
    Views/DeviceSummaryWidget.vala
    Views/AlbumView/AlbumViewModel.vala
    Views/AlbumView/AlbumIconView.vala
    #    Views/External/ListView/ExternalMusicTreeView.vala
    #    Views/External/ListView/ExternalMusicTreeModel.vala
    #    Views/External/ExternalViewWrapper.vala
    Views/CellRendererRating.vala
    IO/Device.vala
    IO/DeviceManager.vala
    Settings.vala
    Dialogs/EqualizerWindow.vala
    Dialogs/PresetNameWindow.vala
    Dialogs/SmartPlaylistEditor.vala
    Dialogs/PreferencesWindow.vala
    Dialogs/InstallGstreamerPluginsDialog.vala
    Dialogs/SongEditor.vala
    Dialogs/PlaylistNameWindow.vala
    Dialogs/FileNotFoundDialog.vala
    Dialogs/RemoveFilesDialog.vala
    Dialogs/NotImportedWindow.vala
PACKAGES
    glib-2.0
    gtk+-3.0
    gee-1.0
    gstreamer-0.10
    gstreamer-interfaces-0.10
    gstreamer-pbutils-0.10
    gstreamer-cdda-0.10
    taglib_c
    gio-2.0
    sqlheavy-0.1
    libxml-2.0
    gconf-2.0
    libnotify
    libsoup-2.4
    json-glib-1.0
    gio-unix-2.0
    granite
    ${ADD_PKG}
OPTIONS
    ${ADD_OPTIONS}
)

add_executable(beatbox ${VALA_C})
link_directories(${ZEITGEIST_LIBRARY_DIRS} ${INDICATE_LIBRARY_DIRS} ${DBUS_MENU_LIBRARY_DIRS} ${DEPS_LIBRARY_DIRS})
add_definitions(${DEPS_CFLAGS} ${ZEITGEIST_CFLAGS} ${INDICATE_CFLAGS} ${DBUS_MENU_CFLAGS})
target_link_libraries(beatbox ${DEPS_LIBRARIES} ${ZEITGEIST_LIBRARIES} ${DBUS_MENU_LIBRARIES} ${INDICATE_LIBRARIES})

install(TARGETS beatbox RUNTIME DESTINATION bin)
