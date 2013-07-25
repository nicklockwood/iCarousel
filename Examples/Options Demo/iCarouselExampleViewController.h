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
@property (nonatomic, retain) IBOutlet UISlider *arcSlider;
@property (nonatomic, retain) IBOutlet UISlider *radiusSlider;
@property (nonatomic, retain) IBOutlet UISlider *tiltSlider;
@property (nonatomic, retain) IBOutlet UISlider *spacingSlider;

@property (nonatomic, retain) IBOutlet UISlider *fadeRangeSlider;
@property (nonatomic, retain) IBOutlet UISlider *fadeMinSlider;
@property (nonatomic, retain) IBOutlet UISlider *fadeMaxSlider;
@property (nonatomic, retain) IBOutlet UISlider *decelSlider;

@property (nonatomic, retain) IBOutlet UILabel *arcLabel;
@property (nonatomic, retain) IBOutlet UILabel *radiusLabel;
@property (nonatomic, retain) IBOutlet UILabel *tiltLabel;
@property (nonatomic, retain) IBOutlet UILabel *spacingLabel;

@property (nonatomic, retain) IBOutlet UILabel *fadeRangeLabel;
@property (nonatomic, retain) IBOutlet UILabel *fadeMinLabel;
@property (nonatomic, retain) IBOutlet UILabel *fadeMaxLabel;
@property (nonatomic, retain) IBOutlet UILabel *decelLabel;

@property (nonatomic, retain) IBOutlet UITextField *itemWidthTextField;
@property (nonatomic, retain) IBOutlet UITextField *itemHeightTextField;

- (IBAction)switchCarouselType;
- (IBAction)toggleOrientation;
- (IBAction)toggleWrap;
- (IBAction)insertItem;
- (IBAction)removeItem;
- (IBAction)reloadCarousel;
- (IBAction) editingEnded:(id)sender;
@end
