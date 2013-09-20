//
//  iCarousel.m
//
//  Version 1.8 beta 5
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
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

#import "iCarousel.h"
#import <objc/message.h>


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#define MIN_TOGGLE_DURATION 0.2f
#define MAX_TOGGLE_DURATION 0.4f
#define SCROLL_DURATION 0.4f
#define INSERT_DURATION 0.4f
#define DECELERATE_THRESHOLD 0.1f
#define SCROLL_SPEED_THRESHOLD 2.0f
#define SCROLL_DISTANCE_THRESHOLD 0.1f
#define DECELERATION_MULTIPLIER 30.0f


#ifdef ICAROUSEL_MACOS
#define MAX_VISIBLE_ITEMS 50
#else
#define MAX_VISIBLE_ITEMS 30
#endif


@implementation NSObject (iCarousel)

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel { return 0; }
- (void)carouselWillBeginScrollingAnimation:(iCarousel *)carousel {}
- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {}
- (void)carouselDidScroll:(iCarousel *)carousel {}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {}
- (void)carouselWillBeginDragging:(iCarousel *)carousel {}
- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate {}
- (void)carouselWillBeginDecelerating:(iCarousel *)carousel {}
- (void)carouselDidEndDecelerating:(iCarousel *)carousel {}

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index { return YES; }
- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel { return 0; }
- (CATransform3D)carousel:(iCarousel *)carousel
   itemTransformForOffset:(CGFloat)offset
            baseTransform:(CATransform3D)transform { return transform; }
- (CGFloat)carousel:(iCarousel *)carousel
     valueForOption:(iCarouselOption)option
        withDefault:(CGFloat)value { return value; }

@end


@interface iCarousel ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableDictionary *itemViews;
@property (nonatomic, strong) NSMutableSet *itemViewPool;
@property (nonatomic, strong) NSMutableSet *placeholderViewPool;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) NSInteger numberOfPlaceholdersToShow;
@property (nonatomic, assign) NSInteger numberOfVisibleItems;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat offsetMultiplier;
@property (nonatomic, assign) CGFloat startOffset;
@property (nonatomic, assign) CGFloat endOffset;
@property (nonatomic, assign) NSTimeInterval scrollDuration;
@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) CGFloat startVelocity;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign, getter = isDecelerating) BOOL decelerating;
@property (nonatomic, assign) CGFloat previousTranslation;
@property (nonatomic, assign, getter = isWrapEnabled) BOOL wrapEnabled;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, assign) BOOL didDrag;
@property (nonatomic, assign) NSTimeInterval toggleTime;

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self);

@end


@implementation iCarousel

#pragma mark -
#pragma mark Initialisation

- (void)setUp
{
    _decelerationRate = 0.95f;
    _scrollEnabled = YES;
    _bounces = YES;
    _offsetMultiplier = 1.0f;
    _perspective = -1.0f/500.0f;
    _contentOffset = CGSizeZero;
    _viewpointOffset = CGSizeZero;
    _scrollSpeed = 1.0f;
    _bounceDistance = 1.0f;
    _stopAtItemBoundary = YES;
    _scrollToItemBoundary = YES;
    _ignorePerpendicularSwipes = YES;
    _centerItemWhenSelected = YES;
    
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    
#ifdef ICAROUSEL_IOS
        
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    panGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:panGesture];
    
#else
    
    [_contentView setWantsLayer:YES];
    
#endif
    
    [self addSubview:_contentView];
    
    if (_dataSource)
    {
        [self reloadData];
    }
}

#ifndef USING_CHAMELEON

- (id)initWithCoder:(NSCoder *)aDecoder
{   
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
        [self didMoveToSuperview]; 
    }
    return self;
}

#endif

#ifdef ICAROUSEL_IOS

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    return self;
}

#else

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    return self;
}

#endif

- (void)dealloc
{   
    [self stopAnimation];
}

- (void)setDataSource:(id<iCarouselDataSource>)dataSource
{
    if (_dataSource != dataSource)
    {
        _dataSource = dataSource;
        if (_dataSource)
        {
            [self reloadData];
        }
    }
}

- (void)setDelegate:(id<iCarouselDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegate = delegate;
        if (_delegate && _dataSource)
        {
            [self setNeedsLayout];
        }
    }
}

- (void)setType:(iCarouselType)type
{
    if (_type != type)
    {
        _type = type;
        [self layOutItemViews];
    }
}

- (void)setVertical:(BOOL)vertical
{
    if (_vertical != vertical)
    {
        _vertical = vertical;
        [self layOutItemViews];
    }
}

- (void)setScrollOffset:(CGFloat)scrollOffset
{
    if (_scrollOffset != scrollOffset)
    {
        _scrolling = NO;
        _startOffset = scrollOffset;
        _endOffset = scrollOffset;
        _scrollOffset = scrollOffset;
        [self didScroll];
    }
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    [self setScrollOffset:currentItemIndex];
}

- (void)setPerspective:(CGFloat)perspective
{
    if (_perspective != perspective)
    {
        _perspective = perspective;
        [self transformItemViews];
    }
}

- (void)setViewpointOffset:(CGSize)viewpointOffset
{
    if (!CGSizeEqualToSize(_viewpointOffset, viewpointOffset))
    {
        _viewpointOffset = viewpointOffset;
        [self transformItemViews];
    }
}

- (void)setContentOffset:(CGSize)contentOffset
{
    if (!CGSizeEqualToSize(_contentOffset, contentOffset))
    {
        _contentOffset = contentOffset;
        [self layOutItemViews];
    }
}

- (void)pushAnimationState:(BOOL)enabled
{
    [CATransaction begin];
    [CATransaction setDisableActions:!enabled];
}

- (void)popAnimationState
{
    [CATransaction commit];
}


#pragma mark -
#pragma mark View management

