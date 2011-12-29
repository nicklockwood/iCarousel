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

#import "UIScrollViewAnimationScroll.h"

@implementation UIScrollViewAnimationScroll

- (id)initWithScrollView:(UIScrollView *)sv fromContentOffset:(CGPoint)from toContentOffset:(CGPoint)to duration:(NSTimeInterval)d curve:(UIScrollViewAnimationScrollCurve)c
{
    if ((self=[super initWithScrollView:sv])) {
        beginContentOffset = from;
        endContentOffset = to;
        duration = d;
        curve = c;
    }
    return self;
}
    
- (BOOL)animate
{
    const NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    const NSTimeInterval elapsedTime = currentTime - beginTime;
    const CGFloat animationPosition = MIN(1, (elapsedTime / duration));

    CGFloat (*curveFunction)(CGFloat t, CGFloat start, CGFloat end) = (curve == UIScrollViewAnimationScrollCurveLinear)? &UILinearInterpolation : &UIQuadraticEaseOut;
    
    scrollView.contentOffset = CGPointMake(curveFunction(animationPosition, beginContentOffset.x, endContentOffset.x),
                                           curveFunction(animationPosition, beginContentOffset.y, endContentOffset.y));

    return (animationPosition == 1);
}

@end
