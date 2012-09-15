#
# App icons. These are installed to the system's hicolor theme
#
install(FILES icons/16x16/apps/noise.svg DESTINATION share/icons/hicolor/16x16/apps)
install(FILES icons/22x22/apps/noise.svg DESTINATION share/icons/hicolor/22x22/apps)
install(FILES icons/24x24/apps/noise.svg DESTINATION share/icons/hicolor/24x24/apps)
install(FILES icons/32x32/apps/noise.svg DESTINATION share/icons/hicolor/32x32/apps)
install(FILES icons/48x48/apps/noise.svg DESTINATION share/icons/hicolor/48x48/apps)
install(FILES icons/64x64/apps/noise.svg DESTINATION share/icons/hicolor/64x64/apps)
install(FILES icons/128x128/apps/noise.svg DESTINATION share/icons/hicolor/128x128/apps)
install(FILES icons/128x128/apps/noise.svg DESTINATION share/icons/hicolor/scalable/apps)


#
# Fallback icons. These compliment the default "hicolor" theme, but are installed to a
# separate location (ICON_DIR).
#

# Default album image and album shadow. These would not be found by the icon renderer if they were
# installed to the hicolor sub-directory, since their dimensions are not the ones GTK+ expects to
# find in a normal icon theme. They work fine in the root icon dir though.
install(FILES icons/albumart.svg DESTINATION ${ICON_DIR})
install(FILES icons/albumart-shadow.png DESTINATION ${ICON_DIR})

# location of the fallback icon theme
set (FALLBACK_THEME_DIR "${ICON_DIR}/hicolor")

# library icons
install(FILES icons/16x16/mimetypes/library-music.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/mimetypes)

# CD icon
install(FILES icons/16x16/mimetypes/media-cdrom-audio.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/mimetypes)

# shuffle and repeat
install(FILES icons/16x16/status/media-playlist-no-repeat-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)
install(FILES icons/16x16/status/media-playlist-no-shuffle-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)

# starred / non-starred
install(FILES icons/16x16/status/starred.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)
install(FILES icons/16x16/status/non-starred.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)

# pane hide/show
install(FILES icons/16x16/actions/pane-show-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)
install(FILES icons/16x16/actions/pane-hide-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)

# eq symbolic icon
install(FILES icons/16x16/actions/media-eq-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)

# playlist icons
install(FILES icons/16x16/mimetypes/playlist.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/mimetypes)
install(FILES icons/16x16/mimetypes/playlist-automatic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/mimetypes)

# process-completed and error
install(FILES icons/16x16/mimetypes/process-completed-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)
install(FILES icons/16x16/mimetypes/process-error-symbolic.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/status)

# last fm
install(FILES icons/16x16/actions/love.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)
install(FILES icons/16x16/actions/ban.svg DESTINATION ${FALLBACK_THEME_DIR}/16x16/actions)

# Update icon cache
option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif ()
