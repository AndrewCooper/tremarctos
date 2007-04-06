/*
 *  AMPlugin.h
 *  AutoMac
 *
 *  Created by Andrew Cooper on 3/26/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

@protocol AMPlugin
- (NSString *)pluginName;
- (NSImage *)pluginIcon;
- (NSView *)mainView;
- (NSView *)smallView;
- (NSView *)settingsView;
@end