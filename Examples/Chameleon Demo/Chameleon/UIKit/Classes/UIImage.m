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

#import "UIImage+UIPrivate.h"
#import "UIThreePartImage.h"
#import "UINinePartImage.h"
#import "UIGraphics.h"
#import "UIPhotosAlbum.h"
#import "UIImageRep.h"

@implementation UIImage

+ (UIImage *)_imageNamed:(NSString *)name
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [[bundle resourcePath] stringByAppendingPathComponent:name];
    UIImage *img = [self imageWithContentsOfFile:path];
    
    if (!img) {
        // if nothing is found, try again after replacing any underscores in the name with dashes.
        // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
        // for now this little hack makes Ramp Champ work. :)
        path = [[[bundle resourcePath] stringByAppendingPathComponent:[[name stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@"-"]] stringByAppendingPathExtension:[name pathExtension]];
        img = [self imageWithContentsOfFile:path];
    }
    
    return img;
}

+ (id)imageNamed:(NSString *)name
{
    UIImage *img = [self _cachedImageForName:name];
    
    if (!img) {
        // as per the iOS docs, if it fails to find a match with the bare name, it re-tries by appending a png file extension
        img = [self _imageNamed:name] ?: [self _imageNamed:[name stringByAppendingPathExtension:@"png"]];
        [self _cacheImage:img forName:name];
    }
    
    return img;
}

- (id)initWithContentsOfFile:(NSString *)imagePath
{
    return [self _initWithRepresentations:[UIImageRep imageRepsWithContentsOfFile:imagePath]];
}

- (id)initWithData:(NSData *)data
{
    return [self _initWithRepresentations:[NSArray arrayWithObjects:[[[UIImageRep alloc] initWithData:data] autorelease], nil]];
}

- (id)initWithCGImage:(CGImageRef)imageRef
{
    return [self initWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
}

- (id)initWithCGImage:(CGImageRef)imageRef scale:(CGFloat)scale orientation:(UIImageOrientation)orientation
{
    return [self _initWithRepresentations:[NSArray arrayWithObjects:[[[UIImageRep alloc] initWithCGImage:imageRef scale:scale] autorelease], nil]];
}

- (void)dealloc
{
    [_representations release];
    [super dealloc];
}

+ (UIImage *)imageWithData:(NSData *)data
{
    return [[[self alloc] initWithData:data] autorelease];
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path
{
    return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

+ (UIImage *)imageWithCGImage:(CGImageRef)imageRef
{
    return [[[self alloc] initWithCGImage:imageRef] autorelease];
}

+ (UIImage *)imageWithCGImage:(CGImageRef)imageRef scale:(CGFloat)scale orientation:(UIImageOrientation)orientation
{
    return [[[self alloc] initWithCGImage:imageRef scale:scale orientation:orientation] autorelease];
}

- (UIImage *)stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    const CGSize size = self.size;

    if ((leftCapWidth == 0 && topCapHeight == 0) || (leftCapWidth >= size.width && topCapHeight >= size.height)) {
        return self;
    } else if (leftCapWidth <= 0 || leftCapWidth >= size.width) {
        return [[[UIThreePartImage alloc] initWithRepresentations:[self _representations] capSize:MIN(topCapHeight,size.height) vertical:YES] autorelease];
    } else if (topCapHeight <= 0 || topCapHeight >= size.height) {
        return [[[UIThreePartImage alloc] initWithRepresentations:[self _representations] capSize:MIN(leftCapWidth,size.width) vertical:NO] autorelease];
    } else {
        return [[[UINinePartImage alloc] initWithRepresentations:[self _representations] leftCapWidth:leftCapWidth topCapHeight:topCapHeight] autorelease];
    }
}

- (CGSize)size
{
    CGSize size = CGSizeZero;
    UIImageRep *rep = [_representations lastObject];
    const CGSize repSize = rep.imageSize;
    const CGFloat scale = rep.scale;
    size.width = repSize.width / scale;
    size.height = repSize.height / scale;
    return size;
}

- (NSInteger)leftCapWidth
{
    return 0;
}

- (NSInteger)topCapHeight
{
    return 0;
}

- (CGImageRef)CGImage
{
    return [self _bestRepresentationForProposedScale:2].CGImage;
}

- (UIImageOrientation)imageOrientation
{
    return UIImageOrientationUp;
}

- (CGFloat)scale
{
    return [self _bestRepresentationForProposedScale:2].scale;
}

- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    [self drawInRect:(CGRect){point, self.size} blendMode:blendMode alpha:alpha];
}

- (void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetBlendMode(ctx, blendMode);
    CGContextSetAlpha(ctx, alpha);

    [self drawInRect:rect];
    
    CGContextRestoreGState(ctx);
}

- (void)drawAtPoint:(CGPoint)point
{
    [self drawInRect:(CGRect){point, self.size}];
}

- (void)drawInRect:(CGRect)rect
{
    if (rect.size.height > 0 && rect.size.width > 0) {
        [self _drawRepresentation:[self _bestRepresentationForProposedScale:_UIGraphicsGetContextScaleFactor(UIGraphicsGetCurrentContext())] inRect:rect];
    }
}

@end

void UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo)
{
    [[UIPhotosAlbum sharedPhotosAlbum] writeImage:image completionTarget:completionTarget action:completionSelector context:contextInfo];
}

void UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, id completionTarget, SEL completionSelector, void *contextInfo)
{
}

BOOL UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(NSString *videoPath)
{
    return NO;
}

NSData *UIImageJPEGRepresentation(UIImage *image, CGFloat compressionQuality)
{
    CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
    CGImageDestinationRef dest = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, NULL);
    CFNumberRef quality = CFNumberCreate(NULL, kCFNumberCGFloatType, &compressionQuality);
    CFStringRef keys[] = { kCGImageDestinationLossyCompressionQuality };
    CFTypeRef values[] = { quality };
    CFDictionaryRef properties = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, 1, NULL, NULL);
    CGImageDestinationAddImage(dest, image.CGImage, properties);
    CFRelease(properties);
    CFRelease(quality);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return [(__bridge NSData *)data autorelease];
}

NSData *UIImagePNGRepresentation(UIImage *image)
{
    CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
    CGImageDestinationRef dest = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(dest, image.CGImage, NULL);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return [(__bridge NSData *)data autorelease];
}
