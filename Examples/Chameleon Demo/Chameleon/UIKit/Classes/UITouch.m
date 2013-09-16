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

#import "UITouch+UIPrivate.h"
#import "UIWindow.h"
#import "UIGestureRecognizerSubclass.h"
#import <Cocoa/Cocoa.h>

static NSArray *GestureRecognizersForView(UIView *view)
{
    NSMutableArray *recognizers = [[NSMutableArray alloc] initWithCapacity:0];
    
    while (view) {
        [recognizers addObjectsFromArray:view.gestureRecognizers];
        view = [view superview];
    }
    
    return [recognizers autorelease];
}

@implementation UITouch
@synthesize timestamp=_timestamp, tapCount=_tapCount, phase=_phase, view=_view, window=_window, gestureRecognizers=_gestureRecognizers;

- (id)init
{
    if ((self=[super init])) {
        _phase = UITouchPhaseCancelled;
        _gesture = _UITouchGestureUnknown;
    }
    return self;
}

- (void)dealloc
{
    [_window release];
    [_view release];
    [_gestureRecognizers release];
    [super dealloc];
}




- (void)_setPhase:(UITouchPhase)phase screenLocation:(CGPoint)screenLocation tapCount:(NSUInteger)tapCount timestamp:(NSTimeInterval)timestamp;
{
    _phase = phase;
    _gesture = _UITouchGestureUnknown;
    _previousLocation = _location = screenLocation;
    _tapCount = tapCount;
    _timestamp = timestamp;
    _rotation = 0;
    _magnification = 0;
}

- (void)_updatePhase:(UITouchPhase)phase screenLocation:(CGPoint)screenLocation timestamp:(NSTimeInterval)timestamp;
{
    if (!CGPointEqualToPoint(screenLocation, _location)) {
        _previousLocation = _location;
        _location = screenLocation;
    }
    
    _phase = phase;
    _timestamp = timestamp;
}

- (void)_updateGesture:(_UITouchGesture)gesture screenLocation:(CGPoint)screenLocation delta:(CGPoint)delta rotation:(CGFloat)rotation magnification:(CGFloat)magnification timestamp:(NSTimeInterval)timestamp;
{
    if (!CGPointEqualToPoint(screenLocation, _location)) {
        _previousLocation = _location;
        _location = screenLocation;
    }
    
    _phase = _UITouchPhaseGestureChanged;
    
    _gesture = gesture;
    _delta = delta;
    _rotation = rotation;
    _magnification = magnification;
    _timestamp = timestamp;
}

- (void)_setDiscreteGesture:(_UITouchGesture)gesture screenLocation:(CGPoint)screenLocation tapCount:(NSUInteger)tapCount delta:(CGPoint)delta timestamp:(NSTimeInterval)timestamp;
{
    _phase = _UITouchPhaseDiscreteGesture;
    _gesture = gesture;
    _previousLocation = _location = screenLocation;
    _tapCount = tapCount;
    _delta = delta;
    _timestamp = timestamp;
    _rotation = 0;
    _magnification = 0;
}

- (_UITouchGesture)_gesture
{
    return _gesture;
}

- (void)_setTouchedView:(UIView *)view
{
    if (_view != view) {
        [_view release];
        _view = [view retain];
    }

    if (_window != view.window) {
        [_window release];
        _window = [view.window retain];
    }

    [_gestureRecognizers release];
    _gestureRecognizers = [GestureRecognizersForView(_view) copy];
}

- (void)_removeFromView
{
    NSMutableArray *remainingRecognizers = [_gestureRecognizers mutableCopy];

    // if the view is being removed from this touch, we need to remove/cancel any gesture recognizers that belong to the view
    // being removed. this kinda feels like the wrong place for this, but the touch itself has a list of potential gesture
    // recognizers attached to it so an active touch only considers the recongizers that were present at the point the touch
    // first touched the screen. it could easily have recognizers attached to it from superviews of the view being removed so
    // we can't just cancel them all. the view itself could cancel its own recognizers, but then it needs a way to remove them
    // from an active touch so in a sense we're right back where we started. so I figured we might as well just take care of it
    // here and see what happens.
    for (UIGestureRecognizer *recognizer in _gestureRecognizers) {
        if (recognizer.view == _view) {
            if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
                recognizer.state = UIGestureRecognizerStateCancelled;
            }
            [remainingRecognizers removeObject:recognizer];
        }
    }
    
    [_gestureRecognizers release];
    _gestureRecognizers = [remainingRecognizers copy];
    [remainingRecognizers release];
    
    [_view release];
    _view = nil;
}

- (void)_setTouchPhaseCancelled
{
    _phase = UITouchPhaseCancelled;
}

- (CGPoint)_delta
{
    return _delta;
}

- (CGFloat)_rotation
{
    return _rotation;
}

- (CGFloat)_magnification
{
    return _magnification;
}

- (UIWindow *)window
{
    return _window;
}

- (CGPoint)_convertLocationPoint:(CGPoint)thePoint toView:(UIView *)inView
{
    UIWindow *window = self.window;
    
    // The stored location should always be in the coordinate space of the UIScreen that contains the touch's window.
    // So first convert from the screen to the window:
    CGPoint point = [window convertPoint:thePoint fromWindow:nil];
    
    // Then convert to the desired location (if any).
    if (inView) {
        point = [inView convertPoint:point fromView:window];
    }
    
    return point;
}

- (CGPoint)locationInView:(UIView *)inView
{
    return [self _convertLocationPoint:_location toView:inView];
}

- (CGPoint)previousLocationInView:(UIView *)inView
{
    return [self _convertLocationPoint:_previousLocation toView:inView];
}

- (NSString *)description
{
    NSString *phase = @"";
    switch (self.phase) {
        case UITouchPhaseBegan:
            phase = @"Began";
            break;
        case UITouchPhaseMoved:
            phase = @"Moved";
            break;
        case UITouchPhaseStationary:
            phase = @"Stationary";
            break;
        case UITouchPhaseEnded:
            phase = @"Ended";
            break;
        case UITouchPhaseCancelled:
            phase = @"Cancelled";
            break;
        case _UITouchPhaseGestureBegan:
            phase = @"GestureBegan";
            break;
        case _UITouchPhaseGestureChanged:
            phase = @"GestureChanged";
            break;
        case _UITouchPhaseGestureEnded:
            phase = @"GestureEnded";
            break;
        case _UITouchPhaseDiscreteGesture:
            phase = @"DiscreteGesture";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; timestamp = %e; tapCount = %lu; phase = %@; view = %@; window = %@>", [self className], self, self.timestamp, (unsigned long)self.tapCount, phase, self.view, self.window];
}

@end
