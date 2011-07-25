//
//  iCarousel.m
//
//  Version 1.5.1
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


#define SCROLL_DURATION 0.4
#define INSERT_DURATION 0.4
#define BOUNCE_DISTANCE 1.0
#define DECELERATION_MULTIPLIER 30


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@interface iCarousel () <UIGestureRecognizerDelegate>
#else
@interface iCarousel ()
#endif

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSDictionary *itemViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
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

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

@synthesize centerItemWhenSelected;

#endif


#pragma mark -
#pragma mark Initialisation

- (void)setup
{
    perspective = -1.0/500.0;
    decelerationRate = 0.95;
    scrollEnabled = YES;
    bounces = YES;
    scrollOffset = 0;
    contentOffset = CGSizeZero;
	viewpointOffset = CGSizeZero;
    numberOfVisibleItems = 21;
	shouldWrap = NO;
    scrollSpeed = 1.0;
    toggle = 0.0;
    
	self.itemViews = [NSMutableDictionary dictionary];
    
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
}

- (id)initWithCoder:(NSCoder *)aDecoder
{	
	if ((self = [super initWithCoder:aDecoder]))
    {
		[self setup];
        [self reloadData];
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
		if (dataSource)
		{
			[self reloadData];
		}
    }
}

- (void)setDelegate:(id<iCarouselDelegate>)_delegate
{
    if (delegate != _delegate)
    {
        delegate = _delegate;
		if (delegate)
		{
			[self reloadData];
		}
    }
}

- (void)setType:(iCarouselType)_type
{
    if (type != _type)
    {
        type = _type;
        [self reloadData];
    }
}

- (void)setNumberOfVisibleItems:(NSInteger)_numberOfVisibleItems
{
    if (numberOfVisibleItems != _numberOfVisibleItems)
    {
        numberOfVisibleItems = _numberOfVisibleItems;
        [CATransaction setDisableActions:YES];
		[self layOutItemViews];
        [CATransaction setDisableActions:NO];
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
            return CATransform3DTranslate(transform, offset * itemWidth, 0, 0);
        }
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        {
			NSInteger count = numberOfItems + (shouldWrap? 0: numberOfPlaceholders);

            float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/count);
            float angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedRotary)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            return CATransform3DTranslate(transform, radius * sin(angle), 0, radius * cos(angle) - radius);
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
			NSInteger count = numberOfItems + (shouldWrap? 0: numberOfPlaceholders);
            
			float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/count);
            float angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedCylinder)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, 0, 0, -radius);
            transform = CATransform3DRotate(transform, angle, 0, 1, 0);
            return CATransform3DTranslate(transform, 0, 0, radius);
        }
        case iCarouselTypeCoverFlow:
        case iCarouselTypeCoverFlow2:
        {
            float tilt = 0.9;
            float spacing = 0.25; // should be ~ 1/scrollSpeed;
            float clampedOffset = fmax(-1.0, fmin(1.0, offset));
            
            if (type == iCarouselTypeCoverFlow2)
            {
                if (toggle >= 0)
                {
                    if (offset < -0.5)
                    {
                        clampedOffset = -1.0;
                    }
                    else if (offset < 0.5)
                    {
                        clampedOffset = -toggle;
                    }
                    else if (offset < 1.5)
                    {
                        clampedOffset = 1.0 - toggle;
                    }
                    else
                    {
                        clampedOffset = 1.0;
                    }
                }
                else
                {
                    if (offset > 0.5)
                    {
                        clampedOffset = 1.0;
                    }
                    else if (offset > -0.5)
                    {
                        clampedOffset = - toggle;
                    }
                    else if (offset > -1.5)
                    {
                        clampedOffset = - 1.0 - toggle;
                    }
                    else
                    {
                        clampedOffset = -1.0;
                    }
                }
            }
            
            float x = (clampedOffset * 0.5 * tilt + offset * spacing) * itemWidth;
            float z = fabs(clampedOffset) * -itemWidth * 0.5;
            transform = CATransform3DTranslate(transform, x, 0, z);
            return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0, 1, 0);
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
    if (difference == 0)
    {
        CATransform3D t3 = [carousel currentView].superview.layer.transform;
        float x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
        float x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
        float x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
        difference = fabs(x2 - x3) - fabs(x1 - x3);
    }
    return (difference < 0)? NSOrderedAscending: NSOrderedDescending;
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
    
	view.center = CGPointMake(view.bounds.size.width/2.0, view.bounds.size.height/2.0);
    view.superview.center = CGPointMake(self.bounds.size.width/2.0 + contentOffset.width,
										self.bounds.size.height/2.0 + contentOffset.height);
    
