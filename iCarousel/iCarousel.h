//
//  iCarousel.h
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


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

@interface iCarousel : UIView

@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;
@property (nonatomic, assign) iCarouselType type;
@property (nonatomic, assign) float perspective;
@property (nonatomic, assign) float decelerationRate;
@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, readonly) NSInteger numberOfItems;
@property (nonatomic, readonly) NSInteger numberOfPlaceholders;
@property (nonatomic, readonly) NSInteger currentItemIndex;
@property (nonatomic, retain, readonly) NSArray *itemViews;
@property (nonatomic, retain, readonly) NSArray *placeholderViews;
@property (nonatomic, readonly) float itemWidth;

- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadData;

@end


@protocol iCarouselDataSource <NSObject>

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index;

@optional

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;
- (UIView *)carouselPlaceholderView:(iCarousel *)carousel;

@end


@protocol iCarouselDelegate <NSObject>

@optional

- (void)carouselDidScroll:(iCarousel *)carousel;
- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;
- (float)carouselItemWidth:(iCarousel *)carousel;
- (BOOL)carouselShouldWrap:(iCarousel *)carousel;
- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(float)offset;

@end