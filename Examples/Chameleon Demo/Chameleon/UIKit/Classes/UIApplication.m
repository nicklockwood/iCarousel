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

#import "UIApplication+UIPrivate.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIKitView.h"
#import "UIEvent+UIPrivate.h"
#import "UITouch+UIPrivate.h"
#import "UIWindow+UIPrivate.h"
#import "UIPopoverController+UIPrivate.h"
#import "UIResponderAppKitIntegration.h"
#import "UIApplicationAppKitIntegration.h"
#import "UIKey+UIPrivate.h"
#import "UIBackgroundTask.h"
#import <Cocoa/Cocoa.h>

NSString *const UIApplicationWillChangeStatusBarOrientationNotification = @"UIApplicationWillChangeStatusBarOrientationNotification";
NSString *const UIApplicationDidChangeStatusBarOrientationNotification = @"UIApplicationDidChangeStatusBarOrientationNotification";
NSString *const UIApplicationWillEnterForegroundNotification = @"UIApplicationWillEnterForegroundNotification";
NSString *const UIApplicationWillTerminateNotification = @"UIApplicationWillTerminateNotification";
NSString *const UIApplicationWillResignActiveNotification = @"UIApplicationWillResignActiveNotification";
NSString *const UIApplicationDidEnterBackgroundNotification = @"UIApplicationDidEnterBackgroundNotification";
NSString *const UIApplicationDidBecomeActiveNotification = @"UIApplicationDidBecomeActiveNotification";
NSString *const UIApplicationDidFinishLaunchingNotification = @"UIApplicationDidFinishLaunchingNotification";

NSString *const UIApplicationNetworkActivityIndicatorChangedNotification = @"UIApplicationNetworkActivityIndicatorChangedNotification";

NSString *const UIApplicationLaunchOptionsURLKey = @"UIApplicationLaunchOptionsURLKey";
NSString *const UIApplicationLaunchOptionsSourceApplicationKey = @"UIApplicationLaunchOptionsSourceApplicationKey";
NSString *const UIApplicationLaunchOptionsRemoteNotificationKey = @"UIApplicationLaunchOptionsRemoteNotificationKey";
NSString *const UIApplicationLaunchOptionsAnnotationKey = @"UIApplicationLaunchOptionsAnnotationKey";
NSString *const UIApplicationLaunchOptionsLocalNotificationKey = @"UIApplicationLaunchOptionsLocalNotificationKey";
NSString *const UIApplicationLaunchOptionsLocationKey = @"UIApplicationLaunchOptionsLocationKey";

NSString *const UIApplicationDidReceiveMemoryWarningNotification = @"UIApplicationDidReceiveMemoryWarningNotification";

NSString *const UITrackingRunLoopMode = @"UITrackingRunLoopMode";

const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid = NSUIntegerMax; // correct?
const NSTimeInterval UIMinimumKeepAliveTimeout = 0;

static UIApplication *_theApplication = nil;

static CGPoint ScreenLocationFromNSEvent(UIScreen *theScreen, NSEvent *theNSEvent)
{
    CGPoint screenLocation = NSPointToCGPoint([[theScreen UIKitView] convertPoint:[theNSEvent locationInWindow] fromView:nil]);
    if (![[theScreen UIKitView] isFlipped]) {
        // the y coord from the NSView might be inverted
        screenLocation.y = theScreen.bounds.size.height - screenLocation.y - 1;
    }
    return screenLocation;
}

static CGPoint ScrollDeltaFromNSEvent(NSEvent *theNSEvent)
{
    double dx, dy;

    CGEventRef cgEvent = [theNSEvent CGEvent];
    const int64_t isContinious = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventIsContinuous);
    
    if (isContinious == 0) {
        CGEventSourceRef source = CGEventCreateSourceFromEvent(cgEvent);
        double pixelsPerLine;
        
        if (source) {
           pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
            CFRelease(source);
        } else {
            // docs often say things like, "the default is near 10" so it seems reasonable that if the source doesn't work
            // for some reason to fetch the pixels per line, then 10 is probably a decent fallback value. :)
            pixelsPerLine = 10;
        }

        dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis2) * pixelsPerLine;
        dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis1) * pixelsPerLine;
    } else {
        dx = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis2);
        dy = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis1);
    }

    return CGPointMake(-dx, -dy);
}

