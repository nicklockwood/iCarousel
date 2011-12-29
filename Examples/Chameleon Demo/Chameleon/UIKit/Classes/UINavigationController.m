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

#import "UINavigationController.h"
#import "UIViewController+UIPrivate.h"
#import "UITabBarController.h"
#import "UINavigationBar.h"
#import "UIToolbar.h"

static const NSTimeInterval kAnimationDuration = 0.33;
static const CGFloat NavBarHeight = 28;
static const CGFloat ToolbarHeight = 28;

@implementation UINavigationController
@synthesize viewControllers=_viewControllers, delegate=_delegate, navigationBar=_navigationBar;
@synthesize toolbar=_toolbar, toolbarHidden=_toolbarHidden, navigationBarHidden=_navigationBarHidden;
@synthesize visibleViewController=_visibleViewController;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    if ((self=[super initWithNibName:nibName bundle:bundle])) {
        _viewControllers = [[NSMutableArray alloc] initWithCapacity:1];
        _navigationBar = [[UINavigationBar alloc] init];
        _navigationBar.delegate = self;
        _toolbar = [[UIToolbar alloc] init];
        _toolbarHidden = YES;
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    if ((self=[self initWithNibName:nil bundle:nil])) {
        self.viewControllers = [NSArray arrayWithObject:rootViewController];
    }
    return self;
}

- (void)dealloc
{
    _navigationBar.delegate = nil;
    [_viewControllers release];
    [_visibleViewController release];
    [_navigationBar release];
    [_toolbar release];
    [super dealloc];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.didShowViewController = [_delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)];
    _delegateHas.willShowViewController = [_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)];
}

- (CGRect)_navigationBarFrame
{
    CGRect navBarFrame = self.view.bounds;
    navBarFrame.size.height = NavBarHeight;
    return navBarFrame;
}

- (CGRect)_toolbarFrame
{
    CGRect toolbarRect = self.view.bounds;
    toolbarRect.origin.y = toolbarRect.origin.y + toolbarRect.size.height - ToolbarHeight;
    toolbarRect.size.height = ToolbarHeight;
    return toolbarRect;
}

- (CGRect)_controllerFrameForTransition:(_UINavigationControllerVisibleControllerTransition)transition
{
    CGRect controllerFrame = self.view.bounds;
    
    // adjust for the nav bar
    if (!self.navigationBarHidden) {
        controllerFrame.origin.y += NavBarHeight;
        controllerFrame.size.height -= NavBarHeight;
    }
    
    // adjust for toolbar (if there is one)
    if (!self.toolbarHidden) {
        controllerFrame.size.height -= ToolbarHeight;
    }
    
    if (transition == _UINavigationControllerVisibleControllerTransitionPushAnimated) {
        controllerFrame = CGRectOffset(controllerFrame, controllerFrame.size.width, 0);
    } else if (transition == _UINavigationControllerVisibleControllerTransitionPopAnimated) {
        controllerFrame = CGRectOffset(controllerFrame, -controllerFrame.size.width, 0);
    }
    
    return controllerFrame;
}

- (void)_setVisibleViewControllerNeedsUpdate
{
	// schedules a deferred method to run
	if (!_visibleViewControllerNeedsUpdate) {
		_visibleViewControllerNeedsUpdate = YES;
		[self performSelector:@selector(_updateVisibleViewController) withObject:nil afterDelay:0];
	}
}

