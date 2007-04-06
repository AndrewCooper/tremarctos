//
//  AMBluetoothHandsfreeService.m
//  HandsfreeTest
//
//  Created by Andrew Cooper on 7/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMBluetoothHandsfreeService.h"
#import "AMBluetoothController.h"
#import <AGRegex/AGRegex.h>
#import <IOBluetooth/IOBluetoothUserLib.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothSDPDataElement.h>
#import "AMBluetoothSDPDataElementAdditions.h"
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOKit/audio/IOAudioTypes.h>
#import <IOKit/audio/IOAudioDefines.h>

#pragma mark Constants
NSString * const AMAGVoiceMailIndicator = @"voice mail";
NSString * const AMAGServiceIndicator = @"service";
NSString * const AMAGCallIndicator = @"call";
NSString * const AMAGCallSetupIndicator = @"callsetup";
NSString * const AMAGCallHeldIndicator = @"callheld";
NSString * const AMAGSignalIndicator = @"signal";
NSString * const AMAGRoamIndicator = @"roam";
NSString * const AMAGBatteryIndicator = @"battchg";

NSString * const AMAGIndicatorIndexKey = @"Index";
NSString * const AMAGIndicatorRangeKey = @"Range";

NSString * const AMATBRSFFormatString = @"AT+BRSF=%d\r";
NSString * const AMATCINDTestString = @"AT+CIND=?\r";
NSString * const AMATCINDReadString = @"AT+CIND?\r";
NSString * const AMATCMERSetFormatString = @"AT+CMER=3,0,0,%d\r";
NSString * const AMATCHLDTestString = @"AT+CHLD=?\r";
NSString * const AMATCOPSEnableString = @"AT+COPS=3,0\r";
NSString * const AMATCOPSReadString = @"AT+COPS?\r";
NSString * const AMATCLIPToggleString = @"AT+CLIP=1\r";
NSString * const AMATCNUMReadString = @"AT+CNUM\r";

@interface AMBluetoothHandsfreeService (HFP_Implementation)
//- (void)handleIncomingData:(NSString *)data;
//- (void)sendBRSF;
//- (void)sendCINDTest;
//- (void)sendCINDRead;
//- (void)sendCMERSet:(BOOL)enableCMER;
//- (void)sendCHLDTest;
//- (void)sendCOPSEnable;
//- (void)sendCOPSRead;
//- (void)sendCLIPEnable;
//- (void)sendCNUMRead;
- (void)queueConnectionInitialization;
- (void)handleBRSF:(NSNotification *)notif;
- (void)handleBSIR:(NSNotification *)notif;
- (void)handleCIND:(NSNotification *)notif;
- (void)handleCHLD:(NSNotification *)notif;
- (void)handleCIEV:(NSNotification *)notif;
- (void)handleCOPSRead:(NSNotification *)notif;
- (void)handleCLIP:(NSNotification *)notif;
//- (void)handleOK:(NSString *)data;
//- (SEL)handlerForCommand:(NSString *)cmd;
- (void)initAudioConnection;
- (void)releaseAudioConnection;
@end

@implementation AMBluetoothHandsfreeService

- (id)initWithBluetoothController:(AMBluetoothController *)cont
{
	self = [super init];
	if (self != nil) {
		mController = cont;
		hfFeatures = 
			AMHFCallWaitingAndThreeWayCalling | 
			AMHFCallingLineIdentification | 
			AMHFVoiceRecognitionActivation | 
			AMHFRemoteVolumeControl | 
			AMHFEnhancedCallStatus | 
			AMHFEnhancedCallControl;
		agIndicatorTranslation = 
		[[NSDictionary alloc] initWithObjectsAndKeys:
			AMAGVoiceMailIndicator,AMPhoneVoiceMail,
			AMAGServiceIndicator,AMPhoneService,
			AMAGCallIndicator,AMPhoneLineOneCall,
			AMAGCallSetupIndicator,AMPhoneLineOneCallsetup,
			AMAGCallHeldIndicator,AMPhoneLineOneCallheld,
			AMAGSignalIndicator,AMPhoneSignalStrength,
			AMAGRoamIndicator,AMPhoneRoaming,
			AMAGBatteryIndicator,AMPhoneBatteryLevel
			,nil
		];
	}
	return self;
}

