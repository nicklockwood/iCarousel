//
//  iCarousel.m
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


#import "iCarousel.h"


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#define PointMake CGPointMake
#define RectMake CGRectMake

#else

#define PointMake NSMakePoint
#define RectMake NSMakeRect

#endif


#define SCROLL_DURATION 0.4
#define INSERT_DURATION 0.4


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@interface iCarousel () <UIGestureRecognizerDelegate>
#else
@interface iCarousel ()
#endif

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSArray *itemViews;
@property (nonatomic, retain) NSArray *placeholderViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) float itemWidth;
@property (nonatomic, assign) float scrollOffset;
@property (nonatomic, assign) float startOffset;
@property (nonatomic, assign) float endOffset;
@property (nonatomic, assign) NSTimeInterval scrollDuration;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) float currentVelocity;
@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval previousTime;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) float previousTranslation;
@property (nonatomic, assign) BOOL shouldWrap;

- (void)layOutItemViews;
- (NSInteger)clampedIndex:(NSInteger)index;
- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index;
- (void)didScroll;

@end


@implementation iCarousel

@synthesize dataSource;
@synthesize delegate;
@synthesize type;
@synthesize perspective;
@synthesize numberOfItems;
@synthesize numberOfPlaceholders;
@synthesize contentView;
@synthesize itemViews;
@synthesize placeholderViews;
@synthesize previousItemIndex;
@synthesize itemWidth;
@synthesize scrollOffset;
@synthesize currentVelocity;
@synthesize timer;
@synthesize previousTime;
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

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

@synthesize centerItemWhenSelected;

#endif

- (void)setup
{
    perspective = -1.0/500.0;
    decelerationRate = 0.9;
    scrollEnabled = YES;
    bounces = YES;
    scrollOffset = 0;
    contentOffset = CGSizeZero;
	viewpointOffset = CGSizeZero;
	shouldWrap = NO;
    
	self.itemViews = [NSMutableArray array];
    
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
        [self layOutItemViews];
    }
}

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
        {
            float tilt = 0.9;
            float spacing = 0.25;
            
            float clampedOffset = fmax(-1.0, fmin(1.0, offset));
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
        CATransform3D t3 = ((UIView *)[carousel.itemViews
            objectAtIndex:carousel.currentItemIndex]).superview.layer.transform;
        float x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
        float x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
        float x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
        difference = fabs(x2 - x3) - fabs(x1 - x3);
    }
    return (difference < 0)? NSOrderedAscending: NSOrderedDescending;
}

- (void)depthSortViews
{
    NSArray *allViews = [itemViews arrayByAddingObjectsFromArray:placeholderViews];
    for (UIView *view in [allViews sortedArrayUsingFunction:compareViewDepth context:self])
    {
        [contentView addSubview:view.superview];
    }
}

- (UIView *)containView:(UIView *)view
{
	
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

    UIControl *container = [[[UIControl alloc] initWithFrame:view.frame] autorelease];
    [container addTarget:self action:@selector(didTap:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:view];
    return container;
    
#else
    
    NSView *container = [[[NSView alloc] initWithFrame:view.frame] autorelease];

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
    
    //transform view
    CATransform3D transform = [self transformForItemView:view withOffset:offset];
    view.superview.layer.transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0);

#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED
    
    //remove transform and transition animations
    [view.superview.layer removeAllAnimations];
    
#endif
    
	//hide containers for invisible views
    [view.superview setHidden:([view isHidden] || view.layer.opacity < 0.001)];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void)layoutSubviews
#else
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
#endif
{
    contentView.frame = self.bounds;
    [self layOutItemViews];
}

