//
//  iCarouselExampleViewController.h
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"


@interface iCarouselExampleViewController : UIViewController <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, retain) IBOutlet iCarousel *carousel;
@property (nonatomic, retain) IBOutlet UINavigationItem *navItem;
@property (nonatomic, retain) IBOutlet UIBarItem *orientationBarItem;
@property (nonatomic, retain) IBOutlet UIBarItem *wrapBarItem;

- (IBAction)switchCarouselType;
- (IBAction)toggleOrientation;
- (IBAction)toggleWrap;
- (IBAction)insertItem;
- (IBAction)removeItem;

@end
