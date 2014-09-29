//
//  ReflectionView.m
//
//  Version 1.2
//
//  Created by Nick Lockwood on 19/07/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
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


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#pragma GCC diagnostic ignored "-Wreceiver-is-weak"
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wunused-macros"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wformat-nonliteral"
#pragma GCC diagnostic ignored "-Wgnu"


@interface ReflectionView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *reflectionView;

@end


@implementation ReflectionView

+ (Class)layerClass
{
    return [CAReplicatorLayer class];
}

- (void)update
{
    if (_dynamic)
    {
        //remove gradient view
        [_reflectionView removeFromSuperview];
        self.reflectionView = nil;
        
        //update instances
        CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;
        layer.shouldRasterize = YES;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        layer.instanceCount = 2;
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, 0.0f, layer.bounds.size.height + _reflectionGap, 0.0f);
        transform = CATransform3DScale(transform, 1.0f, -1.0f, 0.0f);
        layer.instanceTransform = transform;
        layer.instanceAlphaOffset = _reflectionAlpha - 1.0f;
        
        //create gradient layer
        if (!_gradientLayer)
        {
            _gradientLayer = [[CAGradientLayer alloc] init];
            self.layer.mask = _gradientLayer;
            _gradientLayer.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                                     (__bridge id)[UIColor blackColor].CGColor,
                                     (__bridge id)[UIColor clearColor].CGColor];
        }
        
        //update mask
        [CATransaction begin];
        [CATransaction setDisableActions:YES]; // don't animate
        CGFloat total = layer.bounds.size.height * 2.0f + _reflectionGap;
        CGFloat halfWay = (layer.bounds.size.height + _reflectionGap) / total - 0.01f;
        _gradientLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, total);
        _gradientLayer.locations = @[@0.0f, @(halfWay), @(halfWay + (1.0f - halfWay) * _reflectionScale)];
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
        if (!_reflectionView)
        {
            _reflectionView = [[UIImageView alloc] initWithFrame:self.bounds];
            _reflectionView.contentMode = UIViewContentModeScaleToFill;
            _reflectionView.userInteractionEnabled = NO;
            [self addSubview:_reflectionView];
        }
        
        //get reflection bounds
        CGSize size = CGSizeMake(self.bounds.size.width, self.bounds.size.height * _reflectionScale);
        if (size.height > 0.0f && size.width > 0.0f)
        {
            //create gradient mask
            UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
            CGContextRef gradientContext = UIGraphicsGetCurrentContext();
            CGFloat colors[] = {1.0f, 1.0f, 0.0f, 1.0f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
            CGPoint gradientStartPoint = CGPointMake(0.0f, 0.0f);
            CGPoint gradientEndPoint = CGPointMake(0.0f, size.height);
            CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                        gradientEndPoint, kCGGradientDrawsAfterEndLocation);
            CGImageRef gradientMask = CGBitmapContextCreateImage(gradientContext);
            CGGradientRelease(gradient);
            CGColorSpaceRelease(colorSpace);
            UIGraphicsEndImageContext();
            
            //create drawing context
            UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1.0f, -1.0f);
            CGContextTranslateCTM(context, 0.0f, -self.bounds.size.height);
            
            //clip to gradient
            CGContextClipToMask(context, CGRectMake(0.0f, self.bounds.size.height - size.height,
                                                    size.width, size.height), gradientMask);
            CGImageRelease(gradientMask);
            
            //draw reflected layer content
            [self.layer renderInContext:context];
            
            //capture resultant image
            _reflectionView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        //update reflection
        _reflectionView.alpha = _reflectionAlpha;
        _reflectionView.frame = CGRectMake(0, self.bounds.size.height + _reflectionGap, size.width, size.height);
    }
}

- (void)setUp
{
    //set default properties
    _reflectionGap = 4.0f;
    _reflectionScale = 0.5f;
    _reflectionAlpha = 0.5f;
    
    //update reflection
    [self setNeedsLayout];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    return self;
}

- (void)setReflectionGap:(CGFloat)reflectionGap
{
    _reflectionGap = reflectionGap;
    [self setNeedsLayout];
}

- (void)setReflectionScale:(CGFloat)reflectionScale
{
    _reflectionScale = reflectionScale;
    [self setNeedsLayout];
}

- (void)setReflectionAlpha:(CGFloat)reflectionAlpha
{
    _reflectionAlpha = reflectionAlpha;
    [self setNeedsLayout];
}

- (void)setDynamic:(BOOL)dynamic
{
    _dynamic = dynamic;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [self update];
    [super layoutSubviews];
}

@end