- (NSArray *)indexesForVisibleItems
{
    return [[_itemViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews
{
    NSArray *indexes = [self indexesForVisibleItems];
    return [_itemViews objectsForKeys:indexes notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSInteger)index
{
    return _itemViews[@(index)];
}

- (UIView *)currentItemView
{
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSInteger)indexOfItemView:(UIView *)view
{
    NSInteger index = [[_itemViews allValues] indexOfObject:view];
    if (index != NSNotFound)
    {
        return [[_itemViews allKeys][index] integerValue];
    }
    return NSNotFound;
}

- (NSInteger)indexOfItemViewOrSubview:(UIView *)view
{
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound && view != nil && view != _contentView)
    {
        return [self indexOfItemViewOrSubview:view.superview];
    }
    return index;
}

- (void)setItemView:(UIView *)view forIndex:(NSInteger)index
{
    _itemViews[@(index)] = view;
}

- (void)removeViewAtIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] - 1];
    for (NSNumber *number in [self indexesForVisibleItems])
    {
        NSInteger i = [number integerValue];
        if (i < index)
        {
            newItemViews[number] = _itemViews[number];
        }
        else if (i > index)
        {
            newItemViews[@(i - 1)] = _itemViews[number];
        }
    }
    self.itemViews = newItemViews;
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] + 1];
    for (NSNumber *number in [self indexesForVisibleItems])
    {
        NSInteger i = [number integerValue];
        if (i < index)
        {
            newItemViews[number] = _itemViews[number];
        }
        else
        {
            newItemViews[@(i + 1)] = _itemViews[number];
        }
    }
    if (view)
    {
        [self setItemView:view forIndex:index];
    }
    self.itemViews = newItemViews;
}


#pragma mark -
#pragma mark View layout

- (CGFloat)alphaForItemWithOffset:(CGFloat)offset
{
    CGFloat fadeMin = -INFINITY;
    CGFloat fadeMax = INFINITY;
    CGFloat fadeRange = 1.0f;
    CGFloat fadeMinAlpha = 0.0f;
    switch (_type)
    {
        case iCarouselTypeTimeMachine:
        {
            fadeMax = 0.0f;
            break;
        }
        case iCarouselTypeInvertedTimeMachine:
        {
            fadeMin = 0.0f;
            break;
        }
        default:
        {
            //do nothing
        }
    }
    fadeMin = [self valueForOption:iCarouselOptionFadeMin withDefault:fadeMin];
    fadeMax = [self valueForOption:iCarouselOptionFadeMax withDefault:fadeMax];
    fadeRange = [self valueForOption:iCarouselOptionFadeRange withDefault:fadeRange];
    fadeMinAlpha = [self valueForOption:iCarouselOptionFadeMinAlpha withDefault:fadeMinAlpha];

#ifdef ICAROUSEL_MACOS
    
    if (_vertical)
    {
        //invert
        offset = -offset;
    }
    
#endif
    
    CGFloat factor = 0.0f;
    if (offset > fadeMax)
    {
        factor = offset - fadeMax;
    }
    else if (offset < fadeMin)
    {
        factor = fadeMin - offset;
    }
    return 1.0f - fminf(factor, fadeRange) / fadeRange * (1.0f - fadeMinAlpha);
}

- (CGFloat)valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{    
    return [_delegate carousel:self valueForOption:option withDefault:value];
}

- (CATransform3D)transformForItemView:(UIView *)view withOffset:(CGFloat)offset
{   
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = _perspective;
    transform = CATransform3DTranslate(transform, -_viewpointOffset.width, -_viewpointOffset.height, 0.0f);

    //perform transform
    switch (_type)
    {
        case iCarouselTypeCustom:
        {
            return [_delegate carousel:self itemTransformForOffset:offset baseTransform:transform];
        }
        case iCarouselTypeLinear:
        {
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            if (_vertical)
            {
                return CATransform3DTranslate(transform, 0.0f, offset * _itemWidth * spacing, 0.0f);
            }
            else
            {
                return CATransform3DTranslate(transform, offset * _itemWidth * spacing, 0.0f, 0.0f);
            }
        }
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        {
            CGFloat count = [self circularCarouselItemCount];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat arc = [self valueForOption:iCarouselOptionArc withDefault:M_PI * 2.0f];
            CGFloat radius = [self valueForOption:iCarouselOptionRadius withDefault:fmaxf(_itemWidth * spacing / 2.0f, _itemWidth * spacing / 2.0f / tanf(arc/2.0f/count))];
            CGFloat angle = [self valueForOption:iCarouselOptionAngle withDefault:offset / count * arc];
            
            if (_type == iCarouselTypeInvertedRotary)
            {
                radius = -radius;
                angle = -angle;
            }
            
            if (_vertical)
            {
                return CATransform3DTranslate(transform, 0.0f, radius * sin(angle), radius * cos(angle) - radius);
            }
            else
            {
                return CATransform3DTranslate(transform, radius * sin(angle), 0.0f, radius * cos(angle) - radius);
            }
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
            CGFloat count = [self circularCarouselItemCount];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat arc = [self valueForOption:iCarouselOptionArc withDefault:M_PI * 2.0f];
            CGFloat radius = [self valueForOption:iCarouselOptionRadius withDefault:fmaxf(0.01f, _itemWidth * spacing / 2.0f / tanf(arc/2.0f/count))];
            CGFloat angle = [self valueForOption:iCarouselOptionAngle withDefault:offset / count * arc];
            
            if (_type == iCarouselTypeInvertedCylinder)
            {
                radius = -radius;
                angle = -angle;
            }
            
            if (_vertical)
            {
                transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
                transform = CATransform3DRotate(transform, angle, -1.0f, 0.0f, 0.0f);
                return CATransform3DTranslate(transform, 0.0f, 0.0f, radius + 0.01f);
            }
            else
            {
                transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
                transform = CATransform3DRotate(transform, angle, 0.0f, 1.0f, 0.0f);
                return CATransform3DTranslate(transform, 0.0f, 0.0f, radius + 0.01f);
            }
        }
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            CGFloat count = [self circularCarouselItemCount];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat arc = [self valueForOption:iCarouselOptionArc withDefault:M_PI * 2.0f];
            CGFloat radius = [self valueForOption:iCarouselOptionRadius withDefault:_itemWidth * spacing * count / arc];
            CGFloat angle = [self valueForOption:iCarouselOptionAngle withDefault:arc / count];
            
            if (_type == iCarouselTypeInvertedWheel)
            {
                radius = -radius;
                angle = -angle;
            }
            
            if (_vertical)
            {
                transform = CATransform3DTranslate(transform, -radius, 0.0f, 0.0f);
                transform = CATransform3DRotate(transform, angle * offset, 0.0f, 0.0f, 1.0f);
                return CATransform3DTranslate(transform, radius, 0.0f, offset * 0.01f);
            }
            else
            {
                transform = CATransform3DTranslate(transform, 0.0f, radius, 0.0f);
                transform = CATransform3DRotate(transform, angle * offset, 0.0f, 0.0f, 1.0f);
                return CATransform3DTranslate(transform, 0.0f, -radius, offset * 0.01f);
            }
        }
        case iCarouselTypeCoverFlow:
        case iCarouselTypeCoverFlow2:
        {
            CGFloat tilt = [self valueForOption:iCarouselOptionTilt withDefault:0.9f];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:0.25f];
            CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
            
            if (_type == iCarouselTypeCoverFlow2)
            {
                if (_toggle >= 0.0f)
                {
                    if (offset <= -0.5f)
                    {
                        clampedOffset = -1.0f;
                    }
                    else if (offset <= 0.5f)
                    {
                        clampedOffset = -_toggle;
                    }
                    else if (offset <= 1.5f)
                    {
                        clampedOffset = 1.0f - _toggle;
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
                        clampedOffset = -_toggle;
                    }
                    else if (offset > -1.5f)
                    {
                        clampedOffset = - 1.0f - _toggle;
                    }
                }
            }
            
            CGFloat x = (clampedOffset * 0.5f * tilt + offset * spacing) * _itemWidth;
            CGFloat z = fabsf(clampedOffset) * -_itemWidth * 0.5f;
            
            if (_vertical)
            {
                transform = CATransform3DTranslate(transform, 0.0f, x, z);
                return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, -1.0f, 0.0f, 0.0f);
            }
            else
            {
                transform = CATransform3DTranslate(transform, x, 0.0f, z);
                return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0.0f, 1.0f, 0.0f);
            }
        }
        case iCarouselTypeTimeMachine:
        case iCarouselTypeInvertedTimeMachine:
        {
            CGFloat tilt = [self valueForOption:iCarouselOptionTilt withDefault:0.3f];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            
            if (_type == iCarouselTypeInvertedTimeMachine)
            {
                tilt = -tilt;
                offset = -offset;
            }
            
            if (_vertical)
            {
                
#ifdef ICAROUSEL_MACOS
                
                //invert again
                tilt = -tilt;
                offset = -offset;
                
#endif
                return CATransform3DTranslate(transform, 0.0f, offset * _itemWidth * tilt, offset * _itemWidth * spacing);
            }
            else
            {
                return CATransform3DTranslate(transform, offset * _itemWidth * tilt, 0.0f, offset * _itemWidth * spacing);
            }
        }
        default:
        {
            //shouldn't ever happen
            return CATransform3DIdentity;
        }
    }
}

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self)
{
    //compare depths
    CATransform3D t1 = view1.superview.layer.transform;
    CATransform3D t2 = view2.superview.layer.transform;
    CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    CGFloat difference = z1 - z2;
    
    //if depths are equal, compare distance from current view
    if (difference == 0.0f)
    {
        CATransform3D t3 = [self currentItemView].superview.layer.transform;
        if (self.vertical)
        {
            CGFloat y1 = t1.m12 + t1.m22 + t1.m32 + t1.m42;
            CGFloat y2 = t2.m12 + t2.m22 + t2.m32 + t2.m42;
            CGFloat y3 = t3.m12 + t3.m22 + t3.m32 + t3.m42;
            difference = fabsf(y2 - y3) - fabsf(y1 - y3);
        }
        else
        {
            CGFloat x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
            CGFloat x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
            CGFloat x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
            difference = fabsf(x2 - x3) - fabsf(x1 - x3);
        }
    }
    return (difference < 0.0f)? NSOrderedAscending: NSOrderedDescending;
}

