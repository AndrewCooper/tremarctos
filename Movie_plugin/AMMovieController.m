//
//  AMMovieController.m
//  AutoMac
//
//  Created by Andrew Cooper on 7/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AMMovieController.h"


@implementation AMMovieController
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 10;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return @"ASDF";
}

@end
