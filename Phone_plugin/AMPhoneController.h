//
//  AMPhoneController.h
//  AutoMac
//
//  Created by Andrew Cooper on 7/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AMSignalStrengthView;
@class AMBluetoothHandsfreeService;
@class AMBluetoothController;

NSString * const AMPhoneStatusChanged;
NSString * const AMPhoneService;
NSString * const AMPhoneRoaming;
NSString * const AMPhoneSignalStrength;
NSString * const AMPhoneVoiceMail;
NSString * const AMPhoneBatteryLevel;
NSString * const AMPhoneNetwork;
NSString * const AMPhoneNumber;

NSString * const AMPhoneLineOneIdentifier;
NSString * const AMPhoneLineOneCall;
NSString * const AMPhoneLineOneCallsetup;
NSString * const AMPhoneLineOneCallheld;
NSString * const AMPhoneLineTwoIdentifier;
NSString * const AMPhoneLineTwoCall;
NSString * const AMPhoneLineTwoCallsetup;
NSString * const AMPhoneLineTwoCallheld;

@interface AMPhoneController : NSObject {
	NSNib                         *viewNib;
	IBOutlet NSView               *mainView;

	IBOutlet AMSignalStrengthView *signalStrength;
	IBOutlet NSButton             *voiceMailButton;
	IBOutlet NSLevelIndicator     *batteryChargeLevel;
	IBOutlet NSTextField          *networkOperatorField;
	IBOutlet NSTextField          *subscriberNumberField;

	IBOutlet NSTextField          *lineOnePartyIdentifier;
	IBOutlet NSTextField          *lineOneConnectionStatus;
	IBOutlet NSButton             *lineOneAnswerButton;
	IBOutlet NSButton             *lineOneMuteButton;
	IBOutlet NSButton             *lineOneHoldButton;

	IBOutlet NSTextField          *lineTwoPartyIdentifier;
	IBOutlet NSTextField          *lineTwoConnectionStatus;
	IBOutlet NSButton             *lineTwoAnswerButton;
	IBOutlet NSButton             *lineTwoMuteButton;
	IBOutlet NSButton             *lineTwoHoldButton;

	IBOutlet NSTextField          *dialerNumberField;
	IBOutlet NSTableView          *phoneContactsTable;
	IBOutlet NSTableView          *addressBookTable;
	IBOutlet NSPopUpButton        *phoneChooser;
	IBOutlet NSButton             *phoneConnectButton;
	
	IBOutlet NSTextField          *cmdInputField;

	AMBluetoothHandsfreeService   *hfpService;
	AMBluetoothController         *btController;
	NSArray                       *pairedPhones;
	BOOL                           enabled;
	NSMutableDictionary           *statusDict;
	
	NSArray                       *phoneContacts;
	NSArray                       *macContacts;
}

- (IBAction)callAnswer:(id)sender;
- (IBAction)keypadPressNumber:(id)sender;
- (IBAction)keypadClear:(id)sender;
- (IBAction)keypadBackspace:(id)sender;
- (IBAction)callVoicemail:(id)sender;
- (IBAction)startConnection:(id)sender;
- (IBAction)sendCommand:(id)sender;

#pragma mark KVO Accessors
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)value;
- (NSView *)mainView;
- (NSView *)smallView;

- (NSArray *)pairedPhones;
- (void)setPairedPhones:(NSArray *)newPhones;

- (NSArray *)phoneContacts;
- (void)setPhoneContacts:(NSArray *)newContacts;

- (NSArray *)macContacts;
- (void)setMacContacts:(NSArray *)newContacts;

- (NSDictionary *)status;
- (void)setStatus:(NSDictionary *)newStatus;
@end
