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
    NSWindow *__unsafe_unretained window;
    NSWindowController *__unsafe_unretained windowController;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSWindowController *windowController;

@end
