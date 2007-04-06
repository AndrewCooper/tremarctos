//
//  AMPhone.m
//  AutoMac
//
//  Created by Andrew Cooper on 3/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AMPhone.h"

@implementation AMPhone

- (id)init
{
	self = [super init];
	if (self != nil) {
		controller = [[AMPhoneController alloc] init];
		
		NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
		NSImage *img;
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"Antenna" ofType:@"tiff"]];
		[img setName:@"Antenna"];
		img = [[NSImage alloc] initByReferencingFile:[thisBundle pathForResource:@"Bluetooth" ofType:@"tiff"]];
		[img setName:@"Bluetooth"];
	}
	return self;
}

- (NSString *)pluginName
{
	return @"Phone";
}

- (NSImage *)pluginIcon
{
	return [NSImage imageNamed:@"Bluetooth"];
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
