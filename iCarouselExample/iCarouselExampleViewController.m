//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iCarouselExampleViewController.h"


@interface iCarouselExampleViewController () <UIActionSheetDelegate>

@end


@implementation iCarouselExampleViewController

@synthesize carousel;
@synthesize navItem;

- (void)dealloc
{
    [carousel release];
    [navItem release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    carousel.type = iCarouselTypeCoverFlow;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.carousel = nil;
    self.navItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)switchCarouselType
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Carousel Type"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Linear", @"Cylinder", @"Inverted Cylinder", @"CoverFlow", nil];
    [sheet showInView:self.view];
    [sheet release];
}

#pragma mark -
#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    carousel.type = buttonIndex;
    navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfPagesInCarousel:(iCarousel *)carousel
{
    return 12;
}

- (UIView *)carousel:(iCarousel *)carousel viewForPageAtIndex:(NSUInteger)index
{
    return [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page.png"]] autorelease];
}

- (float)carouselPageWidth:(iCarousel *)carousel
{
    return 210;
}

@end
