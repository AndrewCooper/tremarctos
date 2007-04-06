//
//  AMLibrary.m
//  AutoMac
//
//  Created by Andrew Cooper on 5/25/06.
//  Copyright 2006 HKCreations. All rights reserved.
//

#import "AMLibrary.h"
@interface AMLibrary (PrivateMethods)
- (NSString *)applicationSupportFolder;
- (NSURL *)persistentStoreFileURL;
- (void)reloadITunesLibrary:(NSDictionary *)library intoManagedContext:(NSManagedObjectContext *)context;
- (NSManagedObject *)selectedPlaylist;
- (void)setGenreSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce;
- (void)setArtistSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce;
- (void)setAlbumSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce;
- (void)setTrackSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce;

#pragma mark CoreData methods
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
@end

@implementation AMLibrary
NSString *AMiTunesLibraryPath = @"~/Music/iTunes/iTunes Music Library.xml";
NSString *AMMediaStoreFile = @"AutoMacMedia.db";
NSString *AMUnknownItemName = @"Unknown";
NSString *AMCustomPlaylistName = @"On-The-Go";

- (id)init
{
	if (self = [super init])
	{
		plBlacklist = [[NSArray alloc] initWithObjects:@"Party Shuffle",@"Purchased"];
		plPriorities = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:0],@"Library", [NSNumber numberWithInt:1],AMCustomPlaylistName, [NSNumber numberWithInt:2],@"Podcasts", [NSNumber numberWithInt:2],@"Videos",nil];
		nameSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
		[self setSelectedPlaylist:0];
		needsReload = YES;
		return self;
	}
	return nil;
}

- (void) dealloc
{	
	[managedObjectContext release], managedObjectContext = nil;
	[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
	[managedObjectModel release], managedObjectModel = nil;
	[selectedGenres release];
	[selectedArtists release];
	[selectedAlbums release];
	[selectedTracks release];
	[super dealloc];
}

#pragma mark Accessors
- (NSArray *)playlists
{
	if (playlists)
		return playlists;
	NSManagedObjectContext *context = [self managedObjectContext];
	NSSortDescriptor *prioritySort = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context]];
//	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:prioritySort,nameSort,nil]];
	playlists = [[context executeFetchRequest:fetchRequest error:NULL] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:prioritySort,nameSort,nil]];;
	[prioritySort release];
	[fetchRequest release];
	return [playlists retain];
}
- (NSArray *)genres
{
	if (genres)
		return genres;
	NSSet *genreSet = [[self selectedPlaylist] valueForKeyPath:@"tracks.@distinctUnionOfObjects.genre"];
	NSArray *tmpArray = [[genreSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSort]];
	genres = [[[NSArray arrayWithObject:[NSString stringWithFormat:@"All Genres (%d)",[tmpArray count]]] arrayByAddingObjectsFromArray:tmpArray] retain];
	return genres;
}
- (NSArray *)artists
{
	if (artists)
		return artists;
	NSIndexSet *idxSetGenres = [self genreSelection];
	NSArray *allGenres = [self genres];
	NSArray *selGenres = [idxSetGenres containsIndex:0] ? [allGenres subarrayWithRange:NSMakeRange(1,[allGenres count]-1)] : [allGenres objectsAtIndexes:idxSetGenres];
	NSMutableSet *artistSet = [NSMutableSet setWithArray:[selGenres valueForKeyPath:@"tracks.@distinctUnionOfSets.artist"]];
	NSSet *plArtistSet = [[self selectedPlaylist] valueForKeyPath:@"tracks.@distinctUnionOfObjects.artist"];
	[artistSet intersectSet:plArtistSet];
	NSArray *tmpArray = [[artistSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSort]];
	artists = [[[NSArray arrayWithObject:[NSString stringWithFormat:@"All Artists (%d)",[tmpArray count]]] arrayByAddingObjectsFromArray:tmpArray] retain];
	return artists;
}
- (NSArray *)albums
{
	if (albums)
		return albums;
	NSIndexSet *idxSetArtists = [self artistSelection];
	NSArray *allArtists = [self artists];
	NSArray *selArtists = [idxSetArtists containsIndex:0] ? [allArtists subarrayWithRange:NSMakeRange(1,[allArtists count]-1)] : [allArtists objectsAtIndexes:idxSetArtists];
	NSMutableSet *albumSet = [NSMutableSet setWithArray:[selArtists valueForKeyPath:@"tracks.@distinctUnionOfSets.album"]];
	NSSet *plAlbumSet = [[self selectedPlaylist] valueForKeyPath:@"tracks.@distinctUnionOfObjects.album"];
	[albumSet intersectSet:plAlbumSet];
	NSArray *tmpArray = [[albumSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSort]];
	albums = [[[NSArray arrayWithObject:[NSString stringWithFormat:@"All Albums (%d)",[tmpArray count]]] arrayByAddingObjectsFromArray:tmpArray] retain];
	return albums;
}
- (NSArray *)tracks
{
	if (tracks)
		return tracks;
	NSIndexSet *idxSetAlbums = [self albumSelection];
	NSArray *allAlbums = [self albums];
	NSArray *selAlbums = [idxSetAlbums containsIndex:0] ? [allAlbums subarrayWithRange:NSMakeRange(1,[allAlbums count]-1)] : [allAlbums objectsAtIndexes:idxSetAlbums];
	NSMutableSet *trackSet = [NSMutableSet setWithArray:[selAlbums valueForKeyPath:@"@unionOfSets.tracks"]];
	NSManagedObject *playlist = [[self playlists] objectAtIndex:selectedPlaylist];
	NSSet *plTrackSet = [playlist valueForKeyPath:@"tracks"];
	[trackSet intersectSet:plTrackSet];
	NSArray*tmpArray = [[trackSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSort]];
	tracks = [[[NSArray arrayWithObject:[NSString stringWithFormat:@"All Tracks (%d)",[tmpArray count]]] arrayByAddingObjectsFromArray:tmpArray] retain];
	return tracks;
}

