//
//  AMMovieTableView.m
//  AutoMac
//
//  Created by Andrew Cooper on 7/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMMovieTableView.h"


@implementation AMMovieTableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
			NSLog(@"frame param:   %@",NSStringFromRect(frame));
			items = 20;
			thumb = [NSImage imageNamed:@"Date & Time"];
    }
    return self;
}

- (void)awakeFromNib
{
	NSSize size = [[self enclosingScrollView] contentSize];
	NSRect rect = [[self enclosingScrollView] documentVisibleRect];
	NSLog(@"contentSize:           %@",NSStringFromSize(size));
	NSLog(@"documentVisibleRect:   %@",NSStringFromRect(rect));
	
	[self setFrameSize:size];
	NSLog(@"contentSize:           %@",NSStringFromSize([[self enclosingScrollView] contentSize]));
	NSLog(@"documentVisibleRect:   %@",NSStringFromRect([[self enclosingScrollView] documentVisibleRect]));
	
	size.height = 50*(items);
	[self setFrameSize:size];
	NSLog(@"contentSize:           %@",NSStringFromSize([[self enclosingScrollView] contentSize]));
	NSLog(@"documentVisibleRect:   %@",NSStringFromRect([[self enclosingScrollView] documentVisibleRect]));
	NSLog(@"frame:   %@",NSStringFromRect([self frame]));
}

- (void)drawRect:(NSRect)rect
{
	NSLog(@"rect param:   %@",NSStringFromRect(rect));
	[[NSColor blackColor] setFill];
	NSRectFill(rect);
	NSPoint imgPt = NSMakePoint(10,10+[thumb size].height);
	for(int i = 0; i < items; i++) {
		[thumb compositeToPoint:imgPt operation:NSCompositeCopy];
		imgPt.y += 50;
	}
}

- (BOOL)isFlipped
{
	return YES;
}

@end