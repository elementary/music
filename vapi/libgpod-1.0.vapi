[CCode (cprefix = "Itdb_", cheader_filename="gpod/itdb.h")]
namespace GPod {
  
  [Compact]
  [CCode (cname="Itdb_Device", lower_case_cprefix = "itdb_device_")]
  public class Device {
	  public void set_mountpoint(string mp);
	  public bool read_sysinfo();
	  public bool write_sysinfo() throws GLib.Error;
	  public string get_sysinfo(string field);
	  public void set_sysinfo(string field, string value);
	  public unowned GPod.iPodInfo get_ipod_info();
	  public bool supports_artwork();
	  public bool supports_chapter_image();
	  public bool supports_video();
	  public bool supports_photo();
	  public bool supports_podcast();
	  public int get_uuid();
	  
	  [CCode (cname="itdb_get_music_dir")]
	  public static string get_music_dir(string mount_point);
  }	
  
  [Compact]
  [CCode (cname="Itdb_IpodInfo", lower_case_cprefix = "itdb_info_")]
  public class iPodInfo {
	  public string model_number;
	  public double capacity;
	  public GPod.iPodModel ipod_model;
	  public GPod.iPodGeneration ipod_generation;
	  public uint musicdirs;
	  
	  [CCode (cname="itdb_info_get_ipod_model_name_string")]
	  public static string get_ipod_model_name_string(GPod.iPodModel model);
	  [CCode (cname="itdb_info_get_ipod_generation_string")]
	  public static string get_ipod_generation_string(GPod.iPodGeneration generation);
  }
	
  [Compact]
  [CCode (cname="Itdb_iTunesDB", lower_case_cprefix = "itdb_")]
  public class iTunesDB {
    public GLib.List<GPod.Track> tracks;
    public GLib.List<GPod.Playlist> playlists;
    public string filename;
    public unowned GPod.Device device;
    public uint32 version;
    public uint64 id;
    public int tzoffset;
	
	/* functions for reading/writing database, general itdb functions */
    public static iTunesDB parse (string mp) throws GLib.Error;
    public static iTunesDB parse_file (string filename) throws GLib.Error;
    
    public bool write () throws GLib.Error;
    public bool write_file (string filename) throws GLib.Error;
    public bool shuffle_write () throws GLib.Error;
    public bool shuffle_write_file (string filename) throws GLib.Error;
    public bool start_sync ();
    public bool stop_sync ();
    public iTunesDB new();
    public void free();
    public iTunesDB duplicate(); /* not implemented */
    public uint tracks_number();
    public uint tracks_number_nontransferred();
    public uint playlists_number();
	
	/* general file functions */
	public int music_dirs_number();
	public static string resolve_path(string root, string components);
	public static bool rename_files(string mp) throws GLib.Error;
	public static string cp_get_dest_filename(GPod.Track track, string mountpoint, string filename) throws GLib.Error;
	public static bool cp(string from_file, string to_file) throws GLib.Error;
	public static GPod.Track cp_finalize(GPod.Track track, string mountpoint, string dest_filename) throws GLib.Error;
	public static bool cp_track_to_ipod(GPod.Track track, string filename) throws GLib.Error;
	
	[CCode (cname = "itdb_filename_ipod2fs")]
	private static void _filename_ipod2fs(string ipod_file);
	[CCode (cname = "_vala_itdb_filename_ipod2fs")]
	public static string filename_ipod2fs (string ipod_file) {
	  string retval = ipod_file;
	  _filename_ipod2fs (retval);
	  return retval;
	}
	
	[CCode (cname = "itdb_filename_fs2ipod")]
	private static void _filename_fs2ipod (string filename);
	[CCode (cname = "_vala_itdb_filename_fs2ipod")]
	public static string filename_fs2ipod (string filename) {
	  string retval = filename;
	  _filename_fs2ipod (retval);
	  return retval;
	}
	
    public void set_mountpoint (string mp);
    public unowned string get_mountpoint ();
    