- (void)dealloc
{
	NSLog(@"Deallocating service");
	[self stopProvidingService];
	[agIndicatorInfo release];
//	[agIndicatorValues release];
	[super dealloc];
}

- (void)setDelegate:(id)delegateObj
{
	mDelegate = delegateObj;
}

- (BOOL)publishService
{
	NSString            *dictionaryPath = nil;
	NSMutableDictionary *sdpEntries = nil;
	
	// Get the path for the dictionary we wish to publish.
	dictionaryPath = [[NSBundle mainBundle] pathForResource:@"SerialPortDictionary" ofType:@"plist"];
	
	if ( ( dictionaryPath != nil ) ) 
	{
		// Initialize sdpEntries with the dictionary from the path.
		sdpEntries = [NSMutableDictionary dictionaryWithContentsOfFile:dictionaryPath];
		unsigned short hff = (unsigned short)hfFeatures & 0x001f;
		NSData *featureData = [NSData dataWithBytes:&hff length:2];
		[sdpEntries setObject:featureData forKey:@"0311 - Supported Features"];
		
		if ( sdpEntries != nil )
		{
			IOBluetoothSDPServiceRecordRef  serviceRecordRef;
			
			// Create a new IOBluetoothSDPServiceRecord that includes both
			// the attributes in the dictionary and the attributes the
			// system assigns. Add this service record to the SDP database.
			if (IOBluetoothAddServiceDict( (CFDictionaryRef) sdpEntries, &serviceRecordRef ) == kIOReturnSuccess)
			{
				IOBluetoothSDPServiceRecord *serviceRecord;
				
				serviceRecord = [IOBluetoothSDPServiceRecord withSDPServiceRecordRef:serviceRecordRef];
				
				// Preserve the RFCOMM channel assigned to this service.
				// A header file contains the following declaration:
				// IOBluetoothRFCOMMChannelID mServerChannelID;
				[serviceRecord getRFCOMMChannelID:&mServerChannelID];
				
				// Preserve the service-record handle assigned to this 
				// service.
				// A header file contains the following declaration:
				// IOBluetoothSDPServiceRecordHandle mServerHandle;
				[serviceRecord getServiceRecordHandle:&mServerHandle];
				
				// Now that we have an IOBluetoothSDPServiceRecord object,
				// we no longer need the IOBluetoothSDPServiceRecordRef.
				IOBluetoothObjectRelease( serviceRecordRef );

				mIncomingChannelNotification = [IOBluetoothRFCOMMChannel 
						registerForChannelOpenNotifications:self 
																			 selector:@selector(newRFCOMMChannelOpened:channel:) 
																	withChannelID:mServerChannelID 
																			direction:kIOBluetoothUserNotificationChannelDirectionIncoming];
				return YES;
			}
		}
	}
	return NO;
}

- (void)stopProvidingService
{
	if ( mServerHandle != 0 )
	{
		// Remove the service.
		IOBluetoothRemoveServiceWithRecordHandle( mServerHandle );
	}
	
	// Unregister the notification.
	if ( mIncomingChannelNotification != nil )
	{
		[mIncomingChannelNotification unregister];
		mIncomingChannelNotification = nil;
	}
	
	mServerChannelID = 0;
}

- (BOOL)isConnected
{
	return (mChannel != nil);
}

- (void)initiateConnectionWithDevice:(id)device
{
	NSArray *serviceMatch = [NSArray arrayWithObjects:[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassHandsfreeAudioGateway],[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassGenericAudio],nil];
	IOBluetoothDevice *phone = (IOBluetoothDevice *)device;
	NSArray *services = [phone getServices];
	BluetoothRFCOMMChannelID channel = 255;
	IOReturn ret;
	for (int servIdx = 0; servIdx < [services count]; ++servIdx) {
		IOBluetoothSDPServiceRecord *service = [services objectAtIndex:servIdx];
		if ([service matchesUUIDArray:serviceMatch] == YES)
			ret = [service getRFCOMMChannelID:&channel];
	}
	if (channel != 255) {
		ret = [phone openRFCOMMChannelAsync:&mChannel withChannelID:channel delegate:mController];
		NSLog(@"Opening async channel %d : return %d", channel, ret);
		[self queueConnectionInitialization];
	} else {
		NSLog(@"Device does not support Handsfree Profile");
	}
}

