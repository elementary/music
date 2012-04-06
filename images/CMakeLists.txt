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
install(FILES icons/16x16/mimetypes/library-music.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)
install(FILES icons/16x16/mimetypes/library-podcast.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)
#install(FILES icons/16x16/mimetypes/library-audiobook.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)


# radio icon
install(FILES icons/16x16/mimetypes/internet-radio.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)

# CD icon
install(FILES icons/16x16/mimetypes/media-cdrom-audio.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)

# media-audio for default album image
install(FILES icons/128x128/mimetypes/media-audio.png DESTINATION share/noise/icons/hicolor/128x128/mimetypes)

# shuffle and repeat
install(FILES icons/16x16/status/media-playlist-repeat-one-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/status)
install(FILES icons/16x16/status/media-playlist-no-repeat-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/status)
install(FILES icons/16x16/status/media-playlist-no-shuffle-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/status)

# pane hide/show
install(FILES icons/16x16/actions/pane-show-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/actions)
install(FILES icons/16x16/actions/pane-hide-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/actions)

# new podcast icon
install(FILES icons/16x16/status/podcast-new.svg DESTINATION share/noise/icons/hicolor/16x16/status)

# playlist icons
install(FILES icons/16x16/mimetypes/playlist.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)
install(FILES icons/16x16/mimetypes/playlist-automatic.svg DESTINATION share/noise/icons/hicolor/16x16/mimetypes)

# process-completed and error
install(FILES icons/16x16/mimetypes/process-completed-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/status)
install(FILES icons/16x16/mimetypes/process-error-symbolic.svg DESTINATION share/noise/icons/hicolor/16x16/status)

# last fm
install(FILES icons/16x16/actions/lastfm-love.svg DESTINATION share/noise/icons/hicolor/16x16/actions)
install(FILES icons/16x16/actions/lastfm-ban.svg DESTINATION share/noise/icons/hicolor/16x16/actions)

# Update icon cache
install (CODE "message(\"Updating GTK+ icon cache (hicolor) ...\")")
install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
")

