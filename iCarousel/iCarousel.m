//
//  iCarousel.m
//
//  Version 1.5.2
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//
//  Get the latest version of iCarousel from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#icarousel
//  https://github.com/demosthenese/icarousel
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "iCarousel.h"


#define SCROLL_DURATION 0.4f
#define INSERT_DURATION 0.4f
#define DECELERATE_THRESHOLD 0.1f
#define SCROLL_SPEED_THRESHOLD 2.0f
#define SCROLL_DISTANCE_THRESHOLD 0.1f
#define DECELERATION_MULTIPLIER 30.0f


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@interface iCarousel () <UIGestureRecognizerDelegate>
#else
@interface iCarousel ()
#endif

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSDictionary *itemViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) NSInteger numberOfPlaceholdersToShow;
@property (nonatomic, assign) float itemWidth;
@property (nonatomic, assign) float scrollOffset;
@property (nonatomic, assign) float startOffset;
@property (nonatomic, assign) float endOffset;
@property (nonatomic, assign) NSTimeInterval scrollDuration;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) float startVelocity;
@property (nonatomic, assign) id timer;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) float previousTranslation;
@property (nonatomic, assign) BOOL shouldWrap;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) float scrollSpeed;
@property (nonatomic, assign) NSTimeInterval toggleTime;

- (void)layOutItemViews;
- (UIView *)loadViewAtIndex:(NSInteger)index;
- (NSInteger)clampedIndex:(NSInteger)index;
- (float)clampedOffset:(float)offset;
- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index;
- (void)startAnimation;
- (void)stopAnimation;
- (void)didScroll;

@end


@implementation iCarousel

@synthesize dataSource;
@synthesize delegate;
@synthesize type;
@synthesize perspective;
@synthesize numberOfItems;
@synthesize numberOfPlaceholders;
@synthesize numberOfPlaceholdersToShow;
@synthesize numberOfVisibleItems;
@synthesize contentView;
@synthesize itemViews;
@synthesize previousItemIndex;
@synthesize itemWidth;
@synthesize scrollOffset;
@synthesize startVelocity;
@synthesize timer;
@synthesize decelerating;
@synthesize scrollEnabled;
@synthesize decelerationRate;
@synthesize bounceDistance;
@synthesize bounces;
@synthesize contentOffset;
@synthesize viewpointOffset;
@synthesize startOffset;
@synthesize endOffset;
@synthesize scrollDuration;
@synthesize startTime;
@synthesize scrolling;
@synthesize previousTranslation;
@synthesize shouldWrap;
@synthesize dragging;
@synthesize scrollSpeed;
@synthesize toggleTime;
@synthesize toggle;
@synthesize stopAtItemBoundary;
@synthesize scrollToItemBoundary;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

@synthesize centerItemWhenSelected;

#endif


#pragma mark -
#pragma mark Initialisation