    /* track functions */
    public void track_add(owned GPod.Track track, int32 pos);
    public GPod.Track track_by_id(uint32 id);
    public GLib.Tree track_id_tree_create();
    public static void track_id_tree_destroy(GLib.Tree idtree);
    public static GPod.Track track_id_tree_by_id(GLib.Tree idtree, uint32 id);
    
    /* initialize a blank ipod */
    public static bool init_ipod (string mountpoint, string model_number, string model_name) throws GLib.Error;
	
	/* playlist stuff */
	public void playlist_add(owned GPod.Playlist pl, int32 pos);
	public GPod.Playlist playlist_by_id(uint64 id);
	public GPod.Playlist playlist_by_nr(uint32 num);
	public GPod.Playlist playlist_by_name(string name);
	
	/* smart playlist stuff */
	public void spl_update_all();
	public void spl_update_live();
	
	/* for master playlist */
	public unowned GPod.Playlist playlist_mpl();
	
	/* for podcasts */
	public unowned GPod.Playlist playlist_podcasts();
  }

  [Compact]
  [CCode (cname="Itdb_Playlist", lower_case_cprefix = "itdb_playlist_")]
  public class Playlist {
    public unowned GPod.iTunesDB itdb;
    public string name;
    public int num;
    public GLib.List<unowned GPod.Track> members;
    public bool is_spl;
    public time_t timestamp;
    public uint64 id;
    public uint sortorder;
    public uint32 podcastflag;
    public GPod.SPLPref splpref;
    public GPod.SPLRules splrules;
    
    public Playlist(string title, bool ispl);

    //public void add (GPod.Playlist pl, uint32 pos);
    public void move (uint32 pos);
    public void remove ();
    public void unlink ();
    public Playlist duplicate ();
    // public bool exists(GPod.Playlist pl);
    public void add_track (GPod.Track track, int32 pos);
    public bool contains_track (GPod.Track track);
    // contain_track_number?
    public void remove_track (GPod.Track track);
    public uint32 tracks_number();
    public void randomize();
    
    /* for master playlist */
    public bool is_mpl();
    public void set_mpl();
    
    /* for podcasts */
    public bool is_podcasts();
    public void set_podcasts();
    
    /* for audio books */
    public bool is_audiobooks();
    
    /* for smart playlists */
    [CCode (cname = "itdb_splr_remove")]
    public void splr_remove(GPod.SPLRule splr);
    
    [CCode (cname = "itdb_splr_add")]
    public void splr_add(owned GPod.SPLRule splr, int pos);
    
    [CCode (cname = "itdb_splr_add_new")]
    public unowned GPod.SPLRule? splr_add_new(int pos);
    
    [CCode (cname = "itdb_spl_copy_rules")]
    public void spl_copy_rules(GPod.Playlist src);
    
    [CCode (cname = "itdb_spl_update")]
    public void spl_update();
  }
  
  [CCode (cname="Itdb_SPLPref")]
  public struct SPLPref {
	  public uint8 liveupdate;
	  public uint8 checkrules;
	  public uint8 checklimits;
	  public uint32 limittype;
	  public uint32 limitsort;
	  public uint32 limitvalue;
	  public uint8 matchcheckedonly;
  }
  
  [CCode (cname="Itdb_SPLRule", lower_case_cprefix="itdb_splr_")]
  public struct SPLRule {
	  public uint32 field;
	  public uint32 action;
	  
	  [CCode (cname="string")]
	  public string @string;
	  
	  public uint64 fromvalue;
	  public int64 fromdate;
	  public uint64 fromunits;
	  public uint64 tovalue;
	  public int64 todate;
	  public uint64 tounits;
	  
	  public GPod.SPLFieldType get_field_type();
	  public GPod.SPLActionType get_action_type();
	  public void validate();
	  public bool eval(GPod.Track track);
  }
  
  public struct SPLRules {
	  public int32 unk004;
	  public uint32 match_operator;
	  public GLib.List<unowned GPod.SPLRule?> rules;
  }
  
  /*[Compact]
  [CCode (cname="Itdb_Thumb", lower_case_prefix="itdb_thumb_")]
  public class Thumb {
	  
  }*/
  
