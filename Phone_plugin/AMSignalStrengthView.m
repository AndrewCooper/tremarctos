//
//  AMSignalStrengthView.m
//  AutoMac
//
//  Created by Andrew Cooper on 7/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMSignalStrengthView.h"


@implementation AMSignalStrengthView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
			mMin = 0;
			mMax = 5;
			mValue = 3;
    }
    return self;
}

- (int)maxValue
{
	return mMax;
}

- (void)setMaxValue:(int)maxValue
{
	mMax = maxValue;
	[self setNeedsDisplay:YES];
}

- (int)minValue
{
	return mMin;
}

- (void)setMinValue:(int)minValue
{
	mMin = minValue;
	[self setNeedsDisplay:YES];
}

- (int)intValue
{
	return mValue;
}

- (void)setIntValue:(int)value
{
	mValue = value;
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect {
	NSImage *antenna = [NSImage imageNamed:@"Antenna"];
	NSRect bounds = [self bounds];
	NSSize imgSize = [antenna size];
	NSRect antRect = NSMakeRect(0,0,imgSize.width*bounds.size.height/imgSize.height,bounds.size.height);
	[antenna drawInRect:antRect fromRect:NSMakeRect(0,0,imgSize.width,imgSize.height) operation:NSCompositeSourceOver fraction:1.0];
	NSRect barsRect = NSMakeRect(antRect.size.width,
															 0,
															 bounds.size.width - antRect.size.width,
															 bounds.size.height);
	for (int barIdx = 0; barIdx < mMax; ++barIdx) {
		if (barIdx < mValue)
			[[NSColor blueColor] set];
		else
			[[NSColor lightGrayColor] set];
		NSRect barRect = NSMakeRect(barsRect.origin.x + barsRect.size.width * (barIdx * 1.0) / mMax,
																barsRect.origin.y,
																0.8 * barsRect.size.width / mMax,
																barsRect.size.height * (barIdx + 1.0) / mMax);
		NSRectFill(barRect);
	}
}

@end
