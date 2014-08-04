//
//  iCarouselMacAppDelegate.h
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface iCarouselMacAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSWindowController *windowController;

@end
