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
        for (int i = 0; i < 10000; i++)
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
    return [items count];
}

- (NSView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(NSView *)view
{
    CGColorRef color = CGColorCreateGenericRGB(0.5f, 0.5f, 0.5f, 1.0f);
    view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,200.0f, 200.0f)];
    [view setWantsLayer:YES];
    [view.layer setBackgroundColor:color];
    CGColorRelease(color);
    
    NSTextField *label = [[NSTextField alloc] init];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setBordered:NO];
    [label setSelectable:NO];
    [label setAlignment:NSCenterTextAlignment];
    [label setFont:[NSFont fontWithName:[[label font] fontName] size:50]];
    [label setStringValue:[NSString stringWithFormat:@"%lu", index]];
    [label sizeToFit];
    [label setFrameOrigin:NSMakePoint((view.bounds.size.width - label.frame.size.width)/2.0,
                                      (view.bounds.size.height - label.frame.size.height)/2.0)];
    [view addSubview:label];
	
	return view;
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel.itemWidth);
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
            return wrap;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
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
