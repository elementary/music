CREATE TABLE IF NOT EXISTS 'song_list_columns' (`title` TEXT,
												`visible` INT,
												`width` INT);

INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('id', 0, 10);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES (' ', 1, 24);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('#', 1, 40);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Track', 1, 60);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Title', 1, 220);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Length', 1, 75);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Artist', 1, 110);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Album', 1, 200);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Genre', 1, 70);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Year', 0, 30);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Bitrate', 0, 20);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Rating', 0, 90);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Plays', 0, 20);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Skips', 0, 20);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Date Added', 0, 150);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('Last Played', 0, 150);
INSERT INTO `song_list_columns` (`title`, `visible`, `width`) VALUES ('BPM', 0, 30);



CREATE TABLE IF NOT EXISTS 'songs' (`file` TEXT,
									`title` TEXT,
									`artist` TEXT,
									`album` TEXT,
									`genre` TEXT,
									`comment` TEXT, 
									`year` INT, 
									`track` INT, 
									`bitrate` INT, 
									`length` INT, 
									`samplerate` INT, 
									`rating` INT, 
									`playcount` INT, 
									'skipcount' INT, 
									`dateadded` INT, 
									`lastplayed` INT, 
									'file_size' INT);
									
CREATE TABLE IF NOT EXISTS 'playlists' (`name` TEXT, 
											`songs` TEXT, 
											'sort_column' TEXT, 
											'sort_direction' TEXT, 
											'columns' TEXT);
											
CREATE TABLE IF NOT EXISTS 'smart_playlists' (`name` TEXT, 
												`and_or` TEXT, 
												`queries` TEXT, 
												'limit' INT, 
												'limit_amount' INT, 
												'sort_column' TEXT, 
												'sort_direction' TEXT, 
												'columns' TEXT);
												
CREATE TABLE IF NOT EXISTS 'artists' ('name' TEXT, 
										'mbid' TEXT, 
										'url' TEXT, 
										'streamable' INT, 
										'listeners' INT, 
										'playcount' INT, 
										'published' TEXT, 
										'summary' TEXT, 
										'content' TEXT, 
										'tags' TEXT, 
										'similar' TEXT, 
										'url_image' TEXT);
										
CREATE TABLE IF NOT EXISTS 'albums' ('name' TEXT, 
										'artist' TEXT, 
										'mbid' TEXT, 
										'url' TEXT, 
										'release_date' TEXT, 
										'listeners' INT, 
										'playcount' INT, 
										'tags' TEXT,  
										'url_image' TEXT);
										
CREATE TABLE IF NOT EXISTS 'tracks' ('id' INT, 
										'name' TEXT, 
										'artist' TEXT, 
										'url' TEXT, 
										'duration' INT, 
										'streamable' INT, 
										'listeners' INT, 
										'playcount' INT, 
										'summary' TEXT, 
										'content' TEXT, 
										'tags' TEXT);

PRAGMA user_version = 0
