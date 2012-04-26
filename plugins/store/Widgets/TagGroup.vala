/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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
 
/*using Gtk;
using Gee;

public class Store.TagGroup : Layout {
	private LinkedList<Store.TagLabel> tags;
	private int spacing;
	
	private int preferredWidth;
	private int preferredHeight;
	
	bool alreadyResized;
	
	public TagGroup(LinkedList<TagLabel> initialTags, int defaultSpacing) {
		tags = initialTags;
		spacing = defaultSpacing;
		
		alreadyResized = false;
		
		foreach(var label in initialTags) {
			put(label, 0, 0);
			label.show();
		}
		
		this.size_allocate.connect(resized);
	}
	
	public void addTagLabel(TagLabel tag) {
		tags.add(tag);
		
		// just add the tag at a random location for now
		put(tag, 0, 0);
	}
	
	public void set_preferred_size(int width, int height) {
		preferredWidth = width;
		preferredHeight = height;
	}
	
	public virtual void resized(Gdk.Rectangle rec) {
		if(alreadyResized) {
			alreadyResized = false;
			return;
		}
		
		alreadyResized = true;
		
		LinkedList<LinkedList<TagLabel>> buckets = new LinkedList<LinkedList<TagLabel>>();
		buckets.add(new LinkedList<TagLabel>());
		
		int runningX = 0;
		int runningY = 0;
		
		foreach(var label in tags) {
			stdout.printf("is %d > %d\n", label.allocation.width + runningX, rec.width);
			if(label.allocation.width + runningX > rec.width && buckets.get(buckets.size - 1).size > 0) {
				buckets.add(new LinkedList<TagLabel>());
				runningX = 0;
			}
			
			buckets.get(buckets.size - 1).add(label);
			runningX += label.allocation.width + spacing;
		}
		
		runningX = 0;
		runningY = 0;
		
		foreach(var row in buckets) {
			int rowUsedSpace = 0;
			int leftovers = 0;
			bool smartSpacing = false;
			
			foreach(var item in row) {
				rowUsedSpace += item.allocation.width;
			}
			
			leftovers = rec.width - rowUsedSpace;
			if(leftovers/(row.size-1) < 50 && leftovers/(row.size-1) > 5) {
				smartSpacing = true;
			}
			
			// now actually move them around
			foreach(var item in row) {
				move(item, runningX, runningY);
				
				runningX += (item.allocation.width) + ((smartSpacing) ? (leftovers/(row.size-1)) : spacing);
			}
			
			runningX = 0;
			runningY += row.get(0).allocation.height + 6;
		}
	}
	
}*/