- (void)_updateVisibleViewController
{
	// do some bookkeeping
	_visibleViewControllerNeedsUpdate = NO;
    UIViewController *topViewController = [self.topViewController retain];
    
	// make sure the new top view is both loaded and set to appear in the correct place
	topViewController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
    
	if (_visibleViewControllerTransition == _UINavigationControllerVisibleControllerTransitionNone) {
		[_visibleViewController viewWillDisappear:NO];
		[topViewController viewWillAppear:NO];
        
        if (_delegateHas.willShowViewController) {
            [_delegate navigationController:self willShowViewController:topViewController animated:NO];
        }
        
		[_visibleViewController.view removeFromSuperview];
		[self.view insertSubview:topViewController.view atIndex:0];
        
		[_visibleViewController viewDidDisappear:NO];
		[topViewController viewDidAppear:NO];

        if (_delegateHas.didShowViewController) {
            [_delegate navigationController:self didShowViewController:topViewController animated:NO];
        }
    } else {
        const CGRect visibleControllerFrame = (_visibleViewControllerTransition == _UINavigationControllerVisibleControllerTransitionPushAnimated)
                                                ? [self _controllerFrameForTransition:_UINavigationControllerVisibleControllerTransitionPopAnimated]
                                                : [self _controllerFrameForTransition:_UINavigationControllerVisibleControllerTransitionPushAnimated];

        const CGRect topControllerFrame = [self _controllerFrameForTransition:_UINavigationControllerVisibleControllerTransitionNone];
        
        UIViewController *previouslyVisibleViewController = _visibleViewController;
        
        [UIView animateWithDuration:kAnimationDuration
                         animations:^(void) {
                             previouslyVisibleViewController.view.frame = visibleControllerFrame;
                             topViewController.view.frame = topControllerFrame;
                         }
                         completion:^(BOOL finished) {
                             [previouslyVisibleViewController.view removeFromSuperview];
                             [previouslyVisibleViewController viewDidDisappear:YES];
                             [topViewController viewDidAppear:YES];
                             
                             if (_delegateHas.didShowViewController) {
                                 [_delegate navigationController:self didShowViewController:topViewController animated:YES];
                             }
                         }];
	}
    
	[_visibleViewController release];
	_visibleViewController = [topViewController retain];
    
    [topViewController release];
}

- (void)loadView
{
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0,0,320,480)] autorelease];
    self.view.clipsToBounds = YES;
    
    UIViewController *viewController = self.visibleViewController;
    viewController.view.frame = [self _controllerFrameForTransition:_UINavigationControllerVisibleControllerTransitionNone];
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:viewController.view];
    
    _navigationBar.frame = [self _navigationBarFrame];
    _navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _navigationBar.hidden = self.navigationBarHidden;
    [self.view addSubview:_navigationBar];
    
    _toolbar.frame = [self _toolbarFrame];
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _toolbar.hidden = self.toolbarHidden;
    [self.view addSubview:_toolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.visibleViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.visibleViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.visibleViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.visibleViewController viewDidDisappear:animated];
}

- (void)setViewControllers:(NSArray *)newViewControllers animated:(BOOL)animated
{
    assert([newViewControllers count] >= 1);

    if (![newViewControllers isEqualToArray:_viewControllers]) {
        // remove them all in bulk
        [_viewControllers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:nil];
        [_viewControllers removeAllObjects];
        
        // reset the nav bar
        _navigationBar.items = nil;
        
        // add them back in one-by-one and only apply animation to the last one (if any)
        for (UIViewController *controller in newViewControllers) {
            [self pushViewController:controller animated:(animated && (controller == [newViewControllers lastObject]))];
        }
    }
}

- (void)setViewControllers:(NSArray *)newViewControllers
{
    [self setViewControllers:newViewControllers animated:NO];
}