  [Compact]
  [CCode (cname="Itdb_Artwork", lower_case_cprefix="itdb_artwork_")]
  public class Artwork {
	  //public unowned GPod.Thumb thumbnail;
	  public uint32 id;
	  public uint64 dbid;
	  public int32 unk028;
	  public uint32 rating;
	  public int32 unk036;
	  public time_t creation_date;
	  public time_t digitized_date;
	  public uint32 artwork_size;
	  
	  public GPod.Artwork duplicate();
	  public bool set_thumbnail(string filename, int rotation) throws GLib.Error;
	  public bool set_thumbnail_fron_data([CCode (type = "guchar*", array_length_type = "gsize")] uint[] image_data, int rotation) throws GLib.Error;
	  public bool set_thumbnail_from_pixbuf(Gdk.Pixbuf pixbuf, int rotation) throws GLib.Error;
	  public void remove_thumbnails();
  }

  [Compact]
  [CCode (cname="Itdb_Track", lower_case_cprefix="itdb_track_")]
  public class Track {
    public unowned GPod.iTunesDB itdb;
    public string title;
    public string ipod_path;
    public string album;
    public string artist;
    public string genre;
    public string filetype;
    public string comment;
    public string category;
    public string composer;
    public string grouping;
    public string description;
    public string podcasturl;
    public string podcastrss;
    //public unowned GPod.Chapterdata chapterdata;
    public string subtitle;
    public string tvshow;
    public string tvepisode;
    public string tvnetwork;
    public string albumartist;
    public string keywords;
    public string sort_artist;
    public string sort_title;
    public string sort_album;
    public string sort_albumartist;
    public string sort_composer;
    public string sort_tvshow;
    public uint32 id;
    public uint32 size;
    public int tracklen;
    public int cd_nr;
    public int cds;
    public int track_nr;
    public int tracks;
    public int bitrate;
    public uint16 samplerate;
    public uint16 samplerate_low;
    public int year;
    public int volume;
    public uint soundcheck;
    public time_t time_added;
    public time_t time_modified;
    public time_t time_played;
    public uint bookmark_time;
    public uint rating;
    public uint playcount;
    public uint playcount2;
    public uint recent_playcount;
    public bool transferred;
    public uint16 BPM;
    public uint8 app_rating;
    public uint8 type1;
    public uint8 type2;
    public uint8 compilation;
    public uint starttime;
    public uint stoptime;
    public int8 checked;
    public uint64 dbid;
    public uint drm_userid;
    public uint visible;
    public int filetype_marker;
    public uint16 artwork_count;
    public uint artwork_size;
    public float samplerate2;
    public uint16 unk126;
    public uint32 unk132;
    public time_t time_released;
    public uint16 unk144;
    public uint16 explicit_flag;
    public uint unk148;
    public uint unk152;
    public uint skipcount;
    public uint recent_skipcount;
    public uint last_skipped;
    public uint8 has_artwork;
    public uint8 skip_when_shuffling;
    public uint8 remember_playback_position;
    public uint8 flag4;
    public uint64 dbid2;
    public uint8 lyrics_flag;
    public uint8 movie_flag;
    public uint8 mark_unplayed;
    public uint8 unk179;
    public uint32 unk180;
    public uint32 pregap;
    public uint64 samplecount;
    public uint unk196;
    public uint postgap;
    public uint unk204;
    public uint mediatype;
    public uint season_nr;
    public uint episode_nr;
    public uint unk220;
    public uint unk224;
    public uint unk228;
    public uint unk232;
    public uint unk236;
    public uint unk240;
    public uint unk244;
    public uint gapless_data;
    public uint unk252;
    public uint16 gapless_track_flag;
    public uint16 gapless_album_flag;
    public uint16 obsolete;
    public unowned GPod.Artwork artwork;
    public uint mhii_link;
    
    //[CCode (cname="itdb_track_new")]
	public Track();
    
    public void remove();
    public void unlink();
    public GPod.Track duplicate();
    
