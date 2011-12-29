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

@interface UIViewAnimationGroup : NSObject {
@private
    NSString *_name;
    void *_context;
    NSUInteger _waitingAnimations;
    BOOL _didSendStartMessage;
    NSTimeInterval _animationDelay;
    NSTimeInterval _animationDuration;
    UIViewAnimationCurve _animationCurve;
    id _animationDelegate;
    SEL _animationDidStopSelector;
    SEL _animationWillStartSelector;
    BOOL _animationBeginsFromCurrentState;
    BOOL _animationRepeatAutoreverses;
    float _animationRepeatCount;
    CFTimeInterval _animationBeginTime;
    CALayer *_transitionLayer;
    UIViewAnimationTransition _transitionType;
    BOOL _transitionShouldCache;
    NSMutableSet *_animatingViews;
}

+ (id)animationGroupWithName:(NSString *)theName context:(void *)theContext;

- (id)actionForView:(UIView *)view forKey:(NSString *)keyPath;

- (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState;
- (void)setAnimationCurve:(UIViewAnimationCurve)curve;
- (void)setAnimationDelay:(NSTimeInterval)delay;
- (void)setAnimationDelegate:(id)delegate;			// retained! (also true of the real UIKit)
- (void)setAnimationDidStopSelector:(SEL)selector;
- (void)setAnimationDuration:(NSTimeInterval)duration;
- (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses;
- (void)setAnimationRepeatCount:(float)repeatCount;
- (void)setAnimationTransition:(UIViewAnimationTransition)transition forView:(UIView *)view cache:(BOOL)cache;
- (void)setAnimationWillStartSelector:(SEL)selector;

- (void)commit;

@end
