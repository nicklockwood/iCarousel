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

#import "UIPhotosAlbum.h"
#import "UIImage.h"
#import <AppKit/NSSavePanel.h>

@implementation UIPhotosAlbum

+ (UIPhotosAlbum *)sharedPhotosAlbum
{
    static UIPhotosAlbum *album = nil;

    if (!album) {
        album = [[self alloc] init];
    }
    
    return album;
}

- (void)_writeImageWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:@"image"];
    NSError *error = nil;

    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];

    if (NSFileHandlingPanelOKButton == [panel runModal] && [panel URL]) {
        NSData *imageData = UIImagePNGRepresentation(image);
        
        if (imageData) {
            [imageData writeToURL:[panel URL] options:NSDataWritingAtomic error:&error];
        } else {
            error = [NSError errorWithDomain:@"could not generate png image" code:2 userInfo:nil];
        }
    } else {
        error = [NSError errorWithDomain:@"save panel cancelled" code:1 userInfo:nil];
    }
    
    id target = [info objectForKey:@"target"];

    if (target) {
        SEL action = NSSelectorFromString([info objectForKey:@"action"]);
        void *context = [[info objectForKey:@"context"] pointerValue];
        
        NSMethodSignature *signature = [target methodSignatureForSelector:action];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:action];
        [invocation setArgument:&image atIndex:2];
        [invocation setArgument:&error atIndex:3];
        [invocation setArgument:&context atIndex:4];
        [invocation invokeWithTarget:target];
    }
}

- (void)writeImage:(UIImage *)image completionTarget:(id)target action:(SEL)action context:(void *)context
{
    if (image) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:4];
        [info setObject:image forKey:@"image"];

        if (target && action) {
            [info setObject:target forKey:@"target"];
            [info setObject:NSStringFromSelector(action) forKey:@"action"];
        }
        
        if (context) {
            [info setObject:[NSValue valueWithPointer:context] forKey:@"context"];
        }
        
        // deferring this partly because the save dialog is modal and partly because I don't think code is going
        // to expect the target/action to be sent before the save function even returns.
        [self performSelector:@selector(_writeImageWithInfo:) withObject:info afterDelay:0];
    }
}

@end