- (NSArray *)selectedTracks
{
	NSIndexSet *idxSetTracks = [self trackSelection];
	NSArray *allTracks = [self tracks];
	NSArray *selTracks = [idxSetTracks containsIndex:0] ? [allTracks subarrayWithRange:NSMakeRange(1,[allTracks count]-1)] : [allTracks objectsAtIndexes:idxSetTracks];
	return selTracks;
}

- (NSIndexSet *)genreSelection
{
	return selectedGenres;
}
- (NSIndexSet *)artistSelection
{
	return selectedArtists;
}
- (NSIndexSet *)albumSelection
{
	return selectedAlbums;
}
- (NSIndexSet *)trackSelection
{
	return selectedTracks;
}

- (void)setSelectedPlaylist:(int)selIndex
{
	selectedPlaylist = selIndex;
	[self setGenreSelection:[NSIndexSet indexSetWithIndex:0] force:YES];
	[genres release]; genres = nil;
}

- (void)setGenreSelection:(NSIndexSet *)indexSet
{
	[self setGenreSelection:indexSet force:NO];
}
- (void)setArtistSelection:(NSIndexSet *)indexSet
{
	[self setArtistSelection:indexSet force:NO];
}
- (void)setAlbumSelection:(NSIndexSet *)indexSet
{
	[self setAlbumSelection:indexSet force:NO];
}
- (void)setTrackSelection:(NSIndexSet *)indexSet
{
	[self setTrackSelection:indexSet force:NO];
}

- (void)reloadLibrary
{
	NSURL *store = [self persistentStoreFileURL];
	NSFileManager *fm = [NSFileManager defaultManager];
	if (persistentStoreCoordinator != nil) {
		[persistentStoreCoordinator release];
		persistentStoreCoordinator = nil;
	}
	if (managedObjectContext != nil) {
		[managedObjectContext release];
		managedObjectContext = nil;
	}
	if ([fm fileExistsAtPath:[store path]]) {
		[fm removeFileAtPath:[store path] handler:nil];
	}

	NSManagedObjectContext *context = [self managedObjectContext];
	[[context retain] release];
}

@end

@implementation AMLibrary (PrivateMethods)
/**
Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "TestCoreData" for
 the content, either in the NSApplicationSupportDirectory location or 
 (if the former cannot be found), the system's temporary directory.
 */
- (NSString *)applicationSupportFolder 
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [basePath stringByAppendingPathComponent:@"AutoMac"];
}

- (NSURL *)persistentStoreFileURL
{
	return [NSURL fileURLWithPath:[[self applicationSupportFolder] stringByAppendingPathComponent:AMMediaStoreFile]];
}

