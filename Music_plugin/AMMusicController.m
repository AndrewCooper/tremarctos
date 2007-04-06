//
//  AMMusicController.m
//  AutoMac
//
//  Created by Andrew Cooper on 5/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMMusicController.h"
#import "AMLibrary.h"
#import "AMNSStringAdditions.h"
#import "stdlib.h"

@interface AMMusicController (PrivateMethods)
- (void)nextMovie;
- (void)updateMovieInfo;
- (void)updateTimerFired:(NSTimer *)timer;
- (void)movieDidEnd:(NSNotification *)notif;
- (void)resetControls;
@end

@implementation AMMusicController
typedef enum _AMFilterIndex {
	AMGenreFilter = 0,
	AMArtistFilter,
	AMAlbumFilter,
	AMTrackFilter,
	AMQueueFilter
} AMFilterIndex;

typedef enum _AMRepeatState {
	AMRepeatOff = 0,
	AMRepeatAll,
	AMRepeatOne
} AMRepeatState;

- (id) init {
	self = [super init];
	if (self != nil) {
		isPlaying = NO;
		hasPlaylist = NO;
		currentFilter = AMGenreFilter;
		selectedNewPlaylist = YES;
		shuffleState = NO;
		repeatState = AMRepeatOff;
		srandom([[NSDate date] timeIntervalSince1970]);
		trackVolume = 0.5;
	}
	return self;
}

-(void)dealloc
{
	[movie release];
	[updateTimer release];
	[library release];
	[super dealloc];
}

-(void)awakeFromNib
{
	library = [[AMLibrary alloc] init];
	[playlistTable selectRow:0 byExtendingSelection:NO];
	[filterControl setSelectedSegment:AMGenreFilter];
	[self filterChange:filterControl];
	[self resetControls];
	[backButton setPeriodicDelay:1.0 interval:0.5];
	[backButton setState:NSOffState];
	backButtonState = NSOffState;
	backButtonIsDown = NO;
	fwdButtonState = NSOffState;
	[fwdButton setState:NSOffState];
	fwdButtonIsDown = NO;
	[fwdButton setPeriodicDelay:1.0 interval:0.5];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:nil];
}