- (void)closeConnection
{
	if (mChannel != nil) {
		IOBluetoothDevice *device = [mChannel getDevice];
		[self releaseAudioConnection];
		[mChannel closeChannel];
		[device closeConnection];
	}
}

- (void)newRFCOMMChannelOpened:(IOBluetoothUserNotification *)notif 
											 channel:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
	NSLog(@"%d : Channel Opened",[rfcommChannel getChannelID]);
	[mChannel autorelease];
	mChannel = [rfcommChannel retain];
	[mChannel setDelegate:mController];
}

- (IOBluetoothRFCOMMChannel *)channel
{
	return mChannel;
}

- (NSArray *)pairedPhones
{
	NSArray *serviceMatch = [NSArray arrayWithObjects:[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassHandsfreeAudioGateway],[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassGenericAudio],nil];
	NSMutableArray *allDevices = [NSMutableArray arrayWithArray:[IOBluetoothDevice pairedDevices]];
	IOBluetoothDevice *device;
	NSMutableIndexSet *agPhones = [NSMutableIndexSet indexSet];
	
	for (int devIdx = 0; devIdx < [allDevices count]; ++devIdx) {
		device = (IOBluetoothDevice *)[allDevices objectAtIndex:devIdx];
		[device performSDPQuery:nil];
		
		NSLog(@"%@",device);
			NSArray *services = [device getServices];
			for (int servIdx = 0; servIdx < [services count]; ++servIdx) {
				IOBluetoothSDPServiceRecord *record = [services objectAtIndex:servIdx];
				if ([record matchesUUIDArray:serviceMatch] == YES)
					[agPhones addIndex:devIdx];
			}
	}
	return [allDevices objectsAtIndexes:agPhones];
}
@end

@implementation AMBluetoothHandsfreeService (HFP_Implementation)
//- (void)handleIncomingData:(NSString *)dataStr
//{
//	NSArray *lines = [dataStr componentsSeparatedByString:@"\r\n"];
//	NSEnumerator *linenum = [lines objectEnumerator];
//	NSString *line;
//	while (line = (NSString *)[linenum nextObject])
//	{
//		if ([line length] > 0) {
//			NSArray *comps = [line componentsSeparatedByString:@": "];
//			NSLog(@"Received %@",comps);
//			SEL handler = [self handlerForCommand:[comps objectAtIndex:0]];
//			NSString *val;
//			if ([comps count] > 1) {
//				val = [comps objectAtIndex:1];
//			}
//			else {
//				val = nil;
//			}
//			if (handler && [self respondsToSelector:handler])
//				[self performSelector:handler withObject:val];
//		}
//	}
//}

- (void)queueConnectionInitialization
{
	[mController registerATResponseObserver:self selector:@selector(handleBRSF:) command:@"+BRSF"];
	[mController registerATResponseObserver:self selector:@selector(handleBSIR:) command:@"+BSIR"];
	[mController registerATResponseObserver:self selector:@selector(handleCIND:) command:@"+CIND"];
	[mController registerATResponseObserver:self selector:@selector(handleCHLD:) command:@"+CHLD"];
	[mController registerATResponseObserver:self selector:@selector(handleCIEV:) command:@"+CIEV"];
	[mController registerATResponseObserver:self selector:@selector(handleCOPSRead:) command:@"+COPS"];
	[mController registerATResponseObserver:self selector:@selector(handleCLIP:) command:@"+CLIP"];

	NSString *brsfStr = [NSString stringWithFormat:AMATBRSFFormatString,hfFeatures];
	NSString *cmerStr = [NSString stringWithFormat:AMATCMERSetFormatString,YES];

	[mController enqueueATCommand:brsfStr forChannel:mChannel];
	[mController enqueueATCommand:AMATCINDTestString forChannel:mChannel];
	[mController enqueueATCommand:AMATCINDReadString forChannel:mChannel];
	[mController enqueueATCommand:cmerStr forChannel:mChannel];
	[mController enqueueATCommand:AMATCHLDTestString forChannel:mChannel];
	[mController enqueueATCommand:AMATCOPSEnableString forChannel:mChannel];
	[mController enqueueATCommand:AMATCOPSReadString forChannel:mChannel];
	[mController enqueueATCommand:AMATCLIPToggleString forChannel:mChannel];
	[mController enqueueATCommand:AMATCNUMReadString forChannel:mChannel];
}

