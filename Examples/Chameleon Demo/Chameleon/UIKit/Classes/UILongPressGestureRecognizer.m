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

#import "UILongPressGestureRecognizer.h"
#import "UIGestureRecognizerSubclass.h"
#import "UITouch+UIPrivate.h"
#import "UIEvent.h"

static CGFloat DistanceBetweenTwoPoints(CGPoint A, CGPoint B)
{
    CGFloat a = B.x - A.x;
    CGFloat b = B.y - A.y;
    return sqrtf((a*a) + (b*b));
}

@implementation UILongPressGestureRecognizer
@synthesize minimumPressDuration=_minimumPressDuration, allowableMovement=_allowableMovement, numberOfTapsRequired=_numberOfTapsRequired;
@synthesize numberOfTouchesRequired=_numberOfTouchesRequired;

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self=[super initWithTarget:target action:action])) {
        _allowableMovement = 10;
        _minimumPressDuration = 0.5;
        _numberOfTapsRequired = 0;
        _numberOfTouchesRequired = 1;
    }
    return self;
}

- (void)_discreteGestures:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event touchesForGestureRecognizer:self] anyObject];
    
    if (self.state == UIGestureRecognizerStatePossible && [touch _gesture] == _UITouchDiscreteGestureRightClick) {
        self.state = UIGestureRecognizerStateBegan;
        [self performSelector:@selector(_endFakeContinuousGesture) withObject:nil afterDelay:0];
    }
}

- (void)_endFakeContinuousGesture
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (void)_beginGesture
{
    _waiting = NO;
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)_cancelWaiting
{
    if (_waiting) {
        _waiting = NO;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_beginGesture) object:nil];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event touchesForGestureRecognizer:self] anyObject];
    
    if (!_waiting && self.state == UIGestureRecognizerStatePossible && touch.tapCount >= self.numberOfTapsRequired) {
        _beginLocation = [touch locationInView:self.view];
        _waiting = YES;
        [self performSelector:@selector(_beginGesture) withObject:nil afterDelay:self.minimumPressDuration];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        UITouch *touch = [[event touchesForGestureRecognizer:self] anyObject];        
        const CGFloat distance = DistanceBetweenTwoPoints([touch locationInView:self.view], _beginLocation);
        
        if (distance <= self.allowableMovement) {
            self.state = UIGestureRecognizerStateChanged;
        } else {
            self.state = UIGestureRecognizerStateCancelled;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    } else {
        [self _cancelWaiting];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateCancelled;
    } else {
        [self _cancelWaiting];
    }
}

@end
