//
//  iCarouselWindowController.m
//  iCarouselMac
//
//  Created by Nick Lockwood on 11/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselWindowController.h"


#define NUMBER_OF_ITEMS 19
#define NUMBER_OF_VISIBLE_ITEMS 19
#define ITEM_SPACING 210
#define INCLUDE_PLACEHOLDERS YES


@interface iCarouselWindowController ()

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, retain) NSMutableArray *items;

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
        for (int i = 0; i < NUMBER_OF_ITEMS; i++)
        {
            [items addObject:[NSNumber numberWithInt:i]];
        }
    }
    return self;
}

- (void)awakeFromNib
{
    //configure carousel
    carousel.type = iCarouselTypeCoverFlow2;
    [self.window makeFirstResponder:carousel];
}

- (void)dealloc
{
	//it's a good idea to set these to nil here to avoid
	//sending messages to a deallocated window or view controller
	carousel.delegate = nil;
	carousel.dataSource = nil;
	
    [carousel release];
    [super dealloc];
}

- (IBAction)switchCarouselType:(id)sender
{
	//restore view opacities to normal
    for (NSView *view in carousel.visibleItemViews)
    {
        view.layer.opacity = 1.0;
    }
	
    carousel.type = (iCarouselType)[sender tag];
}

- (IBAction)toggleVertical:(id)sender
{
    carousel.vertical = !carousel.vertical;
    [sender setState:carousel.vertical? NSOnState: NSOffState];
}

- (IBAction)toggleWrap:(id)sender
{
    wrap = !wrap;
    [sender setState:wrap? NSOnState: NSOffState];
    [carousel reloadData];
}

- (IBAction)insertItem:(id)sender
{
    [carousel insertItemAtIndex:carousel.currentItemIndex animated:YES];
}

- (IBAction)removeItem:(id)sender
{
    [carousel removeItemAtIndex:carousel.currentItemIndex animated:YES];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return NUMBER_OF_ITEMS;
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    //limit the number of items views loaded concurrently (for performance reasons)
    return NUMBER_OF_VISIBLE_ITEMS;
}

- (NSView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(NSView *)view
{
    NSTextField *label = nil;
    
    //create new view if no view is available for recycling
	if (view == nil)
	{
		NSImage *image = [NSImage imageNamed:@"page.png"];
       	view = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)] autorelease];
        [(NSImageView *)view setImage:image];
        [(NSImageView *)view setImageScaling:NSImageScaleAxesIndependently];
        
        label = [[[NSTextField alloc] init] autorelease];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setBordered:NO];
        [label setSelectable:NO];
        [label setAlignment:NSCenterTextAlignment];
        [label setFont:[NSFont fontWithName:[[label font] fontName] size:50]];
        [view addSubview:label];
	}
	else
	{
		label = [[view subviews] lastObject];
	}
    
	//set label
	[label setStringValue:[NSString stringWithFormat:@"%i", index]];
    [label sizeToFit];
    [label setFrameOrigin:NSMakePoint((view.bounds.size.width - label.frame.size.width)/2.0,
                                      (view.bounds.size.height - label.frame.size.height)/2.0)];
	
	return view;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
	//note: placeholder views are only displayed if wrapping is disabled
	return INCLUDE_PLACEHOLDERS? 2: 0;
}

- (NSView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(NSView *)view
{
	NSTextField *label = nil;
    
    //create new view if no view is available for recycling
	if (view == nil)
	{
		NSImage *image = [NSImage imageNamed:@"page.png"];
       	view = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)] autorelease];
        [(NSImageView *)view setImage:image];
        [(NSImageView *)view setImageScaling:NSImageScaleAxesIndependently];
        
        label = [[[NSTextField alloc] init] autorelease];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setBordered:NO];
        [label setSelectable:NO];
        [label setAlignment:NSCenterTextAlignment];
        [label setFont:[NSFont fontWithName:[[label font] fontName] size:50]];
        [view addSubview:label];
	}
	else
	{
		label = [[view subviews] lastObject];
	}
    
	//set label
	[label setStringValue:(index == 0)? @"[": @"]"];
    [label sizeToFit];
    [label setFrameOrigin:NSMakePoint((view.bounds.size.width - label.frame.size.width)/2.0,
                                      (view.bounds.size.height - label.frame.size.height)/2.0)];
    
    return view;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    //usually this should be slightly wider than the item views
    return ITEM_SPACING;
}

- (CGFloat)carousel:(iCarousel *)carousel itemAlphaForOffset:(CGFloat)offset
{
	//set opacity based on distance from camera
    return 1.0f - fminf(fmaxf(offset, 0.0f), 1.0f);
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel
{
    return wrap;
}

@end