- (NSView *)mainView
{
	if (!mainView) {
		viewNib = [[NSNib alloc] initWithNibNamed:@"Music" bundle:[NSBundle bundleForClass:[self class]]];
		[viewNib instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return mainView;
}

- (NSView *)smallView
{
	if (!smallView) {
		viewNib = [[NSNib alloc] initWithNibNamed:@"Music" bundle:nil];
		[viewNib instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return smallView;
}

#pragma mark IBActions
- (IBAction)playAction:(id)sender
{
	if (!isPlaying) {
		if (!hasPlaylist) {
			[self filterChange:filterControl];
			playlist = [[library selectedTracks] retain];
			hasPlaylist = YES;
			playedMovies = [[NSMutableIndexSet alloc] init];
			[self nextMovie];
			[filterControl setEnabled:YES forSegment:AMQueueFilter];
			[filterControl setSelectedSegment:AMQueueFilter];
			[self filterChange:filterControl];
		}
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30 target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
		[playButton setImage:[NSImage imageNamed:@"PauseOff"]];
		[playButton setAlternateImage:[NSImage imageNamed:@"PauseOn"]];
		[stopButton setEnabled:YES];
		isPlaying = YES;
		[movie play];
	} else {
		[updateTimer invalidate];
		[playButton setImage:[NSImage imageNamed:@"PlayOff"]];
		[playButton setAlternateImage:[NSImage imageNamed:@"PlayOn"]];
		isPlaying = NO;
		[movie stop];
	}
}

- (IBAction)stopAction:(id)sender
{
	[movie stop];
	[self resetControls];
	[updateTimer invalidate];
	isPlaying = NO;
	hasPlaylist = NO;
	[playlist release];
	[playedMovies release];
	[filterControl setEnabled:NO forSegment:AMQueueFilter];
	if ([filterControl selectedSegment] == AMQueueFilter){
		[filterControl setSelectedSegment:AMTrackFilter];
		[self filterChange:filterControl];
	}
	movie = nil;
}

- (IBAction)backAction:(id)sender
{
	if (backButtonState != [backButton state]) {
		// This occurs when the button is released
		if (backButtonIsDown == YES) {
			// This is the state toggle after the 'held down' state is released
			backButtonState = [backButton state];
			backButtonIsDown = NO;
		} else { //backButtonIsDown == NO
			// This is a normal button click
			backButtonState = [backButton state];
			backButtonIsDown = NO;
			// Do some back click action
			[movie setCurrentTime:QTMakeTimeWithTimeInterval(0)];
		}
	} else { // backButtonState == [backButton state]
		// This will happen while the button is in 'held down' state
		backButtonIsDown = YES;
		// Do some back hold-down action
	}
}

- (IBAction)fwdAction:(id)sender
{
	if (fwdButtonState != [fwdButton state]) {
		// This occurs when the button is released
		if (fwdButtonIsDown == YES) {
			// This is the state toggle after the 'held down' state is released
			fwdButtonState = [fwdButton state];
			fwdButtonIsDown = NO;
		} else { //fwdButtonIsDown == NO
						 // This is a normal button click
			fwdButtonState = [fwdButton state];
			fwdButtonIsDown = NO;
			// Do some back click action
			[self nextMovie];
		}
	} else { // fwdButtonState == [fwdButton state]
					 // This will happen while the button is in 'held down' state
		fwdButtonIsDown = YES;
		// Do some back hold-down action
	}
}

- (IBAction)filterChange:(id)sender
{
	int qIdx;
	int newFilter = [filterControl selectedSegment];
	switch (currentFilter) {
		case AMGenreFilter:
			[library setGenreSelection:[trackTable selectedRowIndexes]];
			break;
		case AMArtistFilter:
			[library setArtistSelection:[trackTable selectedRowIndexes]];
			break;
		case AMAlbumFilter:
			[library setAlbumSelection:[trackTable selectedRowIndexes]];
			break;
		case AMTrackFilter:
			[library setTrackSelection:[trackTable selectedRowIndexes]];
			break;
	}
	NSIndexSet *newSelection;
	switch (newFilter) {
		case AMGenreFilter:
			newSelection = [library genreSelection];
			break;
		case AMArtistFilter:
			newSelection = [library artistSelection];
			break;
		case AMAlbumFilter:
			newSelection = [library albumSelection];
			break;
		case AMTrackFilter:
			newSelection = [library trackSelection];
			break;
		case AMQueueFilter:
			qIdx = [playlist indexOfObject:currentTrack];
			if (qIdx == NSNotFound) {
				newSelection = [NSIndexSet indexSet];
			} else {
				newSelection = [NSIndexSet indexSetWithIndex:qIdx];
			}
			break;
	}
	if (selectedNewPlaylist || newFilter != currentFilter) {
		selectedNewPlaylist = NO;
		currentFilter = newFilter;
		[trackTable reloadData];
	}
	[trackTable selectRowIndexes:newSelection byExtendingSelection:NO];
	[trackTable scrollRowToVisible:[newSelection firstIndex]];
}

- (IBAction)playlistChange:(id)sender
{
	[library setSelectedPlaylist:[playlistTable selectedRow]];
	selectedNewPlaylist = YES;
	[filterControl setSelectedSegment:AMGenreFilter];
	[self filterChange:filterControl];
}

- (IBAction)artistAlbumInfoAction:(id)sender
{
	
}

- (IBAction)trackTableDblClick:(id)sender
{
	
}

- (IBAction)shuffleAction:(id)sender
{
	if (shuffleState)
	{
		shuffleState = NO;
		[shuffleButton setTitle:@"Shuffle: Off"];
	}
	else
	{
		shuffleState = YES;
		[shuffleButton setTitle:@"Shuffle: On"];
	}
}

- (IBAction)repeatAction:(id)sender
{
	switch (repeatState)
	{
		case AMRepeatOff:
			repeatState = AMRepeatAll;
			[repeatButton setTitle:@"Repeat: All"];
			break;
		case AMRepeatAll:
			repeatState = AMRepeatOne;
			[repeatButton setTitle:@"Repeat: One"];
			break;
		case AMRepeatOne:
			repeatState = AMRepeatOff;
			[repeatButton setTitle:@"Repeat: Off"];
	}
}

- (IBAction)visualizerAction:(id)sender
{
	
}

- (IBAction)volChangeAction:(id)sender
{
	trackVolume = [volSlider doubleValue];
	if (movie)
		[movie setVolume:(float)trackVolume];
}
- (IBAction)volDownAction:(id)sender
{
	trackVolume -= 0.05;
	if (trackVolume < 0)
		trackVolume = 0;
	[volSlider setDoubleValue:trackVolume];
	if (movie)
		[movie setVolume:(float)trackVolume];
}
- (IBAction)volUpAction:(id)sender
{
	trackVolume += 0.05;
	if (trackVolume > 1)
		trackVolume = 1;
	[volSlider setDoubleValue:trackVolume];
	if (movie)
		[movie setVolume:(float)trackVolume];
}

- (IBAction)reloadLibrary:(id)sender
{
	[library reloadLibrary];
}
#pragma mark TableView DataSource Methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == trackTable)
	{
		switch(currentFilter)
		{
			case AMGenreFilter:
				return [[library genres] count];
				break;
			case AMArtistFilter:
				return [[library artists] count];
				break;
			case AMAlbumFilter:
				return [[library albums] count];
				break;
			case AMTrackFilter:
				return [[library tracks] count];
				break;
			case AMQueueFilter:
				return [playlist count];
				break;
		}
	}
	else
		return [[library playlists] count];
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == trackTable) {
		NSArray *theArray;
		switch (currentFilter) {
			case AMGenreFilter:
				theArray = [library genres];
				break;
			case AMArtistFilter:
				theArray = [library artists];
				break;
			case AMAlbumFilter:
				theArray = [library albums];
				break;
			case AMTrackFilter:
				theArray = [library tracks];
				break;
			case AMQueueFilter:
				return [[playlist objectAtIndex:rowIndex] valueForKeyPath:@"name"];
				break;
			default:
				return @"Something is FUBAR";
		}
		id rowObj = [theArray objectAtIndex:rowIndex];
		return rowIndex == 0 ? rowObj : [rowObj valueForKeyPath:@"name"];
	} else {
		NSString *name = [[[library playlists] objectAtIndex:rowIndex] valueForKeyPath:@"name"];
		return name;
	}
	return @"OOPS, this shouldn't be here!";
}

#pragma mark TableView Delegate Methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}
@end

@implementation AMMusicController (PrivateMethods)
- (void)nextMovie
{
	int cnt = [playlist count];
	int idx;
	if (repeatState == AMRepeatOne) {
		[movie setCurrentTime:QTMakeTimeWithTimeInterval(0)];
		[movie play];
		return;
	}
	if (cnt == [playedMovies count]) {
		if (repeatState == AMRepeatAll) {
			[playedMovies removeAllIndexes];
		} else {
			[movie stop];
			[movie release];
			movie = nil;
			currentTrack = nil;
			[playedMovies removeAllIndexes];
			[self updateMovieInfo];
			return;
		}
	}
	if (shuffleState == YES) {
		do {
			idx = (int)(random() % cnt);
		} while ( [playedMovies containsIndex:idx] );
	} else {
		idx = [playedMovies lastIndex] +1;
		if (idx >= [playlist count])
			idx = 0;
	}
	NSError *err;
	currentTrack = [playlist objectAtIndex:idx];
	QTMovie *newMovie = [QTMovie movieWithURL:[NSURL URLWithString:[currentTrack valueForKey:@"location"]] error:&err];
	if (newMovie != nil) {
		[movie stop];
		[movie release];
		movie = [newMovie retain];
		[self updateMovieInfo];
		[playedMovies addIndex:idx];
		[movie setVolume:(float)trackVolume];
		[movie play];
		if ([filterControl selectedSegment] == AMQueueFilter)
			[self filterChange:filterControl];
//		NSImage *poster = [movie posterImage];
//		if (poster)
//			[imgView setImage:poster];
	}
}
- (void)updateMovieInfo
{
	[songTitleField setStringValue:[currentTrack valueForKey:@"name"]];
	[artistAlbumField setStringValue:[NSString stringWithFormat:@"%@ / %@",[currentTrack valueForKeyPath:@"artist.name"],[currentTrack valueForKeyPath:@"album.name"]]];
	[currentTimeField setStringValue:[NSString stringWithQTTime:[movie currentTime]]];
	[totalTimeField setStringValue:[NSString stringWithQTTime:[movie duration]]];
}

- (void)updateTimerFired:(NSTimer *)timer
{
	QTTime curTime = [movie currentTime];
	QTTime maxTime = [movie duration];
	[currentTimeField setStringValue:[NSString stringWithQTTime:[movie currentTime]]];
	double progVal = (double)(curTime.timeValue) / (double)(maxTime.timeValue);
	[trackProgress setDoubleValue:progVal];
}

- (void)movieDidEnd:(NSNotification *)notif
{
	[self nextMovie];
//	[movie play];
}
- (void)resetControls
{
	[trackProgress setIndeterminate:NO];
	[trackProgress setMaxValue:1.0];
	[trackProgress setDoubleValue:0.0];
	[stopButton setEnabled:NO];
	[playButton setImage:[NSImage imageNamed:@"PlayOff"]];
	[songTitleField setStringValue:@""];
	[artistAlbumField setStringValue:@""];
	[currentTimeField setStringValue:@"--:--"];
	[totalTimeField setStringValue:@"--:--"];
	[trackProgress setDoubleValue:0];
}

@end