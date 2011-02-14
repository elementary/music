using Xml;

public class LastFM.SimilarSongs : Object {
	BeatBox.LibraryManager _lm;
	BeatBox.Song _base;
	bool working;
	
	Gee.LinkedList<BeatBox.Song> similarAll;
	Gee.LinkedList<BeatBox.Song> similarDo;
	Gee.LinkedList<BeatBox.Song> similarDont;
	
	BeatBox.Song similarToAdd;
	
	public signal void similar_retrieved(Gee.LinkedList<BeatBox.Song> similarDo, Gee.LinkedList<BeatBox.Song> similarDont);
	
	public class SimilarSongs(BeatBox.LibraryManager lm) {
		_lm = lm;
		working = false;
	}
	
	public virtual void queryForSimilar(BeatBox.Song s) {
		_base = s;
		
		if(!working) {
			working = true;
			
			try {
				Thread.create<void*>(similar_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("ERROR: Could not create similar thread: %s \n", err.message);
			}
		}
	}
	
	public void* similar_thread_function () {	
		similarAll = new Gee.LinkedList<BeatBox.Song>();
		similarDo = new Gee.LinkedList<BeatBox.Song>();
		similarDont = new Gee.LinkedList<BeatBox.Song>();
		
		getSimilarTracks(_base.title, _base.artist);
		
		similarDo.add(_base);
		foreach(BeatBox.Song sim in similarAll) {
			BeatBox.Song s = _lm.song_from_name(sim.title, sim.artist);
			if(s.rowid != 0) {
				similarDo.add(s);
			}
			else {
				similarDont.add(sim);
			}
		}
		
		Idle.add( () => {
			similar_retrieved(similarDo, similarDont);
			return false;
		});
		
		working = false;
		
		return null;	
    }
	
	/** Gets similar songs
	 * @param artist The artist of song to get similar to
	 * @param title The title of song to get similar to
	 * @return The songs that are similar
	 */
	public void getSimilarTracks(string title, string artist) {
		var artist_fixed = LastFM.Core.fix_for_url(artist);
		var title_fixed =  LastFM.Core.fix_for_url(title);
		var url = "http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=" + artist_fixed + "&track=" + title_fixed + "&api_key=" + LastFM.Core.api;
		Xml.Doc* doc = Parser.parse_file (url);
		
		if(doc == null)
			stdout.printf("Could not load similar artist information for %s by %s", title, artist);
		else if(doc->get_root_element() == null)
			stdout.printf("Oddly, similar artist information was invalid");
		else {
			//stdout.printf("Getting similar tracks with %s... \n", url);
			similarToAdd = null;
			parse_similar_nodes(doc->get_root_element(), "");
		}
	}
	
	public void parse_similar_nodes(Xml.Node* node, string parent) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "similartrackstrack") {
				if(node_name == "name") {
					if(similarToAdd != null) {
						similarAll.add(similarToAdd);
					}
					
					similarToAdd = new BeatBox.Song("");
					similarToAdd.title = node_content;
				}
				else if(node_name == "url") {
					similarToAdd.lastfm_url = node_content;
				}
			}
			else if(parent == "similartrackstrackartist") {
				if(node_name == "name") {
					similarToAdd.artist = node_content;
				}
			}
			
			parse_similar_nodes(iter, parent+node_name);
		}
		
	}
}