#ifdef ICAROUSEL_IOS

- (void)depthSortViews
{
    for (UIView *view in [[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self])
    {
        [_contentView bringSubviewToFront:view.superview];
    }
}

#else

- (void)setNeedsLayout
{
    [self setNeedsLayout:YES];
}

- (void)depthSortViews
{
    //does nothing on Mac OS
}

#endif

- (CGFloat)offsetForItemAtIndex:(NSInteger)index
{
    //calculate relative position
    CGFloat offset = index - _scrollOffset;
    if (_wrapEnabled)
    {
        if (offset > _numberOfItems/2)
        {
            offset -= _numberOfItems;
        }
        else if (offset < -_numberOfItems/2)
        {
            offset += _numberOfItems;
        }
    }
    
    //handle special case for one item
    if (_numberOfItems + _numberOfPlaceholdersToShow == 1)
    {
        offset = 0.0f;
    }
    
#ifdef ICAROUSEL_MACOS
    
    if (_vertical)
    {
        //invert transform
        offset = -offset;
    }
    
#endif
    
    return offset;
}

- (UIView *)containView:(UIView *)view
{
    //set item width
    if (!_itemWidth)
    {
        _itemWidth = _vertical? view.bounds.size.height: view.bounds.size.width;
    }
    
    //set container frame
    CGRect frame = view.bounds;
    frame.size.width = _vertical? frame.size.width: _itemWidth;
    frame.size.height = _vertical? _itemWidth: frame.size.height;
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    
#ifdef ICAROUSEL_IOS
    
    //add tap gesture recogniser
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [containerView addGestureRecognizer:tapGesture];
    
#else
    
    //clipping works differently on Mac OS
    [containerView setBoundsSize:view.frame.size];

#endif
    
    //set view frame
    frame = view.frame;
    frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0f;
    frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0f;
    view.frame = frame;
    [containerView addSubview:view];
    
    return containerView;
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index
{
    //calculate offset
    CGFloat offset = [self offsetForItemAtIndex:index];

#ifdef ICAROUSEL_IOS
    
    //center view
    view.superview.center = CGPointMake(self.bounds.size.width/2.0f + _contentOffset.width,
                                        self.bounds.size.height/2.0f + _contentOffset.height);
    
    //update alpha
    view.superview.alpha = [self alphaForItemWithOffset:offset];
    
#else
    
    //center view
    [view.superview setFrameOrigin:NSMakePoint(self.bounds.size.width/2.0f + _contentOffset.width,
                                               self.bounds.size.height/2.0f + _contentOffset.height)];
    view.superview.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    //update alpha
    [view.superview setAlphaValue:[self alphaForItemWithOffset:offset]];
    
#endif
    
    //special-case logic for iCarouselTypeCoverFlow2
    CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
    if (_decelerating || (_scrolling && !_didDrag) || (_scrollOffset - [self clampedOffset:_scrollOffset]) != 0.0f)
    {
        if (offset > 0)
        {
            _toggle = (offset <= 0.5f)? -clampedOffset: (1.0f - clampedOffset);
        }
        else
        {
            _toggle = (offset > -0.5f)? -clampedOffset: (- 1.0f - clampedOffset);
        }
    }
    
    //calculate transform
    CATransform3D transform = [self transformForItemView:view withOffset:offset];
    
    //transform view
    view.superview.layer.transform = transform;
    
    //backface culling
    BOOL showBackfaces = view.layer.doubleSided;
    if (showBackfaces)
    {
        switch (_type)
        {
            case iCarouselTypeInvertedCylinder:
            {
                showBackfaces = NO;
                break;
            }
            default:
            {
                showBackfaces = YES;
                break;
            }
        }
    }
    showBackfaces = !![self valueForOption:iCarouselOptionShowBackfaces withDefault:showBackfaces];
    
    //we can't just set the layer.doubleSided property because it doesn't block interaction
    //instead we'll calculate if the view is front-facing based on the transform
    view.superview.hidden = !(showBackfaces ?: (transform.m33 > 0.0f));
}

- (void)layoutSubviews
{
    _contentView.frame = self.bounds;
    [self layOutItemViews];
}

#ifdef ICAROUSEL_MACOS

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [self pushAnimationState:NO];
    [self layoutSubviews];
    [self popAnimationState];
}

#endif

- (void)transformItemViews
{
    for (NSNumber *number in _itemViews)
    {
        NSInteger index = [number integerValue];
        UIView *view = _itemViews[number];
        [self transformItemView:view atIndex:index];
        
#ifdef ICAROUSEL_IOS
        
        view.userInteractionEnabled = (!_centerItemWhenSelected || index == self.currentItemIndex);
#endif
        
    }
}

- (void)updateItemWidth
{
    _itemWidth = [_delegate carouselItemWidth:self] ?: _itemWidth;
    if (_numberOfItems > 0)
    {
        if ([_itemViews count] == 0)
        {
            [self loadViewAtIndex:0];
        }
    }
    else if (_numberOfPlaceholders > 0)
    {
        if ([_itemViews count] == 0)
        {
            [self loadViewAtIndex:-1];
        }
    }
}

- (void)updateNumberOfVisibleItems
{
    //get number of visible items
    switch (_type)
    {
        case iCarouselTypeLinear:
        {
            //exact number required to fill screen
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat width = _vertical ? self.bounds.size.height: self.bounds.size.width;
            CGFloat itemWidth = _itemWidth * spacing;
            _numberOfVisibleItems = ceilf(width / itemWidth) + 2;
            break;
        }
        case iCarouselTypeCoverFlow:
        case iCarouselTypeCoverFlow2:
        {
            //exact number required to fill screen
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:0.25f];
            CGFloat width = _vertical ? self.bounds.size.height: self.bounds.size.width;
            CGFloat itemWidth = _itemWidth * spacing;
            _numberOfVisibleItems = ceilf(width / itemWidth) + 2;
            break;
        }
        case iCarouselTypeRotary:
        case iCarouselTypeCylinder:
        {
            //based on count value
            _numberOfVisibleItems = [self circularCarouselItemCount];
            break;
        }
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeInvertedCylinder:
        {
            //TODO: improve this
            _numberOfVisibleItems = ceilf([self circularCarouselItemCount] / 2.0f);
            break;
        }
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            //TODO: improve this
            CGFloat count = [self circularCarouselItemCount];
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat arc = [self valueForOption:iCarouselOptionArc withDefault:M_PI * 2.0f];
            CGFloat radius = [self valueForOption:iCarouselOptionRadius withDefault:_itemWidth * spacing * count / arc];
            if (radius - _itemWidth / 2.0f < MIN(self.bounds.size.width, self.bounds.size.height) / 2.0f)
            {
                _numberOfVisibleItems = count;
            }
            else
            {
                _numberOfVisibleItems = ceilf(count / 2.0f) + 1;
            }
            break;
        }
        case iCarouselTypeTimeMachine:
        case iCarouselTypeInvertedTimeMachine:
        case iCarouselTypeCustom:
        default:
        {
            //slightly arbitrary number, chosen for performance reasons
            _numberOfVisibleItems = MAX_VISIBLE_ITEMS;
            break;
        }
    }
    _numberOfVisibleItems = MIN(MAX_VISIBLE_ITEMS, _numberOfVisibleItems);
    _numberOfVisibleItems = [self valueForOption:iCarouselOptionVisibleItems withDefault:_numberOfVisibleItems];
    _numberOfVisibleItems = MAX(0, MIN(_numberOfVisibleItems, _numberOfItems + _numberOfPlaceholdersToShow));

}

