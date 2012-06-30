//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


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
    return 1000;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    //load from nib
    return [[[NSBundle mainBundle] loadNibNamed:@"ItemView" owner:self options:nil] lastObject];
}

#pragma mark -
#pragma mark Controls

- (IBAction)pressedButton:(id)sender
{
    NSLog(@"button %i pressed", [carousel indexOfItemViewOrSubview:sender]);
}

- (IBAction)toggledSwitch:(id)sender
{
    NSLog(@"switch %i toggled", [carousel indexOfItemViewOrSubview:sender]);
}

- (IBAction)changedSlider:(id)sender
{
    NSLog(@"slider %i changed", [carousel indexOfItemViewOrSubview:sender]);
}

@end
