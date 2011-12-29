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

#import "UIPopoverController+UIPrivate.h"
#import "UIViewController.h"
#import "UIWindow.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIKitView.h"
#import "UITouch.h"
#import "UIApplication+UIPrivate.h"
#import "UIPopoverView.h"
#import "UIPopoverNSWindow.h"
#import "UIPopoverOverlayNSView.h"


static BOOL SizeIsLessThanOrEqualSize(NSSize size1, NSSize size2)
{
    return (size1.width <= size2.width) && (size1.height <= size2.height);
}

static NSPoint PopoverWindowOrigin(NSWindow *inWindow, NSRect fromRect, NSSize popoverSize, UIPopoverArrowDirection arrowDirections, NSPoint *pointTo, UIPopoverArrowDirection *arrowDirection)
{
    // 1) define a set of possible quads around fromRect that the popover could appear in
    // 2) eliminate quads based on arrow direction restrictions and sizes
    // 3) the first quad that is large enough "wins"
    
    NSRect screenRect = [[inWindow screen] visibleFrame];
    
    NSRect bottomQuad = NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, fromRect.origin.y-screenRect.origin.y);
    NSRect topQuad = NSMakeRect(screenRect.origin.x, fromRect.origin.y+fromRect.size.height, screenRect.size.width, screenRect.size.height-fromRect.origin.y-fromRect.size.height-screenRect.origin.y);
    NSRect leftQuad = NSMakeRect(screenRect.origin.x, screenRect.origin.y, fromRect.origin.x-screenRect.origin.x, screenRect.size.height-screenRect.origin.y);
    NSRect rightQuad = NSMakeRect(fromRect.origin.x+fromRect.size.width, screenRect.origin.y, screenRect.size.width-fromRect.origin.x-fromRect.size.width-screenRect.origin.x, screenRect.size.height-screenRect.origin.y);
    
    pointTo->x = fromRect.origin.x+(fromRect.size.width/2.f);
    pointTo->y = fromRect.origin.y+(fromRect.size.height/2.f);
    
    NSPoint origin;
    origin.x = fromRect.origin.x + (fromRect.size.width/2.f) - (popoverSize.width/2.f);
    origin.y = fromRect.origin.y + (fromRect.size.height/2.f) - (popoverSize.height/2.f);
    
    const CGFloat minimumPadding = 40;
    const BOOL allowTopOrBottom = (pointTo->x >= NSMinX(screenRect)+minimumPadding && pointTo->x <= NSMaxX(screenRect)-minimumPadding);
    const BOOL allowLeftOrRight = (pointTo->y >= NSMinY(screenRect)+minimumPadding && pointTo->y <= NSMaxY(screenRect)-minimumPadding);
    
    const BOOL allowTopQuad = ((arrowDirections & UIPopoverArrowDirectionDown) != 0) && topQuad.size.width > 0 && topQuad.size.height > 0 && allowTopOrBottom;
    const BOOL allowBottomQuad = ((arrowDirections & UIPopoverArrowDirectionUp) != 0) && bottomQuad.size.width > 0 && bottomQuad.size.height > 0 && allowTopOrBottom;
    const BOOL allowLeftQuad = ((arrowDirections & UIPopoverArrowDirectionRight) != 0) && leftQuad.size.width > 0 && leftQuad.size.height > 0 && allowLeftOrRight;
    const BOOL allowRightQuad = ((arrowDirections & UIPopoverArrowDirectionLeft) != 0) && rightQuad.size.width > 0 && rightQuad.size.height > 0 && allowLeftOrRight;
    
    const CGFloat arrowPadding = 8;		// the arrow images are slightly larger to account for shadows, but the arrow point needs to be up against the rect exactly so this helps with that
        
    if (allowBottomQuad && SizeIsLessThanOrEqualSize(popoverSize,bottomQuad.size)) {
        pointTo->y = fromRect.origin.y;
        origin.y = fromRect.origin.y - popoverSize.height + arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionUp;
    } else if (allowRightQuad && SizeIsLessThanOrEqualSize(popoverSize,rightQuad.size)) {
        pointTo->x = fromRect.origin.x + fromRect.size.width;
        origin.x = pointTo->x - arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionLeft;
    } else if (allowLeftQuad && SizeIsLessThanOrEqualSize(popoverSize,leftQuad.size)) {
        pointTo->x = fromRect.origin.x;
        origin.x = fromRect.origin.x - popoverSize.width + arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionRight;
    } else if (allowTopQuad && SizeIsLessThanOrEqualSize(popoverSize,topQuad.size)) {
        pointTo->y = fromRect.origin.y + fromRect.size.height;
        origin.y = pointTo->y - arrowPadding;
        *arrowDirection = UIPopoverArrowDirectionDown;
    } else {
        *arrowDirection = UIPopoverArrowDirectionUnknown;
    }
    
    NSRect windowRect;
    windowRect.origin = origin;
    windowRect.size = popoverSize;
    
    if (NSMaxX(windowRect) > NSMaxX(screenRect)) {
        windowRect.origin.x = NSMaxX(screenRect) - popoverSize.width;
    }
    if (NSMinX(windowRect) < NSMinX(screenRect)) {
        windowRect.origin.x = NSMinX(screenRect);
    }
    if (NSMaxY(windowRect) > NSMaxY(screenRect)) {
        windowRect.origin.y = NSMaxY(screenRect) - popoverSize.height;
    }
    if (NSMinY(windowRect) < NSMinY(screenRect)) {
        windowRect.origin.y = NSMinY(screenRect);
    }
    
    windowRect.origin.x = roundf(windowRect.origin.x);
    windowRect.origin.y = roundf(windowRect.origin.y);
    
    return windowRect.origin;
}

