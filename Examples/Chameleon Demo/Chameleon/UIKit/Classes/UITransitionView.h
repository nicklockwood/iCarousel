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
    UITransitionNone = 0,		// no animation is done
    UITransitionFromLeft,		// the new view slides in from the left over top of the old view
    UITransitionFromRight,		// the new view slides in from the right over top of the old view
    UITransitionFromTop,		// the new view slides in from the top over top of the old view
    UITransitionFromBottom,		// the new view slides in from the bottom over top of the old view
    UITransitionPushLeft,		// the new view slides in from the right and pushes the old view off the left
    UITransitionPushRight,		// the new view slides in from the left and pushes the old view off the right
    UITransitionPushUp,			// the new view slides in from the bottom and pushes the old view off the top
    UITransitionPushDown,		// the new view slides in from the top and pushes the old view off the bottom
    UITransitionCrossFade,		// new view fades in as old view fades out
    UITransitionFadeIn,			// new view fades in over old view
    UITransitionFadeOut			// old view fades out to reveal the new view behind it
} UITransition;

@class UITransitionView;

@protocol UITransitionViewDelegate <NSObject>
- (void)transitionView:(UITransitionView *)transitionView didTransitionFromView:(UIView *)fromView toView:(UIView *)toView withTransition:(UITransition)transition;
@end

@interface UITransitionView : UIView {
    UITransition _transition;
    UIView *_view;
    __unsafe_unretained id<UITransitionViewDelegate> _delegate;
}

- (id)initWithFrame:(CGRect)frame view:(UIView *)aView;

@property (nonatomic, retain) UIView *view;
@property (nonatomic, assign) UITransition transition;
@property (nonatomic, assign) id<UITransitionViewDelegate> delegate;

@end
