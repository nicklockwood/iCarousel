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

#import "UITouch.h"

@class UIView;

@interface UITouch (UIPrivate)
- (void)_setPhase:(UITouchPhase)phase screenLocation:(CGPoint)screenLocation tapCount:(NSUInteger)tapCount timestamp:(NSTimeInterval)timestamp;
- (void)_updatePhase:(UITouchPhase)phase screenLocation:(CGPoint)screenLocation timestamp:(NSTimeInterval)timestamp;
- (void)_updateGesture:(_UITouchGesture)gesture screenLocation:(CGPoint)screenLocation delta:(CGPoint)delta rotation:(CGFloat)rotation magnification:(CGFloat)magnification timestamp:(NSTimeInterval)timestamp;
- (void)_setDiscreteGesture:(_UITouchGesture)gesture screenLocation:(CGPoint)screenLocation tapCount:(NSUInteger)tapCount delta:(CGPoint)delta timestamp:(NSTimeInterval)timestamp;
- (void)_setTouchedView:(UIView *)view; // sets up the window and gesture recognizers as well
- (void)_removeFromView;                // sets the initial view to nil, but leaves window and gesture recognizers alone - used when a view is removed while touch is active
- (void)_setTouchPhaseCancelled;
- (CGPoint)_delta;
- (CGFloat)_rotation;
- (CGFloat)_magnification;
- (UIView *)_previousView;
- (_UITouchGesture)_gesture;
@end
