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

#import <Foundation/Foundation.h>

@interface UIImageRep : NSObject {
    CGFloat _scale;
    CGImageSourceRef _imageSource;
    NSInteger _imageSourceIndex;
    CGImageRef _image;
}

+ (NSArray *)imageRepsWithContentsOfFile:(NSString *)file;

- (id)initWithCGImageSource:(CGImageSourceRef)source imageIndex:(NSUInteger)index scale:(CGFloat)scale;
- (id)initWithCGImage:(CGImageRef)image scale:(CGFloat)scale;
- (id)initWithData:(NSData *)data;

// note that the cordinates for fromRect are in the image's *scaled* coordinate system, not in raw pixels
// so for a 100x100px image with a scale of 2, the largest valid fromRect is of size 50x50.
- (void)drawInRect:(CGRect)rect fromRect:(CGRect)fromRect;

@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, readonly) CGImageRef CGImage;
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly, getter=isOpaque) BOOL opaque;

@end
