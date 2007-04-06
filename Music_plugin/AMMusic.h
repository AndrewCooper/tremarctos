//
//  AMMusic.h
//  AutoMac
//
//  Created by Andrew Cooper on 3/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMPlugin.h"

@class AMMusicController;
@class AMMusicSettingsController;

@interface AMMusic : NSObject <AMPlugin> {
	AMMusicController *controller;
	AMMusicSettingsController *settings;
}

- (NSString *)pluginName;
- (NSImage *)pluginIcon;
- (NSView *)mainView;
- (NSView *)smallView;
- (NSView *)settingsView;
@end