    public bool set_thumbnails(string filename);
    //public bool set_thumbnails_from_data(string image_data, int image_data_len);
    public bool set_thumbnails_from_pixbuf(Gdk.Pixbuf pixbuf);
    public bool has_thumbnails();
    public void remove_thumbnails();
    public Gdk.Pixbuf get_thumbnail(int width, int height);
  }
  
  [CCode (cname = "Itdb_Mediatype", cprefix="ITDB_MEDIATYPE_")]
  public enum MediaType {
	AUDIO,
    MOVIE,
    PODCAST,
    AUDIOBOOK,
    MUSICVIDEO,
    TVSHOW,
    RINGTONE,
    RENTAL,
    ITUNES_EXTRA,
    MEMO,
    ITUNES_U,
    EPUB_BOOK
  }
  
  [CCode (cname = "Itdb_IpodGeneration", cprefix="ITDB_IPOD_GENERATION_")]
  public enum iPodGeneration {
	UNKNOWN,
    FIRST,
    SECOND,
    THIRD,
    FOURTH,
    PHOTO,
    MOBILE,
    MINI_1,
    MINI_2,
    SHUFFLE_1,
    SHUFFLE_2,
    SHUFFLE_3,
    NANO_1,
    NANO_2,
    NANO_3,
    NANO_4,
    VIDEO_1,
    VIDEO_2,
    CLASSIC_1,
    CLASSIC_2,
    TOUCH_1,
    IPHONE_1,
    SHUFFLE_4,
    TOUCH_2,
    IPHONE_2,
    IPHONE_3,
    CLASSIC_3,
    NANO_5,
    TOUCH_3,
    IPAD_1,
    IPHONE_4,
    TOUCH_4,
    NANO_6
  }
  
  [CCode (cname = "Itdb_IpodModel", cprefix="ITDB_IPOD_MODEL_")]
  public enum iPodModel {
	INVALID,
    UNKNOWN,
    COLOR,
    COLOR_U2,
    REGULAR,
    REGULAR_U2,
    MINI,
    MINI_BLUE,
    MINI_PINK,
    MINI_GREEN,
    MINI_GOLD,
    SHUFFLE,
    NANO_WHITE,
    NANO_BLACK,
    VIDEO_WHITE,
    VIDEO_BLACK,
    MOBILE_1,
    VIDEO_U2,
    NANO_SILVER,
    NANO_BLUE,
    NANO_GREEN,
    NANO_PINK,
    NANO_RED,
    NANO_YELLOW,
    NANO_PURPLE,
    NANO_ORANGE,
    IPHONE_1,
    SHUFFLE_SILVER,
    SHUFFLE_PINK,
    SHUFFLE_BLUE,
    SHUFFLE_GREEN,
    SHUFFLE_ORANGE,
    SHUFFLE_PURPLE,
    SHUFFLE_RED,
    CLASSIC_SILVER,
    CLASSIC_BLACK,
    TOUCH_SILVER,
    SHUFFLE_BLACK,
    IPHONE_WHITE,
    IPHONE_BLACK,
    SHUFFLE_GOLD,
    SHUFFLE_STAINLESS,
    IPAD
  }
  
  [CCode (cname="ItdbPlaylistSortOrder", cprefix="ITDB_PSO_")]
  public enum PlaylistSortOrder {
	MANUAL,
    TITLE,
    ALBUM,
    ARTIST,
    BITRATE,
    GENRE,
    FILETYPE,
    TIME_MODIFIED,
    TRACK_NR,
    SIZE,
    TIME,
    YEAR,
    SAMPLERATE,
    COMMENT,
    TIME_ADDED,
    EQUALIZER,
    COMPOSER,
    PLAYCOUNT,
    TIME_PLAYED,
    CD_NR,
    RATING,
    RELEASE_DATE,
    BPM,
    GROUPING,
    CATEGORY,
    DESCRIPTION
  }
  
  [CCode (cname = "ItdbSPLMatch", cprefix="ITDB_SPLMATCH_")]
  public enum SPLMatch {
	AND,
    OR
  }
  
  [CCode (cname = "ItdbLimitType", cprefix="ITDB_LIMITTYPE_")]
  public enum LimitType {
	MINUTES,
    MB,
    SONGS,
    HOURS,
    GB
  }
  
