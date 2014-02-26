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

#import "UITextField.h"
#import "UITextLayer.h"
#import "UIColor.h"
#import "UIFont.h"
#import "UIImage.h"
#import <AppKit/NSCursor.h>

NSString *const UITextFieldTextDidBeginEditingNotification = @"UITextFieldTextDidBeginEditingNotification";
NSString *const UITextFieldTextDidChangeNotification = @"UITextFieldTextDidChangeNotification";
NSString *const UITextFieldTextDidEndEditingNotification = @"UITextFieldTextDidEndEditingNotification";

@interface UIControl () <UITextLayerContainerViewProtocol>
@end

@interface UITextField () <UITextLayerTextDelegate>
@end

@implementation UITextField
@synthesize delegate=_delegate, background=_background, disabledBackground=_disabledBackground, editing=_editing, clearsOnBeginEditing=_clearsOnBeginEditing;
@synthesize adjustsFontSizeToFitWidth=_adjustsFontSizeToFitWidth, clearButtonMode=_clearButtonMode, leftView=_leftView, rightView=_rightView;
@synthesize leftViewMode=_leftViewMode, rightViewMode=_rightViewMode, placeholder=_placeholder, borderStyle=_borderStyle;
@synthesize inputAccessoryView=_inputAccessoryView, inputView=_inputView, minimumFontSize=_minimumFontSize;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _textLayer = [[UITextLayer alloc] initWithContainer:self isField:YES];
        [self.layer insertSublayer:_textLayer atIndex:0];

        self.textAlignment = UITextAlignmentLeft;
        self.font = [UIFont systemFontOfSize:17];
        self.borderStyle = UITextBorderStyleNone;
        self.textColor = [UIColor blackColor];
        self.clearButtonMode = UITextFieldViewModeNever;
        self.leftViewMode = UITextFieldViewModeNever;
        self.rightViewMode = UITextFieldViewModeNever;
        self.opaque = NO;
    }
    return self;
}

- (void)dealloc
{
    [_textLayer removeFromSuperlayer];
    [_textLayer release];
    [_leftView release];
    [_rightView release];
    [_background release];
    [_disabledBackground release];
    [_placeholder release];
    [_inputAccessoryView release];
    [_inputView release];
    [super dealloc];
}

- (BOOL)_isLeftViewVisible
{
    return _leftView && (_leftViewMode == UITextFieldViewModeAlways
                         || (_editing && _leftViewMode == UITextFieldViewModeWhileEditing)
                         || (!_editing && _leftViewMode == UITextFieldViewModeUnlessEditing));
}

- (BOOL)_isRightViewVisible
{
    return _rightView && (_rightViewMode == UITextFieldViewModeAlways
                         || (_editing && _rightViewMode == UITextFieldViewModeWhileEditing)
                         || (!_editing && _rightViewMode == UITextFieldViewModeUnlessEditing));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    const CGRect bounds = self.bounds;
    _textLayer.frame = [self textRectForBounds:bounds];

    if ([self _isLeftViewVisible]) {
        _leftView.hidden = NO;
        _leftView.frame = [self leftViewRectForBounds:bounds];
    } else {
        _leftView.hidden = YES;
    }

    if ([self _isRightViewVisible]) {
        _rightView.hidden = NO;
        _rightView.frame = [self rightViewRectForBounds:bounds];
    } else {
        _rightView.hidden = YES;
    }
}

- (void)setDelegate:(id<UITextFieldDelegate>)theDelegate
{
    if (theDelegate != _delegate) {
        _delegate = theDelegate;
        _delegateHas.shouldBeginEditing = [_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)];
        _delegateHas.didBeginEditing = [_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)];
        _delegateHas.shouldEndEditing = [_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)];
        _delegateHas.didEndEditing = [_delegate respondsToSelector:@selector(textFieldDidEndEditing:)];
        _delegateHas.shouldChangeCharacters = [_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)];
        _delegateHas.shouldClear = [_delegate respondsToSelector:@selector(textFieldShouldClear:)];
        _delegateHas.shouldReturn = [_delegate respondsToSelector:@selector(textFieldShouldReturn:)];
    }
}

