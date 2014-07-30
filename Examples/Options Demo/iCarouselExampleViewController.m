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
@property (nonatomic, strong) NSMutableArray *items;

@end


@implementation iCarouselExampleViewController

- (void)setUp
{
	//set up data
	_wrap = YES;
	self.items = [NSMutableArray array];
	for (int i = 0; i < 1000; i++)
	{
		[_items addObject:@(i)];
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
	_carousel.delegate = nil;
	_carousel.dataSource = nil;
}

#pragma mark -
#pragma mark View lifecycle

- (void)updateSliders
{
    switch (_carousel.type)
    {
        case iCarouselTypeLinear:
        {
            _arcSlider.enabled = NO;
        	_radiusSlider.enabled = NO;
            _tiltSlider.enabled = NO;
            _spacingSlider.enabled = YES;
            break;
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            _arcSlider.enabled = YES;
        	_radiusSlider.enabled = YES;
            _tiltSlider.enabled = NO;
            _spacingSlider.enabled = YES;
            break;
        }
        default:
        {
            _arcSlider.enabled = NO;
        	_radiusSlider.enabled = NO;
            _tiltSlider.enabled = YES;
            _spacingSlider.enabled = YES;
            break;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure carousel
    _carousel.type = iCarouselTypeCoverFlow2;
    [self updateSliders];
    _navItem.title = @"CoverFlow2";
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
}

- (IBAction)toggleOrientation
{
    //carousel orientation can be animated
    [UIView beginAnimations:nil context:nil];
    _carousel.vertical = !_carousel.vertical;
    [UIView commitAnimations];
    
    //update button
    _orientationBarItem.title = _carousel.vertical? @"Vertical": @"Horizontal";
}

- (IBAction)toggleWrap
{
    _wrap = !_wrap;
    _wrapBarItem.title = _wrap? @"Wrap: ON": @"Wrap: OFF";
    [_carousel reloadData];
}

- (IBAction)insertItem
{
    NSInteger index = MAX(0, _carousel.currentItemIndex);
    [_items insertObject:@(_carousel.numberOfItems) atIndex:index];
    [_carousel insertItemAtIndex:index animated:YES];
}

- (IBAction)removeItem
{
    if (_carousel.numberOfItems > 0)
    {
        NSInteger index = _carousel.currentItemIndex;
        [_carousel removeItemAtIndex:index animated:YES];
        [_items removeObjectAtIndex:index];
    }
}

- (IBAction)reloadCarousel
{
    [_carousel reloadData];
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
        _carousel.type = type;
        [self updateSliders];
        [UIView commitAnimations];
        
        //update title
        _navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
    }
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [_items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        label = [[UILabel alloc] initWithFrame:view.bounds];
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
    label.text = [_items[index] stringValue];
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            return _wrap;
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
            return 2 * M_PI * _arcSlider.value;
        }
        case iCarouselOptionRadius:
        {
            return value * _radiusSlider.value;
        }
        case iCarouselOptionTilt:
        {
            return _tiltSlider.value;
        }
        case iCarouselOptionSpacing:
        {
            return value * _spacingSlider.value;
        }
        default:
        {
            return value;
        }
    }
}

@end