- (void)transformItemViews
{
    //lay out items
	for (NSUInteger i = 0; i < numberOfItems; i++)
    {
		UIView *view = [itemViews objectAtIndex:i];
		[self transformItemView:view atIndex:i];
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        view.userInteractionEnabled = (i == self.currentItemIndex);
#endif
	}
    
    //lay out placeholders
    for (NSInteger i = 0; i < numberOfPlaceholders; i++)
    {
		UIView *view = [placeholderViews objectAtIndex:i];
		if (i < floor(numberOfPlaceholders/2))
		{
			//left placeholder
			[self transformItemView:view atIndex:-(i+1)];
		}
		else
		{
			//right placeholder
			[self transformItemView:view atIndex:i - floor(numberOfPlaceholders/2) + numberOfItems];
		}
		[view.superview setHidden:shouldWrap];
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

    //adjust scroll offset
    scrollOffset = scrollOffset / prevItemWidth * itemWidth;
	
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
        
    //transform views
    [self transformItemViews];
	
    //call delegate
	if (prevItemWidth != itemWidth && [delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
}

- (void)reloadData
{
	//make a note of current index
	previousItemIndex = self.currentItemIndex;
	
	//remove old views
	for (UIView *view in [itemViews arrayByAddingObjectsFromArray:placeholderViews])
    {
		[view.superview removeFromSuperview];
	}
	
	//load new views
	numberOfItems = [dataSource numberOfItemsInCarousel:self];
	self.itemViews = [NSMutableArray arrayWithCapacity:numberOfItems];
	for (NSUInteger i = 0; i < numberOfItems; i++)
    {
        UIView *view = [dataSource carousel:self viewForItemAtIndex:i];
        if (view == nil)
        {
			view = [[[UIView alloc] init] autorelease];
        }
		[(NSMutableArray *)itemViews addObject:view];
        [contentView addSubview:[self containView:view]];
	}
    
    //load placeholders
    if ([dataSource respondsToSelector:@selector(numberOfPlaceholdersInCarousel:)])
    {
        numberOfPlaceholders = [dataSource numberOfPlaceholdersInCarousel:self];
        self.placeholderViews = [NSMutableArray arrayWithCapacity:numberOfPlaceholders];
        for (NSUInteger i = 0; i < numberOfPlaceholders; i++)
        {
            UIView *view = [dataSource carousel:self placeholderViewAtIndex:i];
            if (view == nil)
            {
                view = [[[UIView alloc] init] autorelease];
            }
            [(NSMutableArray *)placeholderViews addObject:view];
            [contentView addSubview:[self containView:view]];
        }
    }
    
    //set item width (may be overidden by delegate)
    itemWidth = [([itemViews count]? [itemViews objectAtIndex:0]: self) bounds].size.width;
	
    //layout views
	previousItemIndex = [self clampedIndex:previousItemIndex];
	scrollOffset = itemWidth * previousItemIndex;
    [self layOutItemViews];
	[self depthSortViews];
}

- (NSInteger)clampedIndex:(NSInteger)index
{
    if (numberOfItems == 0)
    {
        return 0;
    }
    else if (shouldWrap)
    {
        return index - floor((float)index / (float)numberOfItems) * numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (float)clampedOffset:(float)offset
{
    if (numberOfItems == 0)
    {
        return 0;
    }
    else if (shouldWrap)
    {
		float contentWidth = numberOfItems * itemWidth;
		return offset - floor(offset / contentWidth) * contentWidth;
    }
    else
    {
        return fmin(fmax(0.0, scrollOffset), numberOfItems * itemWidth - itemWidth);
    }
}

- (NSInteger)currentItemIndex
{	
    return [self clampedIndex:round(scrollOffset / itemWidth)];
}

- (NSInteger)minScrollDistanceFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
	NSInteger directDistance = toIndex - fromIndex;
	NSInteger wrappedDistance = MIN(toIndex, fromIndex) + numberOfItems - MAX(toIndex, fromIndex);
	if (fromIndex < toIndex)
	{
		wrappedDistance = -wrappedDistance;
	}
	return (ABS(directDistance) <= ABS(wrappedDistance))? directDistance: wrappedDistance;
}

- (float)minScrollDistanceFromOffset:(float)fromOffset toOffset:(float)toOffset
{
	float directDistance = toOffset - fromOffset;
	float wrappedDistance = fmin(toOffset, fromOffset) + numberOfItems*itemWidth - fmax(toOffset, fromOffset);
	if (fromOffset < toOffset)
	{
		wrappedDistance = -wrappedDistance;
	}
	return (fabs(directDistance) <= fabs(wrappedDistance))? directDistance: wrappedDistance;
}

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration
{
	if (duration > 0)
    {
        scrolling = YES;
        startTime = CACurrentMediaTime();
        startOffset = scrollOffset;
		scrollDuration = duration;
		previousItemIndex = self.currentItemIndex;
		if (shouldWrap)
		{
			endOffset = startOffset + [self minScrollDistanceFromOffset:startOffset
															   toOffset:itemWidth * (previousItemIndex + itemCount)];
		}
        else
		{
			endOffset = itemWidth * [self clampedIndex:previousItemIndex + itemCount];
		}
    }
    else
    {
        scrollOffset = itemWidth * [self clampedIndex:previousItemIndex + itemCount];
        [self didScroll];
		[self depthSortViews];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration
{
	[self scrollByNumberOfItems:[self minScrollDistanceFromIndex:self.currentItemIndex toIndex:index] duration:duration];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated
{	
	[self scrollToItemAtIndex:index duration:animated? SCROLL_DURATION: 0];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = [self clampedIndex:index];
    UIView *itemView = [itemViews objectAtIndex:index];
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        itemView.superview.layer.opacity = 0.0;
        [itemView.superview performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
        [UIView commitAnimations];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:INSERT_DURATION];
    }
    else
    {
        [itemView.superview removeFromSuperview];
    }
    
    [(NSMutableArray *)itemViews removeObjectAtIndex:index];
    numberOfItems --;
    [self scrollToItemAtIndex:self.currentItemIndex animated:NO];
	[self transformItemViews];
     
    if (animated)
    {
        [UIView commitAnimations];
    }
}

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    index = [self clampedIndex:index];
    numberOfItems ++;

    UIView *itemView = [dataSource carousel:self viewForItemAtIndex:index];
    [(NSMutableArray *)itemViews insertObject:itemView atIndex:index];
    [contentView addSubview:[self containView:itemView]];
    [self transformItemView:itemView atIndex:index];
    itemView.superview.layer.opacity = 0.0;
 
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:INSERT_DURATION];
        [self transformItemViews];
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelay:INSERT_DURATION - 0.1];
        [UIView setAnimationDuration:0.1];
        itemView.superview.layer.opacity = 1.0;
        [UIView commitAnimations];
    }
    else
    { 
        [self transformItemViews]; 
        itemView.superview.layer.opacity = 1.0;
    } 
}

#endif

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void)didMoveToSuperview
#else
- (void)viewDidMoveToSuperview
#endif
{
    if (self.superview)
	{
		[self reloadData];
		[timer invalidate];
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(step) userInfo:nil repeats:YES];
	}
	else
	{
		[timer invalidate];
		timer = nil;
	}
}