//- (void)sendBRSF
//{
//	NSLog(@"Sending BRSF");
//	NSString *brsfStr = [NSString stringWithFormat:AMATBRSFFormatString,hfFeatures];
//	NSData *data = [brsfStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_BRSF;
//	else
//		NSLog(@"An error occurred while trying to send the BRSF message");
//}

//- (void)sendCINDTest
//{	
//	NSLog(@"Sending CIND Test");
//	NSData *data = [AMATCINDTestString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CINDTest;
//	else
//		NSLog(@"An error occurred while trying to send the CIND Test message");
//}

//- (void)sendCINDRead
//{	
//	NSLog(@"Sending CIND Read");
//	NSData *data = [AMATCINDReadString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CINDRead;
//	else
//		NSLog(@"An error occurred while trying to send the CIND Read message");
//}

//- (void)sendCMERSet:(BOOL)enableCMER
//{	
//	NSLog(@"Sending CMER Set");
//	NSString *cmerStr = [NSString stringWithFormat:AMATCMERSetFormatString,enableCMER];
//	NSData *data = [cmerStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CMERSet;
//	else
//		NSLog(@"An error occurred while trying to send the CMER message");
//}

//- (void)sendCHLDTest
//{	
//	NSLog(@"Sending CHLD Test");
//	NSData *data = [AMATCHLDTestString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CHLDTest;
//	else
//		NSLog(@"An error occurred while trying to send the CHLD Test message");
//}

//- (void)sendCOPSEnable
//{
//	NSLog(@"Sending AT+COPS=3,0");
//	NSData *data = [AMATCOPSEnableString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_COPSEnable;
//	else
//		NSLog(@"An error occurred while trying to send the COPS Enable message");
//}

//- (void)sendCOPSRead
//{
//	NSLog(@"Sending AT+COPS?");
//	NSData *data = [AMATCOPSReadString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_COPSRead;
//	else
//		NSLog(@"An error occurred while trying to send the COPS Read message");
//}

//- (void)sendCLIPEnable
//{
//	NSLog(@"Sending AT+CLIP");
//	NSData *data = [AMATCLIPToggleString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CLIPEnable;
//	else
//		NSLog(@"An error occurred while trying to send the COPS message");
//}

//- (void)sendCNUMRead
//{
//	NSLog(@"Sending AT+CNUM");
//	NSData *data = [AMATCNUMReadString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	if (kIOReturnSuccess == [mChannel writeSync:(void *)[data bytes] length:[data length]])
//		mIOStatus = AMHFIO_CNUMRead;
//	else
//		NSLog(@"An error occurred while trying to send the CNUM message");
//}

//- (SEL)handlerForCommand:(NSString *)cmd
//{
//	if ([cmd isEqualToString:@"OK"]) return @selector(handleOK:);
//	if ([cmd isEqualToString:@"+BSIR"]) return @selector(handleBSIR:);
//	if ([cmd isEqualToString:@"+BRSF"]) return @selector(handleBRSF:);
//	if ([cmd isEqualToString:@"+CHLD"]) return @selector(handleCHLD:);
//	if ([cmd isEqualToString:@"+CIEV"]) return @selector(handleCIEV:);
//	if ([cmd isEqualToString:@"+CIND"]) return @selector(handleCIND:);
//	if ([cmd isEqualToString:@"+CMER"]) return @selector(handleCMER:);
//	if ([cmd isEqualToString:@"+CLIP"]) return @selector(handleCLIP:);
//	if ([cmd isEqualToString:@"+COPS"]) return @selector(handleCOPSRead:);
//	if ([cmd isEqualToString:@"+CNUM"]) return @selector(handleCNUM:);
//	return NULL;
//}

