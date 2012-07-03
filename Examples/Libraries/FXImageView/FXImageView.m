//
//  FXImageView.m
//
//  Version 1.1.1
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

#import "FXImageView.h"
#import "UIImage+FX.h"
#import <objc/message.h>


@interface FXImageOperation : NSOperation

@property (nonatomic, strong) FXImageView *target;

@end


@interface FXImageView ()

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSOperation *operation;

- (void)processImage;

@end


@implementation FXImageOperation

@synthesize target = _target;

- (void)main
{
    @autoreleasepool
    {
        [_target processImage];
    }
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_target release];
    [super dealloc];
}

#endif

@end


@implementation FXImageView

@synthesize asynchronous = _asynchronous;
@synthesize reflectionGap = _reflectionGap;
@synthesize reflectionScale = _reflectionScale;
@synthesize reflectionAlpha = _reflectionAlpha;
@synthesize shadowColor = _shadowColor;
@synthesize shadowOffset = _shadowOffset;
@synthesize shadowBlur = _shadowBlur;

@synthesize originalImage = _originalImage;
@synthesize imageView = _imageView;


#pragma mark -
#pragma mark Shared storage

+ (NSOperationQueue *)processingQueue
{
    static NSOperationQueue *sharedQueue = nil;
    if (sharedQueue == nil)
    {
        sharedQueue = [[NSOperationQueue alloc] init];
        [sharedQueue setMaxConcurrentOperationCount:4];
    }
    return sharedQueue;
}

+ (NSCache *)processedImageCache
{
    static NSCache *sharedCache = nil;
    if (sharedCache == nil)
    {
        sharedCache = [[NSCache alloc] init];
    }
    return sharedCache;
}


#pragma mark -
#pragma mark Setup

- (void)setUp
{
    self.shadowColor = [UIColor blackColor];
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeCenter;
    [self addSubview:_imageView];
    [self setImage:super.image];
    super.image = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_originalImage release];
    [_shadowColor release];
    [_imageView release];
    [super dealloc];    
}

#endif


#pragma mark -
#pragma mark Caching

- (NSString *)colorString:(UIColor *)color
{
    NSString *colorString = @"{0.00,0.00}";
    if (color && ![color isEqual:[UIColor clearColor]])
    {
        NSInteger componentCount = CGColorGetNumberOfComponents(color.CGColor);
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        NSMutableArray *parts = [NSMutableArray arrayWithCapacity:componentCount];
        for (int i = 0; i < componentCount; i++)
        {
            [parts addObject:[NSString stringWithFormat:@"%.2f", components[i]]];
        }
        colorString = [NSString stringWithFormat:@"{%@}", [parts componentsJoinedByString:@","]];
    }
    return colorString;
}

- (NSString *)cacheKey
{
    return [NSString stringWithFormat:@"%i_%@_%.2f_%.2f_%.2f_%@_%@_%.2f_%i",
            (int)_originalImage,
            NSStringFromCGSize(self.bounds.size),
            _reflectionGap,
            _reflectionScale,
            _reflectionAlpha,
            [self colorString:_shadowColor],
            NSStringFromCGSize(_shadowOffset),
            _shadowBlur,
            self.contentMode];
}

- (UIImage *)cachedProcessedImage
{
    NSString *key = [self cacheKey];
    return [[[self class] processedImageCache] objectForKey:key];
}

#pragma mark -
#pragma mark Processing

- (void)setProcessedImageOnMainThread:(NSArray *)images
{
    //get images
    NSString *cacheKey = [images objectAtIndex:1];
    UIImage *processedImage = [images objectAtIndex:0];
    
    //cache image
    [[[self class] processedImageCache] setObject:processedImage forKey:cacheKey];
    
    //set image
    if ([[self cacheKey] isEqualToString:cacheKey])
    {
        //implement crossfade transition without needing to import QuartzCore
        id animation = objc_msgSend(NSClassFromString(@"CATransition"), @selector(animation));
        objc_msgSend(animation, @selector(setType:), @"kCATransitionFade");
        objc_msgSend(self.layer, @selector(addAnimation:forKey:), animation, nil);
        
        //set processed image
        _imageView.image = processedImage;
    }
}

