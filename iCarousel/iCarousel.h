//
//  iCarousel.h
//
//  Version 1.6.2
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#icarousel
//  https://github.com/nicklockwood/iCarousel
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

//
//  ARC Helper
//
//  Version 1.2
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef AH_RETAIN
#if __has_feature(objc_arc)
#define AH_RETAIN(x) x
#define AH_RELEASE(x)
#define AH_AUTORELEASE(x) x
#define AH_SUPER_DEALLOC
#else
#define __AH_WEAK
#define AH_WEAK assign
#define AH_RETAIN(x) [x retain]
#define AH_RELEASE(x) [x release]
#define AH_AUTORELEASE(x) [x autorelease]
#define AH_SUPER_DEALLOC [super dealloc]
#endif
#endif

//  Weak reference support

#ifndef AH_WEAK
#if defined __IPHONE_OS_VERSION_MIN_REQUIRED
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
#define __AH_WEAK __weak
#define AH_WEAK weak
#else
#define __AH_WEAK __unsafe_unretained
#define AH_WEAK unsafe_unretained
#endif
#elif defined __MAC_OS_X_VERSION_MIN_REQUIRED
#if __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
#define __AH_WEAK __weak
#define AH_WEAK weak
#else
#define __AH_WEAK __unsafe_unretained
#define AH_WEAK unsafe_unretained
#endif
#endif
#endif

//  ARC Helper ends


#ifdef USING_CHAMELEON
#define ICAROUSEL_IOS
#elif defined __IPHONE_OS_VERSION_MAX_ALLOWED
#define ICAROUSEL_IOS
typedef CGRect NSRect;
typedef CGSize NSSize;
#else
#define ICAROUSEL_MACOS
#endif


#import <QuartzCore/QuartzCore.h>
#ifdef ICAROUSEL_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
typedef NSView UIView;
#endif


typedef enum
{
    iCarouselTypeLinear = 0,
    iCarouselTypeRotary,
    iCarouselTypeInvertedRotary,
    iCarouselTypeCylinder,
    iCarouselTypeInvertedCylinder,
    iCarouselTypeWheel,
    iCarouselTypeInvertedWheel,
    iCarouselTypeCoverFlow,
    iCarouselTypeCoverFlow2,
    iCarouselTypeTimeMachine,
    iCarouselTypeInvertedTimeMachine,
    iCarouselTypeCustom
}
iCarouselType;


typedef enum
{
    iCarouselTranformOptionCount = 0,
    iCarouselTranformOptionArc,
	iCarouselTranformOptionAngle,
    iCarouselTranformOptionRadius,
    iCarouselTranformOptionTilt,
    iCarouselTranformOptionSpacing
}
iCarouselTranformOption;


@protocol iCarouselDataSource, iCarouselDelegate;

@interface iCarousel : UIView

//required for 32-bit Macs
#ifdef __i386__
{
	@private
	
    id<iCarouselDelegate> __AH_WEAK delegate;
    id<iCarouselDataSource> __AH_WEAK dataSource;
    iCarouselType type;
    CGFloat perspective;
    NSInteger numberOfItems;
    NSInteger numberOfPlaceholders;
	NSInteger numberOfPlaceholdersToShow;
    NSInteger numberOfVisibleItems;
    UIView *contentView;
    NSDictionary *itemViews;
    NSMutableSet *itemViewPool;
    NSMutableSet *placeholderViewPool;
    NSInteger previousItemIndex;
    CGFloat itemWidth;
    CGFloat scrollOffset;
    CGFloat offsetMultiplier;
    CGFloat startVelocity;
    id __unsafe_unretained timer;
    BOOL decelerating;
    BOOL scrollEnabled;
    CGFloat decelerationRate;
    BOOL bounces;
    CGSize contentOffset;
    CGSize viewpointOffset;
    CGFloat startOffset;
    CGFloat endOffset;
    NSTimeInterval scrollDuration;
    NSTimeInterval startTime;
    BOOL scrolling;
    CGFloat previousTranslation;
	BOOL centerItemWhenSelected;
	BOOL shouldWrap;
	BOOL dragging;
    BOOL didDrag;
    CGFloat scrollSpeed;
    CGFloat bounceDistance;
    NSTimeInterval toggleTime;
    CGFloat toggle;
    BOOL stopAtItemBoundary;
    BOOL scrollToItemBoundary;
    BOOL useDisplayLink;
	BOOL vertical;
    BOOL ignorePerpendicularSwipes;
}
#endif