- (void)setup
{
    perspective = -1.0f/500.0f;
    decelerationRate = 0.95f;
    scrollEnabled = YES;
    bounces = YES;
    scrollOffset = 0.0f;
    contentOffset = CGSizeZero;
	viewpointOffset = CGSizeZero;
    numberOfVisibleItems = 21;
	shouldWrap = NO;
    scrollSpeed = 1.0f;
    bounceDistance = 1.0f;
    toggle = 0.0f;
    stopAtItemBoundary = YES;
    scrollToItemBoundary = YES;
    
    contentView = [[UIView alloc] initWithFrame:self.bounds];
    
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    
	centerItemWhenSelected = YES;
	
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
	panGesture.delegate = self;
    [contentView addGestureRecognizer:panGesture];
    [panGesture release];
    
#else
    
    [contentView setWantsLayer:YES];
    
#endif
    
    [self addSubview:contentView];
	[self reloadData];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{	
	if ((self = [super initWithCoder:aDecoder]))
    {
		[self setup];
#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED
        [self viewDidMoveToSuperview]; 
#endif
	}
	return self;
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (id)initWithFrame:(CGRect)frame
#else
- (id)initWithFrame:(NSRect)frame
#endif
{
	if ((self = [super initWithFrame:frame]))
    {
		[self setup];
	}
	return self;
}

- (void)setDataSource:(id<iCarouselDataSource>)_dataSource
{
    if (dataSource != _dataSource)
    {
        dataSource = _dataSource;
		[self reloadData];
    }
}

- (void)setDelegate:(id<iCarouselDelegate>)_delegate
{
    if (delegate != _delegate)
    {
        delegate = _delegate;
		[self layOutItemViews];
    }
}

- (void)setType:(iCarouselType)_type
{
    if (type != _type)
    {
        type = _type;
        [self layOutItemViews];
    }
}

- (void)setNumberOfVisibleItems:(NSInteger)_numberOfVisibleItems
{
    if (numberOfVisibleItems != _numberOfVisibleItems)
    {
        numberOfVisibleItems = _numberOfVisibleItems;
		[self layOutItemViews];
    }
}


#pragma mark -
#pragma mark View management

- (NSArray *)visibleIndices
{
    return [[itemViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSSet *)visibleViews
{
    return [NSSet setWithArray:[itemViews allValues]];
}

- (UIView *)viewAtIndex:(NSInteger)index
{
    return [itemViews objectForKey:[NSNumber numberWithInteger:index]];
}

- (UIView *)currentView
{
    return [self viewAtIndex:self.currentItemIndex];
}

- (void)setView:(UIView *)view forIndex:(NSInteger)index
{
    [(NSMutableDictionary *)itemViews setObject:view forKey:[NSNumber numberWithInteger:index]];
}

- (void)removeViewAtIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[itemViews count] - 1];
    for (NSNumber *number in [self visibleIndices])
    {
        NSInteger i = [number integerValue];
        if (i < index)
        {
            [newItemViews setObject:[itemViews objectForKey:number] forKey:number];
        }
        else if (i > index)
        {
            [newItemViews setObject:[itemViews objectForKey:number] forKey:[NSNumber numberWithInteger:i - 1]];
        }
    }
    self.itemViews = newItemViews;
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[itemViews count] - 1];
    for (NSNumber *number in [self visibleIndices])
    {
        NSInteger i = [number integerValue];
        if (i < index)
        {
            [newItemViews setObject:[itemViews objectForKey:number] forKey:number];
        }
        else
        {
            [newItemViews setObject:[itemViews objectForKey:number] forKey:[NSNumber numberWithInteger:i + 1]];
        }
    }
    if (view)
    {
        [self setView:view forIndex:index];
    }
    self.itemViews = newItemViews;
}

- (NSInteger)indexOfView:(UIView *)view
{
    for (NSNumber *number in [itemViews allKeys])
    {
        if ([itemViews objectForKey:number] == view)
        {
            return [number integerValue];
        }
    }
    return NSNotFound;
}


#pragma mark -
#pragma mark View layout

- (CATransform3D)transformForItemView:(UIView *)view withOffset:(float)offset
{
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = perspective;
    
    //perform transform
    switch (type)
    {
        case iCarouselTypeLinear:
        {
            return CATransform3DTranslate(transform, offset * itemWidth, 0.0f, 0.0f);
        }
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        {
			NSInteger count = numberOfItems + (shouldWrap? 0: numberOfPlaceholdersToShow);
            
            float arc = M_PI * 2.0f;
            float radius = itemWidth / 2.0f / tanf(arc/2.0f/count);
            float angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedRotary)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            return CATransform3DTranslate(transform, radius * sin(angle), 0.0f, radius * cos(angle) - radius);
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
			NSInteger count = numberOfItems + (shouldWrap? 0: numberOfPlaceholdersToShow);
            
			float arc = M_PI * 2.0f;
            float radius = itemWidth / 2.0f / tanf(arc/2.0f/count);
            float angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedCylinder)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
            transform = CATransform3DRotate(transform, angle, 0.0f, 1.0f, 0.0f);
            return CATransform3DTranslate(transform, 0.0f, 0.0f, radius + 0.01f);
        }
        case iCarouselTypeCoverFlow:
        case iCarouselTypeCoverFlow2:
        {
            float tilt = 0.9f;
            float spacing = 0.25f; // should be ~ 1/scrollSpeed;
            float clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
            
            if (type == iCarouselTypeCoverFlow2)
            {
                if (toggle >= 0.0f)
                {
                    if (offset < -0.5f)
                    {
                        clampedOffset = -1.0f;
                    }
                    else if (offset < 0.5f)
                    {
                        clampedOffset = -toggle;
                    }
                    else if (offset < 1.5f)
                    {
                        clampedOffset = 1.0f - toggle;
                    }
                }
                else
                {
                    if (offset > 0.5f)
                    {
                        clampedOffset = 1.0f;
                    }
                    else if (offset > -0.5f)
                    {
                        clampedOffset = -toggle;
                    }
                    else if (offset > -1.5f)
                    {
                        clampedOffset = - 1.0f - toggle;
                    }
                }
            }
            
            float x = (clampedOffset * 0.5f * tilt + offset * spacing) * itemWidth;
            float z = fabsf(clampedOffset) * -itemWidth * 0.5f;
            transform = CATransform3DTranslate(transform, x, 0.0f, z);
            return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0.0f, 1.0f, 0.0f);
        }
        case iCarouselTypeCustom:
        default:
        {
            return [delegate carousel:self transformForItemView:view withOffset:offset];
        }
    }
}

