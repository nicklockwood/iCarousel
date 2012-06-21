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

#import <QuartzCore/CALayer.h>
#import <Foundation/Foundation.h>
#import "UIStringDrawing.h"

@class UICustomNSClipView, UICustomNSTextView, UIColor, UIFont, UIScrollView, UIWindow, UIView;

@protocol UITextLayerContainerViewProtocol <NSObject>
@required
- (UIWindow *)window;
- (CALayer *)layer;
- (BOOL)isHidden;
- (BOOL)isDescendantOfView:(UIView *)view;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

// if any one of these doesn't exist, then scrolling of the NSClipView is disabled
@optional
- (BOOL)isScrollEnabled;
- (void)setContentOffset:(CGPoint)offset;
- (CGPoint)contentOffset;
- (void)setContentSize:(CGSize)size;
- (CGSize)contentSize;
@end

@protocol UITextLayerTextDelegate <NSObject>
@required
- (BOOL)_textShouldBeginEditing;
- (void)_textDidBeginEditing;
- (BOOL)_textShouldEndEditing;
- (void)_textDidEndEditing;
- (BOOL)_textShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

@optional
- (void)_textDidChange;
- (void)_textDidChangeSelection;
- (void)_textDidReceiveReturnKey;
@end

@interface UITextLayer : CALayer {
    id containerView;
    BOOL containerCanScroll;
    UICustomNSTextView *textView;
    UICustomNSClipView *clipView;
    BOOL secureTextEntry;
    BOOL editable;
    UIColor *textColor;
    UIFont *font;
    BOOL changingResponderStatus;

    struct {
        unsigned didChange : 1;
        unsigned didChangeSelection : 1;
        unsigned didReturnKey : 1;
    } textDelegateHas;
}

- (id)initWithContainer:(UIView <UITextLayerContainerViewProtocol,UITextLayerTextDelegate> *)aView isField:(BOOL)isField;
- (void)setContentOffset:(CGPoint)contentOffset;
- (void)scrollRangeToVisible:(NSRange)range;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@property (nonatomic, assign) NSRange selectedRange;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, assign) UITextAlignment textAlignment;

@end