@interface UIPopoverController ()
- (void)_destroyPopover;
@end

@implementation UIPopoverController
@synthesize delegate=_delegate, contentViewController=_contentViewController, passthroughViews=_passthroughViews;
@synthesize popoverArrowDirection=_popoverArrowDirection;

- (id)init
{
    if ((self=[super init])) {
        _popoverArrowDirection = UIPopoverArrowDirectionUnknown;
    }
    return self;
}


- (id)initWithContentViewController:(UIViewController *)viewController
{
    if ((self=[self init])) {
        self.contentViewController = viewController;
    }
    return self;
}

- (void)dealloc
{
    [self _destroyPopover];
    [_passthroughViews release];
    [_contentViewController release];
    [super dealloc];
}

- (void)setDelegate:(id<UIPopoverControllerDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.popoverControllerDidDismissPopover = [_delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)];
    _delegateHas.popoverControllerShouldDismissPopover = [_delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)];
}

- (void)setContentViewController:(UIViewController *)controller animated:(BOOL)animated
{
    if (controller != _contentViewController) {
        if ([self isPopoverVisible]) {
            [_popoverView setContentView:controller.view animated:animated];
        }
        [_contentViewController release];
        _contentViewController = [controller retain];
    }
}

- (void)setContentViewController:(UIViewController *)viewController
{
    [self setContentViewController:viewController animated:NO];
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    assert(_isDismissing == NO);
    assert(view != nil);
    assert(arrowDirections != UIPopoverArrowDirectionUnknown);
    assert(!CGRectIsNull(rect));
    assert(!CGRectEqualToRect(rect,CGRectZero));
    assert([[view.window.screen UIKitView] window] != nil);

    NSWindow *viewNSWindow = [[view.window.screen UIKitView] window];

    // only create new stuff if the popover isn't already visible
    if (![self isPopoverVisible]) {
        assert(_overlayWindow == nil);
        assert(_popoverView == nil);
        assert(_popoverWindow == nil);
        
        // build an overlay window which will capture any clicks on the main window the popover is being presented from and then dismiss it.
        // this overlay can also be used to implement the pass-through views of the popover, but I'm not going to do that right now since
        // we don't need it. attach the overlay window to the "main" window.
        NSRect windowFrame = [viewNSWindow frame];
        NSRect overlayContentRect = NSMakeRect(0,0,windowFrame.size.width,windowFrame.size.height);

        UIPopoverOverlayNSView *popoverOverlayNSView = [[UIPopoverOverlayNSView alloc] initWithFrame:overlayContentRect popoverController:self];
        
        _overlayWindow = [[NSWindow alloc] initWithContentRect:overlayContentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_overlayWindow setContentView:popoverOverlayNSView];
        [_overlayWindow setIgnoresMouseEvents:NO];
        [_overlayWindow setOpaque:NO];
        [(NSWindow *)_overlayWindow setBackgroundColor:[NSColor clearColor]];
        [_overlayWindow setFrameOrigin:windowFrame.origin];
        [viewNSWindow addChildWindow:_overlayWindow ordered:NSWindowAbove];

        // now build the actual popover view which represents the popover's chrome, and since it's a UIView, we need to build a UIKitView 
        // as well to put it in our NSWindow...
        _popoverView = [[UIPopoverView alloc] initWithContentView:_contentViewController.view size:_contentViewController.contentSizeForViewInPopover];

        // this prevents a visible flash from sometimes occuring due to the fact that the window is created and added as a child before it has the
        // proper origin set. this means it it ends up flashing at the bottom left corner of the screen sometimes before it
        // gets down farther in this method where the actual origin is calculated and set. since the window is transparent, simply setting the UIView
        // hidden gets around the problem since you then can't see any of the actual content that's in the window :)
        _popoverView.hidden = YES;

        UIKitView *hostingView = [(UIKitView *)[UIKitView alloc] initWithFrame:NSRectFromCGRect([_popoverView bounds])];
        [[hostingView UIScreen] _setPopoverController:self];
        [[hostingView UIWindow] addSubview:_popoverView];

        // now finally make the actual popover window itself and attach it to the overlay window
        _popoverWindow = [[UIPopoverNSWindow alloc] initWithContentRect:[hostingView bounds] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [(UIPopoverNSWindow *)_popoverWindow setContentView:hostingView];
        [(UIPopoverNSWindow *)_popoverWindow setPopoverController:self];
        [(UIPopoverNSWindow *)_popoverWindow setOpaque:NO];
        [(UIPopoverNSWindow *)_popoverWindow setBackgroundColor:[NSColor clearColor]];
        [_overlayWindow addChildWindow:_popoverWindow ordered:NSWindowAbove];
        [(UIPopoverNSWindow *)_popoverWindow makeFirstResponder:hostingView];

        [hostingView release];
        [popoverOverlayNSView release];
    }

    // cancel current touches (if any) to prevent the main window from losing track of events (such as if the user was holding down the mouse
    // button and a timer triggered the appearance of this popover. the window would possibly then not receive the mouseUp depending on how
    // all this works out... I first ran into this problem with NSMenus. A NSWindow is a bit different, but I think this makes sense here
    // too so premptively doing it to avoid potential problems.)
    [[UIApplication sharedApplication] _cancelTouches];
    
    // now position the popover window according to the passed in parameters.
    CGRect windowRect = [view convertRect:rect toView:nil];
    CGRect screenRect = [view.window convertRect:windowRect toWindow:nil];
    CGRect desktopScreenRect = [view.window.screen convertRect:screenRect toScreen:nil];
    NSPoint pointTo = NSMakePoint(0,0);
    
    // finally, let's show it!
    [_popoverWindow setFrameOrigin:PopoverWindowOrigin(_overlayWindow, NSRectFromCGRect(desktopScreenRect), NSSizeFromCGSize(_popoverView.frame.size), arrowDirections, &pointTo, &_popoverArrowDirection)];
    _popoverView.hidden = NO;
    [_popoverWindow makeKeyWindow];

    // the window has to be visible before these coordinate conversions will work correctly (otherwise the UIScreen isn't attached to anything
    // and blah blah blah...)
    // finally, set the arrow position so it points to the right place and looks all purty.
    if (_popoverArrowDirection != UIPopoverArrowDirectionUnknown) {
        CGPoint screenPointTo = [view.window.screen convertPoint:NSPointToCGPoint(pointTo) fromScreen:nil];
        CGPoint windowPointTo = [view.window convertPoint:screenPointTo fromWindow:nil];
        CGPoint viewPointTo = [view convertPoint:windowPointTo fromView:nil];
        [_popoverView pointTo:viewPointTo inView:view];
    }
    
    if (animated) {
        _popoverView.transform = CGAffineTransformMakeScale(0.98f,0.98f);
        _popoverView.alpha = 0.4f;
        
        [UIView animateWithDuration:0.08 animations:^(void) {
            _popoverView.transform = CGAffineTransformIdentity;
        }];
        
        [UIView animateWithDuration:0.1 animations:^(void) {
            _popoverView.alpha = 1.f;
        }];
    }
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
}

- (BOOL)isPopoverVisible
{
    return (_popoverView || _popoverWindow || _overlayWindow);
}

- (void)_destroyPopover
{
	NSWindow *parentWindow = [[_overlayWindow parentWindow] retain];

    [_overlayWindow removeChildWindow:_popoverWindow];
    [parentWindow removeChildWindow:_overlayWindow];

    [_popoverView release];
    _popoverView = nil;

    [_popoverWindow close];
    _popoverWindow = nil;

    [_overlayWindow close];
    _overlayWindow = nil;
    
    _popoverArrowDirection = UIPopoverArrowDirectionUnknown;
    
    [parentWindow makeKeyAndOrderFront:self];
    [parentWindow release];
    
    _isDismissing = NO;
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (!_isDismissing && [self isPopoverVisible]) {
        _isDismissing = YES;

        [UIView animateWithDuration:animated? 0.2 : 0
                         animations:^(void) {
                             _popoverView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self _destroyPopover];
                         }];
    }
}

- (void)_closePopoverWindowIfPossible
{
    if (!_isDismissing && [self isPopoverVisible]) {
        const BOOL shouldDismiss = _delegateHas.popoverControllerShouldDismissPopover? [_delegate popoverControllerShouldDismissPopover:self] : YES;

        if (shouldDismiss) {
            [self dismissPopoverAnimated:YES];
            
            if (_delegateHas.popoverControllerDidDismissPopover) {
                [_delegate popoverControllerDidDismissPopover:self];
            }
        }
    }
}

@end
