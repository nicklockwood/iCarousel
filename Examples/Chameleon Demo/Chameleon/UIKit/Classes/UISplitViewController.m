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

#import "UISplitViewController.h"
#import "UIViewController+UIPrivate.h"
#import "UIView.h"
#import "UITouch.h"
#import "UIColor.h"
#import "UIResponderAppKitIntegration.h"
#import <AppKit/NSCursor.h>

static const CGFloat SplitterPadding = 3;

@interface _UISplitViewControllerView : UIView {
    BOOL dragging;
    UIView *leftPanel;
    UIView *rightPanel;
}
@property (nonatomic, assign) CGFloat leftWidth;
- (void)addViewControllers:(NSArray *)viewControllers;
@end

@implementation _UISplitViewControllerView

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        leftPanel = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,frame.size.height)];
        rightPanel = [[UIView alloc] initWithFrame:CGRectMake(321,0,MAX(0,frame.size.width-321),frame.size.height)];
        leftPanel.clipsToBounds = rightPanel.clipsToBounds = YES;
        leftPanel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        rightPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:leftPanel];
        [self addSubview:rightPanel];
        
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc
{
    [leftPanel release];
    [rightPanel release];
    [super dealloc];
}

- (void)addViewControllers:(NSArray *)viewControllers
{
    if ([viewControllers count] == 2) {
        UIView *leftView = [[viewControllers objectAtIndex:0] view];
        UIView *rightView = [[viewControllers objectAtIndex:1] view];
        
        leftView.autoresizingMask = rightView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        leftView.frame = leftPanel.bounds;
        rightView.frame = rightPanel.bounds;
        
        [leftPanel addSubview:leftView];
        [rightPanel addSubview:rightView];
    }
}

- (void)setLeftWidth:(CGFloat)newWidth
{
    if (newWidth != leftPanel.frame.size.width) {
        CGRect leftFrame = leftPanel.frame;
        CGRect rightFrame = rightPanel.frame;
        const CGFloat height = self.bounds.size.height;
        
        leftFrame.origin = CGPointZero;
        leftFrame.size = CGSizeMake(newWidth, height);

        rightFrame.origin = CGPointMake(newWidth+1,0);
        rightFrame.size = CGSizeMake(MAX(self.bounds.size.width-newWidth-1,0), height);
        
        leftPanel.frame = leftFrame;
        rightPanel.frame = rightFrame;
    }
}

- (CGFloat)leftWidth
{
    return CGRectGetMaxX(leftPanel.frame);
}

- (CGRect)splitterHitRect
{
    return CGRectMake(self.leftWidth-SplitterPadding,0,SplitterPadding+SplitterPadding+1,self.bounds.size.height);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint([self splitterHitRect], point)) {
        return self;
    } else {
        return [super hitTest:point withEvent:event];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];

    if (CGRectContainsPoint([self splitterHitRect], point)) {
        dragging = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (dragging) {
        CGFloat newWidth = [[touches anyObject] locationInView:self].x;
        
        newWidth = MAX(50, newWidth);
        newWidth = MIN(self.bounds.size.width-50, newWidth);
        
        self.leftWidth = newWidth;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    dragging = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    dragging = NO;
}

- (id)mouseCursorForEvent:(UIEvent *)event
{
    CGRect splitterRect = [self splitterHitRect];
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];

    if (dragging && point.x < splitterRect.origin.x) {
        return [NSCursor resizeLeftCursor];
    } else if (dragging && point.x > splitterRect.origin.x+splitterRect.size.width) {
        return [NSCursor resizeRightCursor];
    } else if (dragging || CGRectContainsPoint(splitterRect, point)) {
        return [NSCursor resizeLeftRightCursor];
    } else {
        return [super mouseCursorForEvent:event];
    }
}

@end



@implementation UISplitViewController
@synthesize delegate=_delegate, viewControllers=_viewControllers;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    if ((self=[super initWithNibName:nibName bundle:nibBundle])) {
    }
    return self;
}

- (void)dealloc
{
    [_viewControllers release];
    [super dealloc];
}

- (void)setDelegate:(id <UISplitViewControllerDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.willPresentViewController = [_delegate respondsToSelector:@selector(splitViewController:popoverController:willPresentViewController:)];
    _delegateHas.willHideViewController = [_delegate respondsToSelector:@selector(splitViewController:willHideViewController:withBarButtonItem:forPopoverController:)];
    _delegateHas.willShowViewController = [_delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)];
}

- (void)loadView
{
    self.view = [[[_UISplitViewControllerView alloc] initWithFrame:CGRectMake(0,0,1024,768)] autorelease];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setViewControllers:(NSArray *)newControllers
{
    assert([newControllers count]==2);
    
    if (![newControllers isEqualToArray:_viewControllers]) {
        for (UIViewController *c in _viewControllers) {
            [c _setParentViewController:nil];
        }

        for (UIViewController *c in newControllers) {
            [c _setParentViewController:self];
        }
        
        if ([self isViewLoaded]) {

            [(_UISplitViewControllerView *)self.view addViewControllers:_viewControllers];

            for (UIViewController *c in newControllers) {
                [c viewWillAppear:NO];
            }
            
            for (UIViewController *c in _viewControllers) {
                if ([c isViewLoaded]) {
                    [c.view removeFromSuperview];
                }
            }

            for (UIViewController *c in newControllers) {
                [c viewDidAppear:NO];
            }
        }

        [_viewControllers release];
        _viewControllers = [newControllers copy];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [(_UISplitViewControllerView *)self.view addViewControllers:_viewControllers];
    for (UIViewController *c in _viewControllers) {
        [c viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    for (UIViewController *c in _viewControllers) {
        [c viewDidAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    for (UIViewController *c in _viewControllers) {
        [c viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    for (UIViewController *c in _viewControllers) {
        [c viewDidDisappear:animated];
    }
}

@end
