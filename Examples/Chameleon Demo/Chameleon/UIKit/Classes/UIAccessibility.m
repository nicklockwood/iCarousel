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

#import "UIAccessibility.h"

UIAccessibilityTraits UIAccessibilityTraitNone = 0;
UIAccessibilityTraits UIAccessibilityTraitButton = 1;
UIAccessibilityTraits UIAccessibilityTraitLink = 2;
UIAccessibilityTraits UIAccessibilityTraitImage = 4;
UIAccessibilityTraits UIAccessibilityTraitSelected = 8;
UIAccessibilityTraits UIAccessibilityTraitPlaysSound = 16;
UIAccessibilityTraits UIAccessibilityTraitKeyboardKey = 32;
UIAccessibilityTraits UIAccessibilityTraitStaticText = 64;
UIAccessibilityTraits UIAccessibilityTraitSummaryElement = 128;
UIAccessibilityTraits UIAccessibilityTraitNotEnabled = 256;
UIAccessibilityTraits UIAccessibilityTraitUpdatesFrequently = 512;
UIAccessibilityTraits UIAccessibilityTraitSearchField = 1024;
UIAccessibilityTraits UIAccessibilityTraitHeader = 2048;

UIAccessibilityNotifications UIAccessibilityScreenChangedNotification = 1000;
UIAccessibilityNotifications UIAccessibilityLayoutChangedNotification = 1001;
UIAccessibilityNotifications UIAccessibilityAnnouncementNotification = 1002;
UIAccessibilityNotifications UIAccessibilityPageScrolledNotification = 1003;


@implementation NSObject (UIAccessibility)
- (BOOL)isAccessibilityElement
{
    return NO;
}

- (void)setIsAccessibilityElement:(BOOL)isElement
{
}

- (NSString *)accessibilityLabel
{
    return nil;
}

- (void)setAccessibilityLabel:(NSString *)label
{
}

- (NSString *)accessibilityHint
{
    return nil;
}

- (void)setAccessibilityHint:(NSString *)hint
{
}

- (NSString *)accessibilityValue
{
    return nil;
}

- (void)setAccessibilityValue:(NSString *)value
{
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone; // STUB
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)traits
{
}

- (CGRect)accessibilityFrame
{
    return CGRectNull;
}

- (void)setAccessibilityFrame:(CGRect)frame
{
}

- (BOOL)accessibilityViewIsModal
{
    return NO;
}

- (void)setAccessibilityViewIsModal:(BOOL)isModal
{
}

- (BOOL)accessibilityElementsHidden
{
    return NO;
}

- (void)setAccessibilityElementsHidden:(BOOL)accessibilityElementsHidden
{
}

@end


@implementation NSObject (UIAccessibilityContainer)
- (NSInteger)accessibilityElementCount
{
    return 0;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    return nil;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return NSNotFound;
}
@end


@implementation NSObject (UIAccessibilityFocus)
- (void)accessibilityElementDidBecomeFocused
{
}

- (void)accessibilityElementDidLoseFocus
{
}

- (BOOL)accessibilityElementIsFocused
{
    return NO;
}
@end


void UIAccessibilityPostNotification(UIAccessibilityNotifications notification, id argument)
{
}

BOOL UIAccessibilityIsVoiceOverRunning()
{
    return NO;
}
