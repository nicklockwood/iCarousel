//
//  iCarouselMacAppDelegate.m
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselMacAppDelegate.h"

@implementation iCarouselMacAppDelegate

@synthesize window;
@synthesize windowController;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(__unused NSApplication *)sender
{
    return YES;
}

@end
