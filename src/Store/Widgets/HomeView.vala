using Gtk;

public class Store.HomeView : HBox {
	Store.store store;
	Store.StoreView parent;
	
	Toolbar leftBar;
	ComboBox tagSelector;
	ToggleToolButton newReleasesOption;
	ToggleToolButton topArtistsOption;
	ToggleToolButton topReleasesOption;
	ToggleToolButton topTracksOption;
	ToggleToolButton recommendedOption;
	
	bool toggling;
	ToggleToolButton currentlySelected;
	
	SearchList mainList;
	
	public HomeView(StoreView storeView, Store.store store) {
		this.parent = storeView;
		this.store = store;
		toggling = false;
		
		buildUI();
		
		topArtistsOption.active = true;
        currentlySelected = topArtistsOption;
	}
	
	public void buildUI() {
		leftBar = new Toolbar();
		tagSelector = new ComboBox.text();
		newReleasesOption = new ToggleToolButton();
		topArtistsOption = new ToggleToolButton();
		topReleasesOption = new ToggleToolButton();
		topTracksOption = new ToggleToolButton();
		recommendedOption = new ToggleToolButton();
		
		mainList = new Store.SearchList(parent, SearchList.SearchListType.RELEASE);
		
		tagSelector.append_text("All Genres");
		tagSelector.append_text("pop");
		tagSelector.append_text("rock");
		tagSelector.append_text("electronic");
		tagSelector.append_text("dance");
		tagSelector.append_text("punk");
		tagSelector.append_text("country");
		tagSelector.append_text("grunge");
		tagSelector.append_text("hip hop/rap");
		tagSelector.append_text("comedy");
		
		ToolItem tagSelectorBin = new ToolItem();
        tagSelectorBin.add(tagSelector);
        tagSelectorBin.set_border_width(1);
        
        leftBar.insert(tagSelectorBin, 0);
        leftBar.insert(new SeparatorToolItem(), 1);
        leftBar.insert(newReleasesOption, 2);
        leftBar.insert(new SeparatorToolItem(), 3);
        leftBar.insert(topArtistsOption, 4);
        leftBar.insert(topReleasesOption, 5);
        leftBar.insert(topTracksOption, 6);
        leftBar.insert(new SeparatorToolItem(), 7);
        leftBar.insert(recommendedOption, 8);
        
        leftBar.set_orientation(Orientation.VERTICAL);
        
        newReleasesOption.set_label("New Releases");
        topArtistsOption.set_label("Top Artists");
        topReleasesOption.set_label("Top Releases");
        topTracksOption.set_label("Top Tracks");
        recommendedOption.set_label("Recommended");
        
        pack_start(leftBar, false, true, 10);
        pack_start(mainList, true, true, 0);
        
        show_all();
        
        newReleasesOption.toggled.connect(newReleasesOptionToggled);
        topArtistsOption.toggled.connect(topArtistsOptionToggled);
        topReleasesOption.toggled.connect(topReleasesOptionToggled);
        topTracksOption.toggled.connect(topTracksOptionToggled);
        recommendedOption.toggled.connect(recommendedOptionToggled);
	}
	
	public void newReleasesOptionToggled() {
		if(currentlySelected == newReleasesOption || toggling)
			return;
		
		toggling = true;
		newReleasesOption.active = true;
		topArtistsOption.active = false;
		topReleasesOption.active = false;
		topTracksOption.active = false;
		recommendedOption.active = false;
		toggling = false;
		
		currentlySelected = newReleasesOption;
		mainList.setType(SearchList.SearchListType.RELEASE);
		
		// now fetch the results
		mainList.clear();
		for(int i = 1; i < 4; ++i) {
			foreach(var rel in store.newReleasesByTag(((tagSelector.get_active_text() != "All Genres") ? tagSelector.get_active_text() : "rock"), i)) {
				mainList.addItem(rel);
			}
		}
	}
	
	public void topArtistsOptionToggled() {
		if(currentlySelected == topArtistsOption || toggling)
			return;
		
		toggling = true;
		newReleasesOption.active = false;
		topArtistsOption.active = true;
		topReleasesOption.active = false;
		topTracksOption.active = false;
		recommendedOption.active = false;
		toggling = false;
		
		currentlySelected = topArtistsOption;
		mainList.setType(SearchList.SearchListType.ARTIST);
		
		mainList.clear();
		for(int i = 1; i < 4; ++i) {
			foreach(var artist in store.topArtists("week", null, ((tagSelector.get_active_text() != "All Genres") ? tagSelector.get_active_text() : null), i)) {
				mainList.addItem(artist);
			}
		}
	}
	
	public void topReleasesOptionToggled() {
		if(currentlySelected == topReleasesOption || toggling)
			return;
		
		toggling = true;
		newReleasesOption.active = false;
		topArtistsOption.active = false;
		topReleasesOption.active = true;
		topTracksOption.active = false;
		recommendedOption.active = false;
		toggling = false;
		
		currentlySelected = topReleasesOption;
		mainList.setType(SearchList.SearchListType.RELEASE);
		
		mainList.clear();
		for(int i = 1; i < 4; ++i) {
			foreach(var rel in store.topReleases("week", null, ((tagSelector.get_active_text() != "All Genres") ? tagSelector.get_active_text() : null), i)) {
				mainList.addItem(rel);
			}
		}
	}
	
	public void topTracksOptionToggled() {
		if(currentlySelected == topTracksOption || toggling)
			return;
		
		toggling = true;
		newReleasesOption.active = false;
		topArtistsOption.active = false;
		topReleasesOption.active = false;
		topTracksOption.active = true;
		recommendedOption.active = false;
		toggling = false;
		
		currentlySelected = topTracksOption;
		mainList.setType(SearchList.SearchListType.TRACK);
		
		mainList.clear();
		foreach(var release in store.topTracks("week", null, 1)) {
			mainList.addItem(release);
		}
		foreach(var release in store.topTracks("week", null, 2)) {
			mainList.addItem(release);
		}
		foreach(var release in store.topTracks("week", null, 3)) {
			mainList.addItem(release);
		}
	}
	
	public void recommendedOptionToggled() {
		if(currentlySelected == recommendedOption || toggling)
			return;
		
		toggling = true;
		newReleasesOption.active = false;
		topArtistsOption.active = false;
		topReleasesOption.active = false;
		topTracksOption.active = false;
		recommendedOption.active = true;
		toggling = false;
		
		currentlySelected = recommendedOption;
		mainList.setType(SearchList.SearchListType.TRACK);
	}
}
