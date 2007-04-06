//
//  AMBluetoothController.h
//  AutoMac
//
//  Created by Andrew Cooper on 3/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IOBluetoothRFCOMMChannel;

NSString * const AMATCommandResponse;

@interface AMBluetoothController : NSObject {
	NSMutableArray *commandQueue;
	
	BOOL isRunning;
	BOOL shouldContinue;
}

- (void)registerATResponseObserver:(id)object selector:(SEL)notificationSelector command:(NSString *)cmd;

- (void)runATCommandQueue;
- (void)pauseATCommandQueue;
- (void)enqueueATCommand:(NSString *)cmd forChannel:(IOBluetoothRFCOMMChannel *)channel;

@end
