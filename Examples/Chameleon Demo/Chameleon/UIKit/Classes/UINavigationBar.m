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

#import "UINavigationBar.h"
#import "UINavigationBar+UIPrivate.h"
#import "UIGraphics.h"
#import "UIColor.h"
#import "UILabel.h"
#import "UINavigationItem.h"
#import "UINavigationItem+UIPrivate.h"
#import "UIFont.h"
#import "UIImage+UIPrivate.h"
#import "UIBarButtonItem.h"
#import "UIButton.h"

static const UIEdgeInsets kButtonEdgeInsets = {0,0,0,0};
static const CGFloat kMinButtonWidth = 30;
static const CGFloat kMaxButtonWidth = 200;
static const CGFloat kMaxButtonHeight = 24;

static const NSTimeInterval kAnimationDuration = 0.33;

typedef enum {
    _UINavigationBarTransitionPush,
    _UINavigationBarTransitionPop,
    _UINavigationBarTransitionReload		// explicitly tag reloads from changed UINavigationItem data
} _UINavigationBarTransition;

@implementation UINavigationBar
@synthesize tintColor=_tintColor, delegate=_delegate, items=_navStack;

+ (void)_setBarButtonSize:(UIView *)view
{
    CGRect frame = view.frame;
    frame.size = [view sizeThatFits:CGSizeMake(kMaxButtonWidth,kMaxButtonHeight)];
    frame.size.height = kMaxButtonHeight;
    frame.size.width = MAX(frame.size.width,kMinButtonWidth);
    view.frame = frame;
}

+ (UIButton *)_backButtonWithBarButtonItem:(UIBarButtonItem *)item
{
    if (!item) return nil;
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setBackgroundImage:[UIImage _backButtonImage] forState:UIControlStateNormal];
    [backButton setBackgroundImage:[UIImage _highlightedBackButtonImage] forState:UIControlStateHighlighted];
    [backButton setTitle:item.title forState:UIControlStateNormal];
    backButton.titleLabel.font = [UIFont systemFontOfSize:11];
    backButton.contentEdgeInsets = UIEdgeInsetsMake(0,15,0,7);
    [backButton addTarget:nil action:@selector(_backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self _setBarButtonSize:backButton];
    return backButton;
}

+ (UIView *)_viewWithBarButtonItem:(UIBarButtonItem *)item
{
    if (!item) return nil;

    if (item.customView) {
        [self _setBarButtonSize:item.customView];
        return item.customView;
    } else {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[UIImage _toolbarButtonImage] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage _highlightedToolbarButtonImage] forState:UIControlStateHighlighted];
        [button setTitle:item.title forState:UIControlStateNormal];
        [button setImage:item.image forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        button.contentEdgeInsets = UIEdgeInsetsMake(0,7,0,7);
        [button addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];
        [self _setBarButtonSize:button];
        return button;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _navStack = [[NSMutableArray alloc] init];
        self.tintColor = [UIColor colorWithRed:21/255.f green:21/255.f blue:25/255.f alpha:1];
    }
    return self;
}

- (void)dealloc
{
    [self.topItem _setNavigationBar: nil];
    [_navStack release];
    [_tintColor release];
    [super dealloc];
}

- (void)setDelegate:(id)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.shouldPushItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPushItem:)];
    _delegateHas.didPushItem = [_delegate respondsToSelector:@selector(navigationBar:didPushItem:)];
    _delegateHas.shouldPopItem = [_delegate respondsToSelector:@selector(navigationBar:shouldPopItem:)];
    _delegateHas.didPopItem = [_delegate respondsToSelector:@selector(navigationBar:didPopItem:)];
}

- (UINavigationItem *)topItem
{
    return [_navStack lastObject];
}

- (UINavigationItem *)backItem
{
    return ([_navStack count] <= 1)? nil : [_navStack objectAtIndex:[_navStack count]-2];
}

- (void)_backButtonTapped:(id)sender
{
    [self popNavigationItemAnimated:YES];
}

