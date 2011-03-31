NULL=

desktopdir       = $(datadir)/applications
desktop_DATA     = $(desktop_in_files:.desktop.in=.desktop)
desktop_in_files = beatbox.desktop.in				
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST = \
	$(desktop_in_files)		\
	$(NULL)

CLEANFILES = \
	$(desktop_DATA)		\
	$(NULL)

