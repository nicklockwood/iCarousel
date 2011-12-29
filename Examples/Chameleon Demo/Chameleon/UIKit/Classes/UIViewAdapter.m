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

#import "UIViewAdapter.h"
#import "UINSClipView.h"
#import "UIWindow.h"
#import "UIKitView.h"
#import "UIScrollView+UIPrivate.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIView+UIPrivate.h"
#import "UIApplication.h"
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>


@implementation UIViewAdapter
@synthesize NSView=_view;

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _clipView = [[UINSClipView alloc] initWithFrame:NSMakeRect(0,0,frame.size.width,frame.size.height) parentView:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hierarchyMayHaveChangedNotification:) name:UIViewHiddenDidChangeNotification object:nil];
    }
    return self;
}

- (id)initWithNSView:(NSView *)aNSView
{
    const NSSize viewFrameSize = aNSView? [aNSView frame].size : NSZeroSize;
    
    if ((self=[self initWithFrame:CGRectMake(0,0,viewFrameSize.width,viewFrameSize.height)])) {
        self.NSView = aNSView;
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewHiddenDidChangeNotification object:nil];
    [_view release];
    [_clipView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Magic

- (void)_addNSView
{
    [_clipView scrollToPoint:NSPointFromCGPoint(self.contentOffset)];
    
    [[self.window.screen UIKitView] addSubview:_clipView];
    
    // all of these notifications are hacks to detect when views or superviews of this view move or change in ways that require
    // the actual NSView to get updated. it's not pretty, but I cannot come up with a better way at this point.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateScrollViewAndFlashScrollbars) name:NSViewBoundsDidChangeNotification object:_clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hierarchyMayHaveChangedNotification:) name:UIViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hierarchyMayHaveChangedNotification:) name:UIViewBoundsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hierarchyMayHaveChangedNotification:) name:UIViewDidMoveToSuperviewNotification object:nil];
}

- (void)_removeNSView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewBoundsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewDidMoveToSuperviewNotification object:nil];
    
    [_clipView removeFromSuperview];
}

- (void)_updateLayers
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    CALayer *layer = self.layer;
    CALayer *clipLayer = [_clipView layer];
    
    // setting these here because I've had bad experiences with NSView changing some layer properties out from under me.
    clipLayer.geometryFlipped = YES;
    
    // always make sure it's at the very bottom
    [layer insertSublayer:clipLayer atIndex:0];
    
    // don't resize unless we have to
    if (!CGRectEqualToRect(clipLayer.frame, layer.bounds)) {
        clipLayer.frame = layer.bounds;
    }
    
    [CATransaction commit];
}

- (void)_updateScrollView
{
    const NSRect docRect = [_clipView documentRect];
    self.contentSize = CGSizeMake(docRect.size.width+docRect.origin.x, docRect.size.height+docRect.origin.y);
    self.contentOffset = NSPointToCGPoint([_clipView bounds].origin);
}

- (void)_updateScrollViewAndFlashScrollbars
{
    [self _updateScrollView];
    [self _quickFlashScrollIndicators];
}

- (BOOL)_NSViewShouldBeVisible
{
    if (_view && self.window) {
        UIView *v = self;

        while (v) {
            if (v.hidden) {
                return NO;
            }
            v = [v superview];
        }
        
        return YES;
    } else {
        return NO;
    }
}

- (void)_updateNSViews
{
    if ([self _NSViewShouldBeVisible]) {
        if ([_clipView superview] != [self.window.screen UIKitView]) {
            [self _addNSView];
        }
        
        // translate the adapter's frame to the real NSWindow's coordinate space so that the NSView lines up correctly
        UIWindow *window = self.window;
        const CGRect windowRect = [window convertRect:self.frame fromView:self.superview];
        const CGRect screenRect = [window convertRect:windowRect toWindow:nil];
        NSRect desiredFrame = NSRectFromCGRect(screenRect);
        [_clipView setFrame:desiredFrame];
        
        [self _updateScrollView];
        [self _updateLayers];
    } else {
        [self _removeNSView];
    }
}

- (void)_hierarchyMayHaveChangedNotification:(NSNotification *)note
{
    if ([self isDescendantOfView:[note object]]) {
        [self _updateNSViews];
    }
}

#pragma mark -
#pragma mark UIView Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self _updateLayers];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self _updateNSViews];
}

#pragma mark -
#pragma mark Properties

- (void)setNSView:(NSView *)aNSView
{
    if (aNSView != _view) {
        [self resignFirstResponder];
        [self _removeNSView];
        
        [_view release];
        _view = [aNSView retain];
        [_clipView setDocumentView:_view];
        
        [self _updateNSViews];
    }
}

#pragma mark -
#pragma mark UIScrollView Overrides

- (void)setContentOffset:(CGPoint)theOffset animated:(BOOL)animated
{
    // rounding to avoid fuzzy images from subpixel alignment issues
    theOffset.x = roundf(theOffset.x);
    theOffset.y = roundf(theOffset.y);

    [super setContentOffset:theOffset animated:animated];
    [_clipView scrollToPoint:[_clipView constrainScrollPoint:NSPointFromCGPoint(theOffset)]];
}

#pragma mark -
#pragma mark UIResponder Overrides

- (BOOL)canBecomeFirstResponder
{
    return [self _NSViewShouldBeVisible]? [_view acceptsFirstResponder] : NO;
}

- (BOOL)becomeFirstResponder
{
    [self _updateNSViews];

    if ([super becomeFirstResponder]) {
        [[_view window] makeFirstResponder:_view];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)resignFirstResponder
{
    [self _updateNSViews];

    const BOOL didResign = [super resignFirstResponder];
    
    if (didResign && [[_view window] firstResponder] == _view) {
        [[_view window] makeFirstResponder:[self.window.screen UIKitView]];
    }
    
    return didResign;
}

@end
