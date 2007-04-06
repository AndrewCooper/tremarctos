//
//  AMWindow.h
//  AutoMac
//
//  Created by Andrew Cooper on 6/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
@interface AMWindow : NSWindow
- (BOOL)canBecomeKeyWindow;
@end

@implementation AMWindow
- (BOOL)canBecomeKeyWindow
{
	return YES;
}
@end