- (void)_removeAnimatedViews:(NSArray *)views
{
    [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)_setViewsWithTransition:(_UINavigationBarTransition)transition animated:(BOOL)animated
{
    {
        NSMutableArray *previousViews = [[NSMutableArray alloc] init];

        if (_leftView) [previousViews addObject:_leftView];
        if (_centerView) [previousViews addObject:_centerView];
        if (_rightView) [previousViews addObject:_rightView];

        if (animated) {
            CGFloat moveCenterBy = self.bounds.size.width - ((_centerView)? _centerView.frame.origin.x : 0);
            CGFloat moveLeftBy = self.bounds.size.width * 0.33f;

            if (transition == _UINavigationBarTransitionPush) {
                moveCenterBy *= -1.f;
                moveLeftBy *= -1.f;
            }
            
            [UIView animateWithDuration:kAnimationDuration
                             animations:^(void) {
                                 if (_leftView)     _leftView.frame = CGRectOffset(_leftView.frame, moveLeftBy, 0);
                                 if (_centerView)   _centerView.frame = CGRectOffset(_centerView.frame, moveCenterBy, 0);
                             }];
            
            [UIView animateWithDuration:kAnimationDuration * 0.8
                                  delay:kAnimationDuration * 0.2
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^(void) {
                                 _leftView.alpha = 0;
                                 _rightView.alpha = 0;
                                 _centerView.alpha = 0;
                             }
                             completion:NULL];
            
            [self performSelector:@selector(_removeAnimatedViews:) withObject:previousViews afterDelay:kAnimationDuration];
        } else {
            [self _removeAnimatedViews:previousViews];
        }
        
        [previousViews release];
    }
    
    UINavigationItem *topItem = self.topItem;
    
    if (topItem) {
        UINavigationItem *backItem = self.backItem;
        
        // update weak references
        [backItem _setNavigationBar: nil];
        [topItem _setNavigationBar: self];

        CGRect leftFrame = CGRectZero;
        CGRect rightFrame = CGRectZero;
        
        if (backItem) {
            _leftView = [isa _backButtonWithBarButtonItem:backItem.backBarButtonItem];
        } else {
            _leftView = [isa _viewWithBarButtonItem:topItem.leftBarButtonItem];
        }

        if (_leftView) {
            leftFrame = _leftView.frame;
            leftFrame.origin = CGPointMake(kButtonEdgeInsets.left, kButtonEdgeInsets.top);
            _leftView.frame = leftFrame;
            [self addSubview:_leftView];
        }

        _rightView = [isa _viewWithBarButtonItem:topItem.rightBarButtonItem];

        if (_rightView) {
            _rightView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            rightFrame = _rightView.frame;
            rightFrame.origin.x = self.bounds.size.width-rightFrame.size.width - kButtonEdgeInsets.right;
            rightFrame.origin.y = kButtonEdgeInsets.top;
            _rightView.frame = rightFrame;
            [self addSubview:_rightView];
        }
        
        _centerView = topItem.titleView;

        if (!_centerView) {
            UILabel *titleLabel = [[[UILabel alloc] init] autorelease];
            titleLabel.text = topItem.title;
            titleLabel.textAlignment = UITextAlignmentCenter;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = [UIFont boldSystemFontOfSize:14];
            _centerView = titleLabel;
        }

        const CGFloat centerPadding = MAX(leftFrame.size.width, rightFrame.size.width);
        _centerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _centerView.frame = CGRectMake(kButtonEdgeInsets.left+centerPadding,kButtonEdgeInsets.top,self.bounds.size.width-kButtonEdgeInsets.right-kButtonEdgeInsets.left-centerPadding-centerPadding,kMaxButtonHeight);
        [self addSubview:_centerView];

        if (animated) {
            CGFloat moveCenterBy = self.bounds.size.width - ((_centerView)? _centerView.frame.origin.x : 0);
            CGFloat moveLeftBy = self.bounds.size.width * 0.33f;

            if (transition == _UINavigationBarTransitionPush) {
                moveLeftBy *= -1.f;
                moveCenterBy *= -1.f;
            }

            CGRect destinationLeftFrame = _leftView? _leftView.frame : CGRectZero;
            CGRect destinationCenterFrame = _centerView? _centerView.frame : CGRectZero;
            
            if (_leftView)      _leftView.frame = CGRectOffset(_leftView.frame, -moveLeftBy, 0);
            if (_centerView)    _centerView.frame = CGRectOffset(_centerView.frame, -moveCenterBy, 0);

            _leftView.alpha = 0;
            _rightView.alpha = 0;
            _centerView.alpha = 0;
            
            [UIView animateWithDuration:kAnimationDuration
                             animations:^(void) {
                                 _leftView.frame = destinationLeftFrame;
                                 _centerView.frame = destinationCenterFrame;
                             }];

            [UIView animateWithDuration:kAnimationDuration * 0.8
                                  delay:kAnimationDuration * 0.2
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:^(void) {
                                 _leftView.alpha = 1;
                                 _rightView.alpha = 1;
                                 _centerView.alpha = 1;
                             }
                             completion:NULL];
        }
    } else {
        _leftView = _centerView = _rightView = nil;
    }
}

- (void)setTintColor:(UIColor *)newColor
{
    if (newColor != _tintColor) {
        [_tintColor release];
        _tintColor = [newColor retain];
        [self setNeedsDisplay];
    }
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    if (![_navStack isEqualToArray:items]) {
        [_navStack removeAllObjects];
        [_navStack addObjectsFromArray:items];
        [self _setViewsWithTransition:_UINavigationBarTransitionPush animated:animated];
    }
}

- (void)setItems:(NSArray *)items
{
    [self setItems:items animated:NO];
}

- (UIBarStyle)barStyle
{
    return UIBarStyleDefault;
}

- (void)setBarStyle:(UIBarStyle)barStyle
{
}

- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated
{
    BOOL shouldPush = YES;

    if (_delegateHas.shouldPushItem) {
        shouldPush = [_delegate navigationBar:self shouldPushItem:item];
    }

    if (shouldPush) {
        [_navStack addObject:item];
        [self _setViewsWithTransition:_UINavigationBarTransitionPush animated:animated];
        
        if (_delegateHas.didPushItem) {
            [_delegate navigationBar:self didPushItem:item];
        }
    }
}

- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated
{
    UINavigationItem *previousItem = self.topItem;
    
    if (previousItem) {
        BOOL shouldPop = YES;

        if (_delegateHas.shouldPopItem) {
            shouldPop = [_delegate navigationBar:self shouldPopItem:previousItem];
        }
        
        if (shouldPop) {
            [previousItem retain];
            [_navStack removeObject:previousItem];
            [self _setViewsWithTransition:_UINavigationBarTransitionPop animated:animated];
            
            if (_delegateHas.didPopItem) {
                [_delegate navigationBar:self didPopItem:previousItem];
            }
            
            return [previousItem autorelease];
        }
    }
    
    return nil;
}

- (void)_updateNavigationItem:(UINavigationItem *)item animated:(BOOL)animated	// ignored for now
{
    // let's sanity-check that the item is supposed to be talking to us
    if (item != self.topItem) {
        [item _setNavigationBar:nil];
        return;
    }
    
    // this is going to remove & re-add all the item views. Not ideal, but simple enough that it's worth profiling.
    // next step is to add animation support-- that will require changing _setViewsWithTransition:animated:
    //  such that it won't perform any coordinate translations, only fade in/out
    
    // don't just fire the damned thing-- set a flag & mark as needing layout
    if (_navigationBarFlags.reloadItem == 0) {
        _navigationBarFlags.reloadItem = 1;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_navigationBarFlags.reloadItem) {
        _navigationBarFlags.reloadItem = 0;
        [self _setViewsWithTransition:_UINavigationBarTransitionReload animated:NO];
    }
}

- (void)drawRect:(CGRect)rect
{
    const CGRect bounds = self.bounds;
    
    // I kind of suspect that the "right" thing to do is to draw the background and then paint over it with the tintColor doing some kind of blending
    // so that it actually doesn "tint" the image instead of define it. That'd probably work better with the bottom line coloring and stuff, too, but
    // for now hardcoding stuff works well enough.
    
    [_tintColor setFill];
    UIRectFill(bounds);
}

@end
