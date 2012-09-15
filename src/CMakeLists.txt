configure_file(${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

vala_precompile(VALA_C
    ${CMAKE_SOURCE_DIR}/src/config.vala

    Icons.vala
    LibraryWindow.vala
    LibraryManager.vala
    PlaybackManager.vala
    FileOperator.vala

    main.vala
    Noise.vala

    Utils/PixbufUtils.vala
    Utils/PixbufCache.vala
    Utils/Search.vala
    Utils/Icon.vala

    Devices/Device.vala
    Devices/NetworkDevice.vala
    Devices/DeviceManager.vala
    Devices/DevicePreferences.vala

    Objects/SmartQuery.vala
    Objects/SmartPlaylist.vala
    Objects/LyricFetcher.vala
    Objects/Playlist.vala
    Objects/MediaInfo.vala
    Objects/AlbumInfo.vala
    Objects/ArtistInfo.vala
    Objects/TrackInfo.vala
    Objects/MediaArtCache.vala
    Objects/CoverartCache.vala
    Objects/MediaKeyListener.vala

    Widgets/NavigationArrows.vala
    Widgets/SmartAlbumRenderer.vala
    Widgets/TopDisplay.vala
    Widgets/InfoPanel.vala
    Widgets/EmbeddedAlert.vala
    Widgets/SimpleOptionChooser.vala
    Widgets/PresetList.vala
    Widgets/SideBar.vala
    Widgets/SideTreeView.vala
    Widgets/StatusBar.vala
    Widgets/RatingWidget.vala
    Widgets/SpaceWidget.vala
    Widgets/FixedBin.vala
    Widgets/ViewSelector.vala
    Widgets/FastView/FastGrid.vala
    Widgets/FastView/FastGridModel.vala
    Widgets/FastView/FastList.vala
    Widgets/FastView/FastListModel.vala

    DataBase/DataBaseManager.vala
    DataBase/DataBaseUpdater.vala
    DataBase/Tables.vala

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
    #--define=HAVE_ADD_PLAYLIST_AS_BUTTON
    #--define=HAVE_SMART_ALBUM_COLUMN
    #--define=GTK_ICON_VIEW_BUG_IS_FIXED  ## TODO: define this automatically when gtk+.3.0 >= 3.4.3
    #--define=ENABLE_EXPERIMENTAL
    ${ADD_OPTIONS}
GENERATE_VAPI
    noise
GENERATE_HEADER
    noise
)

set(EXEC_NAME ${CMAKE_PROJECT_NAME})

add_definitions(${NORMAL_CFLAGS})
include_directories(${CMAKE_BINARY_DIR}/core)
link_directories(${NORMAL_LINK_DIRS})
add_executable(${EXEC_NAME} ${VALA_C})
target_link_libraries (${EXEC_NAME} ${NORMAL_LIBRARIES} noise-core)
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
