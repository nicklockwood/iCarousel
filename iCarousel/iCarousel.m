//
//  iCarousel.m
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import "iCarousel.h"
#import <QuartzCore/QuartzCore.h>


#define PERSPECTIVE - 1.0/500.0


@interface iCarousel () <UIScrollViewDelegate>

@property (nonatomic, retain) NSArray *pageViews;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, assign) NSUInteger oldIndex;
@property (nonatomic, assign) float pageWidth;

- (void)layoutPages;
- (void)transformPageView:(UIView *)view atIndex:(NSUInteger)index;

@end


@implementation iCarousel

@synthesize type;
@synthesize dataSource;
@synthesize delegate;
@synthesize numberOfPages;
@synthesize scrollEnabled;
@synthesize pageViews;
@synthesize scrollView;
@synthesize oldIndex;
@synthesize pageWidth;

- (void)setup
{
	self.scrollEnabled = YES;
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
	scrollView.scrollEnabled = scrollEnabled;
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
    [self layoutPages];
}

- (void)transformPageView:(UIView *)view atIndex:(NSUInteger)index
{
	//position the view at the vanishing point
    float boundsWidth = scrollView.bounds.size.width;
    float offset = boundsWidth/2 + scrollView.contentOffset.x;
    view.center = CGPointMake(offset, scrollView.frame.size.height/2.0);
    
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = PERSPECTIVE;
    
    //perform transform
    switch (type)
    {
        case iCarouselTypeLinear:
        {
            //update transform
            transform = CATransform3DTranslate(transform, index * pageWidth - offset + pageWidth/2.0, 0, 0);
            break;
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
            float radius = (pageWidth/2.0) / tan(M_PI/numberOfPages);
            float angle = (((float)index*pageWidth + scrollView.contentOffset.x) / scrollView.contentSize.width) * 2 * M_PI;
            
            if (type == iCarouselTypeCylinder) {
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, 0, 0, -radius);
            transform = CATransform3DRotate(transform, -angle, 0, 1, 0);
            transform = CATransform3DTranslate(transform, 0, 0, radius);
            break;
        }
        case iCarouselTypeCoverFlow:
        {
            //calculate positioning factors
            float factor = scrollView.contentOffset.x / pageWidth;
            float page = round(factor);
            factor = factor - floor(factor);
            if (factor > 0.5)
            {
                factor -= 1.0;
            }
            factor = page - (float)index + factor;
            float clampedFactor = fmax(-1.0, fmin(1.0, factor));
            
            //calculate positions and rotations
            float rotation = clampedFactor * M_PI_2;
            float spacing = factor * 0.75 * pageWidth;
            float distance = fabs(clampedFactor) * scrollView.frame.size.width/2;
            
            //update transform
            transform = CATransform3DTranslate(transform, index * pageWidth + pageWidth/2.0 - offset + spacing - (clampedFactor  * pageWidth)/2, 0, -distance);
            transform = CATransform3DRotate(transform, rotation, 0, 1, 0);
            break;
        }
        default:
        {
            //no transform
        }
    }
    
    //transform view
    view.layer.doubleSided = NO;
    view.layer.transform = transform;
}

- (void)layoutSubviews
{
    if (scrollView.bounds.size.height != self.bounds.size.height || scrollView.frame.origin.y != 0.0)
    {
        [self layoutPages];
    }
}

- (void)layoutPages
{
    //set scroll size
	if ([(NSObject *)dataSource respondsToSelector:@selector(carouselPageWidth:)])
    {
		pageWidth = [dataSource carouselPageWidth:self];
	}
    else
    {
        pageWidth = self.frame.size.width;
	}
    scrollView.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    scrollView.bounds = CGRectMake(0.0, 0.0, pageWidth, self.bounds.size.height);
    scrollView.contentSize = CGSizeMake(pageWidth * numberOfPages, scrollView.frame.size.height);
	
	for (NSUInteger i = 0; i < numberOfPages; i++)
    {
		UIView *view = [pageViews objectAtIndex:i];
		[self transformPageView:view atIndex:i];
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
	for (UIView *view in pageViews)
    {
		[view removeFromSuperview];
	}
	
	//load new views
	numberOfPages = [dataSource numberOfPagesInCarousel:self];
	self.pageViews = [NSMutableArray arrayWithCapacity:numberOfPages];
	for (NSUInteger i = 0; i < numberOfPages; i++)
    {
        UIView *view = [dataSource carousel:self viewForPageAtIndex:i];
        if (view == nil)
        {
			view = [[[UIView alloc] init] autorelease];
        }
		[(NSMutableArray *)pageViews addObject:view];
        [scrollView addSubview:view];
	}
    
    //layout views
    [self layoutPages];
}

- (void)setScrollEnabled:(BOOL)_scrollEnabled
{	
	scrollEnabled = _scrollEnabled;
	scrollView.scrollEnabled = scrollEnabled;
}

- (NSUInteger)currentPage
{	
	CGPoint offset = scrollView.contentOffset;
	NSUInteger page = round(offset.x / scrollView.frame.size.width); 
	if (page > self.numberOfPages - 1)
    {
		page = self.numberOfPages - 1;
	}
	return page;
}

- (void)scrollToPage:(NSUInteger)index animated:(BOOL)animated
{	
	if (index < numberOfPages)
    {
		oldIndex = self.currentPage;
		[scrollView scrollRectToVisible:CGRectMake(scrollView.frame.size.width * index, 0, scrollView.frame.size.width, scrollView.frame.size.height)
							   animated:animated];
	}
}

- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
    }
    
    UIView *itemView = [pageViews objectAtIndex:index];
    [itemView removeFromSuperview];
    [(NSMutableArray *)pageViews removeObjectAtIndex:index];
    numberOfPages --;
    scrollView.contentSize = CGSizeMake(pageWidth * numberOfPages, scrollView.frame.size.height);
	for (NSUInteger i = index; i < numberOfPages; i++)
    {
		UIView *view = [pageViews objectAtIndex:i];
		[self transformPageView:view atIndex:i];
	}
    
    if (animated)
    {
        [UIView commitAnimations];
    }
}

- (void)showItemView:(UIView *)view
{
    view.hidden = NO;
}

- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{    
    UIView *itemView = [dataSource carousel:self viewForPageAtIndex:index];
    [(NSMutableArray *)pageViews insertObject:itemView atIndex:index];
    itemView.alpha = 0.0;
    [scrollView addSubview:itemView];
    
    if (animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.4];
    }
    
    numberOfPages ++;
    scrollView.contentSize = CGSizeMake(pageWidth * numberOfPages, scrollView.frame.size.height);
	for (NSUInteger i = index + 1; i < numberOfPages; i++)
    {
		UIView *view = [pageViews objectAtIndex:i];
		[self transformPageView:view atIndex:i];
	}
    
    if (animated)
    {   
        [UIView commitAnimations];
        [self transformPageView:itemView atIndex:index];
        [self performSelector:@selector(showItemView:) withObject:itemView afterDelay:animated? 0.395: 0.0];
    }
    else
    {
        [self transformPageView:itemView atIndex:index];
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
	for (NSUInteger i = 0; i < numberOfPages; i++)
    {
		[self transformPageView:[pageViews objectAtIndex:i] atIndex:i];
	}
    if (oldIndex != self.currentPage && [(NSObject *)delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
		oldIndex = self.currentPage;
		[delegate carouselDidScroll:self];
	};
}
	 
#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
	[scrollView release];
	[pageViews release];
	[super dealloc];
}

@end
