//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


@interface iCarouselExampleViewController () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, retain) NSMutableArray *items;

@end


@implementation iCarouselExampleViewController

@synthesize carousel;
@synthesize navItem;
@synthesize orientationBarItem;
@synthesize wrapBarItem;
@synthesize wrap;
@synthesize items;
@synthesize arcSlider;
@synthesize radiusSlider;
@synthesize tiltSlider;
@synthesize spacingSlider;

- (void)setUp
{
	//set up data
	wrap = YES;
	self.items = [NSMutableArray array];
	for (int i = 0; i < 1000; i++)
	{
		[items addObject:[NSNumber numberWithInt:i]];
	}
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (void)dealloc
{
	//it's a good idea to set these to nil here to avoid
	//sending messages to a deallocated viewcontroller
	carousel.delegate = nil;
	carousel.dataSource = nil;
	
    [carousel release];
    [navItem release];
    [orientationBarItem release];
    [wrapBarItem release];
    [items release];
    [arcSlider release];
    [radiusSlider release];
    [tiltSlider release];
    [spacingSlider release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)updateSliders
{
    switch (carousel.type)
    {
        case iCarouselTypeLinear:
        {
            arcSlider.enabled = NO;
        	radiusSlider.enabled = NO;
            tiltSlider.enabled = NO;
            spacingSlider.enabled = YES;
            break;
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            arcSlider.enabled = YES;
        	radiusSlider.enabled = YES;
            tiltSlider.enabled = NO;
            spacingSlider.enabled = YES;
            break;
        }
        default:
        {
            arcSlider.enabled = NO;
        	radiusSlider.enabled = NO;
            tiltSlider.enabled = YES;
            spacingSlider.enabled = YES;
            break;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure carousel
    carousel.type = iCarouselTypeCoverFlow2;
    [self updateSliders];
    navItem.title = @"CoverFlow2";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.carousel = nil;
    self.navItem = nil;
    self.orientationBarItem = nil;
    self.wrapBarItem = nil;
    self.arcSlider = nil;
    self.radiusSlider = nil;
    self.tiltSlider = nil;
    self.spacingSlider = nil;
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
                                              otherButtonTitles:@"Linear", @"Rotary", @"Inverted Rotary", @"Cylinder", @"Inverted Cylinder", @"Wheel", @"Inverted Wheel", @"CoverFlow", @"CoverFlow2", @"Time Machine", @"Inverted Time Machine", nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (IBAction)toggleOrientation
{
    //carousel orientation can be animated
    [UIView beginAnimations:nil context:nil];
    carousel.vertical = !carousel.vertical;
    [UIView commitAnimations];
    
    //update button
    orientationBarItem.title = carousel.vertical? @"Vertical": @"Horizontal";
}

- (IBAction)toggleWrap
{
    wrap = !wrap;
    wrapBarItem.title = wrap? @"Wrap: ON": @"Wrap: OFF";
    [carousel reloadData];
}

- (IBAction)insertItem
{
    NSInteger index = MAX(0, carousel.currentItemIndex);
    [items insertObject:[NSNumber numberWithInt:carousel.numberOfItems] atIndex:index];
    [carousel insertItemAtIndex:index animated:YES];
}

- (IBAction)removeItem
{
    if (carousel.numberOfItems > 0)
    {
        NSInteger index = carousel.currentItemIndex;
        [carousel removeItemAtIndex:index animated:YES];
        [items removeObjectAtIndex:index];
    }
}

- (IBAction)reloadCarousel
{
    [carousel reloadData];
}

#pragma mark -
#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex	>= 0)
    {
        //map button index to carousel type
        iCarouselType type = buttonIndex;
        
        //carousel can smoothly animate between types
        [UIView beginAnimations:nil context:nil];
        carousel.type = type;
        [self updateSliders];
        [UIView commitAnimations];
        
        //update title
        navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
    }
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)] autorelease];
        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [label.font fontWithSize:50];
        label.tag = 1;
        [view addSubview:label];
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    label.text = [[items objectAtIndex:index] stringValue];
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            return wrap;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                return 0.0f;
            }
            return value;
        }
        case iCarouselOptionArc:
        {
            return 2 * M_PI * arcSlider.value;
        }
        case iCarouselOptionRadius:
        {
            return value * radiusSlider.value;
        }
        case iCarouselOptionTilt:
        {
            return tiltSlider.value;
        }
        case iCarouselOptionSpacing:
        {
            return value * spacingSlider.value;
        }
        default:
        {
            return value;
        }
    }
}

@end
