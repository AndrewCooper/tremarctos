//
//  AMMusic.m
//  AutoMac
//
//  Created by Andrew Cooper on 3/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AMMusic.h"


@implementation AMMusic

- (id)init
{
	self = [super init];
	if (self != nil) {
		controller = [[AMMusicController alloc] init];

		NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
		NSImage *img;
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"LevelOff" ofType:@"tiff"]];
		[img setName:@"LevelOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"LevelOn" ofType:@"tiff"]];
		[img setName:@"LevelOn"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"NextDisabled" ofType:@"tiff"]];
		[img setName:@"NextDisabled"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"NextOff" ofType:@"tiff"]];
		[img setName:@"NextOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"NextOn" ofType:@"tiff"]];
		[img setName:@"NextOn"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PauseDisabled" ofType:@"tiff"]];
		[img setName:@"PauseDisabled"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PauseOff" ofType:@"tiff"]];
		[img setName:@"PauseOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PauseOn" ofType:@"tiff"]];
		[img setName:@"PauseOn"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PlayDisabled" ofType:@"tiff"]];
		[img setName:@"PlayDisabled"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PlayOff" ofType:@"tiff"]];
		[img setName:@"PlayOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PlayOn" ofType:@"tiff"]];
		[img setName:@"img"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PrevDisabled" ofType:@"tiff"]];
		[img setName:@"PrevDisabled"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PrevOff" ofType:@"tiff"]];
		[img setName:@"PrevOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"PrevOn" ofType:@"tiff"]];
		[img setName:@"PrevOn"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"StopDisabled" ofType:@"tiff"]];
		[img setName:@"StopDisabled"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"StopOff" ofType:@"tiff"]];
		[img setName:@"StopOff"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"StopOn" ofType:@"tiff"]];
		[img setName:@"StopOn"];

		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"VolumeUp" ofType:@"tiff"]];
		[img setName:@"VolumeUp"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"VolumeDown" ofType:@"tiff"]];
		[img setName:@"VolumeDown"];
	}
	return self;
}

- (NSString *)pluginName
{
	return @"Music";
}

- (NSImage *)pluginIcon
{
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	NSString *imgPath = [selfBundle pathForResource:@"Music" ofType:@"tiff"];
	return [[[NSImage alloc] initByReferencingFile:imgPath] autorelease];
}

- (NSView *)mainView
{
	return [controller mainView];
}

- (NSView *)smallView
{
	return [controller smallView];
}

- (NSView *)settingsView
{
	return [settings mainView];
}

@end