#else
    
	[view setFrameOrigin:NSMakePoint(0, 0)];
    [view.superview setFrameOrigin:NSMakePoint(self.bounds.size.width/2.0 + contentOffset.width,
											   self.bounds.size.height/2.0 + contentOffset.height)];
    view.superview.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
#endif

    //transform view
    CATransform3D transform = [self transformForItemView:view withOffset:[self offsetForIndex:index]];
    view.superview.layer.transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0);
    
	//hide containers for invisible views
    [view.superview setHidden:([view isHidden] || view.layer.opacity < 0.001)];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void)layoutSubviews
#else
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
#endif
{
    [CATransaction setDisableActions:YES];
    contentView.frame = self.bounds;
    [self layOutItemViews];
    [CATransaction setDisableActions:NO];
}

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
    //record current item width
    float prevItemWidth = itemWidth;
    
    //set scrollview size
	if ([delegate respondsToSelector:@selector(carouselItemWidth:)])
    {
		itemWidth = [delegate carouselItemWidth:self];
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
				scrollSpeed = 4.0;
				break;
			}
			default:
			{
				scrollSpeed = 1.0;
				break;
			}
		}
    }

    //adjust scroll offset
    scrollOffset = scrollOffset / prevItemWidth * itemWidth;
        
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
        view = [dataSource carousel:self placeholderViewAtIndex:(int)ceil((float)numberOfPlaceholders/2.0) + index];
    }
    else if (index >= numberOfItems)
    {
        view = [dataSource carousel:self placeholderViewAtIndex:numberOfPlaceholders/2 + index - numberOfItems];
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
    NSInteger min = -(int)ceil((float)numberOfPlaceholders/2);
    NSInteger max = numberOfItems - 1 + numberOfPlaceholders/2;
    NSInteger count = MIN(numberOfVisibleItems, numberOfItems + numberOfPlaceholders);
    NSInteger offset = self.currentItemIndex - ceil((float)numberOfVisibleItems/2);
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
    //record current index
    previousItemIndex = self.currentItemIndex;
    
	//remove old views
    for (UIView *view in self.visibleViews)
    {
		[view.superview removeFromSuperview];
	}
    
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
    
    //get number of items
    numberOfItems = [dataSource numberOfItemsInCarousel:self];
    numberOfPlaceholders = 0;
    if (!shouldWrap && [dataSource respondsToSelector:@selector(numberOfPlaceholdersInCarousel:)])
    {
        numberOfPlaceholders = [dataSource numberOfPlaceholdersInCarousel:self];
    }
	
	//load new views
	self.itemViews = [NSMutableDictionary dictionaryWithCapacity:numberOfVisibleItems];
	[self loadUnloadViews];
    
    //set item width (may be overidden by delegate)
    itemWidth = [([itemViews count]? [[self visibleViews] anyObject] : self) bounds].size.width;
	
    //layout views
    [CATransaction setDisableActions:YES];
    decelerating = NO;
    scrolling = NO;
    dragging = NO;
    previousItemIndex = [self clampedIndex:previousItemIndex];
	scrollOffset = previousItemIndex * itemWidth;
    [self layOutItemViews];
	[self performSelector:@selector(depthSortViews) withObject:nil afterDelay:0];
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
        return index - floor((float)index / (float)numberOfItems) * numberOfItems;
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
		return offset - floor(offset / contentWidth) * contentWidth;
    }
    else
    {
        return fmin(fmax(0.0, offset), numberOfItems * itemWidth - itemWidth);
    }
}

- (NSInteger)currentItemIndex
{	
    return [self clampedIndex:round(scrollOffset / itemWidth)];
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
        float wrappedDistance = fmin(toOffset, fromOffset) + numberOfItems*itemWidth - fmax(toOffset, fromOffset);
        if (fromOffset < toOffset)
        {
            wrappedDistance = -wrappedDistance;
        }
        return (fabs(directDistance) <= fabs(wrappedDistance))? directDistance: wrappedDistance;
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
		previousItemIndex = round(scrollOffset/itemWidth);
		endOffset = round(startOffset / itemWidth + itemCount) * itemWidth;
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
	[self scrollByNumberOfItems:[self minScrollDistanceFromIndex:round(scrollOffset/itemWidth) toIndex:index] duration:duration];
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
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:itemView.superview];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        itemView.superview.layer.opacity = 0.0;
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
        [CATransaction setAnimationDuration:0.1];
        [CATransaction setCompletionBlock:^{
            [itemView.superview removeFromSuperview]; 
        }];
        itemView.superview.layer.opacity = 0.0;
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
    [UIView setAnimationDuration:0.1];
    itemView.superview.layer.opacity = 1.0;
    [UIView commitAnimations];
    
