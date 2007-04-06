//
//  AMNSStringAdditions.h
//  AutoMac
//
//  Created by Andrew Cooper on 5/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>


@interface NSString (AMQTTimeAdditions)
+ (NSString *)stringWithQTTime:(QTTime)time;
@end