- (void)handleBRSF:(NSNotification *)notif
{	
	NSLog(@"Handling received BRSF: %@",notif);
	agFeatures = [[[notif userInfo] objectForKey:AMATCommandResponse] intValue];
}

- (void)handleBSIR:(NSNotification *)notif
{
	//Update in-band ringtone functionality
}

- (void)handleCIND:(NSNotification *)notif
{	
	AGRegex *regex = [[AGRegex alloc] initWithPattern:@"\\(\"([\\w\\s]+)\",\\(([0-9]+)[,|-]([0-9]+)\\)\\)[,]?"];
	NSArray *matches = [regex findAllInString:[[notif userInfo] objectForKey:AMATCommandResponse]];
	if ([matches count] > 0) {
		NSLog(@"Handling received CIND Test: %@",notif);
		NSMutableArray *info = [NSMutableArray arrayWithCapacity:[matches count]];
		for (int matchIdx = 0; matchIdx < [matches count]; ++matchIdx) {
			AGRegexMatch *match = [matches objectAtIndex:matchIdx];
			NSString *key = [match groupAtIndex:1];
			int start = [[match groupAtIndex:2] intValue];
			int end = [[match groupAtIndex:3] intValue];
			NSRange rng = NSMakeRange(start,(end-start));
			NSDictionary *indDict = [NSDictionary dictionaryWithObjectsAndKeys:[key lowercaseString],@"name",NSStringFromRange(rng),@"range",nil];
			[info addObject:indDict];
		}
		agIndicatorInfo = [[NSArray alloc] initWithArray:info];
		NSLog(@"%@",agIndicatorInfo);
	} else {
		NSLog(@"Handling received CIND Read: %@",notif);
		NSArray *vals = [[[notif userInfo] objectForKey:AMATCommandResponse] componentsSeparatedByString:@","];
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:[vals count]];
		for (int valIdx = 0; valIdx < [vals count]; ++valIdx) {
			[userInfo setObject:[NSNumber numberWithInt:[[vals objectAtIndex:valIdx] intValue]] forKey:[agIndicatorTranslation objectForKey:[[agIndicatorInfo objectAtIndex:valIdx] objectForKey:@"name"]]];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:AMPhoneStatusChanged object:nil userInfo:userInfo];
//		if ([mDelegate respondsToSelector:@selector(handsfreeServiceUpdate: signalStrength: hasVoiceMail: isRoaming: hasService:)])
//		{
//			[mDelegate handsfreeServiceUpdate:self
//												 signalStrength:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGSignalIndicator] objectForKey:@"index"] intValue]] intValue]
//													 hasVoiceMail:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGVoiceMailIndicator] objectForKey:@"index"] intValue]] intValue]
//															isRoaming:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGRoamIndicator] objectForKey:@"index"] intValue]] intValue]
//														 hasService:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGServiceIndicator] objectForKey:@"index"] intValue]] intValue]
//				];	
//		}
	}
}

- (void)handleCHLD:(NSNotification *)notif
{	
	NSLog(@"Handling received CHLD: %@",notif);
	// Process CHLD=? result
}

- (void)handleCIEV:(NSNotification *)notif
{	
	NSLog(@"Handling received CIEV: %@",notif);
	NSArray *vals = [[[notif userInfo] objectForKey:AMATCommandResponse] componentsSeparatedByString:@","];
	int idx = [[vals objectAtIndex:0] intValue] - 1;
	int value = [[vals objectAtIndex:1] intValue];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:value],
		[agIndicatorTranslation objectForKey:[[agIndicatorInfo objectAtIndex:idx] objectForKey:@"name"]]];
	[[NSNotificationCenter defaultCenter] postNotificationName:AMPhoneStatusChanged object:nil userInfo:userInfo];
