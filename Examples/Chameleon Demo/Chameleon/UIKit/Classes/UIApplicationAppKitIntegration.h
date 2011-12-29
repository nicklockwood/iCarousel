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

#import "UIApplication.h"
#import <AppKit/NSApplication.h>

extern NSString *const UIApplicationNetworkActivityIndicatorChangedNotification;

@interface UIApplication (AppKitIntegration)

// the -terminateApplicationBeforeDate: method will switch the UIApplication to the background state
// and put the NSApplication into a modal state and present an alert to the user with a "Quit Now" button.
// then it will allow any background tasks registered with UIApplcation (if any) to finish.
// if time expires before they finish, their expiration handlers will be called instead.
// once this is finished waiting/expiring stuff, it will run [NSApp replyToApplicationShouldTerminate:YES];
// if there's no background tasks to run after transitioning UIApplication to the background state, it will
// return NSTerminateNow and there will be no modal alerts presented to the user. otherwise it returns NSTerminateLater.
// this is intended to be run from NSApplicationDelegate's -applicationShouldTerminate: method like this:
/*

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return [[UIApplication sharedApplication] terminateApplicationBeforeDate:[NSDate dateWithTimeIntervalSinceNow:30]];
}

 */

- (NSApplicationTerminateReply)terminateApplicationBeforeDate:(NSDate *)timeoutDate;

@end
