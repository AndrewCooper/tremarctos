//
//  AMCenterFormatter.h
//  AutoMac
//
//  Created by Andrew Cooper on 6/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMCenterFormatter : NSFormatter {
	NSDictionary *attributes;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
																 withDefaultAttributes:(NSDictionary *)attributes;

- (BOOL)getObjectValue:(id *)anObject 
						 forString:(NSString *)string 
			errorDescription:(NSString **)error;

- (NSString *)stringForObjectValue:(id)anObject;

@end
