//
//  UIImage+FX.m
//
//  Version 1.3.5
//
//  Created by Nick Lockwood on 31/10/2011.
//  Copyright (c) 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/FXImageView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "UIImage+FX.h"


#pragma GCC diagnostic ignored "-Wconversion"


@implementation UIImage (FX)

- (UIImage *)imageCroppedToRect:(CGRect)rect
{
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    
    //draw
    [self drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageScaledToSize:(CGSize)size
{   
    //avoid redundant drawing
    if (CGSizeEqualToSize(self.size, size))
    {
        return self;
    }
    
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageScaledToFitSize:(CGSize)size
{
    //calculate rect
    CGFloat aspect = self.size.width / self.size.height;
    if (size.width / aspect <= size.height)
    {
        return [self imageScaledToSize:CGSizeMake(size.width, size.width / aspect)];
    }
    else
    {
        return [self imageScaledToSize:CGSizeMake(size.height * aspect, size.height)];
    }
}

- (UIImage *)imageScaledToFillSize:(CGSize)size
{
    if (CGSizeEqualToSize(self.size, size))
    {
        return self;
    }
    //calculate rect
    CGFloat aspect = self.size.width / self.size.height;
    if (size.width / aspect >= size.height)
    {
        return [self imageScaledToSize:CGSizeMake(size.width, size.width / aspect)];
    }
    else
    {
        return [self imageScaledToSize:CGSizeMake(size.height * aspect, size.height)];
    }
}

- (UIImage *)imageCroppedAndScaledToSize:(CGSize)size
                             contentMode:(UIViewContentMode)contentMode
                                padToFit:(BOOL)padToFit
{
    //calculate rect
    CGRect rect = CGRectZero;
    switch (contentMode)
    {
        case UIViewContentModeScaleAspectFit:
        {
            CGFloat aspect = self.size.width / self.size.height;
            if (size.width / aspect <= size.height)
            {
                rect = CGRectMake(0.0f, (size.height - size.width / aspect) / 2.0f, size.width, size.width / aspect);
            }
            else
            {
                rect = CGRectMake((size.width - size.height * aspect) / 2.0f, 0.0f, size.height * aspect, size.height);
            }
            break;
        }
        case UIViewContentModeScaleAspectFill:
        {
            CGFloat aspect = self.size.width / self.size.height;
            if (size.width / aspect >= size.height)
            {
                rect = CGRectMake(0.0f, (size.height - size.width / aspect) / 2.0f, size.width, size.width / aspect);
            }
            else
            {
                rect = CGRectMake((size.width - size.height * aspect) / 2.0f, 0.0f, size.height * aspect, size.height);
            }
            break;
        }
        case UIViewContentModeCenter:
        {
            rect = CGRectMake((size.width - self.size.width) / 2.0f, (size.height - self.size.height) / 2.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeTop:
        {
            rect = CGRectMake((size.width - self.size.width) / 2.0f, 0.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeBottom:
        {
            rect = CGRectMake((size.width - self.size.width) / 2.0f, size.height - self.size.height, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeLeft:
        {
            rect = CGRectMake(0.0f, (size.height - self.size.height) / 2.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeRight:
        {
            rect = CGRectMake(size.width - self.size.width, (size.height - self.size.height) / 2.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeTopLeft:
        {
            rect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeTopRight:
        {
            rect = CGRectMake(size.width - self.size.width, 0.0f, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeBottomLeft:
        {
            rect = CGRectMake(0.0f, size.height - self.size.height, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeBottomRight:
        {
            rect = CGRectMake(size.width - self.size.width, size.height - self.size.height, self.size.width, self.size.height);
            break;
        }
        case UIViewContentModeRedraw:
        case UIViewContentModeScaleToFill:
        {
            rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
            break;
        }
    }
    
    if (!padToFit)
    {
        //remove padding
        if (rect.size.width < size.width)
        {
            size.width = rect.size.width;
            rect.origin.x = 0.0f;
        }
        if (rect.size.height < size.height)
        {
            size.height = rect.size.height;
            rect.origin.y = 0.0f;
        }
    }
    
    //avoid redundant drawing
    if (CGSizeEqualToSize(self.size, size))
    {
        return self;
    }
    
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [self drawInRect:rect];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

+ (CGImageRef)gradientMask
{
    static CGImageRef sharedMask = NULL;
    if (sharedMask == NULL)
    {
        //create gradient mask
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 256), YES, 0.0);
        CGContextRef gradientContext = UIGraphicsGetCurrentContext();
        CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
        CGPoint gradientStartPoint = CGPointMake(0, 0);
        CGPoint gradientEndPoint = CGPointMake(0, 256);
        CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                    gradientEndPoint, kCGGradientDrawsAfterEndLocation);
        sharedMask = CGBitmapContextCreateImage(gradientContext);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        UIGraphicsEndImageContext();
    }
    return sharedMask;
}

- (UIImage *)reflectedImageWithScale:(CGFloat)scale
{
	//get reflection dimensions
	CGFloat height = ceil(self.size.height * scale);
	CGSize size = CGSizeMake(self.size.width, height);
	CGRect bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
	
	//create drawing context
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	//clip to gradient
	CGContextClipToMask(context, bounds, [[self class] gradientMask]);
	
	//draw reflected image
	CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextTranslateCTM(context, 0.0f, -self.size.height);
	[self drawInRect:CGRectMake(0.0f, 0.0f, self.size.width, self.size.height)];
	
	//capture resultant image
	UIImage *reflection = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return reflection image
	return reflection;
}

- (UIImage *)imageWithReflectionWithScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha
{
    //get reflected image
    UIImage *reflection = [self reflectedImageWithScale:scale];
    CGFloat reflectionOffset = reflection.size.height + gap;
    
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.size.width, self.size.height + reflectionOffset * 2.0f), NO, 0.0f);
    
    //draw reflection
    [reflection drawAtPoint:CGPointMake(0.0f, reflectionOffset + self.size.height + gap) blendMode:kCGBlendModeNormal alpha:alpha];
    
    //draw image
    [self drawAtPoint:CGPointMake(0.0f, reflectionOffset)];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur
{
    //get size
    CGSize border = CGSizeMake(fabsf(offset.width) + blur, fabsf(offset.height) + blur);
    CGSize size = CGSizeMake(self.size.width + border.width * 2.0f, self.size.height + border.height * 2.0f);
    
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //set up shadow
    CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
    
    //draw with shadow
    [self drawAtPoint:CGPointMake(border.width, border.height)];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageWithCornerRadius:(CGFloat)radius
{
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    //clip image
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.size.width, self.size.height) cornerRadius:radius] addClip];
    
    //draw image
    [self drawAtPoint:CGPointZero];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageWithAlpha:(CGFloat)alpha
{
    //create drawing context
	UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    //draw with alpha
    [self drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:alpha];
    
    //capture resultant image
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//return image
	return image;
}

- (UIImage *)imageWithMask:(UIImage *)maskImage
{
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //apply mask
    CGContextClipToMask(context, CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), maskImage.CGImage);
    
    //draw image
    [self drawAtPoint:CGPointZero];
    
    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return image
    return image;
}

- (UIImage *)maskImageFromImageAlpha
{
    //get dimensions
    NSInteger width = CGImageGetWidth(self.CGImage);
    NSInteger height = CGImageGetHeight(self.CGImage);
    
    //create alpha image
    NSInteger bytesPerRow = ((width + 3) / 4) * 4;
    uint8_t *data = (uint8_t *)malloc(bytesPerRow * height);
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    //invert alpha pixels
    for (NSInteger y = 0; y < height; y++)
    {
        for (NSInteger x = 0; x < width; x++)
        {
            NSInteger index = y * bytesPerRow + x;
            data[index] = 255 - data[index];
        }
    }
    
    //create mask image
    CGImageRef maskRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *mask = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    free(data);

    //return image
	return mask;
}

@end
