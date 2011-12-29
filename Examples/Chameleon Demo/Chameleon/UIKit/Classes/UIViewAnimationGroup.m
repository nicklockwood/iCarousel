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

#import "UIViewAnimationGroup.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor.h"

static CAMediaTimingFunction *CAMediaTimingFunctionFromUIViewAnimationCurve(UIViewAnimationCurve curve)
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        case UIViewAnimationCurveEaseIn:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        case UIViewAnimationCurveEaseOut:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        case UIViewAnimationCurveLinear:	return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    }
    return nil;
}

@implementation UIViewAnimationGroup

- (id)initWithGroupName:(NSString *)theName context:(void *)theContext
{
    if ((self=[super init])) {
        _name = [theName copy];
        _context = theContext;
        _waitingAnimations = 1;
        _animationDuration = 0.2;
        _animationCurve = UIViewAnimationCurveEaseInOut;
        _animationBeginsFromCurrentState = NO;
        _animationRepeatAutoreverses = NO;
        _animationRepeatCount = 0;
        _animationBeginTime = CACurrentMediaTime();
        _animatingViews = [[NSMutableSet alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [_animationDelegate release];
    [_animatingViews release];
    [super dealloc];
}

+ (id)animationGroupWithName:(NSString *)theName context:(void *)theContext
{
    return [[[self alloc] initWithGroupName:theName context:theContext] autorelease];
}

- (void)notifyAnimationsDidStopIfNeededUsingStatus:(BOOL)animationsDidFinish
{
    if (_waitingAnimations == 0) {
        if ([_animationDelegate respondsToSelector:_animationDidStopSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationDidStopSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationDidStopSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;
            
            NSNumber *finishedArgument = [NSNumber numberWithBool:animationsDidFinish];
            
            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }

            if (remaining > 0) {
                [invocation setArgument:&finishedArgument atIndex:3];
                remaining--;
            }

            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:4];
            }
            
            [invocation invokeWithTarget:_animationDelegate];
        }
        [_animatingViews removeAllObjects];
    }
}

- (void)animationDidStart:(CAAnimation *)theAnimation
{
    if (!_didSendStartMessage) {
        if ([_animationDelegate respondsToSelector:_animationWillStartSelector]) {
            NSMethodSignature *signature = [_animationDelegate methodSignatureForSelector:_animationWillStartSelector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:_animationWillStartSelector];
            NSInteger remaining = [signature numberOfArguments] - 2;
            
            if (remaining > 0) {
                [invocation setArgument:&_name atIndex:2];
                remaining--;
            }
            
            if (remaining > 0) {
                [invocation setArgument:&_context atIndex:3];
            }
            
            [invocation invokeWithTarget:_animationDelegate];
        }
        _didSendStartMessage = YES;
    }
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    _waitingAnimations--;
    [self notifyAnimationsDidStopIfNeededUsingStatus:flag];
}

- (CAAnimation *)addAnimation:(CAAnimation *)animation
{
    animation.timingFunction = CAMediaTimingFunctionFromUIViewAnimationCurve(_animationCurve);
    animation.duration = _animationDuration;
    animation.beginTime = _animationBeginTime + _animationDelay;
    animation.repeatCount = _animationRepeatCount;
    animation.autoreverses = _animationRepeatAutoreverses;
    animation.fillMode = kCAFillModeBackwards;
    animation.delegate = self;
    animation.removedOnCompletion = YES;
    _waitingAnimations++;
    return animation;
}

- (id)actionForView:(UIView *)view forKey:(NSString *)keyPath
{
    [_animatingViews addObject:view];
    CALayer *layer = view.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue = _animationBeginsFromCurrentState? [layer.presentationLayer valueForKey:keyPath] : [layer valueForKey:keyPath];
    return [self addAnimation:animation];
}

- (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
    _animationBeginsFromCurrentState = beginFromCurrentState;
}

- (void)setAnimationCurve:(UIViewAnimationCurve)curve
{
    _animationCurve = curve;
}

- (void)setAnimationDelay:(NSTimeInterval)delay
{
    _animationDelay = delay;
}

- (void)setAnimationDelegate:(id)delegate
{
    if (delegate != _animationDelegate) {
        [_animationDelegate release];
        _animationDelegate = [delegate retain];
    }
}

- (void)setAnimationDidStopSelector:(SEL)selector
{
    _animationDidStopSelector = selector;
}

- (void)setAnimationDuration:(NSTimeInterval)newDuration
{
    _animationDuration = newDuration;
}

- (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
    _animationRepeatAutoreverses = repeatAutoreverses;
}

- (void)setAnimationRepeatCount:(float)repeatCount
{
    _animationRepeatCount = repeatCount;
}

- (void)setAnimationTransition:(UIViewAnimationTransition)transition forView:(UIView *)view cache:(BOOL)cache
{
    _transitionLayer = view.layer;
    _transitionType = transition;
    _transitionShouldCache = cache;
}

- (void)setAnimationWillStartSelector:(SEL)selector
{
    _animationWillStartSelector = selector;
}

- (void)commit
{
    if (_transitionLayer) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionMoveIn;
        
        switch (_transitionType) {
            case UIViewAnimationTransitionNone:				trans.subtype = nil;						break;
            case UIViewAnimationTransitionCurlUp:			trans.subtype = kCATransitionFromTop;		break;
            case UIViewAnimationTransitionCurlDown:			trans.subtype = kCATransitionFromBottom;	break;
            case UIViewAnimationTransitionFlipFromLeft:		trans.subtype = kCATransitionFromLeft;		break;
            case UIViewAnimationTransitionFlipFromRight:	trans.subtype = kCATransitionFromRight;		break;
        }
        
        [_transitionLayer addAnimation:[self addAnimation:trans] forKey:kCATransition];
    }
    
    _waitingAnimations--;
    [self notifyAnimationsDidStopIfNeededUsingStatus:YES];
}

@end