- (void)reloadITunesLibrary:(NSDictionary *)library intoManagedContext:(NSManagedObjectContext *)context
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *err = nil;
	NSFetchRequest *fetchRequest;
	NSArray *fetchResult;
	NSManagedObject *trackObj, *artistObj, *albumObj, *genreObj, *playlistObj;
	
	NSDictionary *allTracks = [library objectForKey:@"Tracks"];
	NSDictionary *dictTrack;
	NSEnumerator *trackEnum = [allTracks objectEnumerator];

	//Update Progress UI

	while (dictTrack = [trackEnum nextObject]) {
		artistObj = albumObj = genreObj = nil;

		//Update Progress UI

		//Insert next Track object
		trackObj = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:context];
		[trackObj setValue:[dictTrack objectForKey:@"Bit Rate"] forKey:@"bit_rate"];
		[trackObj setValue:[dictTrack objectForKey:@"Kind"] forKey:@"kind"];
		[trackObj setValue:[dictTrack objectForKey:@"Location"] forKey:@"location"];
		[trackObj setValue:[dictTrack objectForKey:@"Name"] forKey:@"name"];
		[trackObj setValue:[dictTrack objectForKey:@"Sample Rate"] forKey:@"sample_rate"];
		[trackObj setValue:[dictTrack objectForKey:@"Total Time"] forKey:@"total_time"];
		[trackObj setValue:[dictTrack objectForKey:@"Track ID"] forKey:@"track_id"];
		[trackObj setValue:[dictTrack objectForKey:@"Track Number"] forKey:@"track_number"];
		[trackObj setValue:[dictTrack objectForKey:@"Year"] forKey:@"year"];
		
		//Find Track's Genre if it exists or create new Genre. Add Track to the Genre's tracks array.
		NSString *trackGenre = [dictTrack objectForKey:@"Genre"];
		if (trackGenre == nil) {
			trackGenre = AMUnknownItemName;
		}
		fetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"genreNameFetch" substitutionVariables:[NSDictionary dictionaryWithObject:trackGenre forKey:@"Name"]];
		fetchResult = [context executeFetchRequest:fetchRequest error:NULL];
		if (fetchResult != nil) {
			if ([fetchResult count] == 0) {
				genreObj = [NSEntityDescription insertNewObjectForEntityForName:@"Genre" inManagedObjectContext:context];
				[genreObj setValue:trackGenre forKey:@"name"];
			} else {
				genreObj = [fetchResult objectAtIndex:0];
			}
			[trackObj setValue:genreObj forKey:@"genre"];
		}
		
		//Find Track's Artist if it exists or create new Artist. Add Track to the Artist's tracks array.
		NSString *trackArtist = [dictTrack objectForKey:@"Artist"];
		if (trackArtist == nil) {
			trackArtist = AMUnknownItemName;
		}
		fetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"artistNameFetch" substitutionVariables:[NSDictionary dictionaryWithObject:trackArtist forKey:@"Name"]];			
		fetchResult = [context executeFetchRequest:fetchRequest error:NULL];
		if (fetchResult != nil) {
			if ([fetchResult count] == 0) {
				artistObj = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];
				[artistObj setValue:trackArtist forKey:@"name"];
			} else {
				artistObj = [fetchResult objectAtIndex:0];
			}
			[trackObj setValue:artistObj forKey:@"artist"];
		}
		
		//Find Track's Album if it exists or create new Album. Add Track to the Album's tracks array.
		NSString *trackAlbum = [dictTrack objectForKey:@"Album"];
		if (trackAlbum == nil) {
			trackAlbum = AMUnknownItemName;
		}
		fetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"albumNameFetch" substitutionVariables:[NSDictionary dictionaryWithObject:trackAlbum forKey:@"Name"]];
		fetchResult = [context executeFetchRequest:fetchRequest error:NULL];
		if (fetchResult != nil) {
			if ([fetchResult count] == 0) {
				albumObj = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext:context];
				[albumObj setValue:trackAlbum forKey:@"name"];
				[albumObj setValue:[dictTrack objectForKey:@"Track Count"] forKey:@"track_count"];
			} else {
				albumObj = [fetchResult objectAtIndex:0];
			}
			[trackObj setValue:albumObj forKey:@"album"];
			NSMutableSet *artistSet = [albumObj mutableSetValueForKey:@"artists"];
			if (artistObj != nil)
				[artistSet addObject:artistObj];
		}
		
		//Update Progress UI
	}
	
	NSMutableArray *plTracks;
	NSDictionary *allPlaylists = [library objectForKey:@"Playlists"];
	NSEnumerator *plItemEnum, *plEnum = [allPlaylists objectEnumerator];
	NSDictionary *plDict,*plItemDict;
	NSNumber *plPriority;
	//Update Progress UI
	{	
		[updateProgressTrackStatus setStringValue:[NSString stringWithFormat:@"Done. %d tracks added to library.",[allTracks count]]];
		[updateProgressIndicator setDoubleValue:0.0];
		[updateProgressIndicator setMaxValue:[allPlaylists count]+1];
	}
	while (plDict = [plEnum nextObject]) {
		//Update Progress UI

		// Check if Playlist is blacklisted
		if (![plBlacklist containsObject:[plDict objectForKey:@"Name"]])
		{
			// Add Playlist's tracks to an array and fetch them from the database
			plTracks = [[NSMutableArray alloc] init];
			plItemEnum = [[plDict objectForKey:@"Playlist Items"] objectEnumerator];
			while (plItemDict = [plItemEnum nextObject]) {
				[plTracks addObject:[plItemDict valueForKey:@"Track ID"]];
			}
			fetchRequest = [managedObjectModel fetchRequestFromTemplateWithName:@"trackIDFetch" substitutionVariables:[NSDictionary dictionaryWithObject:plTracks forKey:@"id_list"]];
			NSArray *trackArray = [context executeFetchRequest:fetchRequest error:NULL];
			// Create a new Playlist and add the Tracks to its tracks array
			playlistObj = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:context];
			[playlistObj setValue:[plDict objectForKey:@"Name"] forKey:@"name"];
			[playlistObj setValue:[NSSet setWithArray:trackArray] forKey:@"tracks"];
			// If the Playlist has a priority, set that value
			if (plPriority = [plPriorities objectForKey:[plDict objectForKey:@"Name"]])
				[playlistObj setValue:plPriority forKey:@"priority"];
		}
		//Update Progress UI
	}
	//Update Progress UI
	// Create empty Custom Playlist
	playlistObj = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:context];
	[playlistObj setValue:AMCustomPlaylistName forKey:@"name"];
	if (plPriority = [plPriorities objectForKey:AMCustomPlaylistName])
		[playlistObj setValue:plPriority forKey:@"priority"];
	//Update Progress UI
		
	err = nil;
	if (![context save:&err])
		NSLog(@"%@",err);
	[pool release];
}

