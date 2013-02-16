
namespace Noise {

    /**
     * Supported audio types.
     *
     * We only support these even though gstreamer
     */
    public const string[] MEDIA_CONTENT_TYPES = {
        "audio/mp2",
        "audio/mpeg",
        "audio/mp4",
        "audio/x-aac",
        "audio/ogg",
        "audio/vorbis",
        "audio/flac",
        "audio/x-wav",
        "audio/x-wavpack"
    };

    /**
     *
     */

    public Settings.SavedState saved_state;
    public Settings.Main main_settings;
    public Settings.Equalizer equalizer_settings;
    public Plugins.Manager plugins;
    public DeviceManager device_manager;
    public NotificationManager notification_manager;

}
