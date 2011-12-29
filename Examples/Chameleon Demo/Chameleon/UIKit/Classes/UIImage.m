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
#import <AppKit/NSImage.h>

@implementation UIImage

- (id)initWithNSImage:(NSImage *)theImage
{
    if (theImage) {
        return [self initWithCGImage:[theImage CGImageForProposedRect:NULL context:NULL hints:nil]];
    } else {
        [self release];
        return nil;
    }
}

- (id)initWithData:(NSData *)data
{
    if (data) {
        return [self initWithNSImage:[[[NSImage alloc] initWithData:data] autorelease]];
    } else {
        [self release];
        return nil;
    }
}

- (id)initWithContentsOfFile:(NSString *)path
{
    return [self initWithNSImage:[[[NSImage alloc] initWithContentsOfFile:[isa _pathForFile:path]] autorelease]];
}

- (id)initWithCGImage:(CGImageRef)imageRef
{
    if (!imageRef) {
        [self release];
        return nil;
    } else if ((self=[super init])) {
        _image = imageRef;
        CGImageRetain(_image);
    }
    return self;
}

- (void)dealloc
{
    if (_image) CGImageRelease(_image);
    [super dealloc];
}

+ (UIImage *)_loadImageNamed:(NSString *)name
{
    if ([name length] > 0) {
        NSString *macName = [self _macPathForFile:name];
        
        // first check for @mac version of the name
        UIImage *cachedImage = [self _cachedImageForName:macName];
        if (!cachedImage) {
            // otherwise try again with the original given name
            cachedImage = [self _cachedImageForName:name];
        }
        
        if (!cachedImage) {
            // okay, we couldn't find a cached version so now lets first try to make an original with the @mac name.
            // if that fails, try to make it with the original name.
            NSImage *image = [NSImage imageNamed:macName];
            if (!image) {
                image = [NSImage imageNamed:name];
            }
            
            if (image) {
                cachedImage = [[[self alloc] initWithNSImage:image] autorelease];
                [self _cacheImage:cachedImage forName:name];
            }
        }
        
        return cachedImage;
    } else {
        return nil;
    }
}

+ (UIImage *)imageNamed:(NSString *)name
{
    // first try it with the given name
    UIImage *image = [self _loadImageNamed:name];
    
    // if nothing is found, try again after replacing any underscores in the name with dashes.
    // I don't know why, but UIKit does something similar. it probably has a good reason and it might not be this simplistic, but
    // for now this little hack makes Ramp Champ work. :)
    if (!image) {
        image = [self _loadImageNamed:[name stringByReplacingOccurrencesOfString:@"_" withString:@"-"]];
    }
    
    return image;
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

- (UIImage *)stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    const CGSize size = self.size;
    if ((leftCapWidth == 0 && topCapHeight == 0) || (leftCapWidth >= size.width && topCapHeight >= size.height)) {
        return self;
    } else if (leftCapWidth <= 0 || leftCapWidth >= size.width) {
        return [[[UIThreePartImage alloc] initWithNSImage:[[[NSImage alloc] initWithCGImage:_image size:NSZeroSize] autorelease] capSize:MIN(topCapHeight,size.height) vertical:YES] autorelease];
    } else if (topCapHeight <= 0 || topCapHeight >= size.height) {
        return [[[UIThreePartImage alloc] initWithNSImage:[[[NSImage alloc] initWithCGImage:_image size:NSZeroSize] autorelease] capSize:MIN(leftCapWidth,size.width) vertical:NO] autorelease];
    } else {
        return [[[UINinePartImage alloc] initWithNSImage:[[[NSImage alloc] initWithCGImage:_image size:NSZeroSize] autorelease] leftCapWidth:leftCapWidth topCapHeight:topCapHeight] autorelease];
    }
}

- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height) blendMode:blendMode alpha:alpha];
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
    const CGSize size = self.size;
    [self drawInRect:CGRectMake(point.x,point.y,size.width,size.height)];
}

- (void)drawInRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y+rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGContextDrawImage(ctx, CGRectMake(0,0,rect.size.width,rect.size.height), _image);
    CGContextRestoreGState(ctx);
}

- (CGSize)size
{
    return CGSizeMake(CGImageGetWidth(_image), CGImageGetHeight(_image));
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
    return _image;
}

- (UIImageOrientation)imageOrientation
{
    return UIImageOrientationUp;
}

- (NSImage *)NSImage
{
    return [[[NSImage alloc] initWithCGImage:_image size:NSSizeFromCGSize(self.size)] autorelease];
}

- (NSBitmapImageRep *)_NSBitmapImageRep
{
    return [[[NSBitmapImageRep alloc] initWithCGImage:_image] autorelease];
}

- (CGFloat)scale
{
    return 1.0;
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
    return [[image _NSBitmapImageRep] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressionQuality] forKey:NSImageCompressionFactor]];
}

NSData *UIImagePNGRepresentation(UIImage *image)
{
    return [[image _NSBitmapImageRep] representationUsingType:NSPNGFileType properties:nil];
}
