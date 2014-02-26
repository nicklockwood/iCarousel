//
//  AppDelegate.m
//  iCarouselChameleonDemo
//
//  Created by Nick Lockwood on 25/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "MacAppDelegate.h"
#import "iCarouselExampleAppDelegate.h"


@interface MacAppDelegate ()

@property (nonatomic, strong) iCarouselExampleAppDelegate *iPhoneAppDelegate;

@end


@implementation MacAppDelegate

@synthesize window;
@synthesize chameleonNSView;
@synthesize iPhoneAppDelegate;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    iPhoneAppDelegate = [[iCarouselExampleAppDelegate alloc] init];
    [chameleonNSView launchApplicationWithDelegate:iPhoneAppDelegate afterDelay:1.0];
}

@end
