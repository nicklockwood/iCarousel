/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIView.h"

typedef enum {
    UIScrollViewIndicatorStyleDefault,
    UIScrollViewIndicatorStyleBlack,
    UIScrollViewIndicatorStyleWhite
} UIScrollViewIndicatorStyle;

extern const float UIScrollViewDecelerationRateNormal;
extern const float UIScrollViewDecelerationRateFast;

@class UIScroller, UIImageView, UIScrollView, UIPanGestureRecognizer, UIScrollWheelGestureRecognizer;

@protocol UIScrollViewDelegate <NSObject>
@optional
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view;
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
@end

@interface UIScrollView : UIView {
@package
    __unsafe_unretained id _delegate;
@private
    CGPoint _contentOffset;
    CGSize _contentSize;
    UIEdgeInsets _contentInset;
    UIEdgeInsets _scrollIndicatorInsets;
    UIScroller *_verticalScroller;
    UIScroller *_horizontalScroller;
    BOOL _showsVerticalScrollIndicator;
    BOOL _showsHorizontalScrollIndicator;
    float _maximumZoomScale;
    float _minimumZoomScale;
    BOOL _scrollsToTop;
    UIScrollViewIndicatorStyle _indicatorStyle;
    BOOL _delaysContentTouches;
    BOOL _canCancelContentTouches;
    BOOL _pagingEnabled;
    float _decelerationRate;
    
    BOOL _bouncesZoom;
    BOOL _bounces;
    BOOL _zooming;
    BOOL _dragging;
    BOOL _decelerating;
    
    UIPanGestureRecognizer *_panGestureRecognizer;
    UIScrollWheelGestureRecognizer *_scrollWheelGestureRecognizer;
    
    id _scrollAnimation;
    NSTimer *_scrollTimer;
    
    struct {
        unsigned scrollViewDidScroll : 1;
        unsigned scrollViewWillBeginDragging : 1;
        unsigned scrollViewDidEndDragging : 1;
        unsigned viewForZoomingInScrollView : 1;
        unsigned scrollViewWillBeginZooming : 1;
        unsigned scrollViewDidEndZooming : 1;
        unsigned scrollViewDidZoom : 1;
        unsigned scrollViewDidEndScrollingAnimation : 1;
        unsigned scrollViewWillBeginDecelerating : 1;
        unsigned scrollViewDidEndDecelerating : 1;
    } _delegateCan;

  // should be flag struct
  BOOL _alwaysBounceHorizontal;
  BOOL _alwaysBounceVertical;
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;

- (void)setZoomScale:(float)scale animated:(BOOL)animated;
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

- (void)setContentOffset:(CGPoint)theOffset animated:(BOOL)animated;
- (void)flashScrollIndicators;		// does nothing

@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) UIEdgeInsets scrollIndicatorInsets;
@property (nonatomic) UIScrollViewIndicatorStyle indicatorStyle;
@property (nonatomic) BOOL showsHorizontalScrollIndicator;
@property (nonatomic) BOOL showsVerticalScrollIndicator;
@property (nonatomic) BOOL bounces;
@property (nonatomic) BOOL alwaysBounceVertical;
@property (nonatomic) BOOL alwaysBounceHorizontal;
@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign) id<UIScrollViewDelegate> delegate;
@property (nonatomic) BOOL scrollsToTop;			// no effect
@property (nonatomic) BOOL delaysContentTouches;	// no effect
@property (nonatomic) BOOL canCancelContentTouches; // no effect
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;
@property (nonatomic, readonly, getter=isTracking) BOOL tracking;           // always returns NO
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating;	// always returns NO
@property (nonatomic, assign) BOOL pagingEnabled;
@property (nonatomic) float decelerationRate;

@property (nonatomic) float maximumZoomScale;
@property (nonatomic) float minimumZoomScale;
@property (nonatomic) float zoomScale;
@property (nonatomic, readonly, getter=isZooming) BOOL zooming;
@property (nonatomic, readonly, getter=isZoomBouncing) BOOL zoomBouncing;	// always NO
@property (nonatomic) BOOL bouncesZoom;                                     // no effect

@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, readonly) UIScrollWheelGestureRecognizer *scrollWheelGestureRecognizer;   // non-standard


@end
