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

#import <AppKit/NSClipView.h>

@class CALayer;

@protocol UICustomNSClipViewBehaviorDelegate
// the point should be in the clip view's superview coordinate space - aka the "screen" coordinate space because if everything
// is being done correctly, this view is never nested inside any other kind of NSView.
- (BOOL)hitTestForClipViewPoint:(NSPoint)point;

// return NO if scroll wheel events should be ignored, otherwise return YES
- (BOOL)clipViewShouldScroll;
@end

@interface UICustomNSClipView : NSClipView {
    CALayer *parentLayer;
    id<UICustomNSClipViewBehaviorDelegate> behaviorDelegate;
}

- (id)initWithFrame:(NSRect)frame;

// A layer parent is just a layer that UICustonNSClipView will attempt to always remain a sublayer of.
// Circumventing AppKit for fun and profit!
// The hitDelegate is for faking out the NSView's usual hitTest: checks to handle cases where UIViews are above
// the UIView that's displaying this layer.
@property (nonatomic, assign) CALayer *parentLayer;
@property (nonatomic, assign) id<UICustomNSClipViewBehaviorDelegate> behaviorDelegate;

@end