@property (nonatomic, AH_WEAK) IBOutlet id<iCarouselDataSource> dataSource;
@property (nonatomic, AH_WEAK) IBOutlet id<iCarouselDelegate> delegate;
@property (nonatomic, assign) iCarouselType type;
@property (nonatomic, assign) CGFloat perspective;
@property (nonatomic, assign) CGFloat decelerationRate;
@property (nonatomic, assign) CGFloat scrollSpeed;
@property (nonatomic, assign) CGFloat bounceDistance;
@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, readonly) CGFloat scrollOffset;
@property (nonatomic, readonly) CGFloat offsetMultiplier;
@property (nonatomic, assign) CGSize contentOffset;
@property (nonatomic, assign) CGSize viewpointOffset;
@property (nonatomic, readonly) NSInteger numberOfItems;
@property (nonatomic, readonly) NSInteger numberOfPlaceholders;
@property (nonatomic, readonly) NSInteger currentItemIndex;
@property (nonatomic, strong, readonly) UIView *currentItemView;
@property (nonatomic, strong, readonly) NSArray *indexesForVisibleItems;
@property (nonatomic, readonly) NSInteger numberOfVisibleItems;
@property (nonatomic, strong, readonly) NSArray *visibleItemViews;
@property (nonatomic, readonly) CGFloat itemWidth;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, readonly) CGFloat toggle;
@property (nonatomic, assign) BOOL stopAtItemBoundary;
@property (nonatomic, assign) BOOL scrollToItemBoundary;
@property (nonatomic, assign) BOOL useDisplayLink;
@property (nonatomic, assign, getter = isVertical) BOOL vertical;
@property (nonatomic, assign) BOOL ignorePerpendicularSwipes;

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;
- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration;
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (UIView *)itemViewAtIndex:(NSInteger)index;
- (NSInteger)indexOfItemView:(UIView *)view;
- (NSInteger)indexOfItemViewOrSubview:(UIView *)view;
- (void)reloadData;

#ifdef ICAROUSEL_IOS

@property (nonatomic, assign) BOOL centerItemWhenSelected;

#endif

@end


@protocol iCarouselDataSource <NSObject>

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel;
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view;

@optional

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel;
- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view;
- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel;

//deprecated, use carousel:viewForItemAtIndex:reusingView: and carousel:placeholderViewAtIndex:reusingView: instead
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index __deprecated;
- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index __deprecated;

@end


@protocol iCarouselDelegate <NSObject>
@optional

- (void)carouselWillBeginScrollingAnimation:(iCarousel *)carousel;
- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel;
- (void)carouselDidScroll:(iCarousel *)carousel;
- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel;
- (void)carouselWillBeginDragging:(iCarousel *)carousel;
- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate;
- (void)carouselWillBeginDecelerating:(iCarousel *)carousel;
- (void)carouselDidEndDecelerating:(iCarousel *)carousel;
- (CGFloat)carouselItemWidth:(iCarousel *)carousel;
- (CGFloat)carouselOffsetMultiplier:(iCarousel *)carousel;
- (BOOL)carouselShouldWrap:(iCarousel *)carousel;
- (CGFloat)carousel:(iCarousel *)carousel itemAlphaForOffset:(CGFloat)offset;
- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform;
- (CGFloat)carousel:(iCarousel *)carousel valueForTransformOption:(iCarouselTranformOption)option withDefault:(CGFloat)value;

//deprecated, use transformForItemAtIndex:withOffset:baseTransform: instead
- (CATransform3D)carousel:(iCarousel *)carousel transformForItemView:(UIView *)view withOffset:(CGFloat)offset __deprecated;

#ifdef ICAROUSEL_IOS

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index;
- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index;

#endif

@end