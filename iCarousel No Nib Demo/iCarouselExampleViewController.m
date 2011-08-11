//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"
#import "iCarousel.h"


#define NUMBER_OF_ITEMS 20
#define ITEM_SPACING 210
#define USE_BUTTONS YES


@interface iCarouselExampleViewController () <iCarouselDataSource, iCarouselDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) iCarousel *carousel;
@property (nonatomic, retain) UINavigationItem *navItem;
@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, retain) NSMutableArray *items;

@end


@implementation iCarouselExampleViewController

@synthesize carousel;
@synthesize navItem;
@synthesize wrap;
@synthesize items;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        //set up data
        self.items = [NSMutableArray array];
        for (int i = 0; i < NUMBER_OF_ITEMS; i++)
        {
            [items addObject:[NSNumber numberWithInt:i]];
        }
    }
    return self;
}

- (void)dealloc
{
    [carousel release];
    [navItem release];
	[items release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    wrap = YES;
	
	//add background
	UIImageView *backgroundView = [[[UIImageView alloc] initWithFrame:self.view.bounds] autorelease];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	backgroundView.image = [UIImage imageNamed:@"background.png"];
	[self.view addSubview:backgroundView];
	
	//create carousel
	self.carousel = [[iCarousel alloc] initWithFrame:self.view.bounds];
	carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    carousel.type = iCarouselTypeCoverFlow2;
	carousel.delegate = self;
	carousel.dataSource = self;

	//add carousel to view
	[self.view addSubview:carousel];
	
	//add top bar
	UINavigationBar *navbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
	navbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.navItem = [[[UINavigationItem alloc] initWithTitle:@"Coverflow2"] autorelease];
	navItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Switch Type" style:UIBarButtonItemStyleBordered target:self action:@selector(switchCarouselType)] autorelease];
	navItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Wrap: ON" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleWrap)] autorelease];
	[navbar setItems:[NSArray arrayWithObject:navItem]];
	[self.view addSubview:navbar];
	[navbar release];
	
	//add bottom bar
	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	[toolbar setItems:[NSArray arrayWithObjects:
					   [[[UIBarButtonItem alloc] initWithTitle:@"Insert Item" style:UIBarButtonItemStyleBordered target:self action:@selector(insertItem)] autorelease],
					   [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],
					   [[[UIBarButtonItem alloc] initWithTitle:@"Delete Item" style:UIBarButtonItemStyleBordered target:self action:@selector(removeItem)] autorelease],
					   nil]];
	[self.view addSubview:toolbar];
	[toolbar release];
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
                                              otherButtonTitles:@"Linear", @"Rotary", @"Inverted Rotary", @"Cylinder", @"Inverted Cylinder", @"CoverFlow", @"CoverFlow2", @"Custom", nil];
    [sheet showInView:self.view];
    [sheet release];
}

- (IBAction)toggleWrap
{
    wrap = !wrap;
    navItem.rightBarButtonItem.title = wrap? @"Wrap: ON": @"Wrap: OFF";
    [carousel reloadData];
}

- (IBAction)insertItem
{
    NSInteger index = carousel.currentItemIndex;
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

#pragma mark -
#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //restore view opacities to normal
    for (UIView *view in carousel.visibleViews)
    {
        view.alpha = 1.0;
    }
        
    carousel.type = buttonIndex;
    navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index
{
    if (USE_BUTTONS)
    {
        //create a numbered button
        UIImage *image = [UIImage imageNamed:@"page.png"];
        UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)] autorelease];
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button setTitle:[[items objectAtIndex:index] stringValue] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.titleLabel.font = [button.titleLabel.font fontWithSize:50];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = index;
        return button;
    }
    else
    {
        //create a numbered view
        UIView *view = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page.png"]] autorelease];
        UILabel *label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
        label.text = [[items objectAtIndex:index] stringValue];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [label.font fontWithSize:50];
        [view addSubview:label];
        return view;
    }
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
	//note: placeholder views are only displayed if wrapping is disabled
	return 2;
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index
{
	//create a placeholder view
	UIView *view = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page.png"]] autorelease];
	UILabel *label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
	label.text = (index == 0)? @"[": @"]";
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [label.font fontWithSize:50];
	[view addSubview:label];
	return view;
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    //limit the number of items views loaded concurrently (for performance reasons)
    return 21;
}

- (float)carouselItemWidth:(iCarousel *)carousel
{
    //slightly wider than item view
    return ITEM_SPACING;
}

- (CATransform3D)carousel:(iCarousel *)_carousel transformForItemView:(UIView *)view withOffset:(float)offset
{
    //implement 'flip3D' style carousel
    
    //set opacity based on distance from camera
    view.alpha = 1.0 - fminf(fmaxf(offset, 0.0), 1.0);
    
    //do 3d transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = self.carousel.perspective;
    transform = CATransform3DRotate(transform, M_PI / 8.0, 0, 1.0, 0);
    return CATransform3DTranslate(transform, 0.0, 0.0, offset * carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel
{
    //wrap all carousels
    return wrap;
}

- (void)carouselWillBeginDragging:(iCarousel *)carousel
{
	NSLog(@"Carousel will begin dragging");
}

- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate
{
	NSLog(@"Carousel did end dragging and %@ decelerate", decelerate? @"will": @"won't");
}

- (void)carouselWillBeginDecelerating:(iCarousel *)carousel
{
	NSLog(@"Carousel will begin decelerating");
}

- (void)carouselDidEndDecelerating:(iCarousel *)carousel
{
	NSLog(@"Carousel did end decelerating");
}

- (void)carouselWillBeginScrollingAnimation:(iCarousel *)carousel
{
	NSLog(@"Carousel will begin scrolling");
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
	NSLog(@"Carousel did end scrolling");
}

- (void)carousel:(iCarousel *)_carousel didSelectItemAtIndex:(NSInteger)index
{
	if (index == carousel.currentItemIndex)
	{
		//note, this will only ever happen if USE_BUTTONS == NO
		//otherwise the button intercepts the tap event
		NSLog(@"Selected current item");
	}
	else
	{
		NSLog(@"Selected item number %i", index);
	}
}

#pragma mark -
#pragma mark Button tap event

- (void)buttonTapped:(UIButton *)sender
{
    [[[[UIAlertView alloc] initWithTitle:@"Button Tapped"
                                 message:[NSString stringWithFormat:@"You tapped button number %i", sender.tag]
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease] show];
}

@end