- (void)processImage
{
    //get properties
    NSString *cacheKey = [self cacheKey];
    UIImage *image = self.image;
    CGSize size = self.bounds.size;
    CGFloat reflectionGap = _reflectionGap;
    CGFloat reflectionScale = _reflectionScale;
    CGFloat reflectionAlpha = _reflectionAlpha;
    UIColor *shadowColor = _shadowColor;
    CGSize shadowOffset = _shadowOffset;
    CGFloat shadowBlur = _shadowBlur;
    UIViewContentMode contentMode = self.contentMode;
    
    //check cache
    UIImage *processedImage = [self cachedProcessedImage];
    if (!processedImage)
    {
        //crop and scale image
        processedImage = [image imageCroppedAndScaledToSize:size
                                                contentMode:contentMode
                                                   padToFit:NO];
        
        //apply reflection
        if (self.reflectionScale && self.reflectionAlpha)
        {
            processedImage = [processedImage imageWithReflectionWithScale:reflectionScale
                                                                      gap:reflectionGap
                                                                    alpha:reflectionAlpha];
        }
        
        //apply shadow
        if (shadowColor && ![shadowColor isEqual:[UIColor clearColor]] &&
            (shadowBlur || !CGSizeEqualToSize(shadowOffset, CGSizeZero)))
        {
            processedImage = [processedImage imageWithShadowColor:shadowColor
                                                           offset:shadowOffset
                                                             blur:shadowBlur];
        }
    }
    
    //cache and set image
    if (processedImage)
    {
        if ([[NSThread currentThread] isMainThread])
        {
            [[[self class] processedImageCache] setObject:processedImage forKey:cacheKey];
            self.imageView.image = processedImage;
        }
        else
        {
            [self performSelectorOnMainThread:@selector(setProcessedImageOnMainThread:)
                                   withObject:[NSArray arrayWithObjects:processedImage, cacheKey, nil]
                                waitUntilDone:YES];
        }
    }
}

- (void)queueImageForProcessing
{
    //suspend operation queue
    NSOperationQueue *queue = [[self class] processingQueue];
    [queue setSuspended:YES];
    
    //check for existing operations
    for (FXImageOperation *op in queue.operations)
    {
        if ([op isKindOfClass:[FXImageOperation class]])
        {
            if (op.target == self && ![op isExecuting])
            {
                //already queued
                [queue setSuspended:NO];
                return;
            }
        }
    }

    //create processing operation
    FXImageOperation *operation = [[FXImageOperation alloc] init];
    operation.target = self;
    
    //set operation thread priority
    [operation setThreadPriority:1.0];
    
    //make op a dependency of all queued ops
    NSInteger index = [queue operationCount] - [queue maxConcurrentOperationCount];
    if (index >= 0)
    {
        NSOperation *op = [[queue operations] objectAtIndex:index];
        if (![op isExecuting])
        {
            [op addDependency:operation];
        }
    }
    
    //add operation to queue
    [queue addOperation:operation];
    
    //resume queue
    [queue setSuspended:NO];
    
#if !__has_feature(objc_arc)

    [operation release];
    
#endif
    
}

- (void)layoutSubviews
{
    _imageView.frame = self.bounds;
    if (self.image)
    {
        UIImage *processedImage = [self cachedProcessedImage];
        if (processedImage)
        {
            //use cached version
            _imageView.image = processedImage;
        }
        else if (_asynchronous)
        {
            //process in background
            [self queueImageForProcessing];
        }
        else
        {
            //process on main thread
            [self processImage];
        }
    }
}


#pragma mark -
#pragma mark Setters and getters

- (UIImage *)processedImage
{
    return _imageView.image;
}

- (void)setProcessedImage:(UIImage *)image
{
    self.originalImage = nil;
    _imageView.image = image;
}

- (UIImage *)image
{
    return _originalImage;
}

- (void)setImage:(UIImage *)image
{
    if (image != _originalImage)
    {
        self.originalImage = image;
        if (image)
        {
            UIImage *processedImage = [self cachedProcessedImage];
            if (processedImage)
            {
                //use cached version
                _imageView.image = processedImage;
            }
            else if (_asynchronous)
            {
                //process in background
                [self queueImageForProcessing];
            }
            else
            {
                //process on main thread
                [self processImage];
            }
        }
        else
        {
            //clear image
            _imageView.image = nil;
        }
    }
}

- (void)setReflectionGap:(CGFloat)reflectionGap
{
    if (_reflectionGap != reflectionGap)
    {
        _reflectionGap = reflectionGap;
        [self setNeedsLayout];
    }
}

- (void)setReflectionScale:(CGFloat)reflectionScale
{
    if (_reflectionScale != reflectionScale)
    {
        _reflectionScale = reflectionScale;
        [self setNeedsLayout];
    }
}

- (void)setReflectionAlpha:(CGFloat)reflectionAlpha
{
    if (_reflectionAlpha != reflectionAlpha)
    {
        _reflectionAlpha = reflectionAlpha;
        [self setNeedsLayout];
    }
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    if (_shadowColor != shadowColor)
    {
        
#if !__has_feature(objc_arc)
        
        [_shadowColor release];
        _shadowColor = [shadowColor retain];
        
#else
        
        _shadowColor = shadowColor;
        
#endif
        
        [self setNeedsLayout];
    }
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    if (!CGSizeEqualToSize(_shadowOffset, shadowOffset))
    {
        _shadowOffset = shadowOffset;
        [self setNeedsLayout];
    }
}

- (void)setShadowBlur:(CGFloat)shadowBlur
{
    if (_shadowBlur != shadowBlur)
    {
        _shadowBlur = shadowBlur;
        [self setNeedsLayout];
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    if (self.contentMode != contentMode)
    {
        super.contentMode = contentMode;
        [self setNeedsLayout];
    }
}

@end