//
//  AMMusicController.h
//  AutoMac
//
//  Created by Andrew Cooper on 5/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@class AMLibrary;

@interface AMMusicController : NSObject {
	AMLibrary   *library;
	NSNib                *viewNib;
	IBOutlet NSView      *mainView;
	IBOutlet NSTextField *songTitleField;
	IBOutlet NSTextField *artistAlbumField;
	IBOutlet NSTextField *currentTimeField;
	IBOutlet NSTextField *totalTimeField;
	IBOutlet NSProgressIndicator *trackProgress;
	IBOutlet NSButton    *playButton;
	IBOutlet NSButton    *stopButton;
	IBOutlet NSButton    *backButton;
	IBOutlet NSButton    *fwdButton;
	IBOutlet NSTableView *trackTable;
	IBOutlet NSTableView *playlistTable;
	IBOutlet NSSegmentedControl *filterControl;
	IBOutlet NSButton    *shuffleButton;
	IBOutlet NSButton    *repeatButton;
//	IBOutlet NSButton    *visualizerButton;
	IBOutlet NSButton    *volDownButton;
	IBOutlet NSButton    *volUpButton;
	IBOutlet NSSlider    *volSlider;

	IBOutlet NSView      *smallView;

	double trackVolume;
	QTMovie *movie;
	NSManagedObject *currentTrack;
	
	NSTimer *updateTimer;
	BOOL hasPlaylist;
	BOOL isPlaying;
	
	int currentFilter;
	BOOL selectedNewPlaylist;
	
	NSArray *playlist;
	NSMutableIndexSet *playedMovies;
	
	int backButtonState;
	BOOL backButtonIsDown;
	int fwdButtonState;
	BOOL fwdButtonIsDown;
	
	BOOL shuffleState;
	int repeatState;
}

- (NSView *)mainView;
- (NSView *)smallView;

- (IBAction)playAction:(id)sender;
- (IBAction)stopAction:(id)sender;
- (IBAction)backAction:(id)sender;
- (IBAction)fwdAction:(id)sender;

- (IBAction)playlistChange:(id)sender;
- (IBAction)filterChange:(id)sender;
- (IBAction)trackTableDblClick:(id)sender;

- (IBAction)shuffleAction:(id)sender;
- (IBAction)repeatAction:(id)sender;
- (IBAction)visualizerAction:(id)sender;

- (IBAction)volUpAction:(id)sender;
- (IBAction)volDownAction:(id)sender;
- (IBAction)volChangeAction:(id)sender;

- (IBAction)reloadLibrary:(id)sender;
@end

