//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


@interface iCarouselExampleViewController ()

@property (nonatomic, strong) NSMutableArray *items1;
@property (nonatomic, strong) NSMutableArray *items2;

@end


@implementation iCarouselExampleViewController

@synthesize carousel1;
@synthesize carousel2;
@synthesize items1;
@synthesize items2;

- (void)awakeFromNib
{
    //set up data sources
    self.items1 = [NSMutableArray array];
    for (int i = 0; i < 100; i++)
    {
        [items1 addObject:[NSNumber numberWithInt:i]];
    }
    
    self.items2 = [NSMutableArray array];
    for (int i = 65; i < 65 + 58; i++)
    {
        [items2 addObject:[NSString stringWithFormat:@"%c", i]];
    }
}

- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    carousel1.delegate = nil;
    carousel1.dataSource = nil;
    carousel2.delegate = nil;
    carousel2.dataSource = nil;
    
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure carousel
    carousel1.type = iCarouselTypeCoverFlow2;
    carousel2.type = iCarouselTypeLinear;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //free up memory by releasing subviews
    self.carousel1 = nil;
    self.carousel2 = nil;
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    if (carousel == carousel1)
    {
        return [items1 count];
    }
    else
    {
        return [items2 count];
    }
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
        [view addSubview:label];
    }
    else
    {
        label = [[view subviews] lastObject];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    if (carousel == carousel1)
    {
        //items in this array are numbers
        label.text = [[items1 objectAtIndex:index] stringValue];
    }
    else
    {
        //items in this array are strings
        label.text = [items2 objectAtIndex:index];
    }
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            if (carousel == carousel2)
            {
                //add a bit of spacing between the item views
                return value * 1.05f;
            }
        }
        default:
        {
            return value;
        }
    }
}

@end
