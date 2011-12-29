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

#import <Foundation/Foundation.h>

typedef enum {
    UITouchPhaseBegan,
    UITouchPhaseMoved,
    UITouchPhaseStationary,
    UITouchPhaseEnded,
    UITouchPhaseCancelled,
    _UITouchPhaseGestureBegan,
    _UITouchPhaseGestureChanged,
    _UITouchPhaseGestureEnded,
    _UITouchPhaseDiscreteGesture
} UITouchPhase;

typedef enum {
    _UITouchGestureUnknown = 0,
    _UITouchGesturePan,                 // maps only to touch-enabled scrolling devices like magic trackpad, etc. for older wheels, use _UITouchGestureScrollWheel
    _UITouchGestureRotation,            // only works for touch-enabled input devices
    _UITouchGesturePinch,               // only works for touch-enabled input devices
    _UITouchGestureSwipe,               // only works for touch-enabled input devices (this is actually discrete, but OSX sends gesture begin/end events around it)
    _UITouchDiscreteGestureRightClick,  // should be pretty obvious
    _UITouchDiscreteGestureScrollWheel, // this is used by old fashioned wheel mice or when the OS sends its automatic momentum scroll events
    _UITouchDiscreteGestureMouseMove    // the mouse moved but wasn't in a gesture or the button was not being held down
} _UITouchGesture;

@class UIView, UIWindow;

@interface UITouch : NSObject {
@private
    NSTimeInterval _timestamp;
    NSUInteger _tapCount;
    UITouchPhase _phase;
    _UITouchGesture _gesture;
    CGPoint _delta;
    CGFloat _rotation;
    CGFloat _magnification;
    CGPoint _location;
    CGPoint _previousLocation;
    UIView *_view;
    UIWindow *_window;
    NSArray *_gestureRecognizers;
}

- (CGPoint)locationInView:(UIView *)inView;
- (CGPoint)previousLocationInView:(UIView *)inView;

@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly) NSUInteger tapCount;
@property (nonatomic, readonly) UITouchPhase phase;
@property (nonatomic, readonly, retain) UIView *view;
@property (nonatomic, readonly, retain) UIWindow *window;
@property (nonatomic,readonly,copy) NSArray *gestureRecognizers;

@end
