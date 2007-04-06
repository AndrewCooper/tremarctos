//
//  AMBluetoothHandsfreeService.h
//  HandsfreeTest
//
//  Created by Andrew Cooper on 7/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
#define BLUETOOTH_VERSION_USE_CURRENT

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/Bluetooth.h>

@class IOBluetoothRFCOMMChannel;
@class IOBluetoothUserNotification;
@class AMBluetoothController;

typedef enum {
	AMHFPConnectionStart = 0,
	AMHFPConnectionEstablished,
	AMHFPConnectionIdle
} AMHFPConnectionStatus;

typedef enum {
	AMHFIO_Idle = 0,
	AMHFIO_BRSF,
	AMHFIO_CINDTest,
	AMHFIO_CINDRead,
	AMHFIO_CMERSet,
	AMHFIO_CHLDTest,
	AMHFIO_CLIPEnable,
	AMHFIO_COPSEnable,
	AMHFIO_COPSRead,
	AMHFIO_CNUMRead
} AMHFIOStatus;

typedef enum {
	AMHFEchoCancelAndOrNoiseReduction = 0x0001,
	AMHFCallWaitingAndThreeWayCalling = 0x0002,
	AMHFCallingLineIdentification = 0x0004,
	AMHFVoiceRecognitionActivation = 0x0008,
	AMHFRemoteVolumeControl = 0x0010,
	AMHFEnhancedCallStatus = 0x0020,
	AMHFEnhancedCallControl = 0x0040
} AMHandsfreeFeatures;

typedef enum {
	AMAGThreeWayCalling = 0x0001,
	AMAGEchoCancelAndOrNoiseReduction = 0x0002,
	AMAGVoiceRecognitionFunction = 0x0004,
	AMAGInBandRingToneCapability = 0x0008,
	AMAGAttachNumberToVoiceTag = 0x0010,
	AMAGRejectCallAbility = 0x0020,
	AMAGEnhancedCallStatus = 0x0040,
	AMAGEnhancedCallControl = 0x0080,
	AMAGExtendedErrorResultCodes = 0x0100
} AMAudioGatewayFeatures;

typedef enum {
	AMHFCallSetupIdle = 0,
	AMHFCallSetupIncoming = 1,
	AMHFCallSetupOutgoing = 2,
	AMHFCallSetupOutgoingRing = 3,
} AMHFCallSetupStatus;

typedef enum {
	AMHFCallInactive = 0,
	AMHFCallActive
} AMHFCallStatus;

typedef enum {
	AMHFCallHeldNone = 0,
	AMHFCallHeldTwo,
	AMHFCallHeldOne
} AMHFCallHeldStatus;

@interface AMBluetoothHandsfreeService : NSObject {
	AMBluetoothController *mController;
	
	BluetoothRFCOMMChannelID mServerChannelID;
	BluetoothSDPServiceRecordHandle mServerHandle;
	IOBluetoothUserNotification *mIncomingChannelNotification;
	IOBluetoothRFCOMMChannel *mChannel;
	
	AMHFPConnectionStatus mConnectionStatus;
	AMHFIOStatus mIOStatus;
	
	AMHandsfreeFeatures hfFeatures;
	AMAudioGatewayFeatures agFeatures;
	
	NSArray *agIndicatorInfo;
//	NSMutableArray *agIndicatorValues;
	NSDictionary *agIndicatorTranslation;
	
	id mDelegate;
	
	NSString *mNetworkProvider;
	NSString *mSubscriberInfo;
}

- (id)initWithBluetoothController:(AMBluetoothController *)controller;
- (void)setDelegate:(id)delegateObj;

- (BOOL)publishService;
- (BOOL)isConnected;
- (void)initiateConnectionWithDevice:(id)device;
- (void)closeConnection;
- (void)newRFCOMMChannelOpened:(IOBluetoothUserNotification *)notif channel:(IOBluetoothRFCOMMChannel *)theChannel;
- (void)stopProvidingService;
- (IOBluetoothRFCOMMChannel *)channel;

- (NSArray *)pairedPhones;
@end

@interface NSObject(AMHandsfreeServiceDelegate)
- (void)handsfreeServiceConnected:(AMBluetoothHandsfreeService *)service
									networkProvider:(NSString *)network
								 subscriberNumber:(NSString *)subscriber;

- (void)handsfreeServiceUpdate:(AMBluetoothHandsfreeService *)service
								signalStrength:(int)newSignalStrength
									hasVoiceMail:(BOOL)voiceMailFlag
										 isRoaming:(BOOL)roamingFlag
										hasService:(BOOL)hasService;

- (void)handsfreeServiceUpdate:(AMBluetoothHandsfreeService *)service
										callStatus:(AMHFCallStatus)callStatus
							 callSetupStatus:(AMHFCallSetupStatus)callSetupStatus
								callHeldStatus:(AMHFCallHeldStatus)callHeldStatus
								 callingNumber:(NSString *)callingNumber;
@end