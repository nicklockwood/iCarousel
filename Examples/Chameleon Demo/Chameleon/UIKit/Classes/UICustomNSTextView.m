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

#import "UICustomNSTextView.h"
#import "UIBulletGlyphGenerator.h"
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBezierPath.h>

static const CGFloat LargeNumberForText = 1.0e7; // Any larger dimensions and the text could become blurry.


@interface UICustomNSTextView () <NSLayoutManagerDelegate>
@end


@implementation UICustomNSTextView

- (id)initWithFrame:(NSRect)frame secureTextEntry:(BOOL)isSecure isField:(BOOL)isField
{
    if ((self=[super initWithFrame:frame])) {
        const NSSize maxSize = NSMakeSize(LargeNumberForText, LargeNumberForText);
        
        // this is not ideal, I suspect... but it seems to work for now.
        // one behavior that's missing is that when a field resigns first responder,
        // it should really sort of turn back into a non-field that happens to have no word wrapping.
        // right now I have it scroll to the beginning of the line, at least, but even though the line break
        // mode is set to truncate on the tail, it doesn't do that because the underlying text container's size
        // has been sized to something bigger here. I tried to work around this by resetting the modes and such
        // on resignFirstResponder, but for some reason it just didn't seem to work reliably (especially when
        // the view was resized - it's like once you turn off setWidthTracksTextView, it doesn't want to turn
        // back on again). I'm likely missing something important, but it's not crazy important right now.
        if (isField) {
            [self setFieldEditor:YES];
            [self setHorizontallyResizable:YES];
            [self setVerticallyResizable:NO];
            [[self textContainer] setWidthTracksTextView:NO];
            [[self textContainer] setContainerSize:maxSize];
        } else {
            [self setFieldEditor:NO];
            [self setHorizontallyResizable:NO];
            [self setVerticallyResizable:YES];
            [self setAutoresizingMask:NSViewWidthSizable];
        }

        [self setMaxSize:maxSize];
        [self setDrawsBackground:NO];
        [self setRichText:NO];
        [self setUsesFontPanel:NO];
        [self setImportsGraphics:NO];
        [self setAllowsImageEditing:NO];
        [self setDisplaysLinkToolTips:NO];
        [self setAutomaticDataDetectionEnabled:NO];
        [self setSecureTextEntry:isSecure];
        
        [self setLayerContentsPlacement:NSViewLayerContentsPlacementTopLeft];
        
        // this is for a spell checking hack.. see below
        [[self layoutManager] setDelegate:self];
    }
    return self;
}

- (void)updateStyles
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    
    if (secureTextEntry) {
        // being all super-paranoid here...
        [self setAutomaticQuoteSubstitutionEnabled:NO];
        [self setGrammarCheckingEnabled:NO];
        [self setAutomaticSpellingCorrectionEnabled:NO];
        [self setContinuousSpellCheckingEnabled:NO];
        [self setAutomaticDashSubstitutionEnabled:NO];
        [self setAutomaticTextReplacementEnabled:NO];
        [self setSmartInsertDeleteEnabled:NO];
        [self setUsesFindPanel:NO];
        [self setAllowsUndo:NO];
        [[self layoutManager] setGlyphGenerator:[[[UIBulletGlyphGenerator alloc] init] autorelease]];
        [style setLineBreakMode:NSLineBreakByCharWrapping];
    } else {
        [self setAllowsUndo:YES];
        [self setContinuousSpellCheckingEnabled:YES];
        [self setSmartInsertDeleteEnabled:YES];
        [self setUsesFindPanel:YES];
        [[self layoutManager] setGlyphGenerator:[NSGlyphGenerator sharedGlyphGenerator]];
    }
    
    if ([self isFieldEditor]) {
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    
    [self setDefaultParagraphStyle:style];
    [style release];
}

- (void)setSecureTextEntry:(BOOL)isSecure
{
    secureTextEntry = isSecure;
    [self updateStyles];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (secureTextEntry && ([menuItem action] == @selector(copy:) || [menuItem action] == @selector(cut:))) {
        return NO;	// don't allow copying/cutting out from a secure field
    } else {
        return [super validateMenuItem:menuItem];
    }
}

- (NSSelectionGranularity)selectionGranularity
{
    if (secureTextEntry) {
        return NSSelectByCharacter;		// trying to avoid the secure one giving any hints about what's under it. :/
    } else {
        return [super selectionGranularity];
    }
}

- (void)startSpeaking:(id)sender
{
    // only allow speaking if it's not secure
    if (!secureTextEntry) {
        [super startSpeaking:sender];
    }
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
    if (secureTextEntry) {
        return nil;
    } else {
        return [super validRequestorForSendType:sendType returnType:returnType];
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSMenu *menu = [super menuForEvent:theEvent];
    
    // screw it.. why not just remove everything from the context menu if it's a secure field? :)
    // it's possible that various key combos could still allow things like searching in spotlight which
    // then would revel the actual value of the password field, but at least those are sorta obscure :)
    if (secureTextEntry) {
        NSArray *items = [[[menu itemArray] copy] autorelease];
        for (NSMenuItem *item in items) {
            if ([item action] != @selector(paste:)) {
                [menu removeItem:item];
            }
        }
    }
    return menu;
}


- (id<UICustomNSTextViewDelegate>)delegate
{
    return (id<UICustomNSTextViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<UICustomNSTextViewDelegate>)d
{
    [super setDelegate:d];
}


- (BOOL)becomeFirstResponder
{
	isBecomingFirstResponder = YES;
    BOOL result = [[self delegate] textViewBecomeFirstResponder:self];
	isBecomingFirstResponder = NO;
	return result;
}

- (BOOL)reallyBecomeFirstResponder
{
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	if(isBecomingFirstResponder) return NO;
	
    return [[self delegate] textViewResignFirstResponder:self];
}

- (BOOL)reallyResignFirstResponder
{
    if ([self isFieldEditor]) {
        [self scrollRangeToVisible:NSMakeRange(0,0)];
    }

    [self setSelectedRange:NSMakeRange(0,0)];

    return [super resignFirstResponder];
}

- (void)keyDown:(NSEvent *)event
{
    if ([[self delegate] textView:self shouldAcceptKeyDown:event]) {
        [super keyDown:event];
    }
}

#pragma mark -
#pragma mark Spell Checking Hacks Of Doom

// These horrible spell checking hacks are here because when in a layer, NSTextView appears to refuse to properly support spell checking.
// It seems that, as of now (10.6.5) there's a variety of problems.
//
// 1) It doesn't even try to draw the red underlines when a word is misspelled.
// 2) When typing, it doesn't appear to correctly update the misspelled state even if it *did* draw the lines correctly.
// 
// I worked around #1 by just implementing my own drawing routine and telling the NSLayoutManager not to draw temp attributes itself just in
// case Apple were to fix some of this in 10.7. (Otherwise I suspect we'd end up with multiple underlines that don't quite match, etc.)
//
// As for #2...
//
// It seems that when in a layer (or as some side effect of how I'm manipulating things here to hack this into UIKit), NSTextView will set the
// range of the word the cursor is touching/within to be spelled correctly even if it isn't. (It's always setting the spelling state to 0 no
// matter what I do). This results in words never being marked as misspelled, therefore even my hack to draw the underline fails. To work
// around this, I'm detecting when the text and/or the cursor's position have changed and setting a timer for a short time. When the timer
// expires, I'm forcing a check of the entire text of the NSTextView. This seemingly results in updating the spelling state correctly for all
// but the word that the cursor might happen to be in. This appears to be about the best I can come up with given the documentation and
// unwillingness to resort to private APIs. It's not right, though, and you can feel it when using the text view. There's weird lags and
// timings when it decides to do a spell check. It's also not very effecient to be rechecking the entire text view, but I'm hoping some other
// approach and/or a fix from Apple appears before that ever becomes a real problem. In the current project, there's never any very large text
// views so I'm not worried too much about performance right now.
//
// This pretty much totally sucks and is just one of many places that using layer-backed NSViews has caused insane problems and resulted in
// stupid workarounds or compromises. Frustration doesn't even being to cover it. The amazing thing, is that all this stuff appears to have
// been broken since at least 10.5 when layers were first introduced. I suspect all the layer guys on the AppKit team were stolen for the
// iOS team and it all fell *way* behind. I'm really hoping this crap is cleaned up in 10.7. Of course if they go ahead and just ship UIKit
// in 10.7, I'll be kinda pissed about that, too... so... uh... yeah...

- (void)setNeedsFakeSpellCheck
{
    if ([self isContinuousSpellCheckingEnabled]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forcedSpellCheck) object:nil];
        [self performSelector:@selector(forcedSpellCheck) withObject:nil afterDelay:0.5];
    }
}

- (void)didChangeText
{
    [super didChangeText];
    [self setNeedsFakeSpellCheck];
}

- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
    [super updateInsertionPointStateAndRestartTimer:flag];
    [self setNeedsFakeSpellCheck];
}

- (void)forcedSpellCheck
{
    [self checkTextInRange:NSMakeRange(0,[[self string] length]) types:[self enabledTextCheckingTypes] options:nil];
}

// Because drawing the misspelling underline squiggle doesn't seem to work when the text view is used on a layer-backed NSView, we have to draw them
// ourselves. In an attempt to be pro-active about avoiding potential problems if Apple were to fix this in 10.7, I'm returning nil in this
// NSLayoutManager delegate method which should mean that it won't even try draw any temporary attributes - even if it can some day.
- (NSDictionary *)layoutManager:(NSLayoutManager *)layoutManager shouldUseTemporaryAttributes:(NSDictionary *)attrs forDrawingToScreen:(BOOL)toScreen atCharacterIndex:(NSUInteger)charIndex effectiveRange:(NSRangePointer)effectiveCharRange
{
    return nil;
}

// My attempt at drawing the underline dots as close to how stock OSX seems to draw them. It's not perfect, but to my eyes it's damn close.
// This should not need to exist.
- (void)drawFakeSpellingUnderlinesInRect:(NSRect)rect
{	
    CGFloat lineDash[2] = {0.75, 3.25};
    
    NSBezierPath *underlinePath = [NSBezierPath bezierPath];
    [underlinePath setLineDash:lineDash count:2 phase:0];
    [underlinePath setLineWidth:2];
    [underlinePath setLineCapStyle:NSRoundLineCapStyle];
    
    NSLayoutManager *layout = [self layoutManager];
    
    NSRange checkRange = NSMakeRange(0,[[self string] length]);
    
    while (checkRange.length > 0) {
        NSRange effectiveRange = NSMakeRange(checkRange.location,0);
        id spellingValue = [layout temporaryAttribute:NSSpellingStateAttributeName atCharacterIndex:checkRange.location longestEffectiveRange:&effectiveRange inRange:checkRange];
        
        if (spellingValue) {
            const NSInteger spellingFlag = [spellingValue intValue];

            if ((spellingFlag & NSSpellingStateSpellingFlag) == NSSpellingStateSpellingFlag) {
                NSUInteger count = 0;
                const NSRectArray rects = [layout rectArrayForCharacterRange:effectiveRange withinSelectedCharacterRange:NSMakeRange(NSNotFound,0) inTextContainer:[self textContainer] rectCount:&count];
                
                for (NSUInteger i=0; i<count; i++) {
                    if (NSIntersectsRect(rects[i], rect)) {
                        [underlinePath moveToPoint:NSMakePoint(rects[i].origin.x, rects[i].origin.y+rects[i].size.height-1.5)];
                        [underlinePath relativeLineToPoint:NSMakePoint(rects[i].size.width,0)];
                    }
                }
            }
        }
        
        checkRange.location = NSMaxRange(effectiveRange);
        checkRange.length = [[self string] length] - checkRange.location;
    }
    
    [[NSColor redColor] setStroke];
    [underlinePath stroke];
}

- (void)drawRect:(NSRect)rect
{
    // This disables font smoothing. This is necessary because in this implementation, the NSTextView is always drawn with a transparent background
    // and layered on top of other views. It therefore cannot properly do subpixel rendering and the smoothing ends up looking like crap. Turning
    // the smoothing off is not as nice as properly smoothed text, of course, but at least its sorta readable. Yet another case of crap layer
    // support making things difficult. Amazingly, iOS fonts look fine when rendered without subpixel smoothing. Why?!
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldSmoothFonts(ctx, NO);
    
    [super drawRect:rect];
    [self drawFakeSpellingUnderlinesInRect:rect];
}

@end
