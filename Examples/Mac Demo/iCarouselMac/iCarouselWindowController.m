//
//  iCarouselWindowController.m
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselWindowController.h"


@interface iCarouselWindowController ()

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, strong) NSMutableArray *items;

@end


@implementation iCarouselWindowController

@synthesize carousel;
@synthesize wrap;
@synthesize items;

- (id)initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window]))
    {
        //set up data
        wrap = YES;
        self.items = [NSMutableArray array];
        for (int i = 0; i < 1000; i++)
        {
            [items addObject:[NSNumber numberWithInt:i]];
        }
    }
    return self;
}

- (void)awakeFromNib
{
    //configure carousel
    self.carousel.type = iCarouselTypeCoverFlow2;
    [self.window makeFirstResponder:self.carousel];
}

- (void)dealloc
{
	//it's a good idea to set these to nil here to avoid
	//sending messages to a deallocated window or view controller
	carousel.delegate = nil;
	carousel.dataSource = nil;
	
}

- (IBAction)switchCarouselType:(id)sender
{
    //restore view opacities to normal
    for (NSView *view in self.carousel.visibleItemViews)
    {
        view.layer.opacity = 1.0;
    }
	
    self.carousel.type = (iCarouselType)[sender tag];
}

- (IBAction)toggleVertical:(id)sender
{
    self.carousel.vertical = !self.carousel.vertical;
    [(NSMenuItem *)sender setState:self.carousel.vertical? NSOnState: NSOffState];
}

- (IBAction)toggleWrap:(id)sender
{
    self.wrap = !self.wrap;
    [(NSMenuItem *)sender setState:self.wrap? NSOnState: NSOffState];
    [self.carousel reloadData];
}

- (IBAction)insertItem:(__unused id)sender
{
    [self.carousel insertItemAtIndex:self.carousel.currentItemIndex animated:YES];
}

- (IBAction)removeItem:(__unused id)sender
{
    [self.carousel removeItemAtIndex:self.carousel.currentItemIndex animated:YES];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return (NSInteger)[self.items count];
}

- (NSView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(NSView *)view
{
    NSTextField *label = nil;
    
    //create new view if no view is available for recycling
	if (view == nil)
	{
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
		NSImage *image = [NSImage imageNamed:@"page.png"];
       	view = [[NSImageView alloc] initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)];
        [(NSImageView *)view setImage:image];
        [(NSImageView *)view setImageScaling:NSImageScaleAxesIndependently];
        
        label = [[NSTextField alloc] init];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setBordered:NO];
        [label setSelectable:NO];
        [label setAlignment:NSCenterTextAlignment];
        [label setFont:[NSFont fontWithName:[(NSFont * __nonnull)[label font] fontName] size:50]];
        label.tag = 1;
        [view addSubview:label];
	}
	else
	{
		//get a reference to the label in the recycled view
		label = (NSTextField *)[view viewWithTag:1];
	}
    
	//set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
	[label setStringValue:[NSString stringWithFormat:@"%lu", index]];
    [label sizeToFit];
    [label setFrameOrigin:NSMakePoint((view.bounds.size.width - label.frame.size.width)/2.0,
                                      (view.bounds.size.height - label.frame.size.height)/2.0)];
	
	return view;
}

- (NSInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel
{
	//note: placeholder views are only displayed if wrapping is disabled
	return 2;
}

- (NSView *)carousel:(__unused iCarousel *)carousel placeholderViewAtIndex:(NSInteger)index reusingView:(NSView *)view
{
	NSTextField *label = nil;
    
    //create new view if no view is available for recycling
	if (view == nil)
	{
		NSImage *image = [NSImage imageNamed:@"page.png"];
       	view = [[NSImageView alloc] initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)];
        [(NSImageView *)view setImage:image];
        [(NSImageView *)view setImageScaling:NSImageScaleAxesIndependently];
        
        label = [[NSTextField alloc] init];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setBordered:NO];
        [label setSelectable:NO];
        [label setAlignment:NSCenterTextAlignment];
        [label setFont:[NSFont fontWithName:[(NSFont * __nonnull)[label font] fontName] size:50]];
        label.tag = 1;
        [view addSubview:label];
	}
	else
	{
        //get a reference to the label in the recycled view
		label = (NSTextField *)[view viewWithTag:1];
	}
    
	//set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
	[label setStringValue:(index == 0)? @"[": @"]"];
    [label sizeToFit];
    [label setFrameOrigin:NSMakePoint((view.bounds.size.width - label.frame.size.width)/2.0,
                                      (view.bounds.size.height - label.frame.size.height)/2.0)];
    
    return view;
}

- (CGFloat)carouselItemWidth:(__unused iCarousel *)carousel
{
    //set correct view size
    //because the background image on the views makes them too large
    return 200.0f;
}

- (CATransform3D)carousel:(__unused iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * self.carousel.itemWidth);
}

- (CGFloat)carousel:(__unused iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
            return self.wrap;
        }
        case iCarouselOptionSpacing:
        {
            //reduce item spacing to compensate
            //for drop shadow and reflection around views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
            if (self.carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        case iCarouselOptionShowBackfaces:
        case iCarouselOptionRadius:
        case iCarouselOptionAngle:
        case iCarouselOptionArc:
        case iCarouselOptionTilt:
        case iCarouselOptionCount:
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeRange:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionVisibleItems:
        {
            return value;
        }
    }
}


@end