- (NSInteger)circularCarouselItemCount
{
    NSInteger count = 0;
    switch (_type)
    {
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            //slightly arbitrary number, chosen for aesthetic reasons
            CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0f];
            CGFloat width = _vertical ? self.bounds.size.height: self.bounds.size.width;
            count = MIN(MAX_VISIBLE_ITEMS, MAX(12, ceilf(width / (spacing * _itemWidth)) * M_PI));
            count = MIN(_numberOfItems + _numberOfPlaceholdersToShow, count);
            break;
        }
        default:
        {
            //not used for non-circular carousels
            return _numberOfItems + _numberOfPlaceholdersToShow;
            break;
        }
    }
    return [self valueForOption:iCarouselOptionCount withDefault:count];
}

- (void)layOutItemViews
{
    //bail out if not set up yet
    if (!_dataSource || !_contentView)
    {
        return;
    }

    //update wrap
    switch (_type)
    {
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        case iCarouselTypeWheel:
        case iCarouselTypeInvertedWheel:
        {
            _wrapEnabled = YES;
            break;
        }
        default:
        {
            _wrapEnabled = NO;
            break;
        }
    }
    _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
    
    //no placeholders on wrapped carousels
    _numberOfPlaceholdersToShow = _wrapEnabled? 0: _numberOfPlaceholders;
    
    //set item width
    [self updateItemWidth];
    
    //update number of visible items
    [self updateNumberOfVisibleItems];
    
    //prevent false index changed event
    _previousItemIndex = self.currentItemIndex;
    
    //update offset multiplier
    switch (_type)
    {
        case iCarouselTypeCoverFlow:
        case iCarouselTypeCoverFlow2:
        {
            _offsetMultiplier = 2.0f;
            break;
        }
        default:
        {
            _offsetMultiplier = 1.0f;
            break;
        }
    }
    _offsetMultiplier = [self valueForOption:iCarouselOptionOffsetMultiplier withDefault:_offsetMultiplier];

    //align
    if (!_scrolling && !_decelerating)
    {
        if (_scrollToItemBoundary)
        {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        }
        else
        {
            _scrollOffset = [self clampedOffset:_scrollOffset];
        }
    }
    
    //update views
    [self didScroll];
}


#pragma mark -
#pragma mark View queing

- (void)queueItemView:(UIView *)view
{
    if (view)
    {
        [_itemViewPool addObject:view];
    }
}

