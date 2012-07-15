//
//  FXImageView.m
//
//  Version 1.2
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


@interface FXImageBlockOperation : FXImageOperation

@property (nonatomic, copy) UIImage *(^block)(void);

@end


@interface FXImageView ()

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSURL *imageContentURL;

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


@implementation FXImageBlockOperation

@synthesize block = _block;

- (void)main
{
    @autoreleasepool
    {
        self.target.image = _block();
        [super main];
    }
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_block release];
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
@synthesize cornerRadius = _cornerRadius;

@synthesize customEffectsBlock = _customEffectsBlock;
@synthesize customEffectsIdentifier = _customEffectsIdentifier;

@synthesize originalImage = _originalImage;
@synthesize imageView = _imageView;
@synthesize imageContentURL = _imageContentURL;


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

- (id)initWithImage:(UIImage *)image
{
    if ((self = [super initWithImage:image]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    if ((self = [super initWithImage:image highlightedImage:highlightedImage]))
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
    [_customEffectsBlock release];
    [_customEffectsIdentifier release];
    [_originalImage release];
    [_shadowColor release];
    [_imageView release];
    [_imageContentURL release];
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
    NSString *key = [NSString stringWithFormat:@"%@_%@_%.2f_%.2f_%.2f_%@_%@_%.2f_%.2f_%i",
                     _imageContentURL ?: _originalImage,
                     NSStringFromCGSize(self.bounds.size),
                     _reflectionGap,
                     _reflectionScale,
                     _reflectionAlpha,
                     [self colorString:_shadowColor],
                     NSStringFromCGSize(_shadowOffset),
                     _shadowBlur,
                     _cornerRadius,
                     self.contentMode];
    
    if (_customEffectsBlock)
    {
        key = [key stringByAppendingFormat:@"_%@", _customEffectsIdentifier];
    }
    return key;
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
    NSURL *imageURL = _imageContentURL;
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
        //load image
        if (_imageContentURL)
        {
            NSURLRequest *request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
            NSError *error = nil;
            NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (error)
            {
                NSLog(@"Error loading image for URL: %@, %@", imageURL, error);
                return;
            }
            else
            {
                image = [UIImage imageWithData:data];
                if ([[[imageURL path] stringByDeletingPathExtension] hasSuffix:@"@2x"])
                {
                    image = [UIImage imageWithCGImage:image.CGImage scale:2.0f orientation:UIImageOrientationUp];
                }
            }
        }
        
        //crop and scale image
        processedImage = [image imageCroppedAndScaledToSize:size
                                                contentMode:contentMode
                                                   padToFit:NO];
        
        //apply custom processing
        if (_customEffectsBlock)
        {
            processedImage = _customEffectsBlock(processedImage);
        }
        
        //clip corners
        if (_cornerRadius)
        {
            processedImage = [processedImage imageWithCornerRadius:_cornerRadius];
        }
        
        //apply shadow
        if (shadowColor && ![shadowColor isEqual:[UIColor clearColor]] &&
            (shadowBlur || !CGSizeEqualToSize(shadowOffset, CGSizeZero)))
        {
            reflectionGap -= 2.0f * (fabsf(shadowOffset.height) + shadowBlur);
            processedImage = [processedImage imageWithShadowColor:shadowColor
                                                           offset:shadowOffset
                                                             blur:shadowBlur];
        }
        
        //apply reflection
        if (self.reflectionScale && self.reflectionAlpha)
        {
            processedImage = [processedImage imageWithReflectionWithScale:reflectionScale
                                                                      gap:reflectionGap
                                                                    alpha:reflectionAlpha];
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

- (void)queueProcessingOperation:(FXImageOperation *)operation
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
    
    //make op a dependency of all queued ops
    NSInteger maxOperations = ([queue maxConcurrentOperationCount] > 0) ? [queue maxConcurrentOperationCount]: INT_MAX;
    NSInteger index = [queue operationCount] - maxOperations;
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
}

- (void)queueImageForProcessing
{
    //create processing operation
    FXImageOperation *operation = [[FXImageOperation alloc] init];
    operation.target = self;
    
    //set operation thread priority
    [operation setThreadPriority:1.0];
    
    //queue operation
    [self queueProcessingOperation:operation];
    
#if !__has_feature(objc_arc)
    
    [operation release];
    
#endif
    
}

- (void)layoutSubviews
{
    _imageView.frame = self.bounds;
    if (_imageContentURL || self.image)
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
    if (![_originalImage isEqual:image])
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
    if (![_shadowColor isEqual:shadowColor])
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

- (void)setCustomEffectsBlock:(UIImage *(^)(UIImage *))customEffectsBlock
{
    if (![customEffectsBlock isEqual:_customEffectsBlock])
    {
        _customEffectsBlock = [customEffectsBlock copy];
        [self setNeedsLayout];
    }
}

- (void)setCustomEffectsIdentifier:(NSString *)customEffectsIdentifier
{
    if (![customEffectsIdentifier isEqual:_customEffectsIdentifier])
    {
        _customEffectsIdentifier = [customEffectsIdentifier copy];
        [self setNeedsLayout];
    }
}


#pragma mark -
#pragma mark loading

- (void)setImageWithContentsOfFile:(NSString *)file
{
    if ([[file pathExtension] length] == 0)
    {
        file = [file stringByAppendingPathExtension:@"png"];
    }
    if (![file isAbsolutePath])
    {
        file = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    }
    if ([UIScreen mainScreen].scale == 2.0f)
    {
        NSString *temp = [[[file stringByDeletingPathExtension] stringByAppendingString:@"@2x"] stringByAppendingPathExtension:[file pathExtension]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:temp])
        {
            file = temp;
        }
    }
    [self setImageWithContentsOfURL:[NSURL fileURLWithPath:file]];
}

- (void)setImageWithContentsOfURL:(NSURL *)URL
{
    if (![URL isEqual:_imageContentURL])
    {
        //clear current image
        self.imageContentURL = URL;
        self.originalImage = nil;
        
        if (_asynchronous)
        {
            [self setNeedsLayout];
        }
        else
        {
            //load image directly
            NSData *data = [NSData dataWithContentsOfURL:URL];
            self.image = [UIImage imageWithData:data];
        }
    }
}

- (void)setImageWithBlock:(UIImage *(^)(void))block
{
    //clear current image
    self.originalImage = nil;
    self.imageContentURL = nil;
    
    if (_asynchronous)
    {
        //create block operation
        FXImageBlockOperation *operation = [[FXImageBlockOperation alloc] init];
        operation.target = self;
        operation.block = block;
        
        //set operation thread priority
        [operation setThreadPriority:1.0];
        
        //queue operation
        [self queueProcessingOperation:operation];
        
#if !__has_feature(objc_arc)
        
        [operation release];
        
#endif
        
    }
    else
    {
        //set image directly
        self.image = block();
    }
}

@end
