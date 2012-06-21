/*
 * Copyright (c) 2012, The Iconfactory. All rights reserved.
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

#import "UIAppearanceProperty.h"

@implementation UIAppearanceProperty
@synthesize axisValues;

- (id)initWithSelector:(SEL)sel axisValues:(NSArray *)values
{
    if ((self=[super init])) {
        cmd = sel;
        axisValues = [values copy];
    }
    return self;
}

- (void)dealloc
{
    [axisValues release];
    [super dealloc];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    } else if ([object isKindOfClass:[UIAppearanceProperty class]]) {
        UIAppearanceProperty *entry = (UIAppearanceProperty *)object;
        return cmd == entry->cmd && [axisValues isEqual:entry->axisValues];
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return [NSStringFromSelector(cmd) hash] ^ [axisValues hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[UIAppearanceProperty alloc] initWithSelector:cmd axisValues:axisValues];
}

- (void)invokeSetterUsingTarget:(id)target withValue:(NSValue *)value
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:cmd]];

    for (int i=0; i<[[invocation methodSignature] numberOfArguments]; i++) {
        if (i == 0) {
            [invocation setTarget:target];
        } else if (i == 1) {
            [invocation setSelector:cmd];
        } else {
            NSValue *v = (i == 2)? value : [axisValues objectAtIndex:i-3];
            
            NSUInteger bufferSize = 0;
            NSGetSizeAndAlignment([v objCType], &bufferSize, NULL);
            UInt8 argumentBuffer[bufferSize];
            memset(argumentBuffer, 0, bufferSize);
            
            [v getValue:argumentBuffer];
            [invocation setArgument:argumentBuffer atIndex:i];
        }
    }
    
    [invocation invoke];
}

@end