static BOOL TouchIsActiveGesture(UITouch *touch)
{
    return (touch.phase == _UITouchPhaseGestureBegan || touch.phase == _UITouchPhaseGestureChanged);
}

static BOOL TouchIsActiveNonGesture(UITouch *touch)
{
    return (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary);
}

static BOOL TouchIsActive(UITouch *touch)
{
    return TouchIsActiveGesture(touch) || TouchIsActiveNonGesture(touch);
}

@implementation UIApplication
@synthesize keyWindow=_keyWindow, delegate=_delegate, idleTimerDisabled=_idleTimerDisabled, applicationSupportsShakeToEdit=_applicationSupportsShakeToEdit;
@synthesize applicationIconBadgeNumber = _applicationIconBadgeNumber, applicationState=_applicationState;

+ (void)initialize
{
    if (self == [UIApplication class]) {
        _theApplication = [[UIApplication alloc] init];
    }
}

+ (UIApplication *)sharedApplication
{
    return _theApplication;
}

- (id)init
{
    if ((self=[super init])) {
        _currentEvent = [[UIEvent alloc] initWithEventType:UIEventTypeTouches];
        [_currentEvent _setTouch:[[[UITouch alloc] init] autorelease]];
        _visibleWindows = [[NSMutableSet alloc] init];
        _backgroundTasks = [[NSMutableArray alloc] init];
        _applicationState = UIApplicationStateActive;
        _applicationSupportsShakeToEdit = YES;		// yeah... not *really* true, but UIKit defaults to YES :)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_applicationWillResignActive:) name:NSWorkspaceScreensDidSleepNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:NSWorkspaceScreensDidWakeNotification object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [_currentEvent release];
    [_visibleWindows release];
    [_backgroundTasks release];
    [_backgroundTasksExpirationDate release];
    [super dealloc];
}

- (NSTimeInterval)statusBarOrientationAnimationDuration
{
    return 0.3;
}

- (BOOL)isStatusBarHidden
{
    return YES;
}

- (CGRect)statusBarFrame
{
    return CGRectZero;
}

- (NSTimeInterval)backgroundTimeRemaining
{
    return [_backgroundTasksExpirationDate timeIntervalSinceNow];
}

- (BOOL)isNetworkActivityIndicatorVisible
{
    return _networkActivityIndicatorVisible;
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)b
{
    if (b != [self isNetworkActivityIndicatorVisible]) {
        _networkActivityIndicatorVisible = b;
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationNetworkActivityIndicatorChangedNotification object:self];
    }
}

- (void)beginIgnoringInteractionEvents
{
    _ignoringInteractionEvents++;
}

- (void)endIgnoringInteractionEvents
{
    _ignoringInteractionEvents--;
}

- (BOOL)isIgnoringInteractionEvents
{
    return (_ignoringInteractionEvents > 0);
}

- (UIInterfaceOrientation)statusBarOrientation
{
    return UIInterfaceOrientationPortrait;
}

- (void)setStatusBarOrientation:(UIInterfaceOrientation)orientation
{
}

- (UIStatusBarStyle)statusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated
{
}

- (void)presentLocalNotificationNow:(UILocalNotification *)notification
{
}

- (void)cancelAllLocalNotifications
{
}

- (void)cancelLocalNotification:(UILocalNotification *)notification
{
}

- (NSArray *)scheduledLocalNotifications
{
    return nil;
}