- (UIViewController *)topViewController
{
    return [_viewControllers lastObject];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    assert(![viewController isKindOfClass:[UITabBarController class]]);
    assert(![_viewControllers containsObject:viewController]);

    // override the animated property based on current state
    animated = animated && _visibleViewController && self.view.window;
    
    // push on to controllers stack
    [_viewControllers addObject:viewController];
    [_navigationBar pushNavigationItem:viewController.navigationItem animated:animated];
    
    // take ownership responsibility
    [viewController _setParentViewController:self];
    
	// if animated and on screen, begin part of the transition immediately, specifically, get the new view
    // on screen asap and tell the new controller it's about to be made visible in an animated fashion
	if (animated) {
		_visibleViewControllerTransition = _UINavigationControllerVisibleControllerTransitionPushAnimated;

		viewController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
        
		[_visibleViewController viewWillDisappear:YES];
		[viewController viewWillAppear:YES];
        
        if (_delegateHas.willShowViewController) {
            [_delegate navigationController:self willShowViewController:viewController animated:YES];
        }

		[self.view insertSubview:viewController.view atIndex:0];
	}
    
	[self _setVisibleViewControllerNeedsUpdate];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    // don't allow popping the rootViewController
    if ([_viewControllers count] <= 1) {
        return nil;
    }
    
    UIViewController *formerTopViewController = [self.topViewController retain];
 
    // adjust the animate property
    animated = animated && self.view.window;

	// pop the controller stack
    [_viewControllers removeLastObject];
    
    // pop the nav bar - note that it's setting the delegate to nil and back because we use the nav bar's
    // -navigationBar:shouldPopItem: delegate method to determine when the user clicks the back button
    // but that method is also called when we do an animated pop like this, so this works around the cycle.
    // I don't love it.
    _navigationBar.delegate = nil;
    [_navigationBar popNavigationItemAnimated:animated];
    _navigationBar.delegate = self;
    
    // give up ownership of the view controller
    [formerTopViewController _setParentViewController:nil];
    
	// if animated, begin part of the transition immediately, specifically, get the new top view on screen asap
	// and tell the old visible controller it's about to be disappeared in an animated fashion
	if (animated && self.view.window) {
        // note the new top here so we don't have to use the accessor method all the time
        UIViewController *topController = [self.topViewController retain];

		_visibleViewControllerTransition = _UINavigationControllerVisibleControllerTransitionPopAnimated;

		// if we never updated the visible controller, we need to add the formerTopViewController
		// on to the screen so we can see it disappear since we're attempting to animate this
		if (!_visibleViewController) {
			_visibleViewController = [formerTopViewController retain];
			_visibleViewController.view.frame = [self _controllerFrameForTransition:_UINavigationControllerVisibleControllerTransitionNone];
			[self.view insertSubview:_visibleViewController.view atIndex:0];
		}
        
		topController.view.frame = [self _controllerFrameForTransition:_visibleViewControllerTransition];
        
		[_visibleViewController viewWillDisappear:YES];
		[topController viewWillAppear:YES];

        if (_delegateHas.willShowViewController) {
            [_delegate navigationController:self willShowViewController:topController animated:YES];
        }

		[self.view insertSubview:topController.view atIndex:0];

        [topController release];
	}
    
	[self _setVisibleViewControllerNeedsUpdate];

	return [formerTopViewController autorelease];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSMutableArray *popped = [[NSMutableArray alloc] init];

    if ([_viewControllers containsObject:viewController]) {
        while (self.topViewController != viewController) {
            UIViewController *poppedController = [self popViewControllerAnimated:animated];
            if (poppedController) {
                [popped addObject:poppedController];
            } else {
                break;
            }
        }
    }
    
    return [popped autorelease];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    return [self popToViewController:[_viewControllers objectAtIndex:0] animated:animated];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    // always initiate an animated pop and return NO so that the nav bar itself doesn't take it upon itself
    // to pop the item, instead popViewControllerAnimated: will command it to do so later.
    [self popViewControllerAnimated:YES];
    return NO;
}

- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated
{
    _toolbarHidden = hidden;
    _toolbar.hidden = hidden;
}

- (void)setToolbarHidden:(BOOL)hidden
{
    [self setToolbarHidden:hidden animated:NO];
}

- (BOOL)isToolbarHidden
{
    return _toolbarHidden || self.topViewController.hidesBottomBarWhenPushed;
}

- (void)setContentSizeForViewInPopover:(CGSize)newSize
{
    self.topViewController.contentSizeForViewInPopover = newSize;
}

- (CGSize)contentSizeForViewInPopover
{
    return self.topViewController.contentSizeForViewInPopover;
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden animated:(BOOL)animated; // doesn't yet animate
{
    _navigationBarHidden = navigationBarHidden;
    
    // this shouldn't just hide it, but should animate it out of view (if animated==YES) and then adjust the layout
    // so the main view fills the whole space, etc.
    _navigationBar.hidden = navigationBarHidden;
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden
{
    [self setNavigationBarHidden:navigationBarHidden animated:NO];
}

@end
