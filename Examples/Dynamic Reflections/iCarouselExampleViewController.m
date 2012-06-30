//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"
#import "ReflectionView.h"


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
    //generate 100 item views
    //normally we'd use a backing array
    //as shown in the basic iOS example
    //but for this example we haven't bothered
    return 100;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(ReflectionView *)view
{ 
	UILabel *label = nil;
	
	//create new view if no view is available for recycling
	if (view == nil)
	{
        //set up reflection view
		view = [[[ReflectionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 200.0f)] autorelease];
        
        //set up content
		label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
		label.backgroundColor = [UIColor lightGrayColor];
		label.layer.borderColor = [UIColor whiteColor].CGColor;
        label.layer.borderWidth = 4.0f;
        label.layer.cornerRadius = 8.0f;
        label.textAlignment = UITextAlignmentCenter;
		label.font = [label.font fontWithSize:50];
        label.tag = 9999;
		[view addSubview:label];
	}
	else
	{
		label = (UILabel *)[view viewWithTag:9999];
	}
	
    //set label
	label.text = [NSString stringWithFormat:@"%i", index];
    
    //update reflection
    //this step is expensive, so if you don't need
    //unique reflections for each item, don't do this
    //and you'll get much smoother peformance
    [view update];
	
	return view;
}

@end
