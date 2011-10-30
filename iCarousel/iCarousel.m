//
//  iCarousel.m
//
//  Version 1.5.8
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//
//  Get the latest version of iCarousel from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#icarousel
//  https://github.com/nicklockwood/icarousel
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


#define MIN_TOGGLE_DURATION 0.2f
#define MAX_TOGGLE_DURATION 0.4f
#define SCROLL_DURATION 0.4f
#define INSERT_DURATION 0.4f
#define DECELERATE_THRESHOLD 0.1f
#define SCROLL_SPEED_THRESHOLD 2.0f
#define SCROLL_DISTANCE_THRESHOLD 0.1f
#define DECELERATION_MULTIPLIER 30.0f


@interface iCarousel ()

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSDictionary *itemViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) NSInteger numberOfPlaceholdersToShow;
@property (nonatomic, assign) NSInteger numberOfVisibleItems;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat scrollOffset;
@property (nonatomic, assign) CGFloat offsetMultiplier;
@property (nonatomic, assign) CGFloat startOffset;
@property (nonatomic, assign) CGFloat endOffset;
@property (nonatomic, assign) NSTimeInterval scrollDuration;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) CGFloat startVelocity;
@property (nonatomic, assign) id timer;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) CGFloat previousTranslation;
@property (nonatomic, assign) BOOL shouldWrap;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) BOOL didDrag;
@property (nonatomic, assign) NSTimeInterval toggleTime;

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self);

- (void)didMoveToSuperview;
- (void)layOutItemViews;
- (UIView *)loadViewAtIndex:(NSInteger)index;
- (NSInteger)clampedIndex:(NSInteger)index;
- (CGFloat)clampedOffset:(CGFloat)offset;
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
@synthesize offsetMultiplier;
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
@synthesize didDrag;
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

- (void)setUp
{
    perspective = -1.0f/500.0f;
    decelerationRate = 0.95f;
    scrollEnabled = YES;
    bounces = YES;
    scrollOffset = 0.0f;
    offsetMultiplier = 1.0f;
    contentOffset = CGSizeZero;
	viewpointOffset = CGSizeZero;
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
	panGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
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
		[self setUp];
        [self didMoveToSuperview]; 
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]))
    {
		[self setUp];
	}
	return self;
}

