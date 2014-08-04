//
//  iCarouselWindowController.h
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iCarousel.h"


@interface iCarouselWindowController : NSWindowController <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) IBOutlet iCarousel *carousel;

- (IBAction)switchCarouselType:(id)sender;
- (IBAction)toggleVertical:(id)sender;
- (IBAction)toggleWrap:(id)sender;
- (IBAction)insertItem:(id)sender;
- (IBAction)removeItem:(id)sender;

@end
