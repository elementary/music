#
# App icons. These are installed to the system's default theme
#

set (SYSTEM_DEFAULT_THEME ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)

install (FILES icons/16x16/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/16x16/apps)
install (FILES icons/22x22/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/22x22/apps)
install (FILES icons/24x24/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/24x24/apps)
install (FILES icons/32x32/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/32x32/apps)
install (FILES icons/48x48/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/48x48/apps)
install (FILES icons/64x64/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/64x64/apps)
install (FILES icons/128x128/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/128x128/apps)
install (FILES icons/128x128/apps/multimedia-audio-player.svg DESTINATION ${SYSTEM_DEFAULT_THEME}/scalable/apps)

#
# Fallback icons. These compliment the default "hicolor" theme, but are installed to a
# separate location (ICON_DIR).
#

# Default album image and album shadow. These would not be found by the icon renderer if
# they were installed to the hicolor sub-directory, since their dimensions are not the ones
# GTK+ expects to find in a normal icon theme. They work fine in the root icon dir though.
set(GENERIC_IMAGES
    icons/albumart.svg
)

install (FILES ${GENERIC_IMAGES} DESTINATION ${ICON_DIR})

# location of the fallback icon theme
set (FALLBACK_THEME_DIR ${ICON_DIR}/hicolor)

set (STATUS_16
  icons/16x16/status/media-playlist-no-shuffle-symbolic.svg
  icons/16x16/status/media-playlist-no-repeat-symbolic.svg
  icons/16x16/status/starred.svg
  icons/16x16/status/non-starred.svg
  icons/16x16/status/process-completed-symbolic.svg
  icons/16x16/status/process-error-symbolic.svg
  icons/16x16/status/audio-volume-high-symbolic.svg
  icons/16x16/status/media-playlist-repeat-one-symbolic.svg
  icons/16x16/status/media-playlist-repeat-symbolic.svg
  icons/16x16/status/media-playlist-shuffle-symbolic.svg
)

set (ACTIONS_16
  icons/16x16/actions/pane-show-symbolic.svg
  icons/16x16/actions/pane-hide-symbolic.svg
  icons/16x16/actions/media-eq-symbolic.svg
  icons/16x16/actions/list-add-symbolic.svg
  icons/16x16/actions/love.svg
  icons/16x16/actions/ban.svg
)

set (MIMETYPES_16
  icons/16x16/mimetypes/playlist.svg
  icons/16x16/mimetypes/playlist-automatic.svg
  icons/16x16/mimetypes/playlist-queue.svg
  icons/16x16/mimetypes/library-music.svg
  icons/16x16/mimetypes/media-cdrom-audio.svg
)

install (FILES ${STATUS_16} DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)
install (FILES ${ACTIONS_16} DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)
install (FILES ${MIMETYPES_16} DESTINATION ${FALLBACK_THEME_DIR}/16x16/mimetypes)
