//
//  iCarousel.m
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import "iCarousel.h"


@interface iCarousel () <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) NSArray *itemViews;
@property (nonatomic, retain) NSArray *placeholderViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) float itemWidth;
@property (nonatomic, assign) float scrollOffset;
@property (nonatomic, assign) float startOffset;
@property (nonatomic, assign) float endOffset;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) float currentVelocity;
@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval previousTime;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) float previousTranslation;

- (void)layOutItemViews;
- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index;
- (BOOL)shouldWrap;
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
@synthesize startOffset;
@synthesize endOffset;
@synthesize startTime;
@synthesize scrolling;
@synthesize previousTranslation;

- (void)setup
{
    perspective = -1.0/500.0;
    decelerationRate = 0.9;
    scrollEnabled = YES;
    bounces = YES;
    
    contentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:contentView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [contentView addGestureRecognizer:panGesture];
    [panGesture release];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(step) userInfo:nil repeats:YES];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{	
	if ((self = [super initWithCoder:aDecoder]))
    {
		[self setup];
        [self reloadData];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
    {
		[self setup];
	}
	return self;
}

- (void)setDataSource:(id<iCarouselDataSource>)_dataSource
{
    dataSource = _dataSource;
    [self reloadData];
}

- (void)setType:(iCarouselType)_type
{
    type = _type;
    [self layOutItemViews];
}

- (BOOL)shouldWrap
{
    if ([delegate respondsToSelector:@selector(carouselShouldWrap:)])
    {
        return [delegate carouselShouldWrap:self];
    }
    switch (type)
    {
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
            return YES;
        default:
            return NO;
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
            float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/numberOfItems);
            float angle = offset / numberOfItems * arc;
            
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
            float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/numberOfItems);
            float angle = offset / numberOfItems * arc;
            
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

- (UIView *)containView:(UIView *)view
{
    UIView *containerView = [[[UIView alloc] init] autorelease];
    [containerView addSubview:view];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [containerView addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    return containerView;
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index
{
    view.superview.bounds = view.bounds;
    view.center = CGPointMake(view.bounds.size.width/2.0, view.bounds.size.height/2.0);
    view.superview.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    
    //calculate relative position
    float itemOffset = scrollOffset / itemWidth;
    float offset = index - itemOffset;
    if ([self shouldWrap])
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
    view.superview.layer.transform = [self transformForItemView:view withOffset:offset];
}

- (void)layoutSubviews
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
        view.userInteractionEnabled = (i == self.currentItemIndex);
	}
    
    //bring current view to front
    if ([itemViews count])
    {
        [contentView addSubview:[[itemViews objectAtIndex:self.currentItemIndex] superview]];
    }
    
    //lay out placeholders
    for (NSInteger i = 0; i < numberOfPlaceholders; i++)
    {
		UIView *view = [placeholderViews objectAtIndex:i];
		[self transformItemView:view atIndex:-(i+1)];
	}
    for (NSInteger i = 0; i < numberOfPlaceholders; i++)
    {
		UIView *view = [placeholderViews objectAtIndex:i + numberOfPlaceholders];
		[self transformItemView:view atIndex:i + numberOfItems];
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
	//remove old views
	for (UIView *view in itemViews)
    {
		[view.superview removeFromSuperview];
	}
    for (UIView *view in placeholderViews)
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
        self.placeholderViews = [NSMutableArray arrayWithCapacity:numberOfPlaceholders * 2];
        for (NSUInteger i = 0; i < numberOfPlaceholders * 2; i++)
        {
            UIView *view = [dataSource carouselPlaceholderView:self];
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
    [self layOutItemViews];
}

- (NSInteger)clampedIndex:(NSInteger)index
{
    if ([self shouldWrap])
    {
        return (index + numberOfItems) % numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (NSInteger)currentItemIndex
{	
    return [self clampedIndex:round(scrollOffset / itemWidth)];
}

- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{	
	index = [self clampedIndex:index];
    previousItemIndex = self.currentItemIndex;
    if ([self shouldWrap] && previousItemIndex == 0 && index == numberOfItems - 1)
    {
        scrollOffset = itemWidth * numberOfItems;
        
    }
    else if ([self shouldWrap] && index == 0 && previousItemIndex == numberOfItems - 1)
    {
        scrollOffset = -itemWidth;
    }
    
    if (animated)
    {
        scrolling = YES;
        startTime = [[NSProcessInfo processInfo] systemUptime];
        startOffset = scrollOffset;
        endOffset = itemWidth * index;
    }
    else
    {
        scrollOffset = itemWidth * index;
        [self didScroll];
    }
}

- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    UIView *itemView = [itemViews objectAtIndex:index];
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        itemView.superview.alpha = 0.0;
        [UIView commitAnimations];
        [itemView.superview performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
    }
    else
    {
        [itemView.superview removeFromSuperview];
    }
    
    [(NSMutableArray *)itemViews removeObjectAtIndex:index];
    numberOfItems --;
	[self transformItemViews];
    
    if (animated)
    {
        [UIView commitAnimations];
    }
}

- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    numberOfItems ++;

    UIView *itemView = [dataSource carousel:self viewForItemAtIndex:index];
    [(NSMutableArray *)itemViews insertObject:itemView atIndex:index];
    [contentView addSubview:[self containView:itemView]];
    [self transformItemView:itemView atIndex:index];
    itemView.superview.alpha = 0.0;
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
        [self transformItemViews];   
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDelay:0.3];
        [UIView setAnimationDuration:0.1];
        itemView.superview.alpha = 1.0;
        [UIView commitAnimations];
    }
    else
    {
        [self transformItemViews]; 
        itemView.superview.alpha = 1.0;
    }
}

- (void)didMoveToSuperview
{
    [self reloadData];
}

- (void)didScroll
{	
    if ([self shouldWrap])
    {
        float contentWidth = numberOfItems * itemWidth;
        if (scrollOffset < -itemWidth/2)
        {
            scrollOffset += contentWidth;
        }
        else if (scrollOffset >= contentWidth - itemWidth/2)
        {
            scrollOffset -= contentWidth;
        }
    }
    else if (!bounces)
    {
        scrollOffset = fmin(fmax(0.0, scrollOffset), numberOfItems * itemWidth - itemWidth);
    }
    [self transformItemViews];
    if ([delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
    NSInteger currentItemIndex = self.currentItemIndex;
    if (previousItemIndex != currentItemIndex && [delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
    {
		previousItemIndex = currentItemIndex;
        if (currentItemIndex > -1)
        {
            [delegate carouselCurrentItemIndexUpdated:self];
        }
	}
}

- (void)step
{
    NSTimeInterval currentTime = [[NSProcessInfo processInfo] systemUptime];
    NSTimeInterval deltaTime = currentTime - previousTime;
    previousTime = currentTime;
    
    if (scrolling)
    {
        NSTimeInterval time = (currentTime - startTime ) / 0.4;
        if (time >= 1.0)
        {
            time = 1.0;
            scrolling = NO;
        }
        float delta = (time < 0.5f)? 0.5f * pow(time * 2.0, 3.0): 0.5f * pow(time * 2.0 - 2.0, 3.0) + 1.0; //ease in/out
        scrollOffset = startOffset + (endOffset - startOffset) * delta;
        [self didScroll];
    }
    else if (decelerating)
    {
        float index = self.currentItemIndex;
        float offset = index - scrollOffset/itemWidth;
        float force = pow(offset, 2.0);
        force = fmin(force, 2.5);
        if (offset < 0)
        {
            force = - force;
        }
        
        currentVelocity -= force*itemWidth/2;
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
                float factor = ([self shouldWrap] || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
                currentVelocity = [panGesture velocityInView:self].x * factor;
                scrollOffset -= translation * factor;
                [self didScroll];
            }
        }
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    UIView *itemView = [tapGesture.view.subviews objectAtIndex:0];
    NSInteger index = [itemViews indexOfObject:itemView];
    if (index != NSNotFound)
    {
        [self scrollToItemAtIndex:index animated:YES];
    }
}
     
- (BOOL)gestureRecognizerShouldBegin:(UITapGestureRecognizer *)tapGesture
{
    UIView *itemView = [tapGesture.view.subviews objectAtIndex:0];
    NSInteger index = [itemViews indexOfObject:itemView];
    return (index != self.currentItemIndex);
}

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