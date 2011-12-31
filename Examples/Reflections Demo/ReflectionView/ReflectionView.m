//
//  ReflectionView.m
//
//  Created by Nick Lockwood on 19/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//
//  Get the latest version of ReflectionView from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#reflectionview
//  https://github.com/nicklockwood/ReflectionView
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

#import "ReflectionView.h"
#import <QuartzCore/QuartzCore.h>


@interface ReflectionView ()

@property (nonatomic, retain) CAGradientLayer *gradientLayer;
@property (nonatomic, retain) UIImageView *reflectionView;

@end


@implementation ReflectionView

@synthesize reflectionGap;
@synthesize reflectionScale;
@synthesize reflectionAlpha;
@synthesize gradientLayer;
@synthesize reflectionView;
@synthesize dynamic;

+ (Class)layerClass
{
    return [CAReplicatorLayer class];
}

- (void)update
{
    if (dynamic)
    {
        //remove gradient view
        [reflectionView removeFromSuperview];
        self.reflectionView = nil;
        
        //update instances
        CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;
        layer.shouldRasterize = YES;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        layer.instanceCount = 2;
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, 0, layer.bounds.size.height + reflectionGap, 0);
        transform = CATransform3DScale(transform, 1.0, -1.0, 0.0);
        layer.instanceTransform = transform;
        layer.instanceAlphaOffset = reflectionAlpha - 1.0;
        
        //create gradient layer
        if (!gradientLayer)
        {
            gradientLayer = [[CAGradientLayer alloc] init];
            self.layer.mask = gradientLayer;
            gradientLayer.colors = [NSArray arrayWithObjects:
                                    (id)[UIColor blackColor].CGColor,
                                    (id)[UIColor blackColor].CGColor,
                                    (id)[UIColor clearColor].CGColor,
                                    nil];
        }
        
        //update mask
        [CATransaction begin];
        [CATransaction setDisableActions:YES]; // don't animate
        CGFloat total = layer.bounds.size.height * 2.0 + reflectionGap;
        CGFloat halfWay = (layer.bounds.size.height + reflectionGap) / total - 0.01;
        gradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width, total);
        gradientLayer.locations = [NSArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0.0],
                                   [NSNumber numberWithFloat:halfWay],
                                   [NSNumber numberWithFloat:halfWay + (1.0 - halfWay) * reflectionScale],
                                   nil];
        [CATransaction commit];
    }
    else
    {
        //remove gradient layer
        self.layer.mask = nil;
        self.gradientLayer = nil;
        
        //update instances
        CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;
        layer.shouldRasterize = NO;
        layer.instanceCount = 1;
        
        //create reflection view
        if (!reflectionView)
        {
            reflectionView = [[UIImageView alloc] initWithFrame:self.bounds];
            reflectionView.contentMode = UIViewContentModeScaleToFill;
            reflectionView.userInteractionEnabled = NO;
            [self addSubview:reflectionView];
        }
        
        //create gradient mask
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
        CGContextRef gradientContext = UIGraphicsGetCurrentContext();
        CGFloat colors[] = {1.0, 1.0, 0.0, 1.0};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
        CGPoint gradientStartPoint = CGPointMake(0, 0);
        CGPoint gradientEndPoint = CGPointMake(0, self.bounds.size.height * reflectionScale);
        CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                    gradientEndPoint, kCGGradientDrawsAfterEndLocation);
        CGImageRef gradientMask = CGBitmapContextCreateImage(gradientContext);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        UIGraphicsEndImageContext();
        
        //create drawing context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -self.bounds.size.height);
        
        //clip to gradient
        CGContextClipToMask(context, self.bounds, gradientMask);
        CGImageRelease(gradientMask);
        
        //draw reflected layer content
        [self.layer renderInContext:context];
        
        //capture resultant image
        reflectionView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //update reflection
        reflectionView.alpha = reflectionAlpha;
        reflectionView.frame = CGRectMake(0, self.bounds.size.height + reflectionGap,
                                          self.bounds.size.width, self.bounds.size.height);
    }
}

- (void)setup
{
    //set default properties
    reflectionGap = 4;
    reflectionScale = 0.5;
    reflectionAlpha = 0.5;
    
    //update reflection
    [self update];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }
    return self;
}

- (void)setReflectionGap:(CGFloat)_reflectionGap
{
    reflectionGap = _reflectionGap;
    [self update];
}

- (void)setReflectionScale:(CGFloat)_reflectionScale
{
    reflectionScale = _reflectionScale;
    [self update];
}

- (void)setReflectionAlpha:(CGFloat)_reflectionAlpha
{
    reflectionAlpha = _reflectionAlpha;
    [self update];
}

- (void)setDynamic:(BOOL)_dynamic
{
    dynamic = _dynamic;
    [self update];
}

- (void)layoutSubviews
{
    [self update];
}

- (void)dealloc
{
    [gradientLayer release];
    [reflectionView release];
    [super dealloc];
}

@end