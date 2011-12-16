namespace Build {
	public class Info {
		[CCode (cname="DATADIR", cheader_filename="config.h")]
		public const string DATADIR;

		[CCode (cname="GETTEXT_PACKAGE", cheader_filename="config.h")]
		public const string GETTEXT_PACKAGE;

		[CCode (cname="RELEASE_NAME", cheader_filename="config.h")]
		public const string RELEASE_NAME;

		[CCode (cname="VERSION", cheader_filename="config.h")]
		public const string VERSION;

		[CCode (cname="VERSION_INFO", cheader_filename="config.h")]
		public const string VERSION_INFO;
		
		public static string GET_PKG_DATADIR() {
			return DATADIR + "/" + GETTEXT_PACKAGE;
		}
	}
}
