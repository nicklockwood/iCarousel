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

@property (nonatomic, unsafe_unretained) IBOutlet NSWindow *window;
@property (nonatomic, unsafe_unretained) IBOutlet UIKitView *chameleonNSView;

@end