NSInteger compareViewDepth(id obj1, id obj2, void *context)
{
    iCarousel *carousel = context;
	CATransform3D t1 = ((UIView *)obj1).superview.layer.transform;
	CATransform3D t2 = ((UIView *)obj2).superview.layer.transform;
    float z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    float z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    float difference = z1 - z2;
    if (difference == 0.0f)
    {
        CATransform3D t3 = [carousel currentView].superview.layer.transform;
        float x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
        float x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
        float x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
        difference = fabsf(x2 - x3) - fabsf(x1 - x3);
    }
    return (difference < 0.0f)? NSOrderedAscending: NSOrderedDescending;
}

- (void)depthSortViews
{
    
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    
    for (UIView *view in [[itemViews allValues] sortedArrayUsingFunction:compareViewDepth context:self])
    {
        [contentView addSubview:view.superview];
    }
    
#endif
    
}

- (float)offsetForIndex:(NSInteger)index
{
    //calculate relative position
    float itemOffset = scrollOffset / itemWidth;
    float offset = index - itemOffset;
    if (shouldWrap)
    {
        if (offset > numberOfItems/2)
        {
            offset -= numberOfItems;
        }
        else if (offset < -numberOfItems/2)
        {
            offset += numberOfItems;
        }
    }
    return offset;
}

- (UIView *)containView:(UIView *)view
{
    UIView *container = [[[UIView alloc] initWithFrame:view.frame] autorelease];
	
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    
    //add tap gesture recogniser
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(didTap:)];
    tapGesture.delegate = self;
    [container addGestureRecognizer:tapGesture];
    [tapGesture release];
    
#endif
    
    [container addSubview:view];
    return container;
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index
{
    view.superview.bounds = view.bounds;
    
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    
	view.center = CGPointMake(view.bounds.size.width/2.0f, view.bounds.size.height/2.0f);
    view.superview.center = CGPointMake(self.bounds.size.width/2.0f + contentOffset.width,
										self.bounds.size.height/2.0f + contentOffset.height);
    
#else
    
	[view setFrameOrigin:NSMakePoint(0.0f, 0.0f)];
    [view.superview setFrameOrigin:NSMakePoint(self.bounds.size.width/2.0f + contentOffset.width,
											   self.bounds.size.height/2.0f + contentOffset.height)];
    view.superview.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    
#endif
    
    //special-case logic for iCarouselTypeCoverFlow2
    float offset = [self offsetForIndex:index];
    float clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
    if (decelerating || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f)
    {
        if (offset > 0)
        {
            toggle = (offset <= 0.5f)? -clampedOffset: (1.0f - clampedOffset);
        }
        else
        {
            toggle = (offset >= -0.5f)? -clampedOffset: (- 1.0f - clampedOffset);
        }
    }
    
    //transform view
    CATransform3D transform = [self transformForItemView:view withOffset:offset];
    view.superview.layer.transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0.0f);
    
	//hide containers for invisible views
    [view.superview setHidden:([view isHidden] || view.layer.opacity < 0.001f)];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void)layoutSubviews
{
    contentView.frame = self.bounds;
    [self layOutItemViews];
}

#else

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[CATransaction setDisableActions:YES];
    contentView.frame = self.bounds;
    [self layOutItemViews];
	[CATransaction setDisableActions:NO];
}

#endif

- (void)transformItemViews
{
	for (NSNumber *number in itemViews)
    {
        NSInteger index = [number integerValue];
		UIView *view = [itemViews objectForKey:number];
		[self transformItemView:view atIndex:index];
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        view.userInteractionEnabled = (!centerItemWhenSelected || index == self.currentItemIndex);
#endif
	}
}

