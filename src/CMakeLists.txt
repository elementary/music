set(CLIENT_SOURCE
    main.vala
    Noise.vala
    LibraryWindow.vala
    PlaybackManager.vala
    FileOperator.vala
    Objects/MediaKeyListener.vala
    Objects/HistoryPlaylist.vala
    LocalBackend/LocalLibrary.vala
    LocalBackend/LocalMedia.vala
    LocalBackend/LocalSmartPlaylist.vala
    LocalBackend/LocalStaticPlaylist.vala
    LocalBackend/DevicePreferences.vala
    Widgets/AlbumListGrid.vala
    Widgets/TopDisplay.vala
    Widgets/SimpleOptionChooser.vala
    Widgets/PresetList.vala
    Widgets/SourceListView.vala
    Widgets/StatusBar.vala
    Widgets/RatingWidget.vala
    Widgets/SpaceWidget.vala
    Widgets/ViewSelector.vala
    Widgets/EqualizerPopover.vala
    Widgets/FastView/TileView/TileRenderer.vala
    Widgets/FastView/TileView/TileView.vala
    Widgets/FastView/FastGrid.vala
    Widgets/FastView/FastGridModel.vala
    Widgets/FastView/FastList.vala
    Widgets/FastView/FastListModel.vala
    DataBase.vala
    GStreamer/GStreamerTagger.vala
    GStreamer/CoverImport.vala
    GStreamer/Streamer.vala
    Views/ViewContainer.vala
    Views/Wrappers/ViewWrapper.vala
    Views/Wrappers/MusicViewWrapper.vala
    Views/Wrappers/DeviceViewWrapper.vala
    Views/Wrappers/PlaylistViewWrapper.vala
    Views/DeviceView.vala
    Views/DeviceSummaryWidget.vala
    Views/ContentView.vala
    Views/ViewTextOverlay.vala
    Views/GridView.vala
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
    Dialogs/SmartPlaylistEditor.vala
    Dialogs/PreferencesWindow.vala
    Dialogs/InstallGstreamerPluginsDialog.vala
    Dialogs/MediaEditor.vala
    Dialogs/FileNotFoundDialog.vala
    Dialogs/RemoveFilesDialog.vala
    Dialogs/NotImportedWindow.vala
    Dialogs/SetMusicFolderConfirmation.vala
    Dialogs/SyncWarningDialog.vala
)

set (CLIENT_VALAC_OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
  #--define=HAVE_ADD_PLAYLIST_AS_BUTTON
  #--define=ENABLE_EXPERIMENTAL
)

set (CLIENT_VAPI ${SRC_TARGET})

vala_precompile (CLIENT_VALA_C ${SRC_TARGET}
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

set (EXEC_NAME ${SRC_TARGET})

include (GResource)
glib_compile_resources (GLIB_RESOURCES_ICONS SOURCE ../data/icons/icons.gresource.xml)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})
add_executable (${EXEC_NAME} ${CLIENT_VALA_C} ${GLIB_RESOURCES_ICONS})

target_link_libraries (${EXEC_NAME} ${DEPS_LIBRARIES})

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