- (void)setPlaceholder:(NSString *)thePlaceholder
{
    if (![thePlaceholder isEqualToString:_placeholder]) {
        [_placeholder release];
        _placeholder = [thePlaceholder copy];
        [self setNeedsDisplay];
    }
}

- (void)setBorderStyle:(UITextBorderStyle)style
{
    if (style != _borderStyle) {
        _borderStyle = style;
        [self setNeedsDisplay];
    }
}

- (void)setBackground:(UIImage *)aBackground
{
    if (aBackground != _background) {
        [_background release];
        _background = [aBackground retain];
        [self setNeedsDisplay];
    }
}

- (void)setDisabledBackground:(UIImage *)aBackground
{
    if (aBackground != _disabledBackground) {
        [_disabledBackground release];
        _disabledBackground = [aBackground retain];
        [self setNeedsDisplay];
    }
}

- (void)setLeftView:(UIView *)leftView
{
    if (leftView != _leftView) {
        [_leftView removeFromSuperview];
        [_leftView release];
        _leftView = [leftView retain];
        [self addSubview:_leftView];
    }
}

- (void)setRightView:(UIView *)rightView
{
    if (rightView != _rightView) {
        [_rightView removeFromSuperview];
        [_rightView release];
        _rightView = [rightView retain];
        [self addSubview:_rightView];
    }
}

- (void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(frame,self.frame)) {
        [super setFrame:frame];
        [self setNeedsDisplay];
    }
}


- (CGRect)borderRectForBounds:(CGRect)bounds
{
    return bounds;
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    return CGRectZero;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    if (_leftView) {
        const CGRect frame = _leftView.frame;
        bounds.origin.x = 0;
        bounds.origin.y = (bounds.size.height / 2.f) - (frame.size.height/2.f);
        bounds.size = frame.size;
        return CGRectIntegral(bounds);
    } else {
        return CGRectZero;
    }
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    if (_rightView) {
        const CGRect frame = _rightView.frame;
        bounds.origin.x = bounds.size.width - frame.size.width;
        bounds.origin.y = (bounds.size.height / 2.f) - (frame.size.height/2.f);
        bounds.size = frame.size;
        return CGRectIntegral(bounds);
    } else {
        return CGRectZero;
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    // Docs say:
    // The default implementation of this method returns a rectangle that is derived from the control’s original bounds,
    // but which does not include the area occupied by the receiver’s border or overlay views.
    
    // It appears what happens is something like this:
    // check border type:
    //   if no border, skip to next major step
    //   if has border, set textRect = borderBounds, then inset textRect according to border style
    // check if textRect overlaps with leftViewRect, if it does, make it smaller
    // check if textRect overlaps with rightViewRect, if it does, make it smaller
    // check if textRect overlaps with clearButtonRect (if currently needed?), if it does, make it smaller
    
    CGRect textRect = bounds;
    
    if (_borderStyle != UITextBorderStyleNone) {
        textRect = [self borderRectForBounds:bounds];
        // TODO: inset the bounds based on border types...
    }
    
    // Going to go ahead and assume that the left view is on the left, the right view is on the right, and there's space between..
    // I imagine this is a dangerous assumption...
    if ([self _isLeftViewVisible]) {
        CGRect overlap = CGRectIntersection(textRect,[self leftViewRectForBounds:bounds]);
        if (!CGRectIsNull(overlap)) {
            textRect = CGRectOffset(textRect, overlap.size.width, 0);
            textRect.size.width -= overlap.size.width;
        }
    }
    
    if ([self _isRightViewVisible]) {
        CGRect overlap = CGRectIntersection(textRect,[self rightViewRectForBounds:bounds]);
        if (!CGRectIsNull(overlap)) {
            textRect = CGRectOffset(textRect, -overlap.size.width, 0);
            textRect.size.width -= overlap.size.width;
        }
    }
    
    return CGRectIntegral(bounds);
}



- (void)drawPlaceholderInRect:(CGRect)rect
{
}

- (void)drawTextInRect:(CGRect)rect
{
}

- (void)drawRect:(CGRect)rect
{
    UIImage *background = self.enabled? _background : _disabledBackground;
    [background drawInRect:self.bounds];
}


- (UITextAutocapitalizationType)autocapitalizationType
{
    return UITextAutocapitalizationTypeNone;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type
{
}

- (UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeDefault;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)type
{
}

- (BOOL)enablesReturnKeyAutomatically
{
    return YES;
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enabled
{
}

- (UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDefault;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)type
{
}

- (UIKeyboardType)keyboardType
{
    return UIKeyboardTypeDefault;
}

- (void)setKeyboardType:(UIKeyboardType)type
{
}

- (UIReturnKeyType)returnKeyType
{
    return UIReturnKeyDefault;
}

- (void)setReturnKeyType:(UIReturnKeyType)type
{
}

- (BOOL)isSecureTextEntry
{
    return [_textLayer isSecureTextEntry];
}

- (void)setSecureTextEntry:(BOOL)secure
{
    [_textLayer setSecureTextEntry:secure];
}


- (BOOL)canBecomeFirstResponder
{
    return (self.window != nil);
}

- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder]) {
        return [_textLayer becomeFirstResponder];
    } else {
        return NO;
    }
}

