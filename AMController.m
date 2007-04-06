//
//  AMController.m
//  AutoMac
//
//  Created by Andrew Cooper on 5/20/06.
//  Copyright 2006 HKCreations. All rights reserved.
//

#import "AMController.h"
#import "AMWindow.h"
#import "AMPlugin.h"

@interface AMController (PrivateMethods)
- (void)loadAllPlugins;
@end

@implementation AMController
NSString *ext = @"plugin";

- (void)dealloc
{
	[super dealloc];
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	int windowLevel;
	NSRect screenRect;
	
// Capture the main display
//	if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
//		NSLog( @"Couldn't capture the main display!" );
//		// Note: you'll probably want to display a proper error dialog here
//	}
	
	// Get the shielding window level
	windowLevel = CGShieldingWindowLevel();
	
	// Get the screen rect of our main display
	screenRect = [[NSScreen mainScreen] frame];
	NSRect dispRect = NSMakeRect(0,0,800,600);
	mainWindow = [[AMWindow alloc] initWithContentRect:dispRect
																					 styleMask:NSTitledWindowMask // NSTexturedBackgroundWindowMask //NSBorderlessWindowMask 
																						 backing:NSBackingStoreBuffered
																							 defer:NO 
																							screen:[NSScreen mainScreen]];
//	[mainWindow setLevel:windowLevel];
//	[mainWindow setBackgroundColor:[NSColor blackColor]];
	[mainWindow setContentView:mainView];

	[mainWindow makeKeyAndOrderFront:nil];
//	NSColor *textBackgroundColor = [NSColor colorWithCalibratedRed:0.968f green:0.975f blue:0.881f alpha:1.0];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[pluginInstances release];
	NSLog(@"Terminating application");
}

- (void)awakeFromNib
{
	[self loadAllPlugins];
	NSEnumerator *pluginEnum = [pluginInstances objectEnumerator];
	id plugin;
	while(plugin = [pluginEnum nextObject])
	{
		[functionButtons addRow];
		id cell = [functionButtons cellAtRow:([functionButtons numberOfRows]-1) column:0];
		NSImage *imgIcon = [plugin pluginIcon];
		[cell setImage:imgIcon];
	}
	[functionButtons sizeToCells];
}

- (IBAction)changeView:(id)sender
{
	NSLog(@"View Change Request: Tag-%d, Selected Tag-%d, Selected Row-%d",[sender tag], [sender selectedTag], [sender selectedRow]);
	int selRow = [sender selectedRow];
	NSRect mvFrame = [pluginView frame];
	[pluginView removeFromSuperview];
	if (selRow != 0)
	{
		pluginView = [[pluginInstances objectAtIndex:([sender selectedRow]-1)] mainView];
		[[mainWindow contentView] addSubview:pluginView];
		[pluginView initWithFrame:mvFrame];
		[pluginView setFrame:mvFrame];
		[pluginView needsDisplay];
	}
}

- (void)loadAllPlugins
{
	NSEnumerator *searchPathEnum;
	NSString *currPath;
	NSMutableArray *bundleSearchPaths = [NSMutableArray array];
	NSMutableArray *bundlePaths = [NSMutableArray array];
	NSMutableArray *instances = [NSMutableArray array];
	NSEnumerator *pathEnum;
	NSBundle *currBundle;
	Class currPrincipalClass;
	id currInstance;
	
	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
	[bundleSearchPaths addObject:[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]];
	
	searchPathEnum = [bundleSearchPaths objectEnumerator];
	while(currPath = [searchPathEnum nextObject])
	{
		NSDirectoryEnumerator *bundleEnum;
		NSString *currBundlePath;
		bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath];
		if(bundleEnum)
		{
			while(currBundlePath = [bundleEnum nextObject])
			{
				if([[currBundlePath pathExtension] isEqualToString:ext])
				{
					[bundlePaths addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
				}
				[bundleEnum skipDescendents];
			}
		}
	}
	
	pathEnum = [bundlePaths objectEnumerator];
	while(currPath = [pathEnum nextObject])
	{
		currBundle = [NSBundle bundleWithPath:currPath];
		if(currBundle)
		{
			currPrincipalClass = [currBundle principalClass];
			if(currPrincipalClass && [currPrincipalClass conformsToProtocol:@protocol(AMPlugin)])  // Validation
			{
				currInstance = [[currPrincipalClass alloc] init];
				if(currInstance)
				{
					[instances addObject:[currInstance autorelease]];
				}
			}
		}
	}
	pluginInstances = [[NSArray alloc] initWithArray:instances];
}
@end
