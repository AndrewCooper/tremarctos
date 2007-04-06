/*
 *  AMBluetoothSDPDataElementAdditions.h
 *  AutoMac
 *
 *  Created by Andrew Cooper on 7/17/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothSDPDataElement.h>

@interface IOBluetoothSDPDataElement (AMAdditions)
- (NSString *)description;
@end

@implementation IOBluetoothSDPDataElement (AMAdditions)
- (NSString *)description
{
	return [[self getValue] description];
//	BluetoothSDPDataElementTypeDescriptor type = [self getTypeDescriptor];
//	switch (type)
//	{
//		case kBluetoothSDPDataElementTypeNil:
//			return @"NULL";
//		case kBluetoothSDPDataElementTypeDataElementAlternative:
//		case kBluetoothSDPDataElementTypeDataElementSequence:
//			return [[self getArrayValue] description];
//		case kBluetoothSDPDataElementTypeBoolean:
//		case kBluetoothSDPDataElementTypeSignedInt:
//		case kBluetoothSDPDataElementTypeUnsignedInt:
//			return [[self getNumberValue] description];
//		case kBluetoothSDPDataElementTypeString:
//			return [self getStringValue];
//		case kBluetoothSDPDataElementTypeUUID:
//			return [[self getUUIDValue] description];
//		case kBluetoothSDPDataElementTypeReservedEnd:
//		case kBluetoothSDPDataElementTypeReservedStart:
//		case kBluetoothSDPDataElementTypeURL:
//			return [[self getDataValue] description];
//		default:
//			return @"Unknown";
//	}
//	return [super description];
}
@end