- (void)dealloc
{	
    [self stopAnimation];
    [contentView release];
	[itemViews release];
	[super dealloc];
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
        if (delegate && dataSource)
        {
            [self layOutItemViews];
        }
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

- (void)setContentOffset:(CGSize)_contentOffset
{
    if (!CGSizeEqualToSize(contentOffset, _contentOffset))
    {
        contentOffset = _contentOffset;
        [self layOutItemViews];
    }
}

- (void)setViewpointOffset:(CGSize)_viewpointOffset
{
    if (!CGSizeEqualToSize(viewpointOffset, _viewpointOffset))
    {
        viewpointOffset = _viewpointOffset;
        [self layOutItemViews];
    }
}


#pragma mark -
#pragma mark View management

- (NSArray *)indexesForVisibleItems
{
    return [[itemViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSSet *)visibleViews
{
    return [NSSet setWithArray:[itemViews allValues]];
}

- (NSArray *)visibleItemViews
{
    NSArray *indexes = [self indexesForVisibleItems];
    return [itemViews objectsForKeys:indexes notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSInteger)index
{
    return [itemViews objectForKey:[NSNumber numberWithInteger:index]];
}

- (UIView *)currentItemView
{
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSInteger)indexOfItemView:(UIView *)view
{
    NSInteger index = [[itemViews allValues] indexOfObject:view];
    if (index != NSNotFound)
    {
        return [[[itemViews allKeys] objectAtIndex:index] integerValue];
    }
    return NSNotFound;
}

- (void)setItemView:(UIView *)view forIndex:(NSInteger)index
{
    [(NSMutableDictionary *)itemViews setObject:view forKey:[NSNumber numberWithInteger:index]];
}

- (void)removeViewAtIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[itemViews count] - 1];
    for (NSNumber *number in [self indexesForVisibleItems])
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
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[itemViews count] + 1];
    for (NSNumber *number in [self indexesForVisibleItems])
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
        [self setItemView:view forIndex:index];
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

- (CATransform3D)transformForItemView:(UIView *)view withOffset:(CGFloat)offset
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
			NSInteger count = MIN(numberOfVisibleItems, numberOfItems + (shouldWrap? 0: numberOfPlaceholdersToShow));
            
            CGFloat arc = M_PI * 2.0f;
            CGFloat radius = itemWidth / 2.0f / tanf(arc/2.0f/count);
            CGFloat angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedRotary)
            {
                radius = -radius;
                angle = -angle;
            }
            
            return CATransform3DTranslate(transform, radius * sin(angle), 0.0f, radius * cos(angle) - radius);
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
			NSInteger count = MIN(numberOfVisibleItems, numberOfItems + (shouldWrap? 0: numberOfPlaceholdersToShow));
            
			CGFloat arc = M_PI * 2.0f;
            CGFloat radius = itemWidth / 2.0f / tanf(arc/2.0f/count);
            CGFloat angle = offset / count * arc;
            
            if (type == iCarouselTypeInvertedCylinder)
            {
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
            CGFloat tilt = 0.9f;
            CGFloat spacing = 0.25f; // should be ~ 1/scrollSpeed;
            CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
            
            if (type == iCarouselTypeCoverFlow2)
            {
                if (toggle >= 0.0f)
                {
                    if (offset <= -0.5f)
                    {
                        clampedOffset = -1.0f;
                    }
                    else if (offset <= 0.5f)
                    {
                        clampedOffset = -toggle;
                    }
                    else if (offset <= 1.5f)
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
            
            CGFloat x = (clampedOffset * 0.5f * tilt + offset * spacing) * itemWidth;
            CGFloat z = fabsf(clampedOffset) * -itemWidth * 0.5f;
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

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self)
{
	CATransform3D t1 = view1.superview.layer.transform;
	CATransform3D t2 = view2.superview.layer.transform;
    CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    CGFloat difference = z1 - z2;
    if (difference == 0.0f)
    {
        CATransform3D t3 = [self currentItemView].superview.layer.transform;
        CGFloat x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
        CGFloat x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
        CGFloat x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
        difference = fabsf(x2 - x3) - fabsf(x1 - x3);
    }
    return (difference < 0.0f)? NSOrderedAscending: NSOrderedDescending;
}

- (void)depthSortViews
{
    for (UIView *view in [[itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:self])
    {
        [contentView addSubview:view.superview];
    }
}

#else

- (void)depthSortViews
{
    //does nothing on Mac OS
}

#endif

- (CGFloat)offsetForIndex:(NSInteger)index
{
    //calculate relative position
    CGFloat itemOffset = scrollOffset / itemWidth;
    CGFloat offset = index - itemOffset;
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
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
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
    CGFloat offset = [self offsetForIndex:index];
    CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
    if (decelerating || (scrolling && !didDrag) || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f)
    {
        if (offset > 0)
        {
            toggle = (offset <= 0.5f)? -clampedOffset: (1.0f - clampedOffset);
        }
        else
        {
            toggle = (offset > -0.5f)? -clampedOffset: (- 1.0f - clampedOffset);
        }
    }
    
    //transform view
    CATransform3D transform = [self transformForItemView:view withOffset:offset];
    view.superview.layer.transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0.0f);
    
	//hide containers for invisible views
    [view.superview setHidden:([view isHidden] || view.layer.opacity < 0.001f)];
}

//for iOS
- (void)layoutSubviews
{
    contentView.frame = self.bounds;
    [self layOutItemViews];
}

//for Mac OS
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[CATransaction setDisableActions:YES];
    [self layoutSubviews];
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

- (void)updateItemWidth
{
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
		itemWidth = [[[itemViews allValues] lastObject] frame].size.width;
	}
    else if (numberOfPlaceholders > 0)
    {
        if ([itemViews count] == 0)
        {
            [self loadViewAtIndex:-1];
        }
        itemWidth = [[[itemViews allValues] lastObject] frame].size.width;
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
    CGFloat prevItemWidth = itemWidth;
	
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
	[self updateItemWidth];
    
    //update offset multiplier
    if ([delegate respondsToSelector:@selector(carouselOffsetMultiplier:)])
    {
        offsetMultiplier = [delegate carouselOffsetMultiplier:self];
    }
    else
    {
        switch (type)
		{
            case iCarouselTypeCoverFlow:
			case iCarouselTypeCoverFlow2:
			{
				offsetMultiplier = 2.0f;
				break;
			}
			default:
			{
				offsetMultiplier = 1.0f;
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
    
    //align
    if (!scrolling && !decelerating)
    {
        if (scrollToItemBoundary)
        {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        }
        else
        {
            scrollOffset = [self clampedOffset:scrollOffset];
        }
    }
    
    //update views
    [self didScroll];
}


#pragma mark -
#pragma mark View loading

- (UIView *)loadViewAtIndex:(NSInteger)index withContainerView:(UIView *)containerView
{
    [CATransaction setDisableActions:YES];
    
    UIView *view = nil;
    if (index < 0)
    {
        view = [dataSource carousel:self placeholderViewAtIndex:(int)ceilf((CGFloat)numberOfPlaceholdersToShow/2.0f) + index];
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
    [self setItemView:view forIndex:index];
    if (containerView)
    {
        [[containerView.subviews lastObject] removeFromSuperview];
        containerView.frame = view.frame;
        [containerView addSubview:view];
    }
    else
    {
        [contentView addSubview:[self containView:view]];
    }
    [self transformItemView:view atIndex:index];
    
    [CATransaction setDisableActions:NO];
    
    return view;
}

- (UIView *)loadViewAtIndex:(NSInteger)index
{
    return [self loadViewAtIndex:index withContainerView:nil];
}

- (void)loadUnloadViews
{
    //calculate visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:numberOfVisibleItems];
    NSInteger min = -(int)ceilf((CGFloat)numberOfPlaceholdersToShow/2.0f);
    NSInteger max = numberOfItems - 1 + numberOfPlaceholdersToShow/2;
    NSInteger count = MIN(numberOfVisibleItems, numberOfItems + numberOfPlaceholdersToShow);
    NSInteger offset = self.currentItemIndex - numberOfVisibleItems/2;
    if (!shouldWrap)
    {
        offset = MAX(min, MIN(max - count + 1, offset));
    }
    for (NSInteger i = 0; i < count; i++)
    {
        NSInteger index = i + offset;
        if (shouldWrap)
        {
            index = [self clampedIndex:index];
        }
        [visibleIndices addObject:[NSNumber numberWithInteger:index]];
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
    for (UIView *view in self.visibleItemViews)
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
    
    //get number of visible items
    numberOfVisibleItems = numberOfItems + numberOfPlaceholders;
    if ([dataSource respondsToSelector:@selector(numberOfVisibleItemsInCarousel:)])
    {
        numberOfVisibleItems = [dataSource numberOfVisibleItemsInCarousel:self];
    }
    
    //layout views
    [CATransaction setDisableActions:YES];
    [self layOutItemViews];
	[self performSelector:@selector(depthSortViews) withObject:nil afterDelay:0.0f];
    [CATransaction setDisableActions:NO];
    
    if (numberOfItems > 0 && scrollOffset < 0.0f)
    {
        [self scrollToItemAtIndex:0 animated:(numberOfPlaceholders > 0)];
    }
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
        return index - floorf((CGFloat)index / (CGFloat)numberOfItems) * numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (CGFloat)clampedOffset:(CGFloat)offset
{
    if (shouldWrap)
    {
        if (numberOfItems == 0)
        {
            return 0;
        }
		CGFloat contentWidth = numberOfItems * itemWidth;
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

- (CGFloat)minScrollDistanceFromOffset:(CGFloat)fromOffset toOffset:(CGFloat)toOffset
{
	CGFloat directDistance = toOffset - fromOffset;
    if (shouldWrap)
    {
        CGFloat wrappedDistance = fminf(toOffset, fromOffset) + numberOfItems*itemWidth - fmaxf(toOffset, fromOffset);
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
            endOffset = roundf(startOffset / itemWidth) * itemWidth;
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
    UIView *itemView = [self itemViewAtIndex:index];
    
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
        if (![dataSource respondsToSelector:@selector(numberOfVisibleItemsInCarousel:)])
        {
            numberOfVisibleItems --;
        }
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
    numberOfItems ++;
    if (![dataSource respondsToSelector:@selector(numberOfVisibleItemsInCarousel:)])
    {
        numberOfVisibleItems ++;
    }
    
    index = [self clampedIndex:index];
    [self insertView:nil atIndex:index];
    UIView *itemView = [self loadViewAtIndex:index];
    itemView.superview.layer.opacity = 0.0f;
    
    if (itemWidth == 0)
    {
        [self updateItemWidth];
    }
    
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
    
    if (scrollOffset < 0.0f)
    {
        [self scrollToItemAtIndex:0 animated:(animated && numberOfPlaceholders)];
    }
}

- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    //get container view
    UIView *containerView = [[self itemViewAtIndex:index] superview];
    
    if (animated)
    {
        //fade transition
        CATransition *transition = [CATransition animation];
        transition.duration = INSERT_DURATION;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [containerView.superview.layer addAnimation:transition forKey:nil];
    }
    
    //reload view
    [self loadViewAtIndex:index withContainerView:containerView];
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
        
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
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

- (CGFloat)decelerationDistance
{
    CGFloat acceleration = -startVelocity * DECELERATION_MULTIPLIER * (1.0f - decelerationRate);
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
    CGFloat distance = [self decelerationDistance];
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

- (CGFloat)easeInOut:(CGFloat)time
{
    return (time < 0.5f)? 0.5f * powf(time * 2.0f, 3.0f): 0.5f * powf(time * 2.0f - 2.0f, 3.0f) + 1.0f;
}

- (void)step
{
    [CATransaction setDisableActions:YES];
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if (toggle != 0.0f)
    {
        CGFloat toggleDuration = fminf(1.0f, fmaxf(0.0f, itemWidth / fabsf(startVelocity)));
        toggleDuration = MIN_TOGGLE_DURATION + (MAX_TOGGLE_DURATION - MIN_TOGGLE_DURATION) * toggleDuration;
        NSTimeInterval time = fminf(1.0f, (currentTime - toggleTime) / toggleDuration);
        CGFloat delta = [self easeInOut:time];
        toggle = (toggle < 0.0f)? (delta - 1.0f): (1.0f - delta);
        [self didScroll];
    }
    
    if (scrolling)
    {
        NSTimeInterval time = fminf(1.0f, (currentTime - startTime) / scrollDuration);
        CGFloat delta = [self easeInOut:time];
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
        CGFloat time = fminf(scrollDuration, currentTime - startTime);
        CGFloat acceleration = -startVelocity/scrollDuration;
        CGFloat distance = startVelocity * time + 0.5f * acceleration * powf(time, 2.0f);
        scrollOffset = startOffset + distance;
        
		[self didScroll];
        if (time == (CGFloat)scrollDuration)
        {
            decelerating = NO;
			if ([delegate respondsToSelector:@selector(carouselDidEndDecelerating:)])
			{
				[delegate carouselDidEndDecelerating:self];
			}
            if (scrollToItemBoundary || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f)
            {
                if (fabsf(scrollOffset/itemWidth - self.currentItemIndex) < 0.01f)
                {
                    //call scroll to trigger events for legacy support reasons
                    //even though technically we don't need to scroll at all
                    [self scrollToItemAtIndex:self.currentItemIndex duration:0.01f];
                }
                else
                {
                    [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                }
            }
            else
            {
                CGFloat difference = (CGFloat)self.currentItemIndex - scrollOffset/itemWidth;
                if (difference > 0.5)
                {
                    difference = difference - 1.0f;
                }
                else if (difference < -0.5)
                {
                    difference = 1.0 + difference;
                }
                toggleTime = currentTime - MAX_TOGGLE_DURATION * fabsf(difference);
                toggle = fmaxf(-1.0f, fminf(1.0f, -difference));
            }
        }
    }
    else if (toggle == 0.0f)
    {
        [self stopAnimation];
    }
    
    [CATransaction setDisableActions:NO];
}

//for iOS
- (void)didMoveToSuperview
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

//for Mac OS
- (void)viewDidMoveToSuperview
{
    [self didMoveToSuperview];
}

- (void)didScroll
{	
    if (shouldWrap || !bounces)
    {
        scrollOffset = [self clampedOffset:scrollOffset];
    }
	else
	{
		CGFloat min = -bounceDistance * itemWidth;
		CGFloat max = (fmaxf(numberOfItems - 1, 0.0f) + bounceDistance) * itemWidth;
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
        toggle = fmaxf(-1.0f, fminf(1.0f, -(CGFloat)difference));
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
    if (view == nil || view == contentView)
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

- (BOOL)viewOrSuperview:(UIView *)view isKindOfClass:(Class)class
{
    if (view == nil || view == contentView)
    {
        return NO;
    }
    else if ([view isKindOfClass:class])
    {
        return YES;
    }
    return [self viewOrSuperview:view.superview isKindOfClass:class];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index == NSNotFound && centerItemWhenSelected)
        {
            //view is a container view
            index = [self viewOrSuperviewIndex:[touch.view.subviews lastObject]];
        }
        if (index != NSNotFound)
        {
			if ([delegate respondsToSelector:@selector(carousel:shouldSelectItemAtIndex:)])
			{
				if (![delegate carousel:self shouldSelectItemAtIndex:index])
				{
					return NO;
				}
			}
            if ([self viewOrSuperview:touch.view isKindOfClass:[UIControl class]] ||
                [self viewOrSuperview:touch.view isKindOfClass:[UITableViewCell class]])
            {
                return NO;
            }
        }
    }
    else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]])
    {
        if ([self viewOrSuperview:touch.view isKindOfClass:[UISlider class]] ||
            [self viewOrSuperview:touch.view isKindOfClass:[UISwitch class]])
        {
            return NO;
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
    NSInteger index = [self indexOfView:[tapGesture.view.subviews lastObject]];
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
                didDrag = YES;
                if ([self shouldDecelerate])
                {
                    didDrag = NO;
                    [self startDecelerating];
                }
				if ([delegate respondsToSelector:@selector(carouselDidEndDragging:willDecelerate:)])
				{
					[delegate carouselDidEndDragging:self willDecelerate:decelerating];
				}
				if (!decelerating && (scrollToItemBoundary || (scrollOffset - [self clampedOffset:scrollOffset]) != 0.0f))
				{
                    if (fabsf(scrollOffset/itemWidth - self.currentItemIndex) < 0.01f)
                    {
                        //call scroll to trigger events for legacy support reasons
                        //even though technically we don't need to scroll at all
                        [self scrollToItemAtIndex:self.currentItemIndex duration:0.01f];
                    }
                    else if ([self shouldScroll])
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
                CGFloat translation = [panGesture translationInView:self].x - previousTranslation;
				CGFloat factor = 1.0f;
				if (!shouldWrap && bounces)
				{
					factor = 1.0f - fminf(fabsf(scrollOffset - [self clampedOffset:scrollOffset]) / itemWidth, bounceDistance) / bounceDistance;
				}
				
                previousTranslation = [panGesture translationInView:self].x;
                startVelocity = -[panGesture velocityInView:self].x * factor * scrollSpeed;
                scrollOffset -= translation * factor * offsetMultiplier;
                [self didScroll];
            }
        }
    }
}

#else


#pragma mark -
#pragma mark Mouse control

- (void)mouseDown:(NSEvent *)theEvent
{
    startVelocity = 0.0f;
}

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
        
        CGFloat translation = [theEvent deltaX];
		CGFloat factor = 1.0f;
		if (!shouldWrap && bounces)
		{
			factor = 1.0f - fminf(fabsf(scrollOffset - [self clampedOffset:scrollOffset]) / itemWidth, bounceDistance) / bounceDistance;
		}
        
        NSTimeInterval thisTime = [theEvent timestamp];
        startVelocity = -(translation / (thisTime - startTime)) * factor * scrollSpeed;
        startTime = thisTime;
        
        scrollOffset -= translation * factor * offsetMultiplier;
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
        didDrag = YES;
		if ([self shouldDecelerate])
        {
            didDrag = NO;
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
    if (scrollEnabled && !scrolling && [characters length])
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

@end