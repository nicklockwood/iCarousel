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

#import "UITextLayer.h"
#import "UIScrollView.h"
#import "UICustomNSTextView.h"
#import "UICustomNSClipView.h"
#import "UIWindow.h"
#import "UIScreen+UIPrivate.h"
#import "UIScreenAppKitIntegration.h"
#import "UIApplication+UIPrivate.h"
#import "AppKitIntegration.h"
#import "UIView+UIPrivate.h"
#import "UIKitView.h"
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSWindow.h>

@interface UITextLayer () <UICustomNSClipViewBehaviorDelegate, UICustomNSTextViewDelegate>
- (void)removeNSView;
@end

@implementation UITextLayer
@synthesize textColor, font, editable, secureTextEntry;

- (id)initWithContainer:(UIView <UITextLayerContainerViewProtocol, UITextLayerTextDelegate> *)aView isField:(BOOL)isField
{
    if ((self=[super init])) {
        self.masksToBounds = NO;

        containerView = aView;

        textDelegateHas.didChange = [containerView respondsToSelector:@selector(_textDidChange)];
        textDelegateHas.didChangeSelection = [containerView respondsToSelector:@selector(_textDidChangeSelection)];
        textDelegateHas.didReturnKey = [containerView respondsToSelector:@selector(_textDidReceiveReturnKey)];
        
        containerCanScroll = [containerView respondsToSelector:@selector(setContentOffset:)]
            && [containerView respondsToSelector:@selector(contentOffset)]
            && [containerView respondsToSelector:@selector(setContentSize:)]
            && [containerView respondsToSelector:@selector(contentSize)]
            && [containerView respondsToSelector:@selector(isScrollEnabled)];
        
        clipView = [(UICustomNSClipView *)[UICustomNSClipView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
        textView = [(UICustomNSTextView *)[UICustomNSTextView alloc] initWithFrame:[clipView frame] secureTextEntry:secureTextEntry isField:isField];

        [textView setDelegate:self];
        [clipView setDocumentView:textView];

        self.textAlignment = UITextAlignmentLeft;
        [self setNeedsLayout];
    }
    return self;
}

- (void)dealloc
{
    [textView setDelegate:nil];
    [self removeNSView];
    [clipView release];
    [textView release];
    [textColor release];
    [font release];
    [super dealloc];
}

// Need to prevent Core Animation effects from happening... very ugly otherwise.
- (id < CAAction >)actionForKey:(NSString *)aKey
{
    return nil;
}

- (void)addNSView
{
    if (containerCanScroll) {
        [clipView scrollToPoint:NSPointFromCGPoint([containerView contentOffset])];
    } else {
        [clipView scrollToPoint:NSZeroPoint];
    }

    clipView.parentLayer = self;
    clipView.behaviorDelegate = self;

    [[[[containerView window] screen] UIKitView] addSubview:clipView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScrollViewContentOffset) name:NSViewBoundsDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hierarchyDidChangeNotification:) name:UIViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hierarchyDidChangeNotification:) name:UIViewBoundsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hierarchyDidChangeNotification:) name:UIViewDidMoveToSuperviewNotification object:nil];
}

- (void)removeNSView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:clipView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewBoundsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIViewDidMoveToSuperviewNotification object:nil];
    
    clipView.parentLayer = nil;
    clipView.behaviorDelegate = nil;

    [clipView removeFromSuperview];
}

- (void)updateScrollViewContentSize
{
    if (containerCanScroll) {
        // also update the content size in the UIScrollView
        const NSRect docRect = [clipView documentRect];
        [containerView setContentSize:CGSizeMake(docRect.size.width+docRect.origin.x, docRect.size.height+docRect.origin.y)];
    }
}

- (BOOL)shouldBeVisible
{
    return ([containerView window] && (self.superlayer == [containerView layer]) && !self.hidden && ![containerView isHidden]);
}

