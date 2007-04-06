//
//  AMPhone.h
//  AutoMac
//
//  Created by Andrew Cooper on 3/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMPlugin.h"

@class AMPhoneController;
@class AMPhoneSettingsController;

@interface AMPhone : NSObject <AMPlugin> {
	AMPhoneController *controller;
	AMPhoneSettingsController *settings;
}
- (NSString *)pluginName;
- (NSImage *)pluginIcon;
- (NSView *)mainView;
- (NSView *)smallView;
- (NSView *)settingsView;
@end
