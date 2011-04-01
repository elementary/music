DATADIR = $(datadir)

bin_PROGRAMS = \
    beatbox

beatbox_CPPFLAGS = \
    -I$(top_srcdir) \
    $(CORE_CFLAGS) \
    -DVERSION="\"$(VERSION)\"" 	                    \
    $(NULL)

beatbox_VALAFLAGS = \
    -C \
    -H beatbox-vala.h \
    --pkg gtk+-2.0 \
	--pkg glib-2.0 \
    --pkg gio-2.0 \
    --pkg gee-1.0 \
	--pkg unique-1.0 \
	--pkg taglib_c \
	--pkg webkit-1.0 \
	--pkg gstreamer-0.10 \
	--pkg libxml-2.0 \
	--pkg libnotify \
	--pkg sqlheavy-0.1 \
	--pkg gconf-2.0 \
    -g \
    $(NULL)

beatbox_LDADD = \
    $(CORE_LIBS) \
    $(NULL)

BUILT_SOURCES = \
    beatbox.vala.stamp \
    $(NULL)

beatbox_VALASOURCES = \
	BeatBox.vala								\
	DataBaseManager.vala					\
	DataBaseUpdater.vala					\
	FileOperator.vala						\
	LibraryManager.vala						\
	LibraryWindow.vala						\
	Settings.vala							\
	StreamPlayer.vala						\
	Dialogs/NotImportedWindow.vala			\
	Dialogs/PlaylistNameWindow.vala			\
	Dialogs/PreferencesWindow.vala			\
	Dialogs/SmartPlaylistEditor.vala		\
	Dialogs/SongEditor.vala					\
	LastFM/AlbumInfo.vala					\
	LastFM/ArtistInfo.vala					\
	LastFM/Image.vala						\
	LastFM/LastFM.vala						\
	LastFM/SimilarSongs.vala				\
	LastFM/Tag.vala							\
	LastFM/TrackInfo.vala					\
	Objects/MediaKeyListener.vala			\
	Objects/Playlist.vala					\
	Objects/SmartPlaylist.vala				\
	Objects/SmartQuery.vala					\
	Objects/Song.vala						\
	Objects/SongInfo.vala					\
	Objects/SoundMenuIntegration.vala		\
	Objects/TreeViewSetup.vala				\
	Widgets/AppMenu.vala					\
	Widgets/ElementaryEntry.vala			\
	Widgets/ElementaryTreeView.vala			\
	Widgets/InfoPanel.vala					\
	Widgets/MusicTreeView.vala				\
	Widgets/RatingWidget.vala				\
	Widgets/ScrollingLabel.vala				\
	Widgets/SideTreeView.vala				\
	Widgets/SimilarPane.vala				\
	Widgets/SimilarSongsView.vala			\
	Widgets/SimpleOptionChooser.vala		\
	Widgets/ToolButtonWithMenu.vala			\
	Widgets/TopDisplay.vala					\
	Widgets/Welcome.vala					\
    $(NULL)

beatbox_CSOURCES = \
	$(NULL)

beatbox_SOURCES = \
    $(beatbox_VALASOURCES:.vala=.c)         \
	$(beatbox_CSOURCES)						\
    $(NULL)

nodist_beatbox_SOURCES = \
    $(BUILT_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	beatbox.vala.stamp \
	$(beatbox_VALASOURCES) \
	$(NULL)


beatbox.vala.stamp: $(beatbox_VALASOURCES)
	$(AM_V_GEN) $(VALAC) $(beatbox_VALAFLAGS) $^
	touch beatbox.vala.stamp

CLEANFILES = \
    $(BUILT_SOURCES) \
	$(beatbox_VALASOURCES:.vala=.c) \
	$(NULL)

