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

#import "UIKey+UIPrivate.h"
#import <AppKit/NSEvent.h>

@implementation UIKey
@synthesize keyCode=_keyCode, characters=_characters, charactersWithModifiers=_charactersWithModifiers, repeat=_repeat;

- (id)initWithNSEvent:(NSEvent *)event
{
    if ((self=[super init])) {
        _keyCode = [event keyCode];
        _characters = [[event charactersIgnoringModifiers] copy];
        _charactersWithModifiers = [[event characters] copy];
        _repeat = [event isARepeat];
        _modifierFlags = [event modifierFlags];
    }
    return self;
}

- (void)dealloc
{
    [_characters release];
    [_charactersWithModifiers release];
    [super dealloc];
}

- (UIKeyType)type
{
    if ([_characters length] > 0) {
        switch ([_characters characterAtIndex:0]) {
            case NSUpArrowFunctionKey:			return UIKeyTypeUpArrow;
            case NSDownArrowFunctionKey:		return UIKeyTypeDownArrow;
            case NSLeftArrowFunctionKey:		return UIKeyTypeLeftArrow;
            case NSRightArrowFunctionKey:		return UIKeyTypeRightArrow;
            case NSEndFunctionKey:				return UIKeyTypeEnd;
            case NSPageUpFunctionKey:			return UIKeyTypePageUp;
            case NSPageDownFunctionKey:			return UIKeyTypePageDown;
            case NSDeleteFunctionKey:			return UIKeyTypeDelete;
            case NSInsertFunctionKey:			return UIKeyTypeInsert;
            case NSHomeFunctionKey:				return UIKeyTypeHome;
            case 0x000D:						return UIKeyTypeReturn;
            case 0x0003:						return UIKeyTypeEnter;
        }
    }
    
    return UIKeyTypeCharacter;
}

- (BOOL)isCapslockEnabled
{
    return (_modifierFlags & NSAlphaShiftKeyMask) == NSAlphaShiftKeyMask;
}

- (BOOL)isShiftKeyPressed
{
    return (_modifierFlags & NSShiftKeyMask) == NSShiftKeyMask;
}

- (BOOL)isControlKeyPressed
{
    return (_modifierFlags & NSControlKeyMask) == NSControlKeyMask;
}

- (BOOL)isOptionKeyPressed
{
    return (_modifierFlags & NSAlternateKeyMask) == NSAlternateKeyMask;
}

- (BOOL)isCommandKeyPressed
{
    return (_modifierFlags & NSCommandKeyMask) == NSCommandKeyMask;
}

@end