- (void)layOutItemViews
{
	//bail out if not set up yet
	if (!dataSource || !contentView)
	{
		return;
	}
	
    //record current item width
    float prevItemWidth = itemWidth;
	
	//update wrap
	if ([delegate respondsToSelector:@selector(carouselShouldWrap:)])
    {
        shouldWrap = [delegate carouselShouldWrap:self];
    }
	else
	{
		switch (type)
		{
			case iCarouselTypeRotary:
			case iCarouselTypeInvertedRotary:
			case iCarouselTypeCylinder:
			case iCarouselTypeInvertedCylinder:
			{
				shouldWrap = YES;
				break;
			}
			default:
			{
				shouldWrap = NO;
				break;
			}
		}
	}
    
    //no placeholders on wrapped carousels
	numberOfPlaceholdersToShow = shouldWrap? 0: numberOfPlaceholders;
    
    //set item width
	if ([delegate respondsToSelector:@selector(carouselItemWidth:)])
    {
		itemWidth = [delegate carouselItemWidth:self];
	}
	else if (numberOfItems > 0)
	{
		if ([itemViews count] == 0)
		{
			[self loadViewAtIndex:0];
		}
		itemWidth = [[[itemViews allValues] lastObject] bounds].size.width;
	}
    
    //update scroll speed
    if ([delegate respondsToSelector:@selector(carouselScrollSpeed:)])
    {
        scrollSpeed = [delegate carouselScrollSpeed:self];
    }
    else
    {
        switch (type)
		{
            case iCarouselTypeCoverFlow:
			case iCarouselTypeCoverFlow2:
			{
				scrollSpeed = 4.0f;
				break;
			}
			default:
			{
				scrollSpeed = 1.0f;
				break;
			}
		}
    }
    
    //adjust scroll offset
	if (prevItemWidth)
	{
		scrollOffset = scrollOffset / prevItemWidth * itemWidth;
	}
	else
	{
		//prevent false index changed event
		previousItemIndex = self.currentItemIndex;
	}
    
    //update views
    [self didScroll];
}


#pragma mark -
#pragma mark View loading

- (UIView *)loadViewAtIndex:(NSInteger)index
{
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    [UIView setAnimationsEnabled:NO];
#endif
    UIView *view = nil;
    if (index < 0)
    {
        view = [dataSource carousel:self placeholderViewAtIndex:(int)ceilf((float)numberOfPlaceholdersToShow/2.0f) + index];
    }
    else if (index >= numberOfItems)
    {
        view = [dataSource carousel:self placeholderViewAtIndex:numberOfPlaceholdersToShow/2.0f + index - numberOfItems];
    }
    else
    {
        view = [dataSource carousel:self viewForItemAtIndex:index];
    }
    if (view == nil)
    {
        view = [[[UIView alloc] init] autorelease];
    }
    [self setView:view forIndex:index];
    [contentView addSubview:[self containView:view]];
    [self transformItemView:view atIndex:index];
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    [UIView setAnimationsEnabled:YES];
#endif
    return view;
}

- (void)loadUnloadViews
{
    //calculate visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:numberOfVisibleItems];
    NSInteger min = -(int)ceilf((float)numberOfPlaceholdersToShow/2.0f);
    NSInteger max = numberOfItems - 1 + numberOfPlaceholdersToShow/2;
    NSInteger count = MIN(numberOfVisibleItems, numberOfItems + numberOfPlaceholdersToShow);
    NSInteger offset = self.currentItemIndex - numberOfVisibleItems/2;
    offset = MAX(min, MIN(max - count + 1, offset));
    for (NSInteger i = 0; i < count; i++)
    {
        [visibleIndices addObject:[NSNumber numberWithInteger:i + offset]];
    }
    
    //remove offscreen views
    for (NSNumber *number in [itemViews allKeys])
    {
        if (![visibleIndices containsObject:number])
        {
            UIView *view = [itemViews objectForKey:number];
            [view.superview removeFromSuperview];
            [(NSMutableDictionary *)itemViews removeObjectForKey:number];
        }
    }
    
    //add onscreen views
    for (NSNumber *number in visibleIndices)
    {
        UIView *view = [itemViews objectForKey:number];
        if (view == nil)
        {
            [self loadViewAtIndex:[number integerValue]];
        }
    }
}

- (void)reloadData
{
	//bail out if not set up yet
	if (!dataSource || !contentView)
	{
		return;
	}

	//remove old views
    for (UIView *view in self.visibleViews)
    {
		[view.superview removeFromSuperview];
	}
	self.itemViews = [NSMutableDictionary dictionary];
   
    //get number of items and placeholders
    numberOfItems = [dataSource numberOfItemsInCarousel:self];
    if ([dataSource respondsToSelector:@selector(numberOfPlaceholdersInCarousel:)])
    {
        numberOfPlaceholders = [dataSource numberOfPlaceholdersInCarousel:self];
    }
	
    //layout views
    [CATransaction setDisableActions:YES];
    decelerating = NO;
    scrolling = NO;
    dragging = NO;
    [self layOutItemViews];
	[self performSelector:@selector(depthSortViews) withObject:nil afterDelay:0.0f];
    [CATransaction setDisableActions:NO];
}