- (void)setScheduledLocalNotifications:(NSArray *)scheduledLocalNotifications
{
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^)(void))handler
{
    UIBackgroundTask *task = [[[UIBackgroundTask alloc] initWithExpirationHandler:handler] autorelease];
    [_backgroundTasks addObject:task];
    return task.taskIdentifier;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier
{
    for (UIBackgroundTask *task in _backgroundTasks) {
        if (task.taskIdentifier == identifier) {
            [_backgroundTasks removeObject:task];
            break;
        }
    }
}

- (BOOL)_enterBackground
{
    if (self.applicationState != UIApplicationStateBackground) {
        _applicationState = UIApplicationStateBackground;
        
        if ([_delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [_delegate applicationDidEnterBackground:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:self];
        
        return YES;
    } else {
        return NO;
    }
}

- (void)_enterForeground
{
    if (self.applicationState == UIApplicationStateBackground) {
        if ([_delegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
            [_delegate applicationWillEnterForeground:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];
        
        _applicationState = UIApplicationStateInactive;
    }
}

- (BOOL)_runRunLoopForBackgroundTasksBeforeDate:(NSDate *)date
{
    // check if all tasks were done, and if so, break
    if ([_backgroundTasks count] == 0) {
        return NO;
    }

    // run the runloop in the default mode so things like connections and timers still work for processing our
    // background tasks. we'll make sure not to run this any longer than 1 second at a time, otherwise the alert
    // might hang around for a lot longer than is necessary since we might not have anything to run in the default
    // mode for awhile or something which would keep this method from returning.
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
    
    // otherwise check if we've timed out and if we are, break
    if ([[NSDate date] timeIntervalSinceReferenceDate] >= [_backgroundTasksExpirationDate timeIntervalSinceReferenceDate]) {
        return NO;
    }
    
    return YES;
}

- (void)_cancelBackgroundTasks
{
    // if there's any remaining tasks, run their expiration handlers
    for (UIBackgroundTask *task in [[_backgroundTasks copy] autorelease]) {
        if (task.expirationHandler) {
            task.expirationHandler();
        }
    }
    
    // remove any lingering tasks so we're back to being empty
    [_backgroundTasks removeAllObjects];
}

- (void)_runBackgroundTasks:(void (^)(void))run_tasks
{
    run_tasks();
}

- (NSApplicationTerminateReply)terminateApplicationBeforeDate:(NSDate *)timeoutDate
{
    [self _enterBackground];
    
    [_backgroundTasksExpirationDate release];
    _backgroundTasksExpirationDate = [timeoutDate retain];
    
    // we will briefly block here for a short time and run the runloop in an attempt to let the background tasks finish up before
    // actually prompting the user with an annoying alert. users are much more used to an app hanging for a brief moment while
    // quitting than they are with an alert appearing/disappearing suddenly that they might have had trouble reading and processing
    // before it's gone. that sort of thing creates anxiety.
    NSDate *blockingBackgroundExpiration = [NSDate dateWithTimeIntervalSinceNow:1.33];

    for (;;) {
        if (![self _runRunLoopForBackgroundTasksBeforeDate:blockingBackgroundExpiration] || [NSDate timeIntervalSinceReferenceDate] >= [blockingBackgroundExpiration timeIntervalSinceReferenceDate]) {
            break;
        }
    }

    // if it turns out we're all done with tasks (or maybe had none to begin with), we'll clean up the structures
    // and tell our app we can terminate immediately now.
    if ([_backgroundTasks count] == 0) {
        [self _cancelBackgroundTasks];
    
        // and reset our timer since we're done
        [_backgroundTasksExpirationDate release];
        _backgroundTasksExpirationDate = nil;
        
        // and return
        return NSTerminateNow;
    }
    
    // otherwise... we have to do a deferred thing so we can show an alert while we wait for background tasks to finish...
    
    void (^taskFinisher)(void) = ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setShowsSuppressionButton:NO];
        [alert setMessageText:@"Quitting"];
        [alert setInformativeText:@"Finishing some tasks..."];
        [alert addButtonWithTitle:@"Quit Now"];
        [alert layout];

        // to avoid upsetting the user with an alert that flashes too quickly to read, we'll later artifically ensure that
        // the alert has been visible for at least some small amount of time to give them a chance to see and understand it.
        NSDate *minimumDisplayTime = [NSDate dateWithTimeIntervalSinceNow:2.33];

        NSModalSession session = [NSApp beginModalSessionForWindow:alert.window];
        
        // run the runloop and wait for tasks to finish
        while ([NSApp runModalSession:session] == NSRunContinuesResponse) {
            if (![self _runRunLoopForBackgroundTasksBeforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]) {
                break;
            }
        }
        
        // when we exit the runloop loop, then we're done with the tasks. either they are all finished or the time has run out
        // so we need to clean things up here as if we're all finished. if there's any remaining tasks, run their expiration handlers
        [self _cancelBackgroundTasks];
        
        // and reset our timer since we're done
        [_backgroundTasksExpirationDate release];
        _backgroundTasksExpirationDate = nil;

        // now just in case all of this happened too quickly and the user might not have had time to read and understand the alert,
        // we will kill some time for a bit as long as the alert is still visible. runModalSession: will not return NSRunContinuesResponse
        // if the user closed the alert, so in that case then this delay won't happen at all. however if the tasks finished too quickly
        // then what this does is kill time until the user clicks the quit button or the timer expires.
        while ([NSApp runModalSession:session] == NSRunContinuesResponse) {
            if ([NSDate timeIntervalSinceReferenceDate] >= [minimumDisplayTime timeIntervalSinceReferenceDate]) {
                break;
            }
        }

        [alert release];

        [NSApp endModalSession:session];
        
        // tell the real NSApp we're all done here
        [NSApp replyToApplicationShouldTerminate:YES];
    };
    
    // I need to delay this but run it on the main thread and also be able to run it in the panel run loop mode
    // because we're probably in that run loop mode due to how -applicationShouldTerminate: does things. I don't
    // know if I could do this same thing with a couple of simple GCD calls, but whatever, this works too. :)
    [self performSelectorOnMainThread:@selector(_runBackgroundTasks:)
                           withObject:[[taskFinisher copy] autorelease]
                        waitUntilDone:NO
                                modes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSRunLoopCommonModes, nil]];
    
    return NSTerminateLater;
}

- (void)_computerWillSleep:(NSNotification *)note
{
    if ([self _enterBackground]) {
        // docs say we have 30 seconds to return from our handler for the sleep notification, so we'll let background tasks
        // take up to 29 of them with the idea that hopefully this means that any cancelation handlers that might need to run
        // have a full second or so to finish up before we're forced to sleep.
        // since we can just block here we don't need to put the app into a modal state or popup a window or anything because
        // the machine is about to go to sleep.. so we'll just do things in a blocking way in this case while still handling
        // any pending background tasks.

        [_backgroundTasksExpirationDate release];
        _backgroundTasksExpirationDate = [[NSDate alloc] initWithTimeIntervalSinceNow:29];

        for (;;) {
            if (![self _runRunLoopForBackgroundTasksBeforeDate:_backgroundTasksExpirationDate]) {
                break;
            }
        }
        
        [self _cancelBackgroundTasks];

        // and reset our timer since we're done
        [_backgroundTasksExpirationDate release];
        _backgroundTasksExpirationDate = nil;
    }
}

- (void)_computerDidWakeUp:(NSNotification *)note
{
    [self _enterForeground];
}

- (void)_setKeyWindow:(UIWindow *)newKeyWindow
{
    _keyWindow = newKeyWindow;

    if (_keyWindow) {
        // this will make the NSView that the key window lives on the first responder in its NSWindow
        // highly confusing, but I think this is mostly the correct thing to do
        // when a UIView is made first responder, it also tells its window to become the key window
        // which means that we can ultimately end up here and if keyboard stuff is to work as expected
        // (for example) the underlying NSView really needs to be the first responder as far as AppKit
        // is concerned. this is all very confusing in my mind right now, but I think it makes sense.
        [[[_keyWindow.screen UIKitView] window] makeFirstResponder:[_keyWindow.screen UIKitView]];
    }
}

- (void)_windowDidBecomeVisible:(UIWindow *)theWindow
{
    [_visibleWindows addObject:[NSValue valueWithNonretainedObject:theWindow]];
}

- (void)_windowDidBecomeHidden:(UIWindow *)theWindow
{
    if (theWindow == _keyWindow) [self _setKeyWindow:nil];
    [_visibleWindows removeObject:[NSValue valueWithNonretainedObject:theWindow]];
}

- (NSArray *)windows
{
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"windowLevel" ascending:YES] autorelease];
    return [[_visibleWindows valueForKey:@"nonretainedObjectValue"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event
{
    if (!target) {
        // The docs say this method will start with the first responder if target==nil. Initially I thought this meant that there was always a given
        // or set first responder (attached to the window, probably). However it doesn't appear that is the case. Instead it seems UIKit is perfectly
        // happy to function without ever having any UIResponder having had a becomeFirstResponder sent to it. This method seems to work by starting
        // with sender and traveling down the responder chain from there if target==nil. The first object that responds to the given action is sent
        // the message. (or no one is)
        
        // My confusion comes from the fact that motion events and keyboard events are supposed to start with the first responder - but what is that
        // if none was ever set? Apparently the answer is, if none were set, the message doesn't get delivered. If you expicitly set a UIResponder
        // using becomeFirstResponder, then it will receive keyboard/motion events but it does not receive any other messages from other views that
        // happen to end up calling this method with a nil target. So that's a seperate mechanism and I think it's confused a bit in the docs.
        
        // It seems that the reality of message delivery to "first responder" is that it depends a bit on the source. If the source is an external
        // event like motion or keyboard, then there has to have been an explicitly set first responder (by way of becomeFirstResponder) in order for
        // those events to even get delivered at all. If there is no responder defined, the action is simply never sent and thus never received.
        // This is entirely independent of what "first responder" means in the context of a UIControl. Instead, for a UIControl, the first responder
        // is the first UIResponder (including the UIControl itself) that responds to the action. It starts with the UIControl (sender) and not with
        // whatever UIResponder may have been set with becomeFirstResponder.
        
        id responder = sender;
        while (responder) {
            if ([responder respondsToSelector:action]) {
                target = responder;
                break;
            } else if ([responder respondsToSelector:@selector(nextResponder)]) {
                responder = [responder nextResponder];
            } else {
                responder = nil;
            }
        }
    }
    
    if (target) {
        [target performSelector:action withObject:sender withObject:event];
        return YES;
    } else {
        return NO;
    }
}

- (UIResponder *)_firstResponderForScreen:(UIScreen *)screen
{
    if (_keyWindow.screen == screen) {
        return [_keyWindow _firstResponder];
    } else {
        return nil;
    }
}

- (BOOL)_sendActionToFirstResponder:(SEL)action withSender:(id)sender fromScreen:(UIScreen *)theScreen
{
    UIResponder *responder = [self _firstResponderForScreen:theScreen];
    
    while (responder) {
        if ([responder respondsToSelector:action]) {
            [responder performSelector:action withObject:sender];
            return YES;
        } else {
            responder = [responder nextResponder];
        }
    }
    
    return NO;
}

- (BOOL)_firstResponderCanPerformAction:(SEL)action withSender:(id)sender fromScreen:(UIScreen *)theScreen
{
    return [[self _firstResponderForScreen:theScreen] canPerformAction:action withSender:sender];
}

- (void)sendEvent:(UIEvent *)event
{
    for (UITouch *touch in [event allTouches]) {
        [touch.window sendEvent:event];
    }
}

- (BOOL)openURL:(NSURL *)url
{
    return url? [[NSWorkspace sharedWorkspace] openURL:url] : NO;
}

- (BOOL)canOpenURL:(NSURL *)url
{
    return (url? [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:url] : nil) != nil;
}

- (BOOL)_sendGlobalKeyboardNSEvent:(NSEvent *)theNSEvent fromScreen:(UIScreen *)theScreen
{
    if (![self isIgnoringInteractionEvents]) {
        UIKey *key = [[[UIKey alloc] initWithNSEvent:theNSEvent] autorelease];
        
        if (key.type == UIKeyTypeEnter || (key.commandKeyPressed && key.type == UIKeyTypeReturn)) {
            if ([self _firstResponderCanPerformAction:@selector(commit:) withSender:key fromScreen:theScreen]) {
                return [self _sendActionToFirstResponder:@selector(commit:) withSender:key fromScreen:theScreen];
            }
        }
    }
    
    return NO;
}

- (BOOL)_sendKeyboardNSEvent:(NSEvent *)theNSEvent fromScreen:(UIScreen *)theScreen
{
    if (![self isIgnoringInteractionEvents]) {
        if (![self _sendGlobalKeyboardNSEvent:theNSEvent fromScreen:theScreen]) {
            UIResponder *firstResponder = [self _firstResponderForScreen:theScreen];
            
            if (firstResponder) {
                UIKey *key = [[[UIKey alloc] initWithNSEvent:theNSEvent] autorelease];
                UIEvent *event = [[[UIEvent alloc] initWithEventType:UIEventTypeKeyPress] autorelease];
                [event _setTimestamp:[theNSEvent timestamp]];
                
                [firstResponder keyPressed:key withEvent:event];
                return ![event _isUnhandledKeyPressEvent];
            }
        }
    }
    
    return NO;
}

- (void)_setCurrentEventTouchedViewWithNSEvent:(NSEvent *)theNSEvent fromScreen:(UIScreen *)theScreen
{
    const CGPoint screenLocation = ScreenLocationFromNSEvent(theScreen, theNSEvent);
    UITouch *touch = [[_currentEvent allTouches] anyObject];
    UIView *previousView = [touch.view retain];

    [touch _setTouchedView:[theScreen _hitTest:screenLocation event:_currentEvent]];
    
    if (touch.view != previousView) {
        [previousView mouseExitedView:previousView enteredView:touch.view withEvent:_currentEvent];
        [touch.view mouseExitedView:previousView enteredView:touch.view withEvent:_currentEvent];
    }
    
    [previousView release];
}

- (void)_sendMouseNSEvent:(NSEvent *)theNSEvent fromScreen:(UIScreen *)theScreen
{
    UITouch *touch = [[_currentEvent allTouches] anyObject];
    
    [_currentEvent _setTimestamp:[theNSEvent timestamp]];

    const NSTimeInterval timestamp = [theNSEvent timestamp];
    const CGPoint screenLocation = ScreenLocationFromNSEvent(theScreen, theNSEvent);

    // this is a special case to cancel any existing gestures (as far as the client code is concerned) if a mouse
    // button is pressed mid-gesture. the reason is that sometimes when using a magic mouse a user will intend to
    // click but if their finger moves against the surface ever so slightly, it will trigger a touch gesture to
    // begin instead. without this, the fact that we're in a touch gesture phase effectively overrules everything
    // else and clicks end up not getting registered. I don't think it's right to allow clicks to pass through when
    // we're in a gesture state since that'd be somewhat like a multitouch scenerio on a real iOS device and we're
    // not supporting anything like that at the moment.
    if (TouchIsActiveGesture(touch) && ([theNSEvent type] == NSLeftMouseDown || [theNSEvent type] == NSRightMouseDown)) {
        [touch _updatePhase:_UITouchPhaseGestureEnded screenLocation:screenLocation timestamp:timestamp];
        [self sendEvent:_currentEvent];
    }
    
    if (TouchIsActiveNonGesture(touch)) {
        switch ([theNSEvent type]) {
            case NSLeftMouseUp:
                [touch _updatePhase:UITouchPhaseEnded screenLocation:screenLocation timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
                
            case NSLeftMouseDragged:
                [touch _updatePhase:UITouchPhaseMoved screenLocation:screenLocation timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
        }
    } else if (TouchIsActiveGesture(touch)) {
        switch ([theNSEvent type]) {
            case NSEventTypeEndGesture:
                [touch _updatePhase:_UITouchPhaseGestureEnded screenLocation:screenLocation timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;

            case NSScrollWheel:
                // when captured here, the scroll wheel event had to have been part of a gesture - in other words it is a
                // touch device scroll event and is therefore mapped to UIPanGestureRecognizer.
                [touch _updateGesture:_UITouchGesturePan screenLocation:screenLocation delta:ScrollDeltaFromNSEvent(theNSEvent) rotation:0 magnification:0 timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
                
            case NSEventTypeMagnify:
                [touch _updateGesture:_UITouchGesturePinch screenLocation:screenLocation delta:CGPointZero rotation:0 magnification:[theNSEvent magnification] timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
                
            case NSEventTypeRotate:
                [touch _updateGesture:_UITouchGestureRotation screenLocation:screenLocation delta:CGPointZero rotation:[theNSEvent rotation] magnification:0 timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
                
            case NSEventTypeSwipe:
                [touch _updateGesture:_UITouchGestureSwipe screenLocation:screenLocation delta:ScrollDeltaFromNSEvent(theNSEvent) rotation:0 magnification:0 timestamp:timestamp];
                [self sendEvent:_currentEvent];
                break;
        }
    } else if (![self isIgnoringInteractionEvents]) {
        switch ([theNSEvent type]) {
            case NSLeftMouseDown:
                [touch _setPhase:UITouchPhaseBegan screenLocation:screenLocation tapCount:[theNSEvent clickCount] timestamp:timestamp];
                [self _setCurrentEventTouchedViewWithNSEvent:theNSEvent fromScreen:theScreen];
                [self sendEvent:_currentEvent];
                break;

            case NSEventTypeBeginGesture:
                [touch _setPhase:_UITouchPhaseGestureBegan screenLocation:screenLocation tapCount:0 timestamp:timestamp];
                [self _setCurrentEventTouchedViewWithNSEvent:theNSEvent fromScreen:theScreen];
                [self sendEvent:_currentEvent];
                break;

            case NSScrollWheel:
                // we should only get a scroll wheel event down here if it was done on a non-touch device or was the result of a momentum
                // scroll, so they are treated differently so we can tell them apart later in UIPanGestureRecognizer and UIScrollWheelGestureRecognizer
                // which are both used by UIScrollView.
                [touch _setDiscreteGesture:_UITouchDiscreteGestureScrollWheel screenLocation:screenLocation tapCount:0 delta:ScrollDeltaFromNSEvent(theNSEvent) timestamp:timestamp];
                [self _setCurrentEventTouchedViewWithNSEvent:theNSEvent fromScreen:theScreen];
                [self sendEvent:_currentEvent];
                break;

            case NSRightMouseDown:
                [touch _setDiscreteGesture:_UITouchDiscreteGestureRightClick screenLocation:screenLocation tapCount:[theNSEvent clickCount] delta:CGPointZero timestamp:timestamp];
                [self _setCurrentEventTouchedViewWithNSEvent:theNSEvent fromScreen:theScreen];
                [self sendEvent:_currentEvent];
                break;

            case NSMouseMoved:
            case NSMouseEntered:
            case NSMouseExited:
                [touch _setDiscreteGesture:_UITouchDiscreteGestureMouseMove screenLocation:screenLocation tapCount:0 delta:ScrollDeltaFromNSEvent(theNSEvent) timestamp:timestamp];
                [self _setCurrentEventTouchedViewWithNSEvent:theNSEvent fromScreen:theScreen];
                [self sendEvent:_currentEvent];
                break;
        }
    }
}

// this is used to cause an interruption/cancel of the current touches.
// Use this when a modal UI element appears (such as a native popup menu), or when a UIPopoverController appears. It seems to make the most sense
// to call _cancelTouches *after* the modal menu has been dismissed, as this causes UI elements to remain in their "pushed" state while the menu
// is being displayed. If that behavior isn't desired, the simple solution is to present the menu from touchesEnded: instead of touchesBegan:.
- (void)_cancelTouches
{
    UITouch *touch = [[_currentEvent allTouches] anyObject];
    const BOOL wasActiveTouch = TouchIsActive(touch);
        
    [touch _setTouchPhaseCancelled];
        
    if (wasActiveTouch) {
        [self sendEvent:_currentEvent];
    }
}

// this sets the touches view property to nil (while retaining the window property setting)
// this is used when a view is removed from its superview while it may have been the origin
// of an active touch. after a view is removed, we don't want to deliver any more touch events
// to it, but we still may need to route the touch itself for the sake of gesture recognizers
// so we need to retain the touch's original window setting so that events can still be routed.
//
// note that the touch itself is not being cancelled here so its phase remains unchanged.
// I'm not entirely certain if that's the correct thing to do, but I think it makes sense. The
// touch itself has not gone anywhere - just the view that it first touched. That breaks the
// delivery of the touch events themselves as far as the usual responder chain delivery is
// concerned, but that appears to be what happens in the real UIKit when you remove a view out
// from under an active touch.
//
// this whole thing is necessary because otherwise a gesture which may have been initiated over
// some specific view would end up getting cancelled/failing if the view under it happens to be
// removed. this is more common than you might expect. a UITableView that is not reusing rows
// does exactly this as it scrolls - which coincidentally is how I found this bug in the first
// place. :P
- (void)_removeViewFromTouches:(UIView *)aView
{
    for (UITouch *touch in [_currentEvent allTouches]) {
        if (touch.view == aView) {
            [touch _removeFromView];
        }
    }
}

- (void)_applicationWillTerminate:(NSNotification *)note
{
    if ([_delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
        [_delegate applicationWillTerminate:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:self];
}

- (void)_applicationWillResignActive:(NSNotification *)note
{
    if (self.applicationState == UIApplicationStateActive) {
        if ([_delegate respondsToSelector:@selector(applicationWillResignActive:)]) {
            [_delegate applicationWillResignActive:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:self];
        
        _applicationState = UIApplicationStateInactive;
    }
}

- (void)_applicationDidBecomeActive:(NSNotification *)note
{
    if (self.applicationState == UIApplicationStateInactive) {
        _applicationState = UIApplicationStateActive;

        if ([_delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [_delegate applicationDidBecomeActive:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:self];
    }
}

@end


@implementation UIApplication(UIApplicationDeprecated)

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated
{
}

@end
