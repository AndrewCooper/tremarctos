//
//  AMBluetoothController.m
//  AutoMac
//
//  Created by Andrew Cooper on 3/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AMBluetoothController.h"
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>

NSString * const AMATNotificationFormat = @"AMBluetoothATCommand %@";
NSString * const AMATQueueCommandKey = @"ATCommandKey";
NSString * const AMATQueueChannelKey = @"ATChannelKey";
NSString * const AMATCommandResponse = @"ATResponse";

@interface AMBluetoothController (Private)
- (void)handleIncomingData:(NSString *)dataStr;
- (void)executeQueue;
- (void)handleOK:(NSNotification *)notif;
- (void)handleERROR:(NSNotification *)notif;
@end

@interface AMBluetoothController (RFCOMM_Delegate)
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength;
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error;
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error;
- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel;
@end

@implementation AMBluetoothController
- (id)init
{
	self = [super init];
	if (self != nil)
	{	
		isRunning = NO;
		shouldContinue = NO;
		commandQueue = [[NSMutableArray alloc] init];
		[self registerATResponseObserver:self selector:@selector(handleOK:) command:@"OK"];
		[self registerATResponseObserver:self selector:@selector(handleERROR:) command:@"ERROR"];
		[self registerATResponseObserver:self selector:@selector(handleERROR:) command:@"+CME ERROR"];
	}
	return self;
}

- (void)dealloc
{
	[commandQueue release];
	[super dealloc];
}

- (void)registerATResponseObserver:(id)object
                          selector:(SEL)notificationSelector
                           command:(NSString*)cmd
{
	[[NSNotificationCenter defaultCenter] addObserver:object
                                           selector:notificationSelector
                                               name:[NSString stringWithFormat:AMATNotificationFormat,cmd]
                                             object:nil];
}
- (void)removeATResponseObserver:(id)object
                         command:(NSString*)cmd
{
	[[NSNotificationCenter defaultCenter] removeObserver:object
                                                  name:[NSString stringWithFormat:AMATNotificationFormat,cmd]
                                                object:nil];
}
- (void)runATCommandQueue
{
	shouldContinue = YES;
	[self executeQueue];
}
- (void)pauseATCommandQueue
{
	shouldContinue = NO;
}
- (void)enqueueATCommand:(NSString *)cmd forChannel:(IOBluetoothRFCOMMChannel *)channel
{
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:channel,AMATQueueChannelKey,cmd,AMATQueueCommandKey,nil];
	[commandQueue addObject:params];
}
@end

@implementation AMBluetoothController (Private)
- (void)handleIncomingData:(NSString *)dataStr
{
	NSArray *lines = [dataStr componentsSeparatedByString:@"\r\n"];
	NSEnumerator *linenum = [lines objectEnumerator];
	NSString *line;
	while (line = (NSString *)[linenum nextObject])
	{
		if ([line length] > 0) {
			NSArray *comps = [line componentsSeparatedByString:@": "];
			NSString *val;
			if ([comps count] > 1) {
				val = [comps objectAtIndex:1];
			}
			else {
				val = [NSString stringWithString:@""];
			}
			NSString *name = [NSString stringWithFormat:AMATNotificationFormat,[comps objectAtIndex:0]];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:val,AMATCommandResponse,nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo];
		}
	}
}

- (void)executeQueue
{
	if ([commandQueue count] > 0)
	{
		NSDictionary *params = (NSDictionary *)[commandQueue objectAtIndex:0];
		IOBluetoothRFCOMMChannel *chan = [params objectForKey:AMATQueueChannelKey];
		NSString *cmd = [params objectForKey:AMATQueueCommandKey];
		NSData *data = [cmd dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		isRunning = YES;
		NSLog(@"%d TX %@",[chan getChannelID],cmd);
		IOReturn ret = [chan writeSync:(void *)[data bytes] length:[data length]];
		// TODO Handle an error here
		
	}
}

- (void)handleOK:(NSNotification *)notif
{
	NSLog(@"Received OK code");
	[commandQueue removeObjectAtIndex:0];
	if (shouldContinue)
	{	
		[self executeQueue];
	}
}

- (void)handleERROR:(NSNotification *)notif
{
	NSLog(@"Received ERROR code");
	[commandQueue removeObjectAtIndex:0];
	if (shouldContinue)
	{	
		[self executeQueue];
	}	
}

@end

@implementation AMBluetoothController (RFCOMM_Delegate)
#pragma mark RFCOMM Channel Delegate Messages
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
	NSString *dataStr = [NSString stringWithCString:dataPointer length:dataLength];
	NSLog(@"%d RX %@ (%d bytes)",[rfcommChannel getChannelID], dataStr, dataLength);
	[self handleIncomingData:dataStr];
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
	NSLog(@"%d : Channel Open Complete %p %d",[rfcommChannel getChannelID],rfcommChannel,error);
	[self runATCommandQueue];
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
	NSLog(@"%d : Channel Closed",[rfcommChannel getChannelID]);
}

- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
	NSLog(@"%d : Control Signals Changed",[rfcommChannel getChannelID]);
}
- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
	NSLog(@"%d : Flow Control Changed",[rfcommChannel getChannelID]);
}
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error
{
	NSLog(@"%d : Write Complete",[rfcommChannel getChannelID]);
}
- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
	NSLog(@"%d : Queue Space Available",[rfcommChannel getChannelID]);
}
@end