#pragma mark -
#pragma mark Scrolling

- (NSInteger)clampedIndex:(NSInteger)index
{
    if (shouldWrap)
    {
        if (numberOfItems == 0)
        {
            return 0;
        }
        return index - floorf((float)index / (float)numberOfItems) * numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (float)clampedOffset:(float)offset
{
    if (shouldWrap)
    {
        if (numberOfItems == 0)
        {
            return 0;
        }
		float contentWidth = numberOfItems * itemWidth;
		return offset - floorf(offset / contentWidth) * contentWidth;
    }
    else
    {
        return fminf(fmaxf(0.0f, offset), numberOfItems * itemWidth - itemWidth);
    }
}

- (NSInteger)currentItemIndex
{	
    return itemWidth? [self clampedIndex:roundf(scrollOffset / itemWidth)]: 0;
}

- (NSInteger)minScrollDistanceFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	NSInteger directDistance = toIndex - fromIndex;
    if (shouldWrap)
    {
        NSInteger wrappedDistance = MIN(toIndex, fromIndex) + numberOfItems - MAX(toIndex, fromIndex);
        if (fromIndex < toIndex)
        {
            wrappedDistance = -wrappedDistance;
        }
        return (ABS(directDistance) <= ABS(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (float)minScrollDistanceFromOffset:(float)fromOffset toOffset:(float)toOffset
{
	float directDistance = toOffset - fromOffset;
    if (shouldWrap)
    {
        float wrappedDistance = fminf(toOffset, fromOffset) + numberOfItems*itemWidth - fmaxf(toOffset, fromOffset);
        if (fromOffset < toOffset)
        {
            wrappedDistance = -wrappedDistance;
        }
        return (fabsf(directDistance) <= fabsf(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration
{
	if (duration > 0)
    {
        scrolling = YES;
        startTime = CACurrentMediaTime();
        startOffset = scrollOffset;
		scrollDuration = duration;
		previousItemIndex = roundf(scrollOffset/itemWidth);
        if (itemCount > 0)
        {
            endOffset = (floorf(startOffset / itemWidth) + itemCount) * itemWidth;
        }
        else if (itemCount < 0)
        {
            endOffset = (ceilf(startOffset / itemWidth) + itemCount) * itemWidth;
        }
        else
        {
            endOffset = (roundf(startOffset / itemWidth) + itemCount) * itemWidth;
        }
		if (!shouldWrap)
		{
			endOffset = [self clampedOffset:endOffset];
		}
		if ([delegate respondsToSelector:@selector(carouselWillBeginScrollingAnimation:)])
		{
			[delegate carouselWillBeginScrollingAnimation:self];
		}
        [self startAnimation];
    }
    else
    {
        [CATransaction setDisableActions:YES];
        scrollOffset = itemWidth * [self clampedIndex:previousItemIndex + itemCount];
        [self didScroll];
        [self depthSortViews];
        [CATransaction setDisableActions:NO];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration
{
	[self scrollByNumberOfItems:[self minScrollDistanceFromIndex:roundf(scrollOffset/itemWidth) toIndex:index] duration:duration];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated
{	
	[self scrollToItemAtIndex:index duration:animated? SCROLL_DURATION: 0];
}

- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = [self clampedIndex:index];
    UIView *itemView = [self viewAtIndex:index];
    
    if (animated)
    {
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1f];
        [UIView setAnimationDelegate:itemView.superview];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        itemView.superview.layer.opacity = 0.0f;
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:INSERT_DURATION];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(depthSortViews)];
        [self removeViewAtIndex:index];
        numberOfItems --;
        scrollOffset = itemWidth * self.currentItemIndex;
        [self didScroll];
        [UIView commitAnimations];
        
#else
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.1f];
        [CATransaction setCompletionBlock:^{
            [itemView.superview removeFromSuperview]; 
        }];
        itemView.superview.layer.opacity = 0.0f;
        [CATransaction commit];
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:INSERT_DURATION];
        [CATransaction setCompletionBlock:^{
            [self depthSortViews]; 
        }];
        [self removeViewAtIndex:index];
        numberOfItems --;
        scrollOffset = itemWidth * self.currentItemIndex;
        [self didScroll];
        [CATransaction commit];
        
#endif
        
    }
    else
    {
        [CATransaction setDisableActions:YES];
        [itemView.superview removeFromSuperview];
        [self removeViewAtIndex:index];
        numberOfItems --;
        scrollOffset = itemWidth * self.currentItemIndex;
        [self didScroll];
        [self depthSortViews];
        [CATransaction setDisableActions:NO];
    }
}

- (void)fadeInItemView:(UIView *)itemView
{
    
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.1f];
    itemView.superview.layer.opacity = 1.0f;
    [UIView commitAnimations];
    
#else
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.1f];
    itemView.superview.layer.opacity = 1.0f;
    [CATransaction commit];
    
#endif
    
}

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = [self clampedIndex:index];
    numberOfItems ++;
    
    [self insertView:nil atIndex:index];
    UIView *itemView = [self loadViewAtIndex:index];
    itemView.superview.layer.opacity = 0.0f;
    
    if (animated)
    {
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:INSERT_DURATION];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(loadUnloadViews)];
        [self transformItemViews];
        [UIView commitAnimations];
        
#else
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:INSERT_DURATION];
        [CATransaction setCompletionBlock:^{
            [self loadUnloadViews]; 
        }];
        [self transformItemViews];
        [CATransaction commit];
        
#endif
        
        [self performSelector:@selector(fadeInItemView:) withObject:itemView afterDelay:INSERT_DURATION - 0.1f];
    }
    else
    {
        [CATransaction setDisableActions:YES];
        [self transformItemViews]; 
        [CATransaction setDisableActions:NO];
        itemView.superview.layer.opacity = 1.0f; 
    }
}

#pragma mark -
#pragma mark Animation

- (void)startAnimation
{
    if (!timer)
    {
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        
        timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
        [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
#else
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
                                                      target:self
                                                    selector:@selector(step)
                                                    userInfo:nil
                                                     repeats:YES];
#endif
        
    }
}

- (void)stopAnimation
{
    [timer invalidate];
    timer = nil;
}

- (float)decelerationDistance
{
    float acceleration = -startVelocity * DECELERATION_MULTIPLIER * (1.0f - decelerationRate);
    return -powf(startVelocity, 2.0f) / (2.0f * acceleration);
}

- (BOOL)shouldDecelerate
{
    return (fabsf(startVelocity) > itemWidth * SCROLL_SPEED_THRESHOLD) &&
		(fabsf([self decelerationDistance]) > itemWidth * DECELERATE_THRESHOLD);
}

- (BOOL)shouldScroll
{
    return (fabsf(startVelocity) > itemWidth * SCROLL_SPEED_THRESHOLD) &&
        (fabsf(scrollOffset/itemWidth - self.currentItemIndex) > SCROLL_DISTANCE_THRESHOLD);
}

- (void)startDecelerating
{
    float distance = [self decelerationDistance];
    startOffset = scrollOffset;
    endOffset = startOffset + distance;
    if (stopAtItemBoundary)
    {
        if (distance > 0.0f)
        {
            endOffset = ceilf(endOffset / itemWidth) * itemWidth;
        }
        else
        {
            endOffset = floorf(endOffset / itemWidth) * itemWidth;
        }
    }
    if (!shouldWrap)
    {
        if (bounces)
        {
            endOffset = fmaxf(itemWidth * -bounceDistance,
                fminf((numberOfItems - 1.0f + bounceDistance) * itemWidth, endOffset));
        }
        else
        {
            endOffset = [self clampedOffset:endOffset];
        }
    }
    distance = endOffset - startOffset;
    
    startTime = CACurrentMediaTime();
    scrollDuration = fabsf(distance) / fabsf(0.5f * startVelocity);   
    
    if (distance != 0.0f)
    {
        decelerating = YES;
        [self startAnimation];
    }
}

- (float)easeInOut:(float)time
{
    return (time < 0.5f)? 0.5f * powf(time * 2.0f, 3.0f): 0.5f * powf(time * 2.0f - 2.0f, 3.0f) + 1.0f;
}

