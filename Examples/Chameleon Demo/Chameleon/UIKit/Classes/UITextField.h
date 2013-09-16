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

#import "UIControl.h"
#import "UIStringDrawing.h"
#import "UITextInputTraits.h"

extern NSString *const UITextFieldTextDidBeginEditingNotification;
extern NSString *const UITextFieldTextDidChangeNotification;
extern NSString *const UITextFieldTextDidEndEditingNotification;

typedef enum {
    UITextBorderStyleNone,
    UITextBorderStyleLine,
    UITextBorderStyleBezel,
    UITextBorderStyleRoundedRect
} UITextBorderStyle;

typedef enum {
    UITextFieldViewModeNever,
    UITextFieldViewModeWhileEditing,
    UITextFieldViewModeUnlessEditing,
    UITextFieldViewModeAlways
} UITextFieldViewMode;

@class UIFont, UIColor, UITextField, UIImage, UITextLayer;

@protocol UITextFieldDelegate <NSObject>
@optional
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
- (BOOL)textFieldShouldClear:(UITextField *)textField;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
@end

@interface UITextField : UIControl <UITextInputTraits> {
@private
    UITextLayer *_textLayer;

    __unsafe_unretained id _delegate;
    UITextFieldViewMode _clearButtonMode;
    UIView *_leftView;
    UITextFieldViewMode _leftViewMode;
    UIView *_rightView;
    UITextFieldViewMode _rightViewMode;
    UIImage *_background;
    UIImage *_disabledBackground;
    BOOL _editing;
    BOOL _clearsOnBeginEditing;
    BOOL _adjustsFontSizeToFitWidth;
    NSString *_placeholder;
    UITextBorderStyle _borderStyle;
    CGFloat _minimumFontSize;

    UIView *_inputAccessoryView;
    UIView *_inputView;

    struct {
        unsigned shouldBeginEditing : 1;
        unsigned didBeginEditing : 1;
        unsigned shouldEndEditing : 1;
        unsigned didEndEditing : 1;
        unsigned shouldChangeCharacters : 1;
        unsigned shouldClear : 1;
        unsigned shouldReturn : 1;
    } _delegateHas;	
}

- (CGRect)borderRectForBounds:(CGRect)bounds;
- (CGRect)clearButtonRectForBounds:(CGRect)bounds;
- (CGRect)editingRectForBounds:(CGRect)bounds;
- (CGRect)leftViewRectForBounds:(CGRect)bounds;
- (CGRect)placeholderRectForBounds:(CGRect)bounds;
- (CGRect)rightViewRectForBounds:(CGRect)bounds;
- (CGRect)textRectForBounds:(CGRect)bounds;

- (void)drawPlaceholderInRect:(CGRect)rect;
- (void)drawTextInRect:(CGRect)rect;

@property (nonatomic, assign) id<UITextFieldDelegate> delegate;
@property (nonatomic, assign) UITextAlignment textAlignment;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic) UITextBorderStyle borderStyle;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, readonly, getter=isEditing) BOOL editing;
@property (nonatomic) BOOL clearsOnBeginEditing;
@property (nonatomic) BOOL adjustsFontSizeToFitWidth;
@property (nonatomic) CGFloat minimumFontSize;

@property (nonatomic, retain) UIImage *background;
@property (nonatomic, retain) UIImage *disabledBackground;

@property (nonatomic) UITextFieldViewMode clearButtonMode;
@property (nonatomic, retain) UIView *leftView;
@property (nonatomic) UITextFieldViewMode leftViewMode;
@property (nonatomic, retain) UIView *rightView;
@property (nonatomic) UITextFieldViewMode rightViewMode;

@property (nonatomic, readwrite, retain) UIView *inputAccessoryView;
@property (nonatomic, readwrite, retain) UIView *inputView;

@end