#else
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.1];
    itemView.superview.layer.opacity = 1.0;
    [CATransaction commit];
    
#endif
    
}

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = [self clampedIndex:index];
    numberOfItems ++;

    [self insertView:nil atIndex:index];
    UIView *itemView = [self loadViewAtIndex:index];
    itemView.superview.layer.opacity = 0.0;
  
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
         
         [self performSelector:@selector(fadeInItemView:) withObject:itemView afterDelay:INSERT_DURATION - 0.1];
    }
    else
    {
        [CATransaction setDisableActions:YES];
        [self transformItemViews]; 
        [CATransaction setDisableActions:NO];
        itemView.superview.layer.opacity = 1.0; 
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
    
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
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
    float acceleration = -startVelocity * DECELERATION_MULTIPLIER * (1.0 - decelerationRate);
    return -powf(startVelocity, 2.0) / (2.0 * acceleration);
}

- (BOOL)shouldDecelerate
{
    return fabs([self decelerationDistance]) > itemWidth;
}

- (void)startDecelerating
{
    decelerating = YES;

    float distance = [self decelerationDistance];
    startOffset = scrollOffset;
    endOffset = roundf((startOffset + distance) / itemWidth) * itemWidth;
    if (!shouldWrap)
    {
        if (bounces)
        {
            endOffset = fmax(itemWidth * -BOUNCE_DISTANCE, fmin((numberOfItems - 1 + BOUNCE_DISTANCE) * itemWidth, endOffset));
        }
        else
        {
            endOffset = [self clampedOffset:endOffset];
        }
    }
    distance = endOffset - startOffset;
    
    startTime = CACurrentMediaTime();
    scrollDuration = fabs(distance) / fabs(0.5 * startVelocity);   
    
    [self startAnimation];
}

- (float)easeInOut:(float)time
{
    return (time < 0.5f)? 0.5f * pow(time * 2.0, 3.0): 0.5f * pow(time * 2.0 - 2.0, 3.0) + 1.0;
}

- (void)step
{
    [CATransaction setDisableActions:YES];
    NSTimeInterval currentTime = CACurrentMediaTime();

    if (toggle != 0.0)
    {
        NSTimeInterval time = fmin(1.0, (currentTime - toggleTime) / SCROLL_DURATION);
        float delta = [self easeInOut:time];
        toggle = (toggle < 0.0)? (delta - 1.0): (1.0 - delta);
        [self didScroll];
    }
    
    if (scrolling)
    {
        NSTimeInterval time = fmin(1.0, (currentTime - startTime) / scrollDuration);
        float delta = [self easeInOut:time];
        scrollOffset = startOffset + (endOffset - startOffset) * delta;
		[self didScroll];
        if (time == 1.0)
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
        float time = fmin(scrollDuration, currentTime - startTime);
        float acceleration = -startVelocity/scrollDuration;
        float distance = startVelocity * time + 0.5 * acceleration * powf(time, 2.0);
        scrollOffset = startOffset + distance;
        
		[self didScroll];
        if (time == (float)scrollDuration)
        {
            decelerating = NO;
			if ([delegate respondsToSelector:@selector(carouselDidEndDecelerating:)])
			{
				[delegate carouselDidEndDecelerating:self];
			}
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        }
    }
    else if (toggle == 0.0)
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
    
    //check if index has changed
    NSInteger currentIndex = round(scrollOffset/itemWidth);
    NSInteger difference = [self minScrollDistanceFromIndex:previousItemIndex toIndex:currentIndex];
    if (difference)
    {
        toggleTime = CACurrentMediaTime();
        toggle = fmax(-1.0, fmin(1.0, -(float)difference));
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
		return fabs(translation.x) >= fabs(translation.y);
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
				if (!decelerating)
				{
					[self scrollToItemAtIndex:self.currentItemIndex animated:YES];
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
                previousTranslation = [panGesture translationInView:self].x;
                NSInteger index = round(scrollOffset / itemWidth);
				float factor = (shouldWrap || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
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
        NSInteger index = round(scrollOffset / itemWidth);
        float factor = (shouldWrap || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
        
        NSTimeInterval thisTime = [theEvent timestamp];
        startVelocity = -(translation / (thisTime - startTime)) * factor;
        startTime = thisTime;
        
        [CATransaction setDisableActions:YES];
        scrollOffset -= translation * factor * scrollSpeed;
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
			[self scrollToItemAtIndex:self.currentItemIndex animated:YES];
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