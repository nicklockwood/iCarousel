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

#import "UICustomNSClipView.h"
#import <AppKit/NSEvent.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>

@implementation UICustomNSClipView
@synthesize parentLayer, behaviorDelegate;

- (id)initWithFrame:(NSRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        [self setDrawsBackground:NO];
        [self setWantsLayer:YES];
    }
    return self;
}

- (void)scrollWheel:(NSEvent *)event
{
    if ([behaviorDelegate clipViewShouldScroll]) {
        NSPoint offset = [self bounds].origin;
        offset.x += [event deltaX];
        offset.y -= [event deltaY];
        offset.x = floor(offset.x);
        offset.y = floor(offset.y);
        [self scrollToPoint:[self constrainScrollPoint:offset]];
    } else {
        [[self nextResponder] scrollWheel:event];
    }
}

- (void)fixupTheLayer
{
    if ([self superview] && parentLayer) {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        CALayer *layer = [self layer];

        if (parentLayer != layer.superlayer) {
            [parentLayer addSublayer:layer];
        }
        
        if (!CGRectEqualToRect(layer.frame, parentLayer.bounds)) {
            layer.frame = parentLayer.bounds;
        }
        
        [CATransaction commit];
    }
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    [self fixupTheLayer];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
    [self fixupTheLayer];
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self fixupTheLayer];
}

- (void)viewDidUnhide
{
    [super viewDidUnhide];
    [self fixupTheLayer];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    NSView *hit = [super hitTest:aPoint];

    if (hit && behaviorDelegate) {
        // call out to the text layer via a delegate or something and ask if this point should be considered a hit or not.
        // if not, then we set hit to nil, otherwise we return it like normal.
        // the purpose of this is to make the NSView act invisible/hidden to clicks when it's visually behind other UIViews.
        // super tricky, eh?
        if (![behaviorDelegate hitTestForClipViewPoint:aPoint]) {
            hit = nil;
        }
    }

    return hit;
}

@end
