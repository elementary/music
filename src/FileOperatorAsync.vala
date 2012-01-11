/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
/*
using TagLib;
using GLib;
using Gee;

public class BeatBox.MetadataJob : Object {
	public enum JobType {
		IMPORT,
		ART_FETCH
	}
	
	public MetadataJob(string path, JobType type) {
		this.path = path;
		this.type = type;
	}
	
	public string path { get; set; default=""; }
	public JobType type { get; set; default=JobType.IMPORT; }
}

public class BeatBox.MetadataWorker : Object {
	private BeatBox.LibraryManager lm;
	public GStreamerTagger tagger;
	
	LinkedList<Media> new_imports;
	LinkedList<string> import_errors;
	HashMap<string, MetadataJob> jobs;
	MetadataJob current_job;
	Media being_imported;
	
	public MetadataWorker(BeatBox.LibraryManager lmm, BeatBox.Settings sett) {
		lm = lmm;
		tagger = new GStreamerTagger();
		new_imports = new LinkedList<Media>();
		import_errors = new LinkedList<string>();
		jobs = new HashMap<string, MetadataJob>();
		
		lm.progress_cancel_clicked.connect( () => { cancelled = true; } );
		tagger.media_imported.connect(media_imported);
		tagger.import_error.connect(import_error);
		tagger.queue_finished.connect(queue_finished);
	}
	
	public void import_files(LinkedList<string> files) {
		foreach(string s in files) {
			if(jobs.get(s) == null) {
				MetadataJob j = new MetadataJob(s, MetadataJob.JobType.IMPORT);
				tagger.discoverer_import_media(s);
			}
			else {
				stdout.printf("Not going to import %s: already queued\n", s);
			}
		}
	}
	
	void media_imported(Media m) {
		new_imports.add(m);
		
		if(new_imports.size > 500) {
			stdout.printf("adding medias\n");
			lm.add_medias(new_imports, true); // give user some feedback
			stdout.printf("media added\n");
			new_imports.clear();
		}
	}
	
	void import_error(string file) {
		import_errors.add(file);
	}
	
	void queue_finished() {
		lm.add_medias(new_imports);
	}
}*/
