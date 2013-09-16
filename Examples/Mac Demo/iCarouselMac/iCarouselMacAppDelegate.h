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
    NSWindow *__weak window;
    NSWindowController *__weak windowController;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSWindowController *windowController;

@end
