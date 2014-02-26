//
//  iCarouselExampleAppDelegate.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleAppDelegate.h"
#import "iCarouselExampleViewController.h"

@implementation iCarouselExampleAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];
    return YES;
}


@end
