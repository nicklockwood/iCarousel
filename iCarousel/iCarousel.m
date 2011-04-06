//
//  iCarousel.m
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import "iCarousel.h"


#define PERSPECTIVE - 1.0/500.0


@interface iCarousel () <UIScrollViewDelegate>

@property (nonatomic, retain) NSMutableArray *itemViews;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) float itemWidth;

- (void)layOutItemViews;
- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index;

@end


@implementation iCarousel

@synthesize type;
@synthesize dataSource;
@synthesize delegate;
@synthesize numberOfItems;
@synthesize itemViews;
@synthesize scrollView;
@synthesize previousItemIndex;
@synthesize itemWidth;

- (void)setup
{
    self.autoresizesSubviews = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleLowMemory:)
												 name:UIApplicationDidReceiveMemoryWarningNotification
											   object:nil];
	
	scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizesSubviews = NO;
    scrollView.clipsToBounds = NO;
	scrollView.delaysContentTouches = YES;
	scrollView.pagingEnabled = YES;
	scrollView.scrollEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.scrollsToTop = NO;
    scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    scrollView.delegate = self;
    
	[self addSubview:scrollView];
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

- (CATransform3D)transformForItemWithOffset:(float)offset
{
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = PERSPECTIVE;
    
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
            float radius = (itemWidth/2.0) / tan(M_PI/numberOfItems);
            float angle = offset / numberOfItems * 2.0 * M_PI;
            
            if (type == iCarouselTypeRotary) {
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, fabs(radius) * cos(angle), 0, fabs(radius) * sin(angle) + radius);
            return transform;
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
            float radius = (itemWidth/2.0) / tan(M_PI/numberOfItems);
            float angle = offset / numberOfItems * 2.0 * M_PI;
            
            if (type == iCarouselTypeInvertedCylinder) {
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, 0, 0, -radius);
            transform = CATransform3DRotate(transform, angle, 0, 1, 0);
            transform = CATransform3DTranslate(transform, 0, 0, radius);
            return transform;
        }
        case iCarouselTypeCoverFlow:
        {
            float clampedOffset = fmax(-1.0, fmin(1.0, offset));
            transform = CATransform3DTranslate(transform, (clampedOffset * 0.5 + offset * 0.25) * itemWidth,
                                               0, fabs(clampedOffset) * -itemWidth * 0.5);
            return CATransform3DRotate(transform, -clampedOffset * M_PI_2, 0, 1, 0);
        }
        case iCarouselTypeCustom:
        default:
        {
            return [delegate carousel:self transformForItemWithOffset:offset];
        }
    }
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index
{
	//position the view at the vanishing point
    float boundsWidth = scrollView.bounds.size.width;
    float frameOffset = boundsWidth/2 + scrollView.contentOffset.x;
    view.center = CGPointMake(frameOffset, scrollView.frame.size.height/2.0);
    
    //calculate relative position
    float offset = self.currentItemIndex - index - scrollView.contentOffset.x / itemWidth;
    
    //transform view
    view.layer.doubleSided = NO;
    view.layer.transform = [self transformForItemWithOffset:offset];
}

- (void)layoutSubviews
{
    if (scrollView.bounds.size.height != self.bounds.size.height || scrollView.frame.origin.y != 0.0)
    {
        [self layOutItemViews];
    }
}

- (void)layOutItemViews
{
    //set scroll size
	if ([(NSObject *)dataSource respondsToSelector:@selector(carouselItemWidth:)])
    {
		itemWidth = [delegate carouselItemWidth:self];
	}
    else
    {
        itemWidth = self.frame.size.width;
	}
    scrollView.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    scrollView.bounds = CGRectMake(0.0, 0.0, itemWidth, self.bounds.size.height);
    scrollView.contentSize = CGSizeMake(itemWidth * numberOfItems, scrollView.frame.size.height);
	
	for (NSUInteger i = 0; i < numberOfItems; i++)
    {
		UIView *view = [itemViews objectAtIndex:i];
		[self transformItemView:view atIndex:i];
	}
	
    //call delegate
	if ([(NSObject *)delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
}

- (void)reloadData
{
	//remove old views
	for (UIView *view in itemViews)
    {
		[view removeFromSuperview];
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
		[itemViews addObject:view];
        [scrollView addSubview:view];
	}
    
    //layout views
    [self layOutItemViews];
}

- (NSInteger)currentItemIndex
{	
	CGPoint offset = scrollView.contentOffset;
	NSInteger itemIndex = round(offset.x / scrollView.frame.size.width); 
	return MAX(MIN(itemIndex, 0), self.numberOfItems - 1);
}

- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{	
	if (index < numberOfItems)
    {
		previousItemIndex = self.currentItemIndex;
		[scrollView scrollRectToVisible:CGRectMake(scrollView.frame.size.width * index, 0, scrollView.frame.size.width, scrollView.frame.size.height)
							   animated:animated];
	}
}

- (void)removeItemView:(UIView *)itemView
{
    [itemView removeFromSuperview];
}

- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    UIView *itemView = [itemViews objectAtIndex:index];
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        itemView.alpha = 0.0;
        [UIView commitAnimations];
        [self performSelector:@selector(removeItemView:) withObject:itemView afterDelay:0.1];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
    }
    else
    {
        [itemView removeFromSuperview];
    }
    
    [itemViews removeObjectAtIndex:index];
    numberOfItems --;
    scrollView.contentSize = CGSizeMake(itemWidth * numberOfItems, scrollView.frame.size.height);
	for (NSUInteger i = index; i < numberOfItems; i++)
    {
		UIView *view = [itemViews objectAtIndex:i];
		[self transformItemView:view atIndex:i];
	}
    
    if (animated)
    {
        [UIView commitAnimations];
    }
}

- (void)showItemView:(UIView *)itemView
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.1];
    itemView.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    UIView *itemView = [dataSource carousel:self viewForItemAtIndex:index];
    [itemViews insertObject:itemView atIndex:index];
    itemView.alpha = 0.0;
    [scrollView addSubview:itemView];
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
    }
    
    numberOfItems ++;
    scrollView.contentSize = CGSizeMake(itemWidth * numberOfItems, scrollView.frame.size.height);
	for (NSUInteger i = index + 1; i < numberOfItems; i++)
    {
		UIView *view = [itemViews objectAtIndex:i];
		[self transformItemView:view atIndex:i];
	}
    
    if (animated)
    {   
        [UIView commitAnimations];
        [self transformItemView:itemView atIndex:index];
        [self performSelector:@selector(showItemView:) withObject:itemView afterDelay:animated? 0.3: 0.0];
    }
    else
    {
        [self transformItemView:itemView atIndex:index];
        itemView.alpha = 1.0;
    }
}

- (void)didMoveToSuperview
{
    [self reloadData];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *view = [super hitTest:point withEvent:event];
	if ([view isEqual:self])
    {
		return scrollView;
	}
	return view;
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{	
	if ([(NSObject *)delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		[delegate carouselDidScroll:self];
	}
    for (NSUInteger i = 0; i < numberOfItems; i++)
    {
		[self transformItemView:[itemViews objectAtIndex:i] atIndex:i];
	}
    if (previousItemIndex != self.currentItemIndex && [(NSObject *)delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
    {
		previousItemIndex = self.currentItemIndex;
		[delegate carouselCurrentItemIndexUpdated:self];
	}
}
	 
#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
	[scrollView release];
	[itemViews release];
	[super dealloc];
}

@end
