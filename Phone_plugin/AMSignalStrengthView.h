//
//  AMSignalStrengthView.h
//  AutoMac
//
//  Created by Andrew Cooper on 7/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMSignalStrengthView : NSView {
	int mMin;
	int mMax;
	int mValue;
}

- (int)maxValue;
- (void)setMaxValue:(int)maxValue;
- (int)minValue;
- (void)setMinValue:(int)minValue;
- (int)intValue;
- (void)setIntValue:(int)value;

@end
