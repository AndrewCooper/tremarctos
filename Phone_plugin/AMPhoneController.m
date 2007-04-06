//
//  AMPhoneController.m
//  AutoMac
//
//  Created by Andrew Cooper on 7/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMPhoneController.h"
#import "AMBluetoothHandsfreeService.h"
#import "AMBluetoothController.h"

NSString * const AMPhoneStatusChanged = @"AMPhoneStatusChangedKey";
NSString * const AMPhoneService = @"AMPhoneServiceKey";
NSString * const AMPhoneRoaming = @"AMPhoneRoamingKey";
NSString * const AMPhoneSignalStrength = @"AMPhoneSignalStrengthKey";
NSString * const AMPhoneVoiceMail = @"AMPhoneVoiceMailKey";
NSString * const AMPhoneBatteryLevel = @"AMPhoneBatteryLevelKey";
NSString * const AMPhoneNetwork = @"AMPhoneNetworkKey";
NSString * const AMPhoneNumber = @"AMPhoneNumberKey";

NSString * const AMPhoneLineOneIdentifier = @"AMPhoneLineOneIdentifierKey";
NSString * const AMPhoneLineOneCall = @"AMPhoneLineOneCallKey";
NSString * const AMPhoneLineOneCallsetup = @"AMPhoneLineOneCallsetupKey";
NSString * const AMPhoneLineOneCallheld = @"AMPhoneLineOneCallheldKey";
NSString * const AMPhoneLineOneStatus = @"AMPhoneLineOneStatusKey";
NSString * const AMPhoneLineTwoIdentifier = @"AMPhoneLineTwoIdentifierKey";
NSString * const AMPhoneLineTwoCall = @"AMPhoneLineTwoCallKey";
NSString * const AMPhoneLineTwoCallsetup = @"AMPhoneLineTwoCallsetupKey";
NSString * const AMPhoneLineTwoCallheld = @"AMPhoneLineTwoCallheldKey";
NSString * const AMPhoneLineTwoStatus = @"AMPhoneLineTwoStatusKey";

@interface AMPhoneController (PrivateMethods)
- (void)clearStatus;
@end

@implementation AMPhoneController
- (id) init {
	self = [super init];
	if (self != nil) {
		btController = [[AMBluetoothController alloc] init];
		hfpService = [[AMBluetoothHandsfreeService alloc] initWithBluetoothController:btController]; [hfpService publishService];
		[self setPairedPhones:[hfpService pairedPhones]]; //TODO should the Bluetooth Controller be doing this?
		statusDict = [[NSMutableDictionary alloc] init];
		[self setEnabled:NO];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phoneStatusChanged:) name:AMPhoneStatusChanged object:nil];
	}
	return self;
}

- (void)dealloc
{
	[hfpService release];
	[viewNib release];
	[super dealloc];
}

- (void)awakeFromNib
{
}

- (IBAction)callAnswer:(id)sender
{
	
}

- (IBAction)keypadPressNumber:(id)sender
{
	
}

- (IBAction)callVoicemail:(id)sender
{
	
}

- (IBAction)sendCommand:(id)sender
{
	NSString *cmd = [NSString stringWithFormat:@"%@\r",[sender stringValue]];
	NSLog(@"Wanting to send command: %@",cmd);
	[btController enqueueATCommand:cmd forChannel:[hfpService channel]];
	[btController runATCommandQueue];
}

- (IBAction)startConnection:(id)sender
{
	[hfpService initiateConnectionWithDevice:[[self pairedPhones] objectAtIndex:[phoneChooser selectedTag]]];

}

- (IBAction)keypadClear:(id)sender
{
}

- (IBAction)keypadBackspace:(id)sender
{
	
}

#pragma mark KVO Accessors
- (BOOL)isEnabled
{
	return enabled;
}

- (void)setEnabled:(BOOL)value
{
	enabled = value;
	if (!enabled)
		[self clearStatus];
}

- (NSView *)mainView
{
	if (!mainView) {
		viewNib = [[NSNib alloc] initWithNibNamed:@"Phone" bundle:[NSBundle bundleForClass:[self class]]];
		[viewNib instantiateNibWithOwner:self topLevelObjects:nil];
	}
	return mainView;
}

- (NSView *)smallView
{	
	return nil;
}

- (NSArray *)pairedPhones
{
	return pairedPhones;
}
- (void)setPairedPhones:(NSArray *)newPhones
{
	[pairedPhones autorelease];
	pairedPhones = [newPhones retain];
}

- (NSArray *)phoneContacts
{
	return phoneContacts;
}

- (void)setPhoneContacts:(NSArray *)newContacts
{
	[phoneContacts autorelease];
	phoneContacts = newContacts;
}

- (NSArray *)macContacts
{
	return macContacts;
}

- (void)setMacContacts:(NSArray *)newContacts
{
	[macContacts autorelease];
	macContacts = newContacts;
}

- (NSDictionary *)status
{
	return statusDict;
}

- (void)setStatus:(NSDictionary *)newStatus
{
	[statusDict setValuesForKeysWithDictionary:newStatus];
}

@end

@implementation AMPhoneController (PrivateMethods)
- (void)clearStatus
{
	[statusDict setValue:[NSNumber numberWithInt:3] forKey:AMPhoneSignalStrength];
	[statusDict setValue:[NSNumber numberWithBool:NO] forKey:AMPhoneVoiceMail];
	[statusDict setValue:[NSNumber numberWithInt:3] forKey:AMPhoneBatteryLevel];
	[statusDict setValue:@"Network" forKey:AMPhoneNetwork];
	[statusDict setValue:@"Subscriber" forKey:AMPhoneNumber];
	
	[statusDict setValue:@"Not Connected" forKey:AMPhoneLineOneIdentifier];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallInactive] forKey:AMPhoneLineOneCall];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallSetupIdle] forKey:AMPhoneLineOneCallsetup];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallHeldNone] forKey:AMPhoneLineOneCallheld];
	
	[statusDict setValue:@"Not Connected" forKey:AMPhoneLineTwoIdentifier];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallInactive] forKey:AMPhoneLineTwoCall];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallSetupIdle] forKey:AMPhoneLineTwoCallsetup];
	[statusDict setValue:[NSNumber numberWithInt:AMHFCallHeldNone] forKey:AMPhoneLineTwoCallheld];
}
@end
