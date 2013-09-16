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

@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *viewpointOffsetLabel;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *contentOffsetLabel;

- (IBAction)updateViewpointOffset:(UISlider *)slider;
- (IBAction)updateContentOffset:(UISlider *)slider;

@end