- (void)updateNSViews
{
    if ([self shouldBeVisible]) {
        if (![clipView superview]) {
            [self addNSView];
        }
        
        UIWindow *window = [containerView window];
        const CGRect windowRect = [window convertRect:self.frame fromView:containerView];
        const CGRect screenRect = [window convertRect:windowRect toWindow:nil];
        NSRect desiredFrame = NSRectFromCGRect(screenRect);

        [clipView setFrame:desiredFrame];
        [self updateScrollViewContentSize];
        clipView.layer.geometryFlipped = YES;
    } else {
        [self removeNSView];
    }
}

- (void)layoutSublayers
{
    [self updateNSViews];
    [super layoutSublayers];
}

- (void)removeFromSuperlayer
{
    [super removeFromSuperlayer];
    [self updateNSViews];
}

- (void)setHidden:(BOOL)hide
{
    if (hide != self.hidden) {
        [super setHidden:hide];
        [self updateNSViews];
    }
}

- (void)hierarchyDidChangeNotification:(NSNotification *)note
{
    if ([containerView isDescendantOfView:[note object]]) {
        if ([self shouldBeVisible]) {
            [self setNeedsLayout];
        } else {
            [self removeNSView];
        }
    }
}


- (void)setContentOffset:(CGPoint)contentOffset
{
    NSPoint point = [clipView constrainScrollPoint:NSPointFromCGPoint(contentOffset)];
    [clipView scrollToPoint:point];
}

- (void)updateScrollViewContentOffset
{
    if (containerCanScroll) {
        [containerView setContentOffset:NSPointToCGPoint([clipView bounds].origin)];
    }
}

- (void)setFont:(UIFont *)newFont
{
    assert(newFont != nil);
    if (newFont != font) {
        [font release];
        font = [newFont retain];
        [textView setFont:[font NSFont]];
    }
}

- (void)setTextColor:(UIColor *)newColor
{
    if (newColor != textColor) {
        [textColor release];
        textColor = [newColor retain];
        [textView setTextColor:[textColor NSColor]];
    }
}

- (NSString *)text
{
    return [textView string];
}

- (void)setText:(NSString *)newText
{
    [textView setString:newText ?: @""];
    [self updateScrollViewContentSize];
}

- (void)setSecureTextEntry:(BOOL)s
{
    if (s != secureTextEntry) {
        secureTextEntry = s;
        [textView setSecureTextEntry:secureTextEntry];
    }
}

- (void)setEditable:(BOOL)edit
{
    if (editable != edit) {
        editable = edit;
        [textView setEditable:editable];
    }
}

- (void)scrollRangeToVisible:(NSRange)range
{
    [textView scrollRangeToVisible:range];
}

- (NSRange)selectedRange
{
    return [textView selectedRange];
}

- (void)setSelectedRange:(NSRange)range
{
    [textView setSelectedRange:range];
}

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
    switch (textAlignment) {
        case UITextAlignmentLeft:
            [textView setAlignment:NSLeftTextAlignment];
            break;
        case UITextAlignmentCenter:
            [textView setAlignment:NSCenterTextAlignment];
            break;
        case UITextAlignmentRight:
            [textView setAlignment:NSRightTextAlignment];
            break;
    }
}

- (UITextAlignment)textAlignment
{
    switch ([textView alignment]) {
        case NSCenterTextAlignment:
            return UITextAlignmentCenter;
        case NSRightTextAlignment:
            return UITextAlignmentRight;
        default:
            return UITextAlignmentLeft;
    }
}

// this is used to fake out AppKit when the UIView that owns this layer/editor stuff is actually *behind* another UIView. Since the NSViews are
// technically above all of the UIViews, they'd normally capture all clicks no matter what might happen to be obscuring them. That would obviously
// be less than ideal. This makes it ideal. Awesome.
- (BOOL)hitTestForClipViewPoint:(NSPoint)point
{
    UIScreen *screen = [[containerView window] screen];
    
    if (screen) {
        if (![[screen UIKitView] isFlipped]) {
            point.y = screen.bounds.size.height - point.y - 1;
        }
        return (containerView == [[[containerView window] screen] _hitTest:NSPointToCGPoint(point) event:nil]);
    }

    return NO;
}

