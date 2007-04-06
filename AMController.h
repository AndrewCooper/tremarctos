//
//  AutoMacController.h
//  AutoMac
//
//  Created by Andrew Cooper on 5/20/06.
//  Copyright 2006 HKCreations. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@class AMToolbar;
@class AMWindow;

@interface AMController : NSObject
{
	IBOutlet NSView      *mainView;
	IBOutlet NSView      *pluginView;
	IBOutlet NSView      *smallView1;
	IBOutlet NSView      *smallView2;
	IBOutlet NSView      *smallView3;
	IBOutlet NSMatrix    *functionButtons;
	AMWindow *mainWindow;
	
	NSArray *pluginInstances;
}

- (IBAction)changeView:(id)sender;

@end
