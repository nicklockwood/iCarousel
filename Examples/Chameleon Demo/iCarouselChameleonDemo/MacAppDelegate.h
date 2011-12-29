//
//  AppDelegate.h
//  iCarouselChameleonDemo
//
//  Created by Nick Lockwood on 25/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UIKit/UIKitView.h>

@interface MacAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet UIKitView *chameleonNSView;

@end