- (void)queuePlaceholderView:(UIView *)view
{
    if (view)
    {
        [_placeholderViewPool addObject:view];
    }
}

- (UIView *)dequeueItemView
{
    UIView *view = [_itemViewPool anyObject];
    if (view)
    {
        [_itemViewPool removeObject:view];
    }
    return view;
}

- (UIView *)dequeuePlaceholderView
{
    UIView *view = [_placeholderViewPool anyObject];
    if (view)
    {
        [_placeholderViewPool removeObject:view];
    }
    return view;
}


#pragma mark -
#pragma mark View loading

- (UIView *)loadViewAtIndex:(NSInteger)index withContainerView:(UIView *)containerView
{
    [self pushAnimationState:NO];
    
    UIView *view = nil;
    if (index < 0)
    {
        view = [_dataSource carousel:self placeholderViewAtIndex:(int)ceilf((CGFloat)_numberOfPlaceholdersToShow/2.0f) + index reusingView:[self dequeuePlaceholderView]];
    }
    else if (index >= _numberOfItems)
    {
        view = [_dataSource carousel:self placeholderViewAtIndex:_numberOfPlaceholdersToShow/2.0f + index - _numberOfItems reusingView:[self dequeuePlaceholderView]];
    }
    else
    {
        view = [_dataSource carousel:self viewForItemAtIndex:index reusingView:[self dequeueItemView]];
    }
    
    if (view == nil)
    {
        view = [[UIView alloc] init];
    }
    [self setItemView:view forIndex:index];
    if (containerView)
    {
        //get old item view
        UIView *oldItemView = [containerView.subviews lastObject];
        if (index < 0 || index >= _numberOfItems)
        {
            [self queuePlaceholderView:oldItemView];
        }
        else
        {
            [self queueItemView:oldItemView];
        }
        
        //set container frame
        CGRect frame = containerView.bounds;
        if(_vertical) {
            frame.size.width = view.frame.size.width;
            frame.size.height = MIN(_itemWidth, view.frame.size.height);
        } else {
            frame.size.width = MIN(_itemWidth, view.frame.size.width);
            frame.size.height = view.frame.size.height;
        }
        containerView.bounds = frame;
        
#ifdef ICAROUSEL_MACOS
        
        //clipping works differently on Mac OS
        [containerView setBoundsSize:view.frame.size];
        
#endif
        
        //set view frame
        frame = view.frame;
        frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0f;
        frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0f;
        view.frame = frame;
        
        //switch views
        [oldItemView removeFromSuperview];
        [containerView addSubview:view];
    }
    else
    {
        [_contentView addSubview:[self containView:view]];
    }
    [self transformItemView:view atIndex:index];
    
    [self popAnimationState];
    
    return view;
}

- (UIView *)loadViewAtIndex:(NSInteger)index
{
    return [self loadViewAtIndex:index withContainerView:nil];
}

- (void)loadUnloadViews
{
    //set item width
    [self updateItemWidth];
    
    //update number of visible items
    [self updateNumberOfVisibleItems];
    
    //calculate visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:_numberOfVisibleItems];
    NSInteger min = -(int)ceilf((CGFloat)_numberOfPlaceholdersToShow/2.0f);
    NSInteger max = _numberOfItems - 1 + _numberOfPlaceholdersToShow/2;
    NSInteger offset = self.currentItemIndex - _numberOfVisibleItems/2;
    if (!_wrapEnabled)
    {
        offset = MAX(min, MIN(max - _numberOfVisibleItems + 1, offset));
    }
    for (NSInteger i = 0; i < _numberOfVisibleItems; i++)
    {
        NSInteger index = i + offset;
        if (_wrapEnabled)
        {
            index = [self clampedIndex:index];
        }
        CGFloat alpha = [self alphaForItemWithOffset:[self offsetForItemAtIndex:index]];
        if (alpha)
        {
            //only add views with alpha > 0
            [visibleIndices addObject:@(index)];
        }
    }
    
    //remove offscreen views
    for (NSNumber *number in [_itemViews allKeys])
    {
        if (![visibleIndices containsObject:number])
        {
            UIView *view = _itemViews[number];
            if ([number integerValue] < 0 || [number integerValue] >= _numberOfItems)
            {
                [self queuePlaceholderView:view];
            }
            else
            {
                [self queueItemView:view];
            }
            [view.superview removeFromSuperview];
            [(NSMutableDictionary *)_itemViews removeObjectForKey:number];
        }
    }
    
    //add onscreen views
    for (NSNumber *number in visibleIndices)
    {
        UIView *view = _itemViews[number];
        if (view == nil)
        {
            [self loadViewAtIndex:[number integerValue]];
        }
    }
}

- (void)reloadData
{    
    //remove old views
    for (UIView *view in [_itemViews allValues])
    {
        [view.superview removeFromSuperview];
    }
    
    //bail out if not set up yet
    if (!_dataSource || !_contentView)
    {
        return;
    }
    
    //get number of items and placeholders
    _numberOfVisibleItems = 0;
    _numberOfItems = [_dataSource numberOfItemsInCarousel:self];
    _numberOfPlaceholders = [_dataSource numberOfPlaceholdersInCarousel:self];

    //reset view pools
    self.itemViews = [NSMutableDictionary dictionary];
    self.itemViewPool = [NSMutableSet set];
    self.placeholderViewPool = [NSMutableSet setWithCapacity:_numberOfPlaceholders];
    
    //layout views
    [self setNeedsLayout];
    
    //fix scroll offset
    if (_numberOfItems > 0 && _scrollOffset < 0.0f)
    {
        [self scrollToItemAtIndex:0 animated:(_numberOfPlaceholders > 0)];
    }
}


#pragma mark -
#pragma mark Scrolling

- (NSInteger)clampedIndex:(NSInteger)index
{
    if (_wrapEnabled)
    {
        return _numberOfItems? (index - floorf((CGFloat)index / (CGFloat)_numberOfItems) * _numberOfItems): 0;
    }
    else
    {
        return MIN(MAX(0, index), MAX(0, _numberOfItems - 1));
    }
}

- (CGFloat)clampedOffset:(CGFloat)offset
{
    if (_wrapEnabled)
    {
        return _numberOfItems? (offset - floorf(offset / (CGFloat)_numberOfItems) * _numberOfItems): 0.0f;
    }
    else
    {
        return fminf(fmaxf(0.0f, offset), fmaxf(0.0f, (CGFloat)_numberOfItems - 1.0f));
    }
}

- (NSInteger)currentItemIndex
{   
    return [self clampedIndex:roundf(_scrollOffset)];
}

- (NSInteger)minScrollDistanceFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSInteger directDistance = toIndex - fromIndex;
    if (_wrapEnabled)
    {
        NSInteger wrappedDistance = MIN(toIndex, fromIndex) + _numberOfItems - MAX(toIndex, fromIndex);
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
    if (_wrapEnabled)
    {
        CGFloat wrappedDistance = fminf(toOffset, fromOffset) + _numberOfItems - fmaxf(toOffset, fromOffset);
        if (fromOffset < toOffset)
        {
            wrappedDistance = -wrappedDistance;
        }
        return (fabsf(directDistance) <= fabsf(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (void)scrollByOffset:(CGFloat)offset duration:(NSTimeInterval)duration
{
    if (duration > 0.0)
    {
        _decelerating = NO;
        _scrolling = YES;
        _startTime = CACurrentMediaTime();
        _startOffset = _scrollOffset;
        _scrollDuration = duration;
        _previousItemIndex = roundf(_scrollOffset);
        _endOffset = _startOffset + offset;
        if (!_wrapEnabled)
        {
            _endOffset = [self clampedOffset:_endOffset];
        }
        [_delegate carouselWillBeginScrollingAnimation:self];
        [self startAnimation];
    }
    else
    {
        self.scrollOffset += offset;
    }
}

- (void)scrollToOffset:(CGFloat)offset duration:(NSTimeInterval)duration
{
    [self scrollByOffset:[self minScrollDistanceFromOffset:_scrollOffset toOffset:offset] duration:duration];
}

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration
{
    if (duration > 0.0)
    {
        CGFloat offset = 0.0f;
        if (itemCount > 0)
        {
            offset = (floorf(_scrollOffset) + itemCount) - _scrollOffset;
        }
        else if (itemCount < 0)
        {
            offset = (ceilf(_scrollOffset) + itemCount) - _scrollOffset;
        }
        else
        {
            offset = roundf(_scrollOffset) - _scrollOffset;
        }
        [self scrollByOffset:offset duration:duration];
    }
    else
    {
        self.scrollOffset = [self clampedIndex:_previousItemIndex + itemCount];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration
{
    [self scrollToOffset:index duration:duration];
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
        
#ifdef ICAROUSEL_IOS
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:itemView.superview];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        [self performSelector:@selector(queueItemView:) withObject:itemView afterDelay:0.1];
        itemView.superview.layer.opacity = 0.0f;
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelay:0.1];
        [UIView setAnimationDuration:INSERT_DURATION];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(depthSortViews)];
        [self removeViewAtIndex:index];
        _numberOfItems --;
        _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
        [self updateNumberOfVisibleItems];
        _scrollOffset = self.currentItemIndex;
        [self didScroll];
        [UIView commitAnimations];
        
#else
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.1];
        [CATransaction setCompletionBlock:^{
            [self queueItemView:itemView];
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
        _numberOfItems --;
        _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
        _scrollOffset = self.currentItemIndex;
        [self didScroll];
        [CATransaction commit];
        
#endif
        
    }
    else
    {
        [self pushAnimationState:NO];
        [self queueItemView:itemView];
        [itemView.superview removeFromSuperview];
        [self removeViewAtIndex:index];
        _numberOfItems --;
        _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
        _scrollOffset = self.currentItemIndex;
        [self didScroll];
        [self depthSortViews];
        [self popAnimationState];
    }
}

- (void)fadeInItemView:(UIView *)itemView
{
    NSInteger index = [self indexOfItemView:itemView];
    CGFloat offset = [self offsetForItemAtIndex:index];
    CGFloat alpha = [self alphaForItemWithOffset:offset];
    
#ifdef ICAROUSEL_IOS
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.1f];
    itemView.superview.layer.opacity = alpha;
    [UIView commitAnimations];
    
#else
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.1f];
    itemView.superview.layer.opacity = alpha;
    [CATransaction commit];
    
#endif
    
}

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    _numberOfItems ++;
    _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
    [self updateNumberOfVisibleItems];
    
    index = [self clampedIndex:index];
    [self insertView:nil atIndex:index];
    UIView *itemView = [self loadViewAtIndex:index];
    itemView.superview.layer.opacity = 0.0f;
    
    if (_itemWidth == 0)
    {
        [self updateItemWidth];
    }
    
    if (animated)
    {
        
#ifdef ICAROUSEL_IOS
        
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
        [self pushAnimationState:NO];
        [self transformItemViews]; 
        [self popAnimationState];
        itemView.superview.layer.opacity = 1.0f; 
    }
    
    if (_scrollOffset < 0.0f)
    {
        [self scrollToItemAtIndex:0 animated:(animated && _numberOfPlaceholders)];
    }
}

- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    //get container view
    UIView *containerView = [[self itemViewAtIndex:index] superview];
    if (containerView)
    {
        if (animated)
        {
            //fade transition
            CATransition *transition = [CATransition animation];
            transition.duration = INSERT_DURATION;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [containerView.layer addAnimation:transition forKey:nil];
        }
        
        //reload view
        [self loadViewAtIndex:index withContainerView:containerView];
    }
}

#pragma mark -
#pragma mark Animation

- (void)startAnimation
{
    if (!_timer)
    {
        self.timer = [NSTimer timerWithTimeInterval:1.0/60.0
                                             target:self
                                           selector:@selector(step)
                                           userInfo:nil
                                            repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];

#ifdef ICAROUSEL_IOS
        
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];

#endif
        
    }
}

- (void)stopAnimation
{
    [_timer invalidate];
    _timer = nil;
}

- (CGFloat)decelerationDistance
{
    CGFloat acceleration = -_startVelocity * DECELERATION_MULTIPLIER * (1.0f - _decelerationRate);
    return -powf(_startVelocity, 2.0f) / (2.0f * acceleration);
}

- (BOOL)shouldDecelerate
{
    return (fabsf(_startVelocity) > SCROLL_SPEED_THRESHOLD) &&
    (fabsf([self decelerationDistance]) > DECELERATE_THRESHOLD);
}

- (BOOL)shouldScroll
{
    return (fabsf(_startVelocity) > SCROLL_SPEED_THRESHOLD) &&
    (fabsf(_scrollOffset - self.currentItemIndex) > SCROLL_DISTANCE_THRESHOLD);
}

- (void)startDecelerating
{
    CGFloat distance = [self decelerationDistance];
    _startOffset = _scrollOffset;
    _endOffset = _startOffset + distance;
    if (_pagingEnabled)
    {
        if (distance > 0.0f)
        {
            _endOffset = ceilf(_startOffset);
        }
        else
        {
            _endOffset = floorf(_startOffset);
        }
    }
    else if (_stopAtItemBoundary)
    {
        if (distance > 0.0f)
        {
            _endOffset = ceilf(_endOffset);
        }
        else
        {
            _endOffset = floorf(_endOffset);
        }
    }
    if (!_wrapEnabled)
    {
        if (_bounces)
        {
            _endOffset = fmaxf(-_bounceDistance, fminf(_numberOfItems - 1.0f + _bounceDistance, _endOffset));
        }
        else
        {
            _endOffset = [self clampedOffset:_endOffset];
        }
    }
    distance = _endOffset - _startOffset;
    
    _startTime = CACurrentMediaTime();
    _scrollDuration = fabsf(distance) / fabsf(0.5f * _startVelocity);   
    
    if (distance != 0.0f)
    {
        _decelerating = YES;
        [self startAnimation];
    }
}

- (CGFloat)easeInOut:(CGFloat)time
{
    return (time < 0.5f)? 0.5f * powf(time * 2.0f, 3.0f): 0.5f * powf(time * 2.0f - 2.0f, 3.0f) + 1.0f;
}

- (void)step
{
    [self pushAnimationState:NO];
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if (_toggle != 0.0f)
    {
        NSTimeInterval toggleDuration = _startVelocity? fminf(1.0, fmaxf(0.0, 1.0 / fabsf(_startVelocity))): 1.0;
        toggleDuration = MIN_TOGGLE_DURATION + (MAX_TOGGLE_DURATION - MIN_TOGGLE_DURATION) * toggleDuration;
        NSTimeInterval time = fminf(1.0f, (currentTime - _toggleTime) / toggleDuration);
        CGFloat delta = [self easeInOut:time];
        _toggle = (_toggle < 0.0f)? (delta - 1.0f): (1.0f - delta);
        [self didScroll];
    }
    
    if (_scrolling)
    {
        NSTimeInterval time = fminf(1.0f, (currentTime - _startTime) / _scrollDuration);
        CGFloat delta = [self easeInOut:time];
        _scrollOffset = _startOffset + (_endOffset - _startOffset) * delta;
        [self didScroll];
        if (time == 1.0f)
        {
            _scrolling = NO;
            [self depthSortViews];
            [self pushAnimationState:YES];
            [_delegate carouselDidEndScrollingAnimation:self];
            [self popAnimationState];
        }
    }
    else if (_decelerating)
    {
        CGFloat time = fminf(_scrollDuration, currentTime - _startTime);
        CGFloat acceleration = -_startVelocity/_scrollDuration;
        CGFloat distance = _startVelocity * time + 0.5f * acceleration * powf(time, 2.0f);
        _scrollOffset = _startOffset + distance;
        
        [self didScroll];
        if (time == (CGFloat)_scrollDuration)
        {
            _decelerating = NO;
            [self pushAnimationState:YES];
            [_delegate carouselDidEndDecelerating:self];
            [self popAnimationState];
            if (_scrollToItemBoundary || (_scrollOffset - [self clampedOffset:_scrollOffset]) != 0.0f)
            {
                if (fabsf(_scrollOffset - self.currentItemIndex) < 0.01f)
                {
                    //call scroll to trigger events for legacy support reasons
                    //even though technically we don't need to scroll at all
                    [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                }
                else
                {
                    [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                }
            }
            else
            {
                CGFloat difference = (CGFloat)self.currentItemIndex - _scrollOffset;
                if (difference > 0.5)
                {
                    difference = difference - 1.0f;
                }
                else if (difference < -0.5)
                {
                    difference = 1.0 + difference;
                }
                _toggleTime = currentTime - MAX_TOGGLE_DURATION * fabsf(difference);
                _toggle = fmaxf(-1.0f, fminf(1.0f, -difference));
            }
        }
    }
    else if (_toggle == 0.0f)
    {
        [self stopAnimation];
    }
    
    [self popAnimationState];
}

//for iOS
- (void)didMoveToSuperview
{
    if (self.superview)
    {
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
    if (_wrapEnabled || !_bounces)
    {
        _scrollOffset = [self clampedOffset:_scrollOffset];
    }
    else
    {
        CGFloat min = -_bounceDistance;
        CGFloat max = fmaxf(_numberOfItems - 1, 0.0f) + _bounceDistance;
        if (_scrollOffset < min)
        {
            _scrollOffset = min;
            _startVelocity = 0.0f;
        }
        else if (_scrollOffset > max)
        {
            _scrollOffset = max;
            _startVelocity = 0.0f;
        }
    }
    
    //check if index has changed
    NSInteger currentIndex = roundf(_scrollOffset);
    NSInteger difference = [self minScrollDistanceFromIndex:_previousItemIndex toIndex:currentIndex];
    if (difference)
    {
        _toggleTime = CACurrentMediaTime();
        _toggle = fmaxf(-1.0f, fminf(1.0f, -(CGFloat)difference));
        
#ifdef ICAROUSEL_MACOS
        
        if (_vertical)
        {
            //invert toggle
            _toggle = -_toggle;
        }
        
#endif
        
        [self startAnimation];
    }
    
    [self loadUnloadViews];    
    [self transformItemViews];
    
    [self pushAnimationState:YES];
    [_delegate carouselDidScroll:self];
    [self popAnimationState];
    
    //notify delegate of change index
    if ([self clampedIndex:_previousItemIndex] != self.currentItemIndex)
    {
        [self pushAnimationState:YES];
        [_delegate carouselCurrentItemIndexDidChange:self];
        [self popAnimationState];
    }

    //update previous index
    _previousItemIndex = currentIndex;
} 


#ifdef ICAROUSEL_IOS


#pragma mark -
#pragma mark Gestures and taps

- (NSInteger)viewOrSuperviewIndex:(UIView *)view
{
    if (view == nil || view == _contentView)
    {
        return NSNotFound;
    }
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound)
    {
        return [self viewOrSuperviewIndex:view.superview];
    }
    return index;
}

- (BOOL)viewOrSuperview:(UIView *)view implementsSelector:(SEL)selector
{
    //thanks to @mattjgalloway and @shaps for idea
    //https://gist.github.com/mattjgalloway/6279363
    //https://gist.github.com/shaps80/6279008
    
    Class class = [view class];
	while (class && class != [UIView class])
    {
		int unsigned numberOfMethods;
		Method *methods = class_copyMethodList(class, &numberOfMethods);
		for (int i = 0; i < numberOfMethods; i++)
        {
			if (method_getName(methods[i]) == selector)
            {
				return YES;
			}
		}
		class = [class superclass];
	}
    
    if (view.superview && view.superview != self.contentView)
    {
        return [self viewOrSuperview:view.superview implementsSelector:selector];
    }
    
	return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index == NSNotFound && _centerItemWhenSelected)
        {
            //view is a container view
            index = [self viewOrSuperviewIndex:[touch.view.subviews lastObject]];
        }
        if (index != NSNotFound)
        {
            if (_delegate && ![_delegate carousel:self shouldSelectItemAtIndex:index])
            {
                return NO;
            }
            else if ([self viewOrSuperview:touch.view implementsSelector:@selector(touchesBegan:withEvent:)])
            {
                return NO;
            }
        }
    }
    else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]])
    {
        if (!_alwaysReceivePanGestureTouches && (!_scrollEnabled || [self viewOrSuperview:touch.view implementsSelector:@selector(touchesMoved:withEvent:)]))
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
        if (_ignorePerpendicularSwipes)
        {
            if (_vertical)
            {
                return fabsf(translation.x) <= fabsf(translation.y);
            }
            else
            {
                return fabsf(translation.x) >= fabsf(translation.y);
            }
        }
    }
    return YES;
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    NSInteger index = [self indexOfItemView:[tapGesture.view.subviews lastObject]];
    if (_centerItemWhenSelected && index != self.currentItemIndex)
    {
        [self scrollToItemAtIndex:index animated:YES];
    }
    [_delegate carousel:self didSelectItemAtIndex:index];
}

- (void)didPan:(UIPanGestureRecognizer *)panGesture
{
    if (_scrollEnabled)
    {
        switch (panGesture.state)
        {
            case UIGestureRecognizerStateBegan:
            {
                _dragging = YES;
                _scrolling = NO;
                _decelerating = NO;
                _previousTranslation = _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                [_delegate carouselWillBeginDragging:self];
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            {
                _dragging = NO;
                _didDrag = YES;
                if ([self shouldDecelerate])
                {
                    _didDrag = NO;
                    [self startDecelerating];
                }
                
                [self pushAnimationState:YES];
                [_delegate carouselDidEndDragging:self willDecelerate:_decelerating];
                [self popAnimationState];
                
                if (!_decelerating && (_scrollToItemBoundary || (_scrollOffset - [self clampedOffset:_scrollOffset]) != 0.0f))
                {
                    if (fabsf(_scrollOffset - self.currentItemIndex) < 0.01f)
                    {
                        //call scroll to trigger events for legacy support reasons
                        //even though technically we don't need to scroll at all
                        [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                    }
                    else if ([self shouldScroll])
                    {
                        NSInteger direction = (int)(_startVelocity / fabsf(_startVelocity));
                        [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
                    }
                    else
                    {
                        [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                    }
                }
                else
                {
                    [self pushAnimationState:YES];
                    [_delegate carouselWillBeginDecelerating:self];
                    [self popAnimationState];
                }
                break;
            }
            default:
            {
                CGFloat translation = (_vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x) - _previousTranslation;
                CGFloat factor = 1.0f;
                if (!_wrapEnabled && _bounces)
                {
                    factor = 1.0f - fminf(fabsf(_scrollOffset - [self clampedOffset:_scrollOffset]), _bounceDistance) / _bounceDistance;
                }
                
                _previousTranslation = _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                _startVelocity = -(_vertical? [panGesture velocityInView:self].y: [panGesture velocityInView:self].x) * factor * _scrollSpeed / _itemWidth;
                _scrollOffset -= translation * factor * _offsetMultiplier / _itemWidth;
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
    _didDrag = NO;
    _startVelocity = 0.0f;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    _didDrag = YES;
    if (_scrollEnabled)
    {
        if (!_dragging)
        {
            _dragging = YES;
            [_delegate carouselWillBeginDragging:self];
        }
        _scrolling = NO;
        _decelerating = NO;
        
        CGFloat translation = _vertical? [theEvent deltaY]: [theEvent deltaX];
        CGFloat factor = 1.0f;
        if (!_wrapEnabled && _bounces)
        {
            factor = 1.0f - fminf(fabsf(_scrollOffset - [self clampedOffset:_scrollOffset]), _bounceDistance) / _bounceDistance;
        }
        
        NSTimeInterval thisTime = [theEvent timestamp];
        _startVelocity = -(translation / (thisTime - _startTime)) * factor * _scrollSpeed / _itemWidth;
        _startTime = thisTime;
        
        _scrollOffset -= translation * factor * _offsetMultiplier / _itemWidth;
        [self pushAnimationState:NO];
        [self didScroll];
        [self popAnimationState];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (!_didDrag)
    {
        //convert position to view
        CGPoint position = [theEvent locationInWindow];
        position = [self convertPoint:position fromView:self.window.contentView];
        
        //check for tapped view
        for (UIView *view in [[[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self] reverseObjectEnumerator])
        {
            if ([view.superview.layer hitTest:position])
            {
                NSInteger index = [self indexOfItemView:view];
                if (_centerItemWhenSelected && index != self.currentItemIndex)
                {
                    [self scrollToItemAtIndex:index animated:YES];
                }
                if (!_delegate || [_delegate carousel:self shouldSelectItemAtIndex:index])
                {
                    [self pushAnimationState:YES];
                    [_delegate carousel:self didSelectItemAtIndex:index];
                    [self popAnimationState];
                }
                break;
            }
        }
    }
    else if (_scrollEnabled)
    {
        _dragging = NO;
        if ([self shouldDecelerate])
        {
            _didDrag = NO;
            [self startDecelerating];
        }
        
        [self pushAnimationState:YES];
        [_delegate carouselDidEndDragging:self willDecelerate:_decelerating];
        [self popAnimationState];

        if (!_decelerating)
        {
            if ([self shouldScroll])
            {
                NSInteger direction = (int)(_startVelocity / fabsf(_startVelocity));
                [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
            }
            else
            {
                [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
            }
        }
        else
        {
            [self pushAnimationState:YES];
            [_delegate carouselWillBeginDecelerating:self];
            [self popAnimationState];
        }
    }
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
    if (_scrollEnabled && !_scrolling && [characters length])
    {
        if (_vertical)
        {
            switch ([characters characterAtIndex:0])
            {
                case NSUpArrowFunctionKey:
                {
                    [self scrollToItemAtIndex:self.currentItemIndex-1 animated:YES];
                    break;
                }
                case NSDownArrowFunctionKey:
                {
                    [self scrollToItemAtIndex:self.currentItemIndex+1 animated:YES];
                    break;
                }
            }
        }
        else
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
}

#endif

@end