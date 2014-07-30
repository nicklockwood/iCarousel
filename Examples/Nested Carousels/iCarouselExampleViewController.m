//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


#define SYNCHRONIZE_CAROUSELS NO


@interface iCarouselExampleViewController () <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, strong) NSMutableArray *items;

@end


@implementation iCarouselExampleViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        //set up data
        //this is an array of arrays
        self.items = [NSMutableArray array];
        for (int i = 0; i < 100; i++)
        {
            NSMutableArray *subitems = [NSMutableArray array];
            for (int j = 0; j < 20; j++)
            {
                [subitems addObject:[NSNumber numberWithInt:j]];
            }
            [_items addObject:subitems];
        }
    }
    return self;
}

- (void)updatePerspective
{
    for (iCarousel *subCarousel in _carousel.visibleItemViews)
    {
        NSInteger index = subCarousel.tag;
        CGFloat offset = [_carousel offsetForItemAtIndex:index];
        subCarousel.viewpointOffset = CGSizeMake(-offset * _carousel.itemWidth, 0.0f);
        subCarousel.contentOffset = CGSizeMake(-offset * _carousel.itemWidth, 0.0f);
    }
}

- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    //this is true even if your project is using ARC, unless
    //you are targeting iOS 5 as a minimum deployment target
    _carousel.delegate = nil;
    _carousel.dataSource = nil;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure outer carousel
    _carousel.type = iCarouselTypeLinear;
    _carousel.centerItemWhenSelected = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
  
    [self updatePerspective];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //free up memory by releasing subviews
    self.carousel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark iCarousel methods

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    if (carousel == _carousel)
    {
        return 210.0f;
    }
    else
    {
        return 210.0f;
    }
}

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    if (carousel == _carousel)
    {
        return [_items count];
    }
    else
    {
        NSInteger index = carousel.tag;
        return [[_items objectAtIndex:index] count];
    }
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (carousel == _carousel)
    {
        //item for outer carousel
        iCarousel *subCarousel = (iCarousel *)view;

        if (view == nil)
        {
            subCarousel = [[iCarousel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, self.view.bounds.size.height)];
            subCarousel.dataSource = self;
            subCarousel.delegate = self;
            subCarousel.vertical = YES;
            subCarousel.type = iCarouselTypeCylinder;
            view = subCarousel;
        }

        //configure view
        //you might want to restore a saved scrollOffset here
        //but for now we'll just set it to zero
        subCarousel.scrollOffset = 0.0f;
        subCarousel.tag = index;
    }
    else
    {
        //item for inner carousel
        UILabel *label = nil;
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
            imageView.image = [UIImage imageNamed:@"page.png"];
            imageView.contentMode = UIViewContentModeCenter;
            view = imageView;
            
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
        
        //configure view
        NSInteger outerIndex = carousel.tag;
        NSArray *subItems = [_items objectAtIndex:outerIndex];
        label.text = [[subItems objectAtIndex:index] stringValue];
    }
    
    //return view
    return view;
}

- (void)carouselDidScroll:(iCarousel *)carousel
{
    if (carousel == _carousel)
    {
        //adjust perspective for inner carousels
        //every time the outer carousel is moved
        //for 2D carousel styles this wouldn't be neccesary
        [self updatePerspective];
    }
    else if (SYNCHRONIZE_CAROUSELS)
    {
        //synchronise inner carousel scroll offsets each time any
        //of the inner carousels is moved - if you don't want this
        //you can turn it off, but then you'd need to keep track of
        //the scroll state for each carousel when they are loaded/unloaded
        for (iCarousel *subCarousel in _carousel.visibleItemViews)
        {
            subCarousel.scrollOffset = carousel.scrollOffset;
        }
    }
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionShowBackfaces:
        {
            //depths sorting doesn't really work for
            //nested carousels, so it looks pretty odd
            //if you change this to YES
            return NO;
        }
        case iCarouselOptionVisibleItems:
        {
            if (carousel == _carousel)
            {
                //the standard visible items calculation
                //cuts off the carousel a bit early if the
                //inner views are also 3D - here we increase
                //the visible item count a bit
                return value + 2;
            }
            return value;
        }
        case iCarouselOptionCount:
        {
            if (carousel != _carousel)
            {
                //precisely control the carousel
                //size for the inner carousels
                return 12;
            }
            return value;
        }
        default:
        {
            return value;
        }
    }
}

@end
