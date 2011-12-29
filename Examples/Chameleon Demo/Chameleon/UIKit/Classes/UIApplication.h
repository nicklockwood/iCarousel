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

#import "UIResponder.h"
#import "UIDevice.h"
#import "UIApplicationDelegate.h"

extern NSString *const UIApplicationWillChangeStatusBarOrientationNotification;
extern NSString *const UIApplicationDidChangeStatusBarOrientationNotification;
extern NSString *const UIApplicationWillEnterForegroundNotification;
extern NSString *const UIApplicationWillTerminateNotification;
extern NSString *const UIApplicationWillResignActiveNotification;
extern NSString *const UIApplicationDidEnterBackgroundNotification;
extern NSString *const UIApplicationDidBecomeActiveNotification;
extern NSString *const UIApplicationDidFinishLaunchingNotification;

extern NSString *const UIApplicationLaunchOptionsURLKey;
extern NSString *const UIApplicationLaunchOptionsSourceApplicationKey;
extern NSString *const UIApplicationLaunchOptionsRemoteNotificationKey;
extern NSString *const UIApplicationLaunchOptionsAnnotationKey;
extern NSString *const UIApplicationLaunchOptionsLocalNotificationKey;
extern NSString *const UIApplicationLaunchOptionsLocationKey;

extern NSString *const UIApplicationDidReceiveMemoryWarningNotification;

extern NSString *const UITrackingRunLoopMode;

typedef enum {
  UIStatusBarStyleDefault,
  UIStatusBarStyleBlackTranslucent,
  UIStatusBarStyleBlackOpaque
} UIStatusBarStyle;

typedef enum {
    UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
    UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
    UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
    UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
} UIInterfaceOrientation;

#define UIInterfaceOrientationIsPortrait(orientation) \
((orientation) == UIInterfaceOrientationPortrait || \
(orientation) == UIInterfaceOrientationPortraitUpsideDown)

#define UIInterfaceOrientationIsLandscape(orientation) \
((orientation) == UIInterfaceOrientationLandscapeLeft || \
(orientation) == UIInterfaceOrientationLandscapeRight)

// push is not gonna work in mac os, unless you are apple (facetime)
typedef enum {
  UIRemoteNotificationTypeNone    = 0,
  UIRemoteNotificationTypeBadge   = 1 << 0,
  UIRemoteNotificationTypeSound   = 1 << 1,
  UIRemoteNotificationTypeAlert   = 1 << 2
} UIRemoteNotificationType;

// whenever the NSApplication is no longer "active" from OSX's point of view, your UIApplication instance
// will switch to UIApplicationStateInactive. This happens when the app is no longer in the foreground, for instance.
// chameleon will also switch to the inactive state when the screen is put to sleep due to power saving mode.
// when the screen wakes up or the app is brought to the foreground, it is switched back to UIApplicationStateActive.
// 
// UIApplicationStateBackground is now supported and your app will transition to this state in two possible ways.
// one is when the AppKitIntegration method -terminateApplicationBeforeDate: is called. that method is intended to be
// used when your NSApplicationDelegate is being asked to terminate. the application is also switched to
// UIApplicationStateBackground when the machine is put to sleep. when the machine is reawakened, it will transition
// back to UIApplicationStateInactive (as per the UIKit docs). The OS tends to reactive the app in the usual way if
// it happened to be the foreground app when the machine was put to sleep, so it should ultimately work out as expected.
//
// any registered background tasks are allowed to complete whenever the app switches into UIApplicationStateBackground
// mode, so that means that when -terminateApplicationBeforeDate: is called directly, we will wait on background tasks
// and also show an alert to the user letting them know what's happening. it also means we attempt to delay machine
// sleep whenever sleep is initiated for as long as we can until any pending background tasks are completed. (there is no
// alert in that case) this should allow your app time to do any of the usual things like sync with network services or
// save state. just as on iOS, there's no guarentee you'll have time to complete you background task and there's no
// guarentee that your expiration handler will even be called. additionally, the reliability of your network is certainly
// going to be suspect when entering sleep as well. so be aware - but basically these same constraints exist on iOS so
// in many respects it shouldn't affect your code much or at all.
typedef enum {
  UIApplicationStateActive,
  UIApplicationStateInactive,
  UIApplicationStateBackground
} UIApplicationState;

typedef NSUInteger UIBackgroundTaskIdentifier;

extern const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid;
extern const NSTimeInterval UIMinimumKeepAliveTimeout;

@class UIWindow, UIApplication, UILocalNotification;

@interface UIApplication : UIResponder {
@private
    UIEvent *_currentEvent;
    UIWindow *_keyWindow;
    NSMutableSet *_visibleWindows;
    UIApplicationState _applicationState;
    __unsafe_unretained id<UIApplicationDelegate> _delegate;
    BOOL _idleTimerDisabled;
    BOOL _networkActivityIndicatorVisible;
    BOOL _applicationSupportsShakeToEdit;
    NSUInteger _ignoringInteractionEvents;
    NSInteger _applicationIconBadgeNumber;
    NSDate *_backgroundTasksExpirationDate;
    NSMutableArray *_backgroundTasks;
}

+ (UIApplication *)sharedApplication;

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event;
- (void)sendEvent:(UIEvent *)event;

- (BOOL)openURL:(NSURL *)url;
- (BOOL)canOpenURL:(NSURL *)URL;

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated;  // no effect

- (void)beginIgnoringInteractionEvents;
- (void)endIgnoringInteractionEvents;
- (BOOL)isIgnoringInteractionEvents;

- (void)presentLocalNotificationNow:(UILocalNotification *)notification;
- (void)cancelLocalNotification:(UILocalNotification *)notification;
- (void)cancelAllLocalNotifications;

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^)(void))handler;
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@property (nonatomic, readonly) UIWindow *keyWindow;
@property (nonatomic, readonly) NSArray *windows;
@property (nonatomic, getter=isStatusBarHidden, readonly) BOOL statusBarHidden;
@property (nonatomic, readonly) CGRect statusBarFrame;
@property (nonatomic, getter=isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;	// does nothing, always returns NO
@property (nonatomic) UIInterfaceOrientation statusBarOrientation;
@property (nonatomic, readonly) NSTimeInterval statusBarOrientationAnimationDuration;
@property (nonatomic, assign) id<UIApplicationDelegate> delegate;
@property (nonatomic, getter=isIdleTimerDisabled) BOOL idleTimerDisabled;	// has no actual affect
@property (nonatomic) BOOL applicationSupportsShakeToEdit;					// no effect
@property (nonatomic) UIStatusBarStyle statusBarStyle;                      // always returns UIStatusBarStyleDefault
@property (nonatomic, readonly) UIApplicationState applicationState;        // see notes near UIApplicationState struct for details!
@property (nonatomic, readonly) NSTimeInterval backgroundTimeRemaining;     // always 0
@property (nonatomic) NSInteger applicationIconBadgeNumber;                 // no effect, but does set/get the number correctly
@property (nonatomic, copy) NSArray *scheduledLocalNotifications;           // no effect, returns nil

@end


@interface UIApplication(UIApplicationDeprecated)
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated __attribute__((deprecated)); // use -setStatusBarHidden:withAnimation:
@end
