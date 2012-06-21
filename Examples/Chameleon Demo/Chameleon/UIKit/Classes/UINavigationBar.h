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

#import "UIToolbar.h"
#import "UIView.h"

@class UIColor, UINavigationItem, UINavigationBar;

@protocol UINavigationBarDelegate <NSObject>
@optional
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item;
- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item;
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item;
@end

@interface UINavigationBar : UIView {
@private
    NSMutableArray *_navStack;
    UIColor *_tintColor;
    __unsafe_unretained id _delegate;
    
    UIView *_leftView;
    UIView *_centerView;
    UIView *_rightView;
    
    struct {
        unsigned shouldPushItem : 1;
        unsigned didPushItem : 1;
        unsigned shouldPopItem : 1;
        unsigned didPopItem : 1;
    } _delegateHas;
    
    // ideally this should share the same memory as the above flags structure...
    struct {
        unsigned reloadItem : 1;
        unsigned __RESERVED__ : 31;
    } _navigationBarFlags;
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;
- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated;

@property (nonatomic, assign) UIBarStyle barStyle;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, readonly, retain) UINavigationItem *topItem;
@property (nonatomic, readonly, retain) UINavigationItem *backItem;
@property (nonatomic, copy) NSArray *items;
@property (nonatomic, assign) id delegate;

@end
