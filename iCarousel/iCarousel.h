//
//  iCarousel.h
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef UIView View;

#else

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef NSView View;

#endif


typedef enum
{
    iCarouselTypeLinear = 0,
    iCarouselTypeRotary,
    iCarouselTypeInvertedRotary,
    iCarouselTypeCylinder,
    iCarouselTypeInvertedCylinder,
    iCarouselTypeCoverFlow,
    iCarouselTypeCustom
}
iCarouselType;


@protocol iCarouselDataSource, iCarouselDelegate;

@interface iCarousel : View
#ifdef __i386__
{
    id<iCarouselDelegate> delegate;
    id<iCarouselDataSource> dataSource;
    iCarouselType type;
    float perspective;
    NSInteger numberOfItems;
    NSInteger numberOfPlaceholders;
    View* contentView;
    NSArray* itemViews;
    NSArray* placeholderViews;
    NSInteger previousItemIndex;
    float itemWidth;
    float scrollOffset;
    float currentVelocity;
    NSTimer* timer;
    NSTimeInterval previousTime;
    BOOL decelerating;
    BOOL scrollEnabled;
    float decelerationRate;
    BOOL bounces;
    CGSize contentOffset;
    CGSize viewpointOffset;
    float startOffset;
    float endOffset;
    NSTimeInterval scrollDuration;
    NSTimeInterval startTime;
    BOOL scrolling;
    float previousTranslation;
}
#endif

@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;
@property (nonatomic, assign) iCarouselType type;
@property (nonatomic, assign) float perspective;
@property (nonatomic, assign) float decelerationRate;
@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) CGSize contentOffset;
@property (nonatomic, assign) CGSize viewpointOffset;
@property (nonatomic, readonly) NSInteger numberOfItems;
@property (nonatomic, readonly) NSInteger numberOfPlaceholders;
@property (nonatomic, readonly) NSInteger currentItemIndex;
@property (nonatomic, retain, readonly) NSArray *itemViews;
@property (nonatomic, retain, readonly) NSArray *placeholderViews;
@property (nonatomic, readonly) float itemWidth;
@property (nonatomic, retain, readonly) View *contentView;

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;
- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration;
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated;
#endif
- (void)reloadData;

@end


@protocol iCarouselDataSource <NSObject>

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;
- (View *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index;

@optional

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;
- (View *)carouselPlaceholderView:(iCarousel *)carousel;

@end


@protocol iCarouselDelegate <NSObject>

@optional

- (void)carouselDidScroll:(iCarousel *)carousel;
- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;
- (float)carouselItemWidth:(iCarousel *)carousel;
- (BOOL)carouselShouldWrap:(iCarousel *)carousel;
- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(View *)view withOffset:(float)offset;

@end