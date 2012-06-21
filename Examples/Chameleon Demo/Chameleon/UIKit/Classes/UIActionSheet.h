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

#import "UIView.h"
#import "UIInterface.h"

@class UIActionSheet, UITabBar, UIToolbar, UIBarButtonItem;

@protocol UIActionSheetDelegate <NSObject>
@optional
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet;
- (void)didPresentActionSheet:(UIActionSheet *)actionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)actionSheetCancel:(UIActionSheet *)actionSheet;
@end

typedef enum {
  UIActionSheetStyleAutomatic        = -1,
  UIActionSheetStyleDefault          = UIBarStyleDefault,
  UIActionSheetStyleBlackTranslucent = UIBarStyleBlackTranslucent,
  UIActionSheetStyleBlackOpaque      = UIBarStyleBlackOpaque,
} UIActionSheetStyle;

@interface UIActionSheet : UIView {
@private
    __unsafe_unretained id<UIActionSheetDelegate> _delegate;
    NSInteger _destructiveButtonIndex;
    NSInteger _cancelButtonIndex;
    NSInteger _firstOtherButtonIndex;
    NSString *_title;
    NSMutableArray *_menuTitles;
    NSMutableArray *_separatorIndexes;
    UIActionSheetStyle _actionSheetStyle;
    id _menu;
    
    struct {
        unsigned clickedButtonAtIndex : 1;
        unsigned willPresentActionSheet : 1;
        unsigned didPresentActionSheet : 1;
        unsigned willDismissWithButtonIndex : 1;
        unsigned didDismissWithButtonIndex : 1;
        unsigned actionSheetCancel : 1;
    } _delegateHas;
}

- (id)initWithTitle:(NSString *)title delegate:(id<UIActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
- (NSInteger)addButtonWithTitle:(NSString *)title;

- (void)showInView:(UIView *)view;														// menu will appear wherever the mouse cursor is
- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;		// if rect is CGRectNull, the menu will appear wherever the mouse cursor is
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

// these are not yet implemented:
- (void)showFromToolbar:(UIToolbar *)view;
- (void)showFromTabBar:(UITabBar *)view;
- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) id<UIActionSheetDelegate> delegate;
@property (nonatomic, assign) UIActionSheetStyle actionSheetStyle;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;
@property (nonatomic) NSInteger destructiveButtonIndex;
@property (nonatomic) NSInteger cancelButtonIndex;
@property (nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property (nonatomic, readonly) NSInteger numberOfButtons;

@end
