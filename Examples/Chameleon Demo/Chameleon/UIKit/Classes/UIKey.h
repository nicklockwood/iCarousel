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

// NOTE: This does not come from Apple's UIKit and only exist to solve some current problems.
// I have no idea what Apple will do with keyboard handling. If they ever expose that stuff publically,
// then all of this should change to reflect the official API.

typedef enum {
    UIKeyTypeCharacter,		// the catch-all/default... I wouldn't depend much on this at this point
    UIKeyTypeUpArrow,
    UIKeyTypeDownArrow,
    UIKeyTypeLeftArrow,
    UIKeyTypeRightArrow,
    UIKeyTypeReturn,
    UIKeyTypeEnter,
    UIKeyTypeHome,
    UIKeyTypeInsert,
    UIKeyTypeDelete,
    UIKeyTypeEnd,
    UIKeyTypePageUp,
    UIKeyTypePageDown,
} UIKeyType;

@interface UIKey : NSObject {
@private
    unsigned short _keyCode;
    NSString *_characters;
    NSString *_charactersWithModifiers;
    NSUInteger _modifierFlags;
    BOOL _repeat;
}

@property (nonatomic, readonly) UIKeyType type;
@property (nonatomic, readonly) unsigned short keyCode;
@property (nonatomic, readonly) NSString *characters;
@property (nonatomic, readonly) NSString *charactersWithModifiers;
@property (nonatomic, readonly, getter=isRepeat) BOOL repeat;
@property (nonatomic, readonly, getter=isCapslockEnabled) BOOL capslockEnabled;
@property (nonatomic, readonly, getter=isShiftKeyPressed) BOOL shiftKeyPressed;
@property (nonatomic, readonly, getter=isControlKeyPressed) BOOL controlKeyPressed;
@property (nonatomic, readonly, getter=isOptionKeyPressed) BOOL optionKeyPressed;
@property (nonatomic, readonly, getter=isCommandKeyPressed) BOOL commandKeyPressed;

@end