- (BOOL)clipViewShouldScroll
{
    return containerCanScroll && [containerView isScrollEnabled];
}




- (BOOL)textShouldBeginEditing:(NSText *)aTextObject
{
    return [containerView _textShouldBeginEditing];
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    [containerView _textDidBeginEditing];
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject
{
    return [containerView _textShouldEndEditing];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    [containerView _textDidEndEditing];
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if (textDelegateHas.didChangeSelection) {
        // IMPORTANT! see notes about why this hack exists down in -textViewDidChangeSelection:!
        [NSObject cancelPreviousPerformRequestsWithTarget:containerView selector:@selector(_textDidChangeSelection) object:nil];
    }

    if (textDelegateHas.didChange) {
        [containerView _textDidChange];
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
    if (textDelegateHas.didChangeSelection) {
        // this defers the sending of the selection change delegate message. the reason is that on the real iOS, Apple does not appear to send
        // the selection changing delegate messages when text is actually changing. since I can't find a decent way to check here if text is
        // actually changing or if the cursor is just moving, I'm deferring the actual sending of this message. above in -textDidChange:, it
        // cancels the deferred send if it ends up that text actually changed. this only works if -textDidChange: is sent after
        // -textViewDidChangeSelection: which appears to be the case, but I don't think this is documented anywhere so this could possibly
        // break someday. anyway, the end result of this nasty hack is that UITextLayer shouldn't send out the selection changing notifications
        // while text is being changed, which mirrors how the real UIKit appears to work in this regard. note that the real UIKit also appears
        // to NOT send the selection change notification if you had multiple characters selected and then typed a single character thus
        // replacing the selected text with the single new character. happily this hack appears to function the same way.
        [containerView performSelector:@selector(_textDidChangeSelection) withObject:nil afterDelay:0];
    }
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    // always prevent newlines when in field editing mode. this seems like a heavy-handed way of doing it, but it's also easy and quick.
    // it should really probably be in the UICustomNSTextView class somewhere and not here, but this works okay, too, I guess.
    // this is also being done in doCommandBySelector: below, but it's done here as well to prevent pasting stuff in with newlines in it.
    // seems like a hack, I dunno.
    if ([textView isFieldEditor] && ([replacementString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound)) {
        return NO;
    } else {
        return [containerView _textShouldChangeTextInRange:affectedCharRange replacementText:replacementString];
    }
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    // this makes sure there's no newlines added when in field editing mode.
    // it also allows us to handle when return/enter is pressed differently for fields. Dunno if there's a better way or not.
    if ([textView isFieldEditor] && ((aSelector == @selector(insertNewline:) || (aSelector == @selector(insertNewlineIgnoringFieldEditor:))))) {
        if (textDelegateHas.didReturnKey) {
            [containerView _textDidReceiveReturnKey];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)textViewBecomeFirstResponder:(UICustomNSTextView *)aTextView
{
    if (changingResponderStatus) {
        return [aTextView reallyBecomeFirstResponder];
    } else {
        return [containerView becomeFirstResponder];
    }
}

- (BOOL)textViewResignFirstResponder:(UICustomNSTextView *)aTextView
{
    if (changingResponderStatus) {
        return [aTextView reallyResignFirstResponder];
    } else {
        return [containerView resignFirstResponder];
    }
}

- (BOOL)becomeFirstResponder
{
    if ([self shouldBeVisible] && ![clipView superview]) {
        [self addNSView];
    }
    
    changingResponderStatus = YES;
    const BOOL result = [[textView window] makeFirstResponder:textView];
    changingResponderStatus = NO;

    return result;
}

- (BOOL)resignFirstResponder
{
    changingResponderStatus = YES;
    const BOOL result = [[textView window] makeFirstResponder:[[[containerView window] screen] UIKitView]];
    changingResponderStatus = NO;
    return result;
}


- (BOOL)textView:(UICustomNSTextView *)aTextView shouldAcceptKeyDown:(NSEvent *)event
{
    return ![[UIApplication sharedApplication] _sendGlobalKeyboardNSEvent:event fromScreen:[[containerView window] screen]];
}

@end