- (BOOL)resignFirstResponder
{
    if ([super resignFirstResponder]) {
        return [_textLayer resignFirstResponder];
    } else {
        return NO;
    }
}

- (UIFont *)font
{
    return _textLayer.font;
}

- (void)setFont:(UIFont *)newFont
{
    _textLayer.font = newFont;
}

- (UIColor *)textColor
{
    return _textLayer.textColor;
}

- (void)setTextColor:(UIColor *)newColor
{
    _textLayer.textColor = newColor;
}

- (UITextAlignment)textAlignment
{
    return _textLayer.textAlignment;
}

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
    _textLayer.textAlignment = textAlignment;
}

- (NSString *)text
{
    return _textLayer.text;
}

- (void)setText:(NSString *)newText
{
    _textLayer.text = newText;
}

- (BOOL)_textShouldBeginEditing
{
    return _delegateHas.shouldBeginEditing? [_delegate textFieldShouldBeginEditing:self] : YES;
}

- (void)_textDidBeginEditing
{
    BOOL shouldClear = _clearsOnBeginEditing;

    if (shouldClear && _delegateHas.shouldClear) {
        shouldClear = [_delegate textFieldShouldClear:self];
    }

    if (shouldClear) {
        // this doesn't work - it can cause an exception to trigger. hrm...
        // so... rather than worry too much about it right now, just gonna delay it :P
        //self.text = @"";
        [self performSelector:@selector(setText:) withObject:@"" afterDelay:0];
    }
    
    _editing = YES;
    [self setNeedsDisplay];
    [self setNeedsLayout];

    if (_delegateHas.didBeginEditing) {
        [_delegate textFieldDidBeginEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:self];
}

- (BOOL)_textShouldEndEditing
{
    return _delegateHas.shouldEndEditing? [_delegate textFieldShouldEndEditing:self] : YES;
}

- (void)_textDidEndEditing
{
    _editing = NO;
    [self setNeedsDisplay];
    [self setNeedsLayout];

    if (_delegateHas.didEndEditing) {
        [_delegate textFieldDidEndEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:self];
}

- (BOOL)_textShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return _delegateHas.shouldChangeCharacters? [_delegate textField:self shouldChangeCharactersInRange:range replacementString:text] : YES;
}

- (void)_textDidChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
}

- (void)_textDidReceiveReturnKey
{
    if (_delegateHas.shouldReturn) {
        [_delegate textFieldShouldReturn:self];
    }
}

- (NSString *)description
{
    NSString *textAlignment = @"";
    switch (self.textAlignment) {
        case UITextAlignmentLeft:
            textAlignment = @"Left";
            break;
        case UITextAlignmentCenter:
            textAlignment = @"Center";
            break;
        case UITextAlignmentRight:
            textAlignment = @"Right";
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p; textAlignment = %@; editing = %@; textColor = %@; font = %@; delegate = %@>", [self className], self, textAlignment, (self.editing ? @"YES" : @"NO"), self.textColor, self.font, self.delegate];
}

- (id)mouseCursorForEvent:(UIEvent *)event
{
    return [NSCursor IBeamCursor];
}

@end
