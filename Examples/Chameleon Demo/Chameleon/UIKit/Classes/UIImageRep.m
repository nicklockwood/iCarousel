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

#import "UIImageRep.h"
#import "UIGraphics.h"

static CGImageSourceRef CreateCGImageSourceWithFile(NSString *imagePath)
{
    NSString *macPath = [[[imagePath stringByDeletingPathExtension] stringByAppendingString:@"~mac"] stringByAppendingPathExtension:[imagePath pathExtension]];
    return CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:macPath], NULL) ?: CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:imagePath], NULL);
}

@implementation UIImageRep
@synthesize scale=_scale;

+ (NSArray *)_imageRepsWithContentsOfMultiResolutionFile:(NSString *)imagePath
{
    // Note - not currently supported, but it should be easy to add in multi-resolution TIFF support here
    // just check the file type initially and if it's a TIFF with multiple scale images in there, build the
    // representations from that and return them, otherwise return nil and +imageRepsWithContentsOfFile: will
    // try looking for the old-school multi-files.
    return nil;
}

+ (NSArray *)_imageRepsWithContentsOfFiles:(NSString *)imagePath
{
    NSMutableArray *reps = [NSMutableArray arrayWithCapacity:2];
    CGImageSourceRef src1X = CreateCGImageSourceWithFile(imagePath);
    CGImageSourceRef src2X = CreateCGImageSourceWithFile([[[imagePath stringByDeletingPathExtension] stringByAppendingString:@"@2x"] stringByAppendingPathExtension:[imagePath pathExtension]]);

    if (src1X) {
        UIImageRep *rep = [[UIImageRep alloc] initWithCGImageSource:src1X imageIndex:0 scale:1];
        if (rep) [reps addObject:rep];
        [rep release];
        CFRelease(src1X);
    }
    if (src2X) {
        UIImageRep *rep = [[UIImageRep alloc] initWithCGImageSource:src2X imageIndex:0 scale:2];
        if (rep) [reps addObject:rep];
        [rep release];
        CFRelease(src2X);
    }
    
    return ([reps count] > 0)? reps : nil;
}

+ (NSArray *)imageRepsWithContentsOfFile:(NSString *)imagePath
{
    return [self _imageRepsWithContentsOfMultiResolutionFile:imagePath] ?: [self _imageRepsWithContentsOfFiles:imagePath];
}

- (id)initWithCGImageSource:(CGImageSourceRef)source imageIndex:(NSUInteger)index scale:(CGFloat)scale
{
    if (!source || CGImageSourceGetCount(source) <= index) {
        [self release];
        self = nil;
    } else if ((self=[super init])) {
        CFRetain(source);
        _imageSource = source;
        _imageSourceIndex = index;
        _scale = scale;
    }
    return self;
}

- (id)initWithCGImage:(CGImageRef)image scale:(CGFloat)scale
{
    if (!image) {
        [self release];
        self = nil;
    } else if ((self=[super init])) {
        _scale = scale;
        _image = CGImageRetain(image);
    }
    return self;
}

- (id)initWithData:(NSData *)data
{
    CGImageSourceRef src = data? CGImageSourceCreateWithData((CFDataRef)data, NULL) : NULL;
    if (src) {
        self = [self initWithCGImageSource:src imageIndex:0 scale:1];
        CFRelease(src);
    } else {
        [self release];
        self = nil;
    }
    
    return self;
}

- (void)dealloc
{
    if (_image) CGImageRelease(_image);
    if (_imageSource) CFRelease(_imageSource);
    [super dealloc];
}

- (BOOL)isLoaded
{
    return (_image != NULL);
}

- (BOOL)isOpaque
{
    BOOL opaque = NO;
    
    if (_image) {
        CGImageAlphaInfo info = CGImageGetAlphaInfo(_image);
        opaque = (info == kCGImageAlphaNone) || (info == kCGImageAlphaNoneSkipLast) || (info == kCGImageAlphaNoneSkipFirst);
    } else if (_imageSource) {
        CFDictionaryRef info = CGImageSourceCopyPropertiesAtIndex(_imageSource, _imageSourceIndex, NULL);
        opaque = CFDictionaryGetValue(info, kCGImagePropertyHasAlpha) != kCFBooleanTrue;
        CFRelease(info);
    }
    
    return opaque;
}

- (CGSize)imageSize
{
    CGSize size = CGSizeZero;
    
    if (_image) {
        size.width = CGImageGetWidth(_image);
        size.height = CGImageGetHeight(_image);
    } else if (_imageSource) {
        CFDictionaryRef info = CGImageSourceCopyPropertiesAtIndex(_imageSource, _imageSourceIndex, NULL);
        CFNumberRef width = CFDictionaryGetValue(info, kCGImagePropertyPixelWidth);
        CFNumberRef height = CFDictionaryGetValue(info, kCGImagePropertyPixelHeight);
        if (width && height) {
            CFNumberGetValue(width, kCFNumberCGFloatType, &size.width);
            CFNumberGetValue(height, kCFNumberCGFloatType, &size.height);
        }
        CFRelease(info);
    }

    return size;
}

- (CGImageRef)CGImage
{
    // lazy load if we only have an image source
    if (!_image && _imageSource) {
        _image = CGImageSourceCreateImageAtIndex(_imageSource, _imageSourceIndex, NULL);
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
    
    return _image;
}

- (void)drawInRect:(CGRect)rect fromRect:(CGRect)fromRect
{
    CGImageRef image = CGImageRetain(self.CGImage);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+rect.size.height);
    CGContextScaleCTM(ctx, 1, -1);
    rect.origin = CGPointZero;
    
    if (CGRectIsNull(fromRect)) {
        CGContextDrawImage(ctx, rect, image);
    } else {
        fromRect.origin.x *= _scale;
        fromRect.origin.y *= _scale;
        fromRect.size.width *= _scale;
        fromRect.size.height *= _scale;

        CGImageRef tempImage = CGImageCreateWithImageInRect(image, fromRect);
        CGContextDrawImage(ctx, rect, tempImage);
        CGImageRelease(tempImage);
    }
    
    CGContextRestoreGState(ctx);
    CGImageRelease(image);
}

@end
