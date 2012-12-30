set(CLIENT_SOURCE
    main.vala
    Noise.vala
    LibraryWindow.vala
    LibraryManager.vala
    PlaybackManager.vala
    FileOperator.vala
    Utils/PixbufUtils.vala
    Utils/PixbufCache.vala
    Utils/Search.vala
    Devices/Device.vala
    Devices/NetworkDevice.vala
    Devices/DeviceManager.vala
    Devices/DevicePreferences.vala
    Objects/LyricFetcher.vala
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
    Widgets/SourceListView.vala
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
    GStreamer/GStreamerTagger.vala
    GStreamer/Streamer.vala
    Views/ViewContainer.vala
    Views/Wrappers/ViewWrapper.vala
    Views/Wrappers/MusicViewWrapper.vala
    Views/Wrappers/DeviceViewWrapper.vala
    Views/Wrappers/PlaylistViewWrapper.vala
    Views/Wrappers/ReadOnlyPlaylistViewWrapper.vala
    Views/DeviceView.vala
    Views/DeviceSummaryWidget.vala
    Views/ContentView.vala
    Views/ViewTextOverlay.vala
    Views/GridView/GridLayout.vala
    Views/GridView/GridView.vala
    Views/GridView/PopupListView.vala
    Views/ListView/ListView.vala
    Views/ListView/ColumnBrowser/BrowserColumnModel.vala
    Views/ListView/ColumnBrowser/BrowserColumn.vala
    Views/ListView/ColumnBrowser/ColumnBrowser.vala
    Views/ListView/ColumnBrowser/MusicColumnBrowser.vala
    Views/ListView/Lists/ListColumn.vala
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
)

set(CLIENT_VALAC_OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
    --define=USE_GRANITE_DECORATED_WINDOW
    #--define=HAVE_ADD_PLAYLIST_AS_BUTTON
    #--define=HAVE_SMART_ALBUM_COLUMN
    #--define=ENABLE_EXPERIMENTAL
)

# Find GTK+ version. A bug with the icon view is supposed to be fixed in version 3.4.3 or higher.
pkg_check_modules(GTK_ICON_VIEW_BUG_IS_FIXED QUIET gtk+-3.0>=3.4.3)
if (GTK_ICON_VIEW_BUG_IS_FIXED_FOUND)
    message("-- Icon view workaround disabled")
    set(CLIENT_VALAC_OPTIONS ${CLIENT_VALAC_OPTIONS} --define=GTK_ICON_VIEW_BUG_IS_FIXED)
else ()
    message("-- Icon view workaround enabled")
endif ()

set(CLIENT_VAPI ${SRC_TARGET})

vala_precompile(CLIENT_VALA_C ${SRC_TARGET}
    ${CLIENT_SOURCE}
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${CLIENT_VALAC_OPTIONS}
GENERATE_VAPI
    ${CLIENT_VAPI}
GENERATE_HEADER
    ${CLIENT_VAPI}
)

set(EXEC_NAME ${SRC_TARGET})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
add_executable(${EXEC_NAME} ${CLIENT_VALA_C})

target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})

install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
