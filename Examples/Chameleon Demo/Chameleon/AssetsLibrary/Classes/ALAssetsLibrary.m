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

#import "ALAssetsLibrary.h"
#import <AppKit/NSSavePanel.h>
#import <CoreServices/CoreServices.h>

NSString *const ALAssetsLibraryErrorDomain = @"ALAssetsLibraryErrorDomain";
NSString *const ALAssetsLibraryChangedNotification = @"ALAssetsLibraryChangedNotification";

static NSString *UTIForImageData(NSData *data)
{
    NSString *type = nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    if (imageSource) {
        type = [[(NSString *)CGImageSourceGetType(imageSource) copy] autorelease];
        CFRelease(imageSource);
    }
    
    return type;
}

@implementation ALAssetsLibrary

- (void)_deferredBlock:(void (^)(void))block
{
    block();
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock
{
    // Chameleon's UIKit has an internal class called UIPhotosAlbum which was used to implement 
    // UIImageWriteToSavedPhotosAlbum(). Somehow it'd be nice if these things shared code, but I don't
    // really want to make UIKit depend on having AssetsLibrary. Since I wasn't sure how to best accomplish
    // that, it's just duplicated here for now in a slightly different way so that we can support writing
    // any sort of image data and not just PNGs.

    // The actual presentation of the save dialog and the saving itself is deferred because that's how
    // my UIImageWriteToSavedPhotosAlbum() did it and ALAssetsLibrary says these methods are asynchronous
    // so we'll pretend that's okay.

    if (imageData) {
        ALAssetsLibraryWriteImageCompletionBlock doneBlock = [completionBlock copy];
        
        [self performSelector:@selector(_deferredBlock:) withObject:[[^{
            NSError *error = nil;
            
            NSSavePanel *panel = [NSSavePanel savePanel];
            NSString *fileType = UTIForImageData(imageData);
        
            if (fileType) {
                [panel setAllowedFileTypes:[NSArray arrayWithObject:fileType]];
            }
            
            if (NSFileHandlingPanelOKButton == [panel runModal] && [panel URL]) {
                [imageData writeToURL:[panel URL] options:NSDataWritingAtomic error:&error];
            } else {
                error = [NSError errorWithDomain:@"save panel cancelled" code:1 userInfo:nil];
            }
            
            if (doneBlock) {
                doneBlock([panel URL], error);
                [doneBlock release];
            }
        } copy] autorelease] afterDelay:0];
    }
}

@end
