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

#import <Foundation/Foundation.h>

extern NSString *const UIMenuControllerWillShowMenuNotification;
extern NSString *const UIMenuControllerDidShowMenuNotification;
extern NSString *const UIMenuControllerWillHideMenuNotification;
extern NSString *const UIMenuControllerDidHideMenuNotification;
extern NSString *const UIMenuControllerMenuFrameDidChangeNotification;

@class UIView, UIWindow;

@interface UIMenuController : NSObject {
@private
    NSArray *_menuItems;
    NSMutableArray *_enabledMenuItems;
    id _menu;
    CGRect _menuFrame;
    CGPoint _menuLocation;
    BOOL _rightAlignMenu;
    UIWindow *_window;
}

+ (UIMenuController *)sharedMenuController;

- (void)setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated;
- (void)setTargetRect:(CGRect)targetRect inView:(UIView *)targetView;		// if targetRect is CGRectNull, the menu will appear wherever the mouse cursor was at the time this method was called
- (void)update;

@property (nonatomic, getter=isMenuVisible) BOOL menuVisible;
@property (copy) NSArray *menuItems;

// returned in screen coords of the screen that the view used in setTargetRect:inView: belongs to
// there's always a value here, but it's not likely to be terribly reliable except immidately after
// the menu is made visible. I have no intenstively tested what the real UIKit does in all the possible
// situations. You have been warned.
@property (nonatomic, readonly) CGRect menuFrame;

@end
