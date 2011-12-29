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

#import "UIScreenAppKitIntegration.h"
#import "UIScreen+UIPrivate.h"
#import "UIKitView.h"
#import <AppKit/AppKit.h>

extern NSMutableArray *_allScreens;

@implementation UIScreen (AppKitIntegration)
- (UIKitView *)UIKitView
{
    return _UIKitView;
}

- (CGPoint)convertPoint:(CGPoint)toConvert toScreen:(UIScreen *)toScreen
{
    if (toScreen == self) {
        return toConvert;
    } else {
        // Go all the way through OSX screen coordinates.
        NSPoint screenCoords = [[_UIKitView window] convertBaseToScreen:[_UIKitView convertPoint:NSPointFromCGPoint(toConvert) toView:nil]];
        
        if (toScreen) {
            // Now from there back to the toScreen's window's base
            return NSPointToCGPoint([[toScreen UIKitView] convertPoint:[[[toScreen UIKitView] window] convertScreenToBase:screenCoords] fromView:nil]);
        } else {
            return NSPointToCGPoint(screenCoords);
        }
    }
}

- (CGPoint)convertPoint:(CGPoint)toConvert fromScreen:(UIScreen *)fromScreen
{
    if (fromScreen == self) {
        return toConvert;
    } else {
        NSPoint screenCoords;
        
        if (fromScreen) {
            // Go all the way through OSX screen coordinates.
            screenCoords = [[[fromScreen UIKitView] window] convertBaseToScreen:[[fromScreen UIKitView] convertPoint:NSPointFromCGPoint(toConvert) toView:nil]];
        } else {
            screenCoords = NSPointFromCGPoint(toConvert);
        }
        
        // Now from there back to the our screen
        return NSPointToCGPoint([_UIKitView convertPoint:[[_UIKitView window] convertScreenToBase:screenCoords] fromView:nil]);
    }
}

- (CGRect)convertRect:(CGRect)toConvert toScreen:(UIScreen *)toScreen
{
    CGPoint origin = [self convertPoint:CGPointMake(CGRectGetMinX(toConvert),CGRectGetMinY(toConvert)) toScreen:toScreen];
    CGPoint bottom = [self convertPoint:CGPointMake(CGRectGetMaxX(toConvert),CGRectGetMaxY(toConvert)) toScreen:toScreen];
    return CGRectStandardize(CGRectMake(origin.x, origin.y, bottom.x-origin.x, bottom.y-origin.y));
}

- (CGRect)convertRect:(CGRect)toConvert fromScreen:(UIScreen *)fromScreen
{
    CGPoint origin = [self convertPoint:CGPointMake(CGRectGetMinX(toConvert),CGRectGetMinY(toConvert)) fromScreen:fromScreen];
    CGPoint bottom = [self convertPoint:CGPointMake(CGRectGetMaxX(toConvert),CGRectGetMaxY(toConvert)) fromScreen:fromScreen];
    return CGRectStandardize(CGRectMake(origin.x, origin.y, bottom.x-origin.x, bottom.y-origin.y));
}

- (void)becomeMainScreen
{
    NSValue *entry = [NSValue valueWithNonretainedObject:self];
    NSInteger index = [_allScreens indexOfObject:entry];
    [_allScreens removeObjectAtIndex:index];
    [_allScreens insertObject:entry atIndex:0];
}

@end