  [CCode (cname = "ItdbLimitSort", cprefix="ITDB_LIMITSORT_")]
  public enum LimitSort {
    RANDOM,
    SONG_NAME,
    ALBUM,
    ARTIST,
    GENRE,
    MOST_RECENTLY_ADDED,
    LEAST_RECENTLY_ADDED, /* See note above */
    MOST_OFTEN_PLAYED,
    LEAST_OFTEN_PLAYED,   /* See note above */
    MOST_RECENTLY_PLAYED,
    LEAST_RECENTLY_PLAYED,/* See note above */
    HIGHEST_RATING,
    LOWEST_RATING         /* See note above */
  }
  
  [CCode (cname = "ItdbSPLAction", cprefix="ITDB_SPLACTION_")]
  public enum SPLAction {
    IS_INT,
    IS_GREATER_THAN,
    IS_LESS_THAN,
    IS_IN_THE_RANGE,
    IS_IN_THE_LAST,
    BINARY_AND,
    BINARY_UNKNOWN1,

    IS_STRING,
    CONTAINS,
    STARTS_WITH,
    ENDS_WITH,

    IS_NOT_INT,
    IS_NOT_GREATER_THAN,
    IS_NOT_LESS_THAN,
    IS_NOT_IN_THE_RANGE,
    IS_NOT_IN_THE_LAST,
    NOT_BINARY_AND,
    BINARY_UNKNOWN2,

    IS_NOT,
    DOES_NOT_CONTAIN,
    DOES_NOT_START_WITH,
    DOES_NOT_END_WITH
  }
  
  [CCode (cname = "ItdbSPLFieldType", cprefix=" ITDB_SPLFT_")]
  public enum SPLFieldType {
	STRING,
    INT,
    BOOLEAN,
    DATE,
    PLAYLIST,
    UNKNOWN,
    BINARY_AND
  }
  
  [CCode (cname = "ItdbSPLActionType", cprefix="ITDB_SPLAT_")]
  public enum SPLActionType {
	STRING,
    INT,
    DATE,
    RANGE_INT,
    RANGE_DATE,
    INTHELAST,
    PLAYLIST,
    NONE,
    INVALID,
    UNKNOWN,
    BINARY_AND
  }
  
  [CCode (cname = "ItdbSPLActionLast", cprefix="ITDB_SPLACTION_LAST_")]
  public enum SPLActionLast {
	DAYS_VALUE,    /* nr of secs in 24 hours */
    WEEKS_VALUE,  /* nr of secs in 7 days   */
    MONTHS_VALUE /* nr of secs in 30.4167
						  days ~= 1 month */
  }
  
  [CCode (cname = "ItdbSPLField", cprefix="ITDB_SPLFIELD_")]
  public enum SPLField {
	SONG_NAME,
    ALBUM,
    ARTIST,
    BITRATE,
    SAMPLE_RATE,
    YEAR,
    GENRE,
    KIND,
    DATE_MODIFIED,
    TRACKNUMBER,
    SIZE,
    TIME,
    COMMENT,
    DATE_ADDED,
    COMPOSER,
    PLAYCOUNT,
    LAST_PLAYED,
    DISC_NUMBER,
    RATING,
    COMPILATION,
    BPM,
    GROUPING,
    PLAYLIST,
    PURCHASE,
    DESCRIPTION,
    CATEGORY,
    PODCAST,
    VIDEO_KIND,
    TVSHOW,
    SEASON_NR,
    SKIPCOUNT,
    LAST_SKIPPED,
    ALBUMARTIST,
    SORT_SONG_NAME,
    SORT_ALBUM,
    SORT_ARTIST,
    SORT_ALBUMARTIST,
    SORT_COMPOSER,
    SORT_TVSHOW,
    ALBUM_RATING
  }
  
  [CCode (cname = "ItdbFileError", cprefix="ITDB_FILE_ERROR_")]
  public enum FileError {
    SEEK,
    CORRUPT,
    NOTFOUND,
    RENAME,
    ITDB_CORRUPT
  }
}
