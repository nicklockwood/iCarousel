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

#import "UIInputController.h"
#import "UIWindow+UIPrivate.h"
#import "UIView+UIPrivate.h"
#import "UIApplication.h"
#import "UIScreen.h"


static UIView *ContainerForView(UIView *view)
{
    // find the reference view's "container" view, which I'm going to define as the nearest view of a UIViewController or a UIWindow.
    UIView *containerView = view;
    
    while (containerView && !([containerView isKindOfClass:[UIWindow class]] || [containerView _viewController])) {
        containerView = [containerView superview];
    }
    
    return containerView;
}


@implementation UIInputController
@synthesize inputAccessoryView=_inputAccessoryView, inputView=_inputView;

+ (UIInputController *)sharedInputController
{
    static UIInputController *controller = nil;
    
    if (!controller) {
        controller = [[self alloc] init];
    }
    
    return controller;
}

- (id)init
{
    if ((self=[super init])) {
        _inputWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
        _inputWindow.windowLevel = UIWindowLevelStatusBar;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewChangedNotification:) name:UIViewFrameDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_viewChangedNotification:) name:UIViewDidMoveToSuperviewNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_inputWindow release];
    [_inputAccessoryView release];
    [_inputView release];
    [super dealloc];
}

// finds the first real UIView that the current key window's first responder "belongs" to so we know where to display the input window
- (UIView *)_referenceView
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIResponder *firstResponder = [keyWindow _firstResponder];
    
    if (firstResponder) {
        UIResponder *currentResponder = firstResponder;
        
        // find the first real UIView that this responder "belongs" to so we know where to display the input view from
        while (currentResponder) {
            if ([currentResponder isKindOfClass:[UIView class]]) {
                return (UIView *)currentResponder;
            } else {
                currentResponder = [currentResponder nextResponder];
            }
        }
    }
    
    return nil;
}

- (void)_repositionInputWindow
{
    UIView *referenceView = [self _referenceView];
    UIView *containerView = ContainerForView(referenceView);
    UIScreen *screen = containerView.window.screen;
    
    if (screen && containerView) {
        _inputWindow.screen = screen;
        
        const CGRect viewFrameInWindow = [referenceView convertRect:referenceView.bounds toView:nil];
        const CGRect viewFrameInScreen = [referenceView.window convertRect:viewFrameInWindow toWindow:nil];
        
        const CGRect containerFrameInWindow = [containerView convertRect:containerView.bounds toView:nil];
        const CGRect containerFrameInScreen = [containerView.window convertRect:containerFrameInWindow toWindow:nil];
        
        const CGFloat inputWidth = CGRectGetWidth(containerFrameInScreen);
        CGFloat inputHeight = 0;

        if (_inputAccessoryView) {
            const CGFloat height = _inputAccessoryView.frame.size.height;
            _inputAccessoryView.autoresizingMask = UIViewAutoresizingNone;
            _inputAccessoryView.frame = CGRectMake(0, inputHeight, inputWidth, height);
            inputHeight += height;
        }
        
        if (_inputView) {
            const CGFloat height = _inputView.frame.size.height;
            _inputView.autoresizingMask = UIViewAutoresizingNone;
            _inputView.frame = CGRectMake(0, inputHeight, inputWidth, height);
            inputHeight += height;
        }
        
        _inputWindow.frame = CGRectMake(CGRectGetMinX(containerFrameInScreen), CGRectGetMaxY(viewFrameInScreen), inputWidth, inputHeight);
    }
}

- (void)_viewChangedNotification:(NSNotification *)note
{
    UIView *view = [note object];
    UIView *referenceView = [self _referenceView];

    if (self.inputVisible && (view == referenceView || [ContainerForView(referenceView) isDescendantOfView:view])) {
        [self _repositionInputWindow];
    }
}

- (void)setInputVisible:(BOOL)visible animated:(BOOL)animated
{
    [self _repositionInputWindow];
    
    NSDictionary *fakeAnimationInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSValue valueWithCGRect:_inputWindow.frame], UIKeyboardFrameBeginUserInfoKey,
                                       [NSValue valueWithCGRect:_inputWindow.frame], UIKeyboardFrameEndUserInfoKey,
                                       [NSNumber numberWithDouble:0], UIKeyboardAnimationDurationUserInfoKey,
                                       [NSNumber numberWithInt:UIViewAnimationCurveLinear], UIKeyboardAnimationCurveUserInfoKey,
                                       nil];
    
    if (visible) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillShowNotification object:nil userInfo:fakeAnimationInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification object:nil userInfo:fakeAnimationInfo];
    }
    
    _inputWindow.hidden = !visible;
    
    if (visible) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidShowNotification object:nil userInfo:fakeAnimationInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidHideNotification object:nil userInfo:fakeAnimationInfo];
    }
}

- (void)setInputVisible:(BOOL)inputVisible
{
    [self setInputVisible:inputVisible animated:NO];
}

- (BOOL)inputVisible
{
    return !_inputWindow.hidden;
}

- (void)setInputAccessoryView:(UIView *)view
{
    if (view != _inputAccessoryView) {
        [_inputAccessoryView removeFromSuperview];
        [_inputAccessoryView release];

        _inputAccessoryView = [view retain];
        [_inputWindow addSubview:_inputAccessoryView];
    }
}

- (void)setInputView:(UIView *)view
{
    if (view != _inputView) {
        [_inputView removeFromSuperview];
        [_inputView release];
        
        _inputView = [view retain];
        [_inputWindow addSubview:_inputView];
    }
}

@end