//	[agIndicatorValues replaceObjectAtIndex:idx withObject:[NSNumber numberWithInt:value]];
//	if ([mDelegate respondsToSelector:@selector(handsfreeServiceUpdate: signalStrength: hasVoiceMail: isRoaming: hasService:)])
//	{
//		[mDelegate handsfreeServiceUpdate:self
//											 signalStrength:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGSignalIndicator] objectForKey:@"index"] intValue]] intValue]
//												 hasVoiceMail:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGVoiceMailIndicator] objectForKey:@"index"] intValue]] intValue]
//														isRoaming:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGRoamIndicator] objectForKey:@"index"] intValue]] intValue]
//													 hasService:[[agIndicatorValues objectAtIndex:[[[agIndicatorInfo objectForKey:AMAGServiceIndicator] objectForKey:@"index"] intValue]] intValue]
//			];	
//	}
}

- (void)handleRING:(NSNotification *)notif
{
}

- (void)handleCLIP:(NSNotification *)notif
{
}

/*!
    @method     handleCOPSRead
    @abstract   Handles the return information from a COPS read command.
    @discussion Use as the selector for a notification to be called for the response to an AT+COPS? command
*/
- (void)handleCOPSRead:(NSNotification *)notif
{
	NSLog(@"Handling received COPS: %@",notif);
	NSArray *comps = [[[notif userInfo] objectForKey:AMATCommandResponse] componentsSeparatedByString:@","];
	NSLog(@"%@",comps);
	NSString *op = [comps objectAtIndex:2];
	NSString *op2 = [op substringWithRange:NSMakeRange(1,[op length]-2)];
	[mNetworkProvider autorelease];
	mNetworkProvider = [op2 retain];
}

- (void)handleCNUM:(NSNotification *)notif
{
	NSLog(@"Handling received CNUM: %@",notif);
	NSArray *comps = [[[notif userInfo] objectForKey:AMATCommandResponse] componentsSeparatedByString:@","];
	NSLog(@"%@",comps);
	[mSubscriberInfo autorelease];
	mSubscriberInfo = [[comps objectAtIndex:1] retain];
}

//- (void)handleOK:(NSString *)data
//{
//	NSLog(@"Handle OK");
//	if (mConnectionStatus != AMHFPConnectionEstablished)
//	{
//		switch (mIOStatus)
//		{
//			case AMHFIO_BRSF:
//				[self sendCINDTest];
//				break;
//			case AMHFIO_CINDTest:
//				[self sendCINDRead];
//				break;
//			case AMHFIO_CINDRead:
//				[self sendCMERSet:YES];
//				break;
//			case AMHFIO_CMERSet:
//				if ((hfFeatures & AMHFCallWaitingAndThreeWayCalling) > 0 &&
//						(agFeatures & AMAGThreeWayCalling) > 0 )
//				{
//					[self sendCHLDTest];
//				}
//				else
//				{
//					[self sendCLIPEnable];
//				}
//				break;
//			case AMHFIO_CHLDTest:
//				[self sendCLIPEnable];
//				break;
//			case AMHFIO_CLIPEnable:
//				[self sendCOPSRead];
////				[self sendCOPSEnable];
//				break;
//			case AMHFIO_COPSEnable:
//				[self sendCOPSRead];
//				break;
//			case AMHFIO_COPSRead:
//				[self sendCNUMRead];
//				break;
//			case AMHFIO_CNUMRead:
//				mIOStatus = AMHFIO_CNUMRead;
//				mConnectionStatus = AMHFPConnectionEstablished;
//				if ([mDelegate respondsToSelector:@selector(handsfreeServiceConnected: networkProvider: subscriberNumber:)])
//				{
//					[mDelegate handsfreeServiceConnected:self
//															 networkProvider:mNetworkProvider
//															subscriberNumber:mSubscriberInfo];
//				}
//				[self initAudioConnection];
//		}
//	}
//}

- (void)initAudioConnection
{
	// Not implementable at this time
}

- (void)releaseAudioConnection
{
	// Not implementable at this time
}

@end