- (NSManagedObject *)selectedPlaylist
{
		return [[self playlists] objectAtIndex:selectedPlaylist];
}

- (void)setGenreSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce
{
	if (![indexSet isEqualToIndexSet:selectedGenres] || shouldForce) {
		[indexSet retain];
		[selectedGenres release];
		selectedGenres = indexSet;
		[self setArtistSelection:[NSIndexSet indexSetWithIndex:0] force:shouldForce];
		[artists release]; artists = nil;
	}
}
- (void)setArtistSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce
{
	if (![indexSet isEqualToIndexSet:selectedArtists] || shouldForce) {
		[indexSet retain];
		[selectedArtists release];
		selectedArtists = indexSet;
		[self setAlbumSelection:[NSIndexSet indexSetWithIndex:0] force:shouldForce];
		[albums release]; albums = nil;
	}
}
- (void)setAlbumSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce
{
	if (![indexSet isEqualToIndexSet:selectedAlbums] || shouldForce) {
		[indexSet retain];
		[selectedAlbums release];
		selectedAlbums = indexSet;
		[self setTrackSelection:[NSIndexSet indexSetWithIndex:0] force:shouldForce];
		[tracks release]; tracks = nil;
	}
}
- (void)setTrackSelection:(NSIndexSet *)indexSet force:(BOOL)shouldForce
{
	if (![indexSet isEqualToIndexSet:selectedTracks] || shouldForce) {
		[indexSet retain];
		[selectedTracks release];
		selectedTracks = indexSet;
	}
}

#pragma mark CoreData methods

/**
Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle and all of the 
 framework bundles.
 */
- (NSManagedObjectModel *)managedObjectModel
{	
	if (managedObjectModel != nil) {
		return managedObjectModel;
	}
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObject: [NSBundle bundleForClass:[self class]]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
	
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
	[allBundles release];
	
	return managedObjectModel;
}

/**
Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{	
	if (persistentStoreCoordinator != nil) {
		return persistentStoreCoordinator;
	}
	
	NSFileManager *fileManager;
	NSString *applicationSupportFolder = nil;
	NSURL *url;
	NSError *error;
	
	fileManager = [NSFileManager defaultManager];
	applicationSupportFolder = [self applicationSupportFolder];
	if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
		[fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
	}
	
	url = [self persistentStoreFileURL];
	needsReload = ![fileManager fileExistsAtPath:[url path]];
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
		[[NSApplication sharedApplication] presentError:error];
	}    
	
	return persistentStoreCoordinator;
}

/**
Returns the managed object context for the application (which is already
																												bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext
{	
	if (managedObjectContext != nil) {
		return managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator: coordinator];
	}
	
	if (needsReload) {
		NSString *fullpath = [AMiTunesLibraryPath stringByExpandingTildeInPath];
		NSURL *itxml = [[[NSURL alloc] initFileURLWithPath:fullpath] autorelease];
		NSDictionary *itDict = [NSDictionary dictionaryWithContentsOfURL:itxml];
		[self reloadITunesLibrary:itDict intoManagedContext:managedObjectContext];
	}
	return managedObjectContext;
}
@end