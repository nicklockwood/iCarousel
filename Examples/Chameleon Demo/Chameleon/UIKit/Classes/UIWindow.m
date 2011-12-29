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

#import "UIWindow+UIPrivate.h"
#import "UIView+UIPrivate.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIApplication+UIPrivate.h"
#import "UIEvent.h"
#import "UITouch+UIPrivate.h"
#import "UIScreenMode.h"
#import "UIResponderAppKitIntegration.h"
#import "UIViewController.h"
#import "UIGestureRecognizerSubclass.h"
#import "UIGestureRecognizer+UIPrivate.h"
#import <AppKit/NSCursor.h>
#import <QuartzCore/QuartzCore.h>

const UIWindowLevel UIWindowLevelNormal = 0;
const UIWindowLevel UIWindowLevelStatusBar = 1000;
const UIWindowLevel UIWindowLevelAlert = 2000;

NSString *const UIWindowDidBecomeVisibleNotification = @"UIWindowDidBecomeVisibleNotification";
NSString *const UIWindowDidBecomeHiddenNotification = @"UIWindowDidBecomeHiddenNotification";
NSString *const UIWindowDidBecomeKeyNotification = @"UIWindowDidBecomeKeyNotification";
NSString *const UIWindowDidResignKeyNotification = @"UIWindowDidResignKeyNotification";

NSString *const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSString *const UIKeyboardDidShowNotification = @"UIKeyboardDidShowNotification";
NSString *const UIKeyboardWillHideNotification = @"UIKeyboardWillHideNotification";
NSString *const UIKeyboardDidHideNotification = @"UIKeyboardDidHideNotification";

NSString *const UIKeyboardFrameBeginUserInfoKey = @"UIKeyboardFrameBeginUserInfoKey";
NSString *const UIKeyboardFrameEndUserInfoKey = @"UIKeyboardFrameEndUserInfoKey";
NSString *const UIKeyboardAnimationDurationUserInfoKey = @"UIKeyboardAnimationDurationUserInfoKey";
NSString *const UIKeyboardAnimationCurveUserInfoKey = @"UIKeyboardAnimationCurveUserInfoKey";

// deprecated
NSString *const UIKeyboardCenterBeginUserInfoKey = @"UIKeyboardCenterBeginUserInfoKey";
NSString *const UIKeyboardCenterEndUserInfoKey = @"UIKeyboardCenterEndUserInfoKey";
NSString *const UIKeyboardBoundsUserInfoKey = @"UIKeyboardBoundsUserInfoKey";


@implementation UIWindow
@synthesize screen=_screen, rootViewController=_rootViewController;

- (id)initWithFrame:(CGRect)theFrame
{
    if ((self=[super initWithFrame:theFrame])) {
        _undoManager = [[NSUndoManager alloc] init];
        [self _makeHidden];	// do this first because before the screen is set, it will prevent any visibility notifications from being sent.
        self.screen = [UIScreen mainScreen];
        self.opaque = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _makeHidden];	// I don't really like this here, but the real UIKit seems to do something like this on window destruction as it sends a notification and we also need to remove it from the app's list of windows
    [_screen release];
    [_undoManager release];
    [_rootViewController release];
    
    // since UIView's dealloc is called after this one, it's hard ot say what might happen in there due to all of the subview removal stuff
    // so it's safer to make sure these things are nil now rather than potential garbage. I don't like how much work UIView's -dealloc is doing
    // but at the moment I don't see a good way around it...
    _screen = nil;
    _undoManager = nil;
    _rootViewController = nil;
    
    [super dealloc];
}

- (UIResponder *)_firstResponder
{
    return _firstResponder;
}

- (void)_setFirstResponder:(UIResponder *)newFirstResponder
{
    _firstResponder = newFirstResponder;
}

- (NSUndoManager *)undoManager
{
    return _undoManager;
}

- (UIView *)superview
{
    return nil;		// lies!
}

- (void)removeFromSuperview
{
    // does nothing
}

- (UIWindow *)window
{
    return self;
}

- (UIResponder *)nextResponder
{
    return [UIApplication sharedApplication];
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    if (rootViewController != _rootViewController) {
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_rootViewController release];
        _rootViewController = [rootViewController retain];
        _rootViewController.view.frame = self.bounds;    // unsure about this
        [self addSubview:_rootViewController.view];
    }
}

- (void)setScreen:(UIScreen *)theScreen
{
    if (theScreen != _screen) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenModeDidChangeNotification object:_screen];
        
        const BOOL wasHidden = self.hidden;
        [self _makeHidden];

        [self.layer removeFromSuperlayer];
        [_screen release];
        _screen = [theScreen retain];
        [[_screen _layer] addSublayer:self.layer];

        if (!wasHidden) {
            [self _makeVisible];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_screenModeChangedNotification:) name:UIScreenModeDidChangeNotification object:_screen];
    }
}

- (void)_screenModeChangedNotification:(NSNotification *)note
{
    UIScreenMode *previousMode = [[note userInfo] objectForKey:@"_previousMode"];
    UIScreenMode *newMode = _screen.currentMode;

    if (!CGSizeEqualToSize(previousMode.size,newMode.size)) {
        [self _superviewSizeDidChangeFrom:previousMode.size to:newMode.size];
    }
}

- (CGPoint)convertPoint:(CGPoint)toConvert toWindow:(UIWindow *)toWindow
{
    if (toWindow == self) {
        return toConvert;
    } else {
        // Convert to screen coordinates
        toConvert.x += self.frame.origin.x;
        toConvert.y += self.frame.origin.y;
        
        if (toWindow) {
            // Now convert the screen coords into the other screen's coordinate space
            toConvert = [self.screen convertPoint:toConvert toScreen:toWindow.screen];

            // And now convert it from the new screen's space into the window's space
            toConvert.x -= toWindow.frame.origin.x;
            toConvert.y -= toWindow.frame.origin.y;
        }
        
        return toConvert;
    }
}

- (CGPoint)convertPoint:(CGPoint)toConvert fromWindow:(UIWindow *)fromWindow
{
    if (fromWindow == self) {
        return toConvert;
    } else {
        if (fromWindow) {
            // Convert to screen coordinates
            toConvert.x += fromWindow.frame.origin.x;
            toConvert.y += fromWindow.frame.origin.y;
            
            // Change to this screen.
            toConvert = [self.screen convertPoint:toConvert fromScreen:fromWindow.screen];
        }
        
        // Convert to window coordinates
        toConvert.x -= self.frame.origin.x;
        toConvert.y -= self.frame.origin.y;

        return toConvert;
    }
}

- (CGRect)convertRect:(CGRect)toConvert fromWindow:(UIWindow *)fromWindow
{
    CGPoint convertedOrigin = [self convertPoint:toConvert.origin fromWindow:fromWindow];
    return CGRectMake(convertedOrigin.x, convertedOrigin.y, toConvert.size.width, toConvert.size.height);
}

- (CGRect)convertRect:(CGRect)toConvert toWindow:(UIWindow *)toWindow
{
    CGPoint convertedOrigin = [self convertPoint:toConvert.origin toWindow:toWindow];
    return CGRectMake(convertedOrigin.x, convertedOrigin.y, toConvert.size.width, toConvert.size.height);
}

- (void)becomeKeyWindow
{
    if ([[self _firstResponder] respondsToSelector:@selector(becomeKeyWindow)]) {
        [(id)[self _firstResponder] becomeKeyWindow];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeKeyNotification object:self];
}

- (void)makeKeyWindow
{
    if (!self.isKeyWindow) {
        [[UIApplication sharedApplication].keyWindow resignKeyWindow];
        [[UIApplication sharedApplication] _setKeyWindow:self];
        [self becomeKeyWindow];
    }
}

- (BOOL)isKeyWindow
{
    return ([UIApplication sharedApplication].keyWindow == self);
}

- (void)resignKeyWindow
{
    if ([[self _firstResponder] respondsToSelector:@selector(resignKeyWindow)]) {
        [(id)[self _firstResponder] resignKeyWindow];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidResignKeyNotification object:self];
}

- (void)_makeHidden
{
    if (!self.hidden) {
        [super setHidden:YES];
        if (self.screen) {
            [[UIApplication sharedApplication] _windowDidBecomeHidden:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeHiddenNotification object:self];
        }
    }
}

- (void)_makeVisible
{
    if (self.hidden) {
        [super setHidden:NO];
        if (self.screen) {
            [[UIApplication sharedApplication] _windowDidBecomeVisible:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIWindowDidBecomeVisibleNotification object:self];
        }
    }
}

- (void)setHidden:(BOOL)hide
{
    if (hide) {
        [self _makeHidden];
    } else {
        [self _makeVisible];
    }
}

- (void)makeKeyAndVisible
{
    [self _makeVisible];
    [self makeKeyWindow];
}

- (void)setWindowLevel:(UIWindowLevel)level
{
    self.layer.zPosition = level;
}

- (UIWindowLevel)windowLevel
{
    return self.layer.zPosition;
}

- (void)sendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeTouches) {
        NSSet *touches = [event touchesForWindow:self];
        NSMutableSet *gestureRecognizers = [NSMutableSet setWithCapacity:0];

        for (UITouch *touch in touches) {
            [gestureRecognizers addObjectsFromArray:touch.gestureRecognizers];
        }

        for (UIGestureRecognizer *recognizer in gestureRecognizers) {
            [recognizer _recognizeTouches:touches withEvent:event];
        }

        for (UITouch *touch in touches) {
            // normally there'd be no need to retain the view here, but this works around a strange problem I ran into.
            // what can happen is, now that UIView's -removeFromSuperview will remove the view from the active touch
            // instead of just cancel the touch (which is how I had implemented it previously - which was wrong), the
            // situation can arise where, in response to a touch event of some kind, the view may remove itself from its
            // superview in some fashion, which means that the handling of the touchesEnded:withEvent: (or whatever)
            // methods could somehow result in the view itself being destroyed before the method is even finished running!
            // I ran into this in particular with a load more button in Twitterrific which would crash in UIControl's
            // touchesEnded: implemention after sending actions to the registered targets (because one of those targets
            // ended up removing the button from view and thus reducing its retain count to 0). For some reason, even
            // though I attempted to rearrange stuff in UIControl so that actions were always the last thing done, it'd
            // still end up crashing when one of the internal methods returned to touchesEnded:, which didn't make sense
            // to me because there was no code after that (at the time) and therefore it should just have been unwinding
            // the stack to eventually get back here and all should have been okay. I never figured out exactly why that
            // crashed in that way, but by putting a retain here it works around this problem and perhaps others that have
            // gone so-far unnoticed. Converting to ARC should also work with this solution because there will be a local
            // strong reference to the view retainined throughout the rest of this logic and thus the same protection
            // against mid-method view destrustion should be provided under ARC. If someone can figure out some other,
            // better way to fix this without it having to have this hacky-feeling retain here, that'd be cool, but be
            // aware that this is here for a reason and that the problem it prevents is very rare and somewhat contrived.
            UIView *view = [touch.view retain];

            const UITouchPhase phase = touch.phase;
            const _UITouchGesture gesture = [touch _gesture];
            
            if (phase == UITouchPhaseBegan) {
                [view touchesBegan:touches withEvent:event];
            } else if (phase == UITouchPhaseMoved) {
                [view touchesMoved:touches withEvent:event];
            } else if (phase == UITouchPhaseEnded) {
                [view touchesEnded:touches withEvent:event];
            } else if (phase == UITouchPhaseCancelled) {
                [view touchesCancelled:touches withEvent:event];
            } else if (phase == _UITouchPhaseDiscreteGesture && gesture == _UITouchDiscreteGestureMouseMove) {
                if ([view hitTest:[touch locationInView:view] withEvent:event]) {
                    [view mouseMoved:[touch _delta] withEvent:event];
                }
            } else if (phase == _UITouchPhaseDiscreteGesture && gesture == _UITouchDiscreteGestureRightClick) {
                [view rightClick:touch withEvent:event];
            } else if ((phase == _UITouchPhaseDiscreteGesture && gesture == _UITouchDiscreteGestureScrollWheel) ||
                       (phase == _UITouchPhaseGestureChanged && gesture == _UITouchGesturePan)) {
                [view scrollWheelMoved:[touch _delta] withEvent:event];
            }
            
            NSCursor *newCursor = [view mouseCursorForEvent:event] ?: [NSCursor arrowCursor];

            if ([NSCursor currentCursor] != newCursor) {
                [newCursor set];
            }
            
            [view release];
        }
    }
}

@end
