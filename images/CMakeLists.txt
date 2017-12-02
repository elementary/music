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
