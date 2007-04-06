//
//  AMCenterFormatter.m
//  AutoMac
//
//  Created by Andrew Cooper on 6/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMCenterFormatter.h"


@implementation AMCenterFormatter
- (id) init {
	self = [super init];
	if (self != nil) {
		NSNumber *blOffset = [NSNumber numberWithFloat:-15.0];
		NSFont *font = [NSFont systemFontOfSize:14];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
			font,NSFontAttributeName,
			blOffset,NSBaselineOffsetAttributeName,
			nil];
	}
	return self;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
																 withDefaultAttributes:(NSDictionary *)attr
{
	NSString *str = [self stringForObjectValue:anObject];
	return [[[NSAttributedString alloc] initWithString:str attributes:attributes] autorelease];
}

- (BOOL)getObjectValue:(id *)anObject 
						 forString:(NSString *)string 
			errorDescription:(NSString **)error
{
	if (anObject)
		*anObject = [[string copy] autorelease];
	return YES;
}

- (NSString *)stringForObjectValue:(id)anObject
{
	return [anObject description];
}
@end
