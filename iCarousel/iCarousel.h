//
//  iCarousel.h
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum
{
    iCarouselTypeLinear = 0,
    iCarouselTypeCylinder,
    iCarouselTypeInvertedCylinder,
    iCarouselTypeCoverFlow
}
iCarouselType;


@protocol iCarouselDataSource, iCarouselDelegate;

@interface iCarousel : UIView

@property (nonatomic, assign) iCarouselType type;
@property (nonatomic, assign) IBOutlet id<iCarouselDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<iCarouselDelegate> delegate;
@property (nonatomic, readonly) NSUInteger numberOfPages;
@property (nonatomic, readonly) NSUInteger currentPage;
@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, retain, readonly) NSArray *pageViews;

- (void)scrollToPage:(NSUInteger)index animated:(BOOL)animated;
- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadData;

@end


@protocol iCarouselDataSource

- (NSUInteger)numberOfPagesInCarousel:(iCarousel *)carousel;
- (UIView *)carousel:(iCarousel *)carousel viewForPageAtIndex:(NSUInteger)index;

@optional

- (float)carouselPageWidth:(iCarousel *)carousel;

@end


@protocol iCarouselDelegate

@optional

- (void)carouselDidScroll:(iCarousel *)carousel;

@end