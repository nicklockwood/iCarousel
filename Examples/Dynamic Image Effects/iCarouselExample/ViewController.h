//
//  ViewController.h
//  ImageFXViewDemo
//
//  Created by Nick Lockwood on 31/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXImageView.h"
#import "iCarousel.h"

@interface ViewController : UIViewController <iCarouselDataSource>

@property (nonatomic, strong) IBOutlet iCarousel *carousel;

@end
