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
@synthesize label;

- (void)dealloc
{
    carousel.delegate = nil;
    carousel.dataSource = nil;
    
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
    self.label = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //generate 100 item views
    //normally we'd use a backing array
    //as shown in the basic iOS example
    //but for this example we haven't bothered
    return 100;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (!view)
    {
    	//load new item view instance from nib
        //control events are bound to view controller in nib file
        //note that it is only safe to use the reusingView if we return the same nib for each
        //item view, if different items have different contents, ignore the reusingView value
    	view = [[[NSBundle mainBundle] loadNibNamed:@"ItemView" owner:self options:nil] lastObject];
    }
    return view;
}

#pragma mark -
#pragma mark Control events

- (IBAction)pressedButton:(id)sender
{
    label.text = [NSString stringWithFormat:@"Button %i pressed", [carousel indexOfItemViewOrSubview:sender]];
}

- (IBAction)toggledSwitch:(id)sender
{
    label.text = [NSString stringWithFormat:@"Switch %i toggled", [carousel indexOfItemViewOrSubview:sender]];
}

- (IBAction)changedSlider:(id)sender
{
    label.text = [NSString stringWithFormat:@"Slider %i changed", [carousel indexOfItemViewOrSubview:sender]];
}

@end
