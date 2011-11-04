//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


#define NUMBER_OF_ITEMS ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? 19: 12)
#define ITEM_SPACING 210


@implementation iCarouselExampleViewController

@synthesize carousel;

- (void)dealloc
{
    carousel.delegate = nil;
    carousel.dataSource = nil;
    [carousel release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure carousel
    carousel.type = iCarouselTypeCoverFlow2;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.carousel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return NUMBER_OF_ITEMS;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index
{
    //load from nib
    return [[[NSBundle mainBundle] loadNibNamed:@"ItemView" owner:self options:nil] lastObject];
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    return ITEM_SPACING;
}

#pragma mark -
#pragma mark Controls

- (IBAction)pressedButton:(id)sender
{
    NSLog(@"button pressed");
}

- (IBAction)toggledSwitch:(id)sender
{
    NSLog(@"switch toggled");
}

- (IBAction)changedSlider:(id)sender
{
    NSLog(@"slider changed");
}

@end
