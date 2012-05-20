# noise icons
install(FILES icons/16x16/apps/noise.svg DESTINATION share/icons/hicolor/16x16/apps)
install(FILES icons/22x22/apps/noise.svg DESTINATION share/icons/hicolor/22x22/apps)
install(FILES icons/24x24/apps/noise.svg DESTINATION share/icons/hicolor/24x24/apps)
install(FILES icons/32x32/apps/noise.svg DESTINATION share/icons/hicolor/32x32/apps)
install(FILES icons/48x48/apps/noise.svg DESTINATION share/icons/hicolor/48x48/apps)
install(FILES icons/64x64/apps/noise.svg DESTINATION share/icons/hicolor/64x64/apps)
install(FILES icons/128x128/apps/noise.svg DESTINATION share/icons/hicolor/128x128/apps)
install(FILES icons/128x128/apps/noise.svg DESTINATION share/icons/hicolor/scalable/apps)

# library icons
install(FILES icons/16x16/mimetypes/library-music.svg DESTINATION ${ICON_DIR}/16x16/mimetypes)

# CD icon
install(FILES icons/16x16/mimetypes/media-cdrom-audio.svg DESTINATION ${ICON_DIR}/16x16/mimetypes)

# media-audio for default album image and album shadow
install(FILES icons/138x138/mimetypes/albumart.svg DESTINATION ${ICON_DIR}/138x138/mimetypes)
install(FILES icons/168x168/other/albumart-shadow.png DESTINATION ${ICON_DIR}/168x168/other)

# shuffle and repeat
install(FILES icons/16x16/status/media-playlist-no-repeat-symbolic.svg DESTINATION ${ICON_DIR}/16x16/status)
install(FILES icons/16x16/status/media-playlist-no-shuffle-symbolic.svg DESTINATION ${ICON_DIR}/16x16/status)

# starred / non-starred
install(FILES icons/16x16/status/starred.svg DESTINATION ${ICON_DIR}/16x16/status)
install(FILES icons/16x16/status/non-starred.svg DESTINATION ${ICON_DIR}/16x16/status)

# pane hide/show
install(FILES icons/16x16/actions/pane-show-symbolic.svg DESTINATION ${ICON_DIR}/16x16/actions)
install(FILES icons/16x16/actions/pane-hide-symbolic.svg DESTINATION ${ICON_DIR}/16x16/actions)

# eq symbolic icon
install(FILES icons/16x16/actions/media-eq-symbolic.svg DESTINATION ${ICON_DIR}/16x16/actions)

# playlist icons
install(FILES icons/16x16/mimetypes/playlist.svg DESTINATION ${ICON_DIR}/16x16/mimetypes)
install(FILES icons/16x16/mimetypes/playlist-automatic.svg DESTINATION ${ICON_DIR}/16x16/mimetypes)

# process-completed and error
install(FILES icons/16x16/mimetypes/process-completed-symbolic.svg DESTINATION ${ICON_DIR}/16x16/status)
install(FILES icons/16x16/mimetypes/process-error-symbolic.svg DESTINATION ${ICON_DIR}/16x16/status)

# last fm
install(FILES icons/16x16/actions/lastfm-love.svg DESTINATION ${ICON_DIR}/16x16/actions)
install(FILES icons/16x16/actions/lastfm-ban.svg DESTINATION ${ICON_DIR}/16x16/actions)

# Update icon cache
option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif ()
