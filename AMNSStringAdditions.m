//
//  AMNSStringAdditions.m
//  AutoMac
//
//  Created by Andrew Cooper on 5/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMNSStringAdditions.h"


@implementation NSString (AMQTTimeAdditions)
+ (NSString *)stringWithQTTime:(QTTime)time
{
	long long tv = time.timeValue;
	long ts = time.timeScale;
//	int days = (int)(tv/(ts*86400));
//	int hours = (int)(tv/(ts*3600));
	int minutes = (int)(tv/(ts*60));
	int seconds = (int)(tv/ts)%60;
//	int millis = (int)(tv % ts * 1000 / ts);
//	if (days == 0) {
//		if (hours == 0) {
//			if (minutes == 0) {
//				if (seconds == 0) {
//					return [NSString stringWithFormat:@"0.%03d",millis];
//				} else {
//					return [NSString stringWithFormat:@"%2d.%03d",seconds,millis];
//				}
//			} else {
//				return [NSString stringWithFormat:@"%2d:%02d",minutes,seconds];
//			}
//		} else {
//			return [NSString stringWithFormat:@"%2d:%02d:%02d",hours,minutes,seconds];
//		}
//	} else {
//		return [NSString stringWithFormat:@"%d:%02d:%02d:%02d",days,hours,minutes,seconds];
//	}
	return [NSString stringWithFormat:@"%d:%02d",minutes,seconds];
}
@end