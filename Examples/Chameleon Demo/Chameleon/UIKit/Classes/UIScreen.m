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

#import "UIScreen.h"
#import "UIScreenAppKitIntegration.h"
#import "UIImage+UIPrivate.h"
#import "UIImageView.h"
#import "UIApplication.h"
#import <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>
#import "UIViewLayoutManager.h"
#import "UIColor.h"
#import "UIScreenMode+UIPrivate.h"
#import "UIWindow.h"
#import "UIKitView.h"
#import "UIView+UIPrivate.h"

NSString *const UIScreenDidConnectNotification = @"UIScreenDidConnectNotification";
NSString *const UIScreenDidDisconnectNotification = @"UIScreenDidDisconnectNotification";
NSString *const UIScreenModeDidChangeNotification = @"UIScreenModeDidChangeNotification";

NSMutableArray *_allScreens = nil;

@implementation UIScreen
@synthesize currentMode=_currentMode;

+ (void)initialize
{
    if (self == [UIScreen class]) {
        _allScreens = [[NSMutableArray alloc] init];
    }
}

+ (UIScreen *)mainScreen
{
    return ([_allScreens count] > 0)? [[_allScreens objectAtIndex:0] nonretainedObjectValue] : nil;
}

+ (NSArray *)screens
{
    NSMutableArray *screens = [NSMutableArray arrayWithCapacity:[_allScreens count]];

    for (NSValue *v in _allScreens) {
        [screens addObject:[v nonretainedObjectValue]];
    }

    return screens;
}

- (id)init
{
    if ((self = [super init])) {
        _layer = [[CALayer layer] retain];
        _layer.delegate = self;		// required to get the magic of the UIViewLayoutManager...
        _layer.layoutManager = [UIViewLayoutManager layoutManager];
        
        _grabber = [[UIImageView alloc] initWithImage:[UIImage _windowResizeGrabberImage]];
        _grabber.layer.zPosition = 10000;
        [_layer addSublayer:_grabber.layer];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_allScreens removeObject:[NSValue valueWithNonretainedObject:self]];

    _layer.layoutManager = nil;
    _layer.delegate = nil;

    [_grabber.layer removeFromSuperlayer];
    [_layer removeFromSuperlayer];

    [_grabber release];
    [_layer release];
    [_currentMode release];
    
    [super dealloc];
}

- (CGFloat)scale
{
    if ([[_UIKitView window] respondsToSelector:@selector(backingScaleFactor)]) {
        return [[_UIKitView window] backingScaleFactor];
    } else {
        return 1;
    }
}

- (void)_setPopoverController:(UIPopoverController *)controller
{
    _popoverController = controller;
}

- (UIPopoverController *)_popoverController
{
    return _popoverController;
}

- (BOOL)_hasResizeIndicator
{
    NSWindow *realWindow = [_UIKitView window];
    NSView *contentView = [realWindow contentView];

    if (_UIKitView && realWindow && contentView && ([realWindow styleMask] & NSResizableWindowMask) && [realWindow showsResizeIndicator] && !NSEqualSizes([realWindow minSize], [realWindow maxSize])) {
        const CGRect myBounds = NSRectToCGRect([_UIKitView bounds]);
        const CGPoint myLowerRight = CGPointMake(CGRectGetMaxX(myBounds),CGRectGetMaxY(myBounds));
        const CGRect contentViewBounds = NSRectToCGRect([contentView frame]);
        const CGPoint contentViewLowerRight = CGPointMake(CGRectGetMaxX(contentViewBounds),0);
        const CGPoint convertedPoint = NSPointToCGPoint([_UIKitView convertPoint:NSPointFromCGPoint(myLowerRight) toView:contentView]);

        if (CGPointEqualToPoint(convertedPoint,contentViewLowerRight) && [realWindow showsResizeIndicator]) {
            return YES;
        }
    }

    return NO;
}

- (void)_layoutSubviews
{
    if ([self _hasResizeIndicator]) {
        const CGSize grabberSize = _grabber.frame.size;
        const CGSize layerSize = _layer.bounds.size;
        CGRect grabberRect = _grabber.frame;
        grabberRect.origin = CGPointMake(layerSize.width-grabberSize.width,layerSize.height-grabberSize.height);
        _grabber.frame = grabberRect;
        _grabber.hidden = NO;
    } else if (!_grabber.hidden) {
        _grabber.hidden = YES;
    }
}

- (id)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return [NSNull null];
}

- (CGRect)applicationFrame
{
    const float statusBarHeight = [UIApplication sharedApplication].statusBarHidden? 0 : 20;
    const CGSize size = [self bounds].size;
    return CGRectMake(0,statusBarHeight,size.width,size.height-statusBarHeight);
}

- (CGRect)bounds
{
    return _layer.bounds;
}

- (CALayer *)_layer
{
    return _layer;
}

- (void)_UIKitViewFrameDidChange
{
    NSDictionary *userInfo = (self.currentMode)? [NSDictionary dictionaryWithObject:self.currentMode forKey:@"_previousMode"] : nil;
    self.currentMode = [UIScreenMode screenModeWithNSView:_UIKitView];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIScreenModeDidChangeNotification object:self userInfo:userInfo];
}

- (void)_NSScreenDidChange
{
    for (UIWindow *window in [[UIApplication sharedApplication].windows reverseObjectEnumerator]) {
        if (window.screen == self) {
            [window _didMoveToScreen];
        }
    }
}

- (void)_setUIKitView:(id)theView
{
    if (_UIKitView != theView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_UIKitView];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidChangeScreenNotification object:nil];
        
        if ((_UIKitView = theView)) {
            [_allScreens addObject:[NSValue valueWithNonretainedObject:self]];
            self.currentMode = [UIScreenMode screenModeWithNSView:_UIKitView];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIScreenDidConnectNotification object:self];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_UIKitViewFrameDidChange) name:NSViewFrameDidChangeNotification object:_UIKitView];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_NSScreenDidChange) name:NSWindowDidChangeScreenNotification object:[_UIKitView window]];
            [self _NSScreenDidChange];
        } else {
            self.currentMode = nil;
            [_allScreens removeObject:[NSValue valueWithNonretainedObject:self]];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIScreenDidDisconnectNotification object:self];
        }
    }
}

- (NSArray *)availableModes
{
    return (self.currentMode)? [NSArray arrayWithObject:self.currentMode] : nil;
}

- (UIView *)_hitTest:(CGPoint)clickPoint event:(UIEvent *)theEvent
{
    for (UIWindow *window in [[UIApplication sharedApplication].windows reverseObjectEnumerator]) {
        if (window.screen == self) {
            CGPoint windowPoint = [window convertPoint:clickPoint fromWindow:nil];
            UIView *clickedView = [window hitTest:windowPoint withEvent:theEvent];
            if (clickedView) {
                return clickedView;
            }
        }
    }
    
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; bounds = %@; mode = %@>", [self className], self, NSStringFromCGRect(self.bounds), self.currentMode];
}

@end
