//
//  iCarouselMacAppDelegate.h
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface iCarouselMacAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow *window;
    NSWindowController *windowController;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindowController *windowController;

@end