- (void)didScroll
{	
    if (shouldWrap || !bounces)
    {
        scrollOffset = [self clampedOffset:scrollOffset];
    }
    [self transformItemViews];
    if ([delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
    
    //update index
    NSInteger currentItemIndex = self.currentItemIndex;
    if (previousItemIndex != currentItemIndex)
	{
		previousItemIndex = currentItemIndex;
		
		//call delegate
		if ([delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
		{
			[delegate carouselCurrentItemIndexUpdated:self];
		}
	}
}

- (void)step
{
    NSTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval deltaTime = currentTime - previousTime;
    previousTime = currentTime;
    
    if (scrolling)
    {
        NSTimeInterval time = (currentTime - startTime ) / scrollDuration;
        if (time >= 1.0)
        {
            time = 1.0;
            scrolling = NO;
            [self depthSortViews];
        }
        float delta = (time < 0.5f)? 0.5f * pow(time * 2.0, 3.0): 0.5f * pow(time * 2.0 - 2.0, 3.0) + 1.0; //ease in/out
        scrollOffset = startOffset + (endOffset - startOffset) * delta;
        [self didScroll];
    }
    else if (decelerating)
    {
        float index = self.currentItemIndex;
        float offset = [self minScrollDistanceFromOffset:index*itemWidth toOffset:[self clampedOffset:scrollOffset]];

        currentVelocity *= decelerationRate;
        scrollOffset -= currentVelocity * deltaTime;
        if (fabs(currentVelocity) < itemWidth*0.5 && fabs(offset) < itemWidth*0.5)
        {
            decelerating = NO;
            [self scrollToItemAtIndex:index animated:YES];
        }
        [self didScroll];
    }
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#pragma mark -
#pragma mark Gestures and taps

- (void)didTap:(UIView *)container
{
    UIView *itemView = [container.subviews objectAtIndex:0];
    NSInteger index = [itemViews indexOfObject:itemView];
	if (index != NSNotFound)
	{
		if (centerItemWhenSelected && index != self.currentItemIndex)
		{
			[self scrollToItemAtIndex:index animated:YES];
		}
		if ([delegate respondsToSelector:@selector(carousel:didSelectItemAtIndex:)])
		{
			[delegate carousel:self didSelectItemAtIndex:index];
		}
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
                scrolling = NO;
                decelerating = NO;
                previousTranslation = [panGesture translationInView:self].x;
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            {
                decelerating = YES;
            }
            default:
            {
                float translation = [panGesture translationInView:self].x - previousTranslation;
                previousTranslation = [panGesture translationInView:self].x;
                NSInteger index = round(scrollOffset / itemWidth);
				float factor = (shouldWrap || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
                currentVelocity = [panGesture velocityInView:self].x * factor;
                scrollOffset -= translation * factor;
                [self didScroll];
            }
        }
    }
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

#else

#pragma mark -
#pragma mark Mouse control

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (scrollEnabled)
    {
        scrolling = NO;
        decelerating = NO;
        
        float translation = [theEvent deltaX];
        NSInteger index = round(scrollOffset / itemWidth);
        float factor = (shouldWrap || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
        
        NSTimeInterval thisTime = [theEvent timestamp];
        currentVelocity = (translation / (thisTime - startTime)) * factor;
        startTime = thisTime;
        scrollOffset -= translation * factor;
        [self didScroll];
        
        decelerating = YES;
    }
}

#pragma mark -
#pragma mark Scrollwheel control

- (void)scrollWheel:(NSEvent *)theEvent
{
    [self mouseDragged:theEvent];
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
    [timer invalidate];
    [contentView release];
	[itemViews release];
    [placeholderViews release];
	[super dealloc];
}

@end