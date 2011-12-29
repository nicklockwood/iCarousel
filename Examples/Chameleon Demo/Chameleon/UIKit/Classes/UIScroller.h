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
#import "UIScrollView.h"

@class UIImageView, UIScroller;

CGFloat UIScrollerWidthForBoundsSize(CGSize boundsSize);

@protocol _UIScrollerDelegate
- (void)_UIScrollerDidBeginDragging:(UIScroller *)scroller withEvent:(UIEvent *)event;
- (void)_UIScroller:(UIScroller *)scroller contentOffsetDidChange:(CGFloat)newOffset;
- (void)_UIScrollerDidEndDragging:(UIScroller *)scroller withEvent:(UIEvent *)event;
@end

@interface UIScroller : UIView {
@private
    __unsafe_unretained id<_UIScrollerDelegate> _delegate;
    CGFloat _contentOffset;
    CGFloat _contentSize;
    CGFloat _dragOffset;
    BOOL _draggingKnob;
    BOOL _isVertical;
    CGPoint _lastTouchLocation;
    NSTimer *_holdTimer;
    UIScrollViewIndicatorStyle _indicatorStyle;
    NSTimer *_fadeTimer;
    BOOL _alwaysVisible;
}

// NOTE: UIScroller set's its own alpha to 0 when it is created, so it is NOT visible by default!
// the flash/quickFlash methods alter its own alpha in order to fade in/out, etc.

- (void)flash;
- (void)quickFlash;

@property (nonatomic, assign) BOOL alwaysVisible;		// if YES, -flash has no effect on the scroller's alpha, setting YES fades alpha to 1, setting NO fades it out if it was visible
@property (nonatomic, assign) id<_UIScrollerDelegate> delegate;
@property (nonatomic, assign) CGFloat contentSize;		// used to calulate how big the slider knob should be (uses its own frame height/width and compares against this value)
@property (nonatomic, assign) CGFloat contentOffset;	// set this after contentSize is set or else it'll normalize in unexpected ways
@property (nonatomic) UIScrollViewIndicatorStyle indicatorStyle;

@end
