//
//  AMLibrary.h
//  AutoMac
//
//  Created by Andrew Cooper on 5/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMLibrary : NSObject {
	NSArray *playlists;
	NSArray *genres;
	NSArray *artists;
	NSArray *albums;
	NSArray *tracks;
	
	int currentFilter;
	int selectedPlaylist;
	NSIndexSet *selectedGenres;
	NSIndexSet *selectedArtists;
	NSIndexSet *selectedAlbums;
	NSIndexSet *selectedTracks;

	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	NSArray *plBlacklist;
	NSDictionary *plPriorities;
	NSSortDescriptor *nameSort;
	
	BOOL needsReload;
	
	IBOutlet NSWindow    *updateProgressDialog;
	IBOutlet NSTextField *updateProgressTrackStatus;
	IBOutlet NSTextField *updateProgressPlaylistStatus;
	IBOutlet NSTextField *updateProgressSaveStatus;
	IBOutlet NSProgressIndicator *updateProgressIndicator;	
}

extern NSString *AMMediaStoreFile;
extern NSString *AMUnknownItemName;
extern NSString *AMCustomPlaylistName;

#pragma mark Accessors
- (NSArray *)tracks;
- (NSArray *)albums;
- (NSArray *)artists;
- (NSArray *)genres;
- (NSArray *)playlists;
- (NSArray *)selectedTracks;

- (NSIndexSet *)genreSelection;
- (NSIndexSet *)artistSelection;
- (NSIndexSet *)albumSelection;
- (NSIndexSet *)trackSelection;

- (void)setGenreSelection:(NSIndexSet *)indexSet;
- (void)setArtistSelection:(NSIndexSet *)indexSet;
- (void)setAlbumSelection:(NSIndexSet *)indexSet;
- (void)setTrackSelection:(NSIndexSet *)indexSet;
- (void)setSelectedPlaylist:(int)selIndex;

- (void)reloadLibrary;

//- (int)currentFilterSelection;
//- (void)setCurrentFilter:(int)filterType;
//- (void)setCurrentFilterSelection:(int)rowIndex;
//
//- (void)selectPlaylist:(int)index;
//- (void)selectGenre:(int)index;
//- (void)selectArtist:(int)index;
//- (void)selectAlbum:(int)index;
//- (void)selectTrack:(int)index;
//- (int)selectedPlaylist;
//- (int)selectedGenre;
//- (int)selectedArtist;
//- (int)selectedAlbum;
//- (int)selectedTrack;
//

@end