- (void)step
{
    [CATransaction setDisableActions:YES];
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if (toggle != 0.0f)
    {
        float toggleDuration = SCROLL_DURATION * fminf(1.0f, fmaxf(0.0f, itemWidth / fabsf(startVelocity)));
        NSTimeInterval time = fminf(1.0f, (currentTime - toggleTime) / toggleDuration);
        float delta = [self easeInOut:time];
        toggle = (toggle < 0.0f)? (delta - 1.0f): (1.0f - delta);
        [self didScroll];
    }
    
    if (scrolling)
    {
        NSTimeInterval time = fminf(1.0f, (currentTime - startTime) / scrollDuration);
        float delta = [self easeInOut:time];
        scrollOffset = startOffset + (endOffset - startOffset) * delta;
		[self didScroll];
        if (time == 1.0f)
        {
            scrolling = NO;
            [self depthSortViews];
			if ([delegate respondsToSelector:@selector(carouselDidEndScrollingAnimation:)])
			{
				[delegate carouselDidEndScrollingAnimation:self];
			}
        }
    }
    else if (decelerating)
    {
        float time = fminf(scrollDuration, currentTime - startTime);
        float acceleration = -startVelocity/scrollDuration;
        float distance = startVelocity * time + 0.5f * acceleration * powf(time, 2.0f);
        scrollOffset = startOffset + distance;
        
		[self didScroll];
        if (time == (float)scrollDuration)
        {
            decelerating = NO;
			if ([delegate respondsToSelector:@selector(carouselDidEndDecelerating:)])
			{
				[delegate carouselDidEndDecelerating:self];
			}
            if (scrollToItemBoundary || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f)
            {
                [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
            }
        }
    }
    else if (toggle == 0.0f)
    {
        [self stopAnimation];
    }
    
    [CATransaction setDisableActions:NO];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void)didMoveToSuperview
#else
- (void)viewDidMoveToSuperview
#endif
{
    if (self.superview)
	{
		[self reloadData];
        [self startAnimation];
	}
	else
	{
        [self stopAnimation];
	}
}

- (void)didScroll
{	
    if (shouldWrap || !bounces)
    {
        scrollOffset = [self clampedOffset:scrollOffset];
    }
	else
	{
		float min = -bounceDistance * itemWidth;
		float max = ((float)numberOfItems - 1.0f + bounceDistance) * itemWidth;
		if (scrollOffset < min)
		{
			scrollOffset = min;
			startVelocity = 0.0f;
		}
		else if (scrollOffset > max)
		{
			scrollOffset = max;
			startVelocity = 0.0f;
		}
	}
    
    //check if index has changed
    NSInteger currentIndex = roundf(scrollOffset/itemWidth);
    NSInteger difference = [self minScrollDistanceFromIndex:previousItemIndex toIndex:currentIndex];
    if (difference)
    {
        toggleTime = CACurrentMediaTime();
        toggle = fmaxf(-1.0f, fminf(1.0f, -(float)difference));
        [self startAnimation];
    }
    
    [self loadUnloadViews];    
    [self transformItemViews];
    
    if ([delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
    
    //notify delegate of change index
    if ([self clampedIndex:previousItemIndex] != self.currentItemIndex &&
        [delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
    {
        [delegate carouselCurrentItemIndexUpdated:self];
    }
    
    //update previous index
    previousItemIndex = currentIndex;
}


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED


#pragma mark -
#pragma mark Gestures and taps

- (NSInteger)viewOrSuperviewIndex:(UIView *)view
{
    if (view == nil)
    {
        return NSNotFound;
    }
    NSInteger index = [self indexOfView:view];
    if (index == NSNotFound)
    {
        return [self viewOrSuperviewIndex:view.superview];
    }
    return index;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index != NSNotFound)
        {
			if ([delegate respondsToSelector:@selector(carousel:shouldSelectItemAtIndex:)])
			{
				if (![delegate carousel:self shouldSelectItemAtIndex:index])
				{
					return NO;
				}
			}
            if (!centerItemWhenSelected || index == self.currentItemIndex)
            {
                if ([touch.view isKindOfClass:[UIControl class]])
                {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture
{
	if ([gesture isKindOfClass:[UIPanGestureRecognizer class]])
	{
		//ignore vertical swipes
		UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
		CGPoint translation = [panGesture translationInView:self];
		return fabsf(translation.x) >= fabsf(translation.y);
	}
	return YES;
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    NSInteger index = [self indexOfView:[tapGesture.view.subviews objectAtIndex:0]];
    if (centerItemWhenSelected && index != self.currentItemIndex)
    {
        [self scrollToItemAtIndex:index animated:YES];
    }
    if ([delegate respondsToSelector:@selector(carousel:didSelectItemAtIndex:)])
    {
        [delegate carousel:self didSelectItemAtIndex:index];
    }
}

- (void)didPan:(UIPanGestureRecognizer *)panGesture
{
    if (scrollEnabled)
    {
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
            {
				dragging = YES;
                scrolling = NO;
                decelerating = NO;
                previousTranslation = [panGesture translationInView:self].x;
				if ([delegate respondsToSelector:@selector(carouselWillBeginDragging:)])
				{
					[delegate carouselWillBeginDragging:self];
				}
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            {
				dragging = NO;
                if ([self shouldDecelerate])
                {
                    [self startDecelerating];
                }
				if ([delegate respondsToSelector:@selector(carouselDidEndDragging:willDecelerate:)])
				{
					[delegate carouselDidEndDragging:self willDecelerate:decelerating];
				}
				if (!decelerating && (scrollToItemBoundary || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f))
				{
                    if ([self shouldScroll])
                    {
                        NSInteger direction = (int)(startVelocity / fabsf(startVelocity));
                        [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
                    }
                    else
                    {
                        [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                    }
				}
				else if ([delegate respondsToSelector:@selector(carouselWillBeginDecelerating:)])
				{
					[delegate carouselWillBeginDecelerating:self];
				}
				break;
            }
            default:
            {
                float translation = [panGesture translationInView:self].x - previousTranslation;
				float factor = 1.0f;
				if (!shouldWrap && bounces)
				{
					factor = 1.0f - fminf(fabsf(scrollOffset - [self clampedOffset:scrollOffset]) / itemWidth, bounceDistance) / bounceDistance;
				}
				
                previousTranslation = [panGesture translationInView:self].x;
                startVelocity = -[panGesture velocityInView:self].x * factor;
                scrollOffset -= translation * factor * scrollSpeed;
                [self didScroll];
            }
        }
    }
}

#else


#pragma mark -
#pragma mark Mouse control

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (scrollEnabled)
    {
		if (!dragging)
		{
			dragging = YES;
			if ([delegate respondsToSelector:@selector(carouselWillBeginDragging:)])
			{
				[delegate carouselWillBeginDragging:self];
			}
		}
        scrolling = NO;
        decelerating = NO;
        
        float translation = [theEvent deltaX];
		float factor = 1.0f;
		if (!shouldWrap && bounces)
		{
			factor = 1.0f - fminf(fabsf(scrollOffset - [self clampedOffset:scrollOffset]) / itemWidth, bounceDistance) / bounceDistance;
		}
     
        NSTimeInterval thisTime = [theEvent timestamp];
        startVelocity = -(translation / (thisTime - startTime)) * factor;
        startTime = thisTime;
        
        scrollOffset -= translation * factor * scrollSpeed;
        [CATransaction setDisableActions:YES];
        [self didScroll];
        [CATransaction setDisableActions:NO];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (scrollEnabled)
    {
		dragging = NO;
		if ([self shouldDecelerate])
        {
            [self startDecelerating];
        }
		if ([delegate respondsToSelector:@selector(carouselDidEndDragging:willDecelerate:)])
		{
			[delegate carouselDidEndDragging:self willDecelerate:decelerating];
		}
		if (!decelerating)
		{
			if ([self shouldScroll])
            {
                NSInteger direction = (int)(startVelocity / fabsf(startVelocity));
                [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
            }
            else
            {
                [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
            }
		}
		else if ([delegate respondsToSelector:@selector(carouselWillBeginDecelerating:)])
		{
			[delegate carouselWillBeginDecelerating:self];
		}
	}
}


#pragma mark -
#pragma mark Scrollwheel control

- (void)scrollWheel:(NSEvent *)theEvent
{
    [self mouseDragged:theEvent];
	
	//the iCarousel deceleration system conflicts with the built-in momentum
	//scrolling for scrollwheel events. need to find a way to trigger the appropriate
	//events, and also detect when user has disabled momentum scrolling in system prefs
	dragging = NO;
	decelerating = NO;
	if ([delegate respondsToSelector:@selector(carouselDidEndDragging:willDecelerate:)])
	{
		[delegate carouselDidEndDragging:self willDecelerate:decelerating];
	}
	[self scrollToItemAtIndex:self.currentItemIndex animated:YES];
}


#pragma mark -
#pragma mark Keyboard control

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    if (scrollEnabled && [characters length])
    {
        switch ([characters characterAtIndex:0])
        {
            case NSLeftArrowFunctionKey:
            {
                [self scrollToItemAtIndex:self.currentItemIndex-1 animated:YES];
                break;
            }
            case NSRightArrowFunctionKey:
            {
                [self scrollToItemAtIndex:self.currentItemIndex+1 animated:YES];
                break;
            }
        }
    }
}

#endif


#pragma mark -
#pragma mark Memory management

- (void)dealloc
{	
    [self stopAnimation];
    [contentView release];
	[itemViews release];
	[super dealloc];
}

@end