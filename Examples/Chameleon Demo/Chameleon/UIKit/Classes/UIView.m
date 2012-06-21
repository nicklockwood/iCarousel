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

#import "UIView+UIPrivate.h"
#import "UIWindow.h"
#import "UIGraphics.h"
#import "UIColor.h"
#import "UIViewLayoutManager.h"
#import "UIViewAnimationGroup.h"
#import "UIViewBlockAnimationDelegate.h"
#import "UIViewController.h"
#import "UIAppearanceInstance.h"
#import "UIApplication+UIPrivate.h"
#import "UIGestureRecognizer+UIPrivate.h"
#import "UIScreen.h"
#import "UIColor+UIPrivate.h"
#import "UIColorRep.h"
#import <QuartzCore/CALayer.h>

NSString *const UIViewFrameDidChangeNotification = @"UIViewFrameDidChangeNotification";
NSString *const UIViewBoundsDidChangeNotification = @"UIViewBoundsDidChangeNotification";
NSString *const UIViewDidMoveToSuperviewNotification = @"UIViewDidMoveToSuperviewNotification";
NSString *const UIViewHiddenDidChangeNotification = @"UIViewHiddenDidChangeNotification";

static NSMutableArray *_animationGroups;
static BOOL _animationsEnabled = YES;

@implementation UIView
@synthesize layer=_layer, superview=_superview, clearsContextBeforeDrawing=_clearsContextBeforeDrawing, autoresizesSubviews=_autoresizesSubviews;
@synthesize tag=_tag, userInteractionEnabled=_userInteractionEnabled, contentMode=_contentMode, backgroundColor=_backgroundColor;
@synthesize multipleTouchEnabled=_multipleTouchEnabled, exclusiveTouch=_exclusiveTouch, autoresizingMask=_autoresizingMask;

+ (void)initialize
{
    if (self == [UIView class]) {
        _animationGroups = [[NSMutableArray alloc] init];
    }
}

+ (Class)layerClass
{
    return [CALayer class];
}

+ (BOOL)_instanceImplementsDrawRect
{
    return [UIView instanceMethodForSelector:@selector(drawRect:)] != [self instanceMethodForSelector:@selector(drawRect:)];
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)theFrame
{
    if ((self=[super init])) {
        _implementsDrawRect = [isa _instanceImplementsDrawRect];
        _clearsContextBeforeDrawing = YES;
        _autoresizesSubviews = YES;
        _userInteractionEnabled = YES;
        _subviews = [[NSMutableSet alloc] init];
        _gestureRecognizers = [[NSMutableSet alloc] init];

        _layer = [[[isa layerClass] alloc] init];
        _layer.delegate = self;
        _layer.layoutManager = [UIViewLayoutManager layoutManager];

        self.contentMode = UIViewContentModeScaleToFill;
        self.contentScaleFactor = 0;
        self.frame = theFrame;
        self.alpha = 1;
        self.opaque = YES;
        [self setNeedsDisplay];
    }
    return self;
}

- (void)dealloc
{
    [[_subviews allObjects] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _layer.layoutManager = nil;
    _layer.delegate = nil;
    [_layer removeFromSuperlayer];

    [_subviews release];
    [_layer release];
    [_backgroundColor release];
    [_gestureRecognizers release];
    
    [super dealloc];
}

- (void)_setViewController:(UIViewController *)theViewController
{
    _viewController = theViewController;
}

- (UIViewController *)_viewController
{
    return _viewController;
}

- (UIWindow *)window
{
    return _superview.window;
}

- (UIResponder *)nextResponder
{
    return (UIResponder *)[self _viewController] ?: (UIResponder *)_superview;
}

- (id)_appearanceContainer
{
    return self.superview;
}

- (NSArray *)subviews
{
    NSArray *sublayers = _layer.sublayers;
    NSMutableArray *subviews = [NSMutableArray arrayWithCapacity:[sublayers count]];

    // This builds the results from the layer instead of just using _subviews because I want the results to match
    // the order that CALayer has them. It's unclear in the docs if the returned order from this method is guarenteed or not,
    // however several other aspects of the system (namely the hit testing) depends on this order being correct.
    for (CALayer *layer in sublayers) {
        id potentialView = [layer delegate];
        if ([_subviews containsObject:potentialView]) {
            [subviews addObject:potentialView];
        }
    }
    
    return subviews;
}

- (void)_willMoveFromWindow:(UIWindow *)fromWindow toWindow:(UIWindow *)toWindow
{
    if (fromWindow != toWindow) {
        
        // need to manage the responder chain. apparently UIKit (at least by version 4.2) seems to make sure that if a view was first responder
        // and it or it's parent views are disconnected from their window, the first responder gets reset to nil. Honestly, I don't think this
        // was always true - but it's certainly a much better and less-crashy design. Hopefully this check here replicates the behavior properly.
        if ([self isFirstResponder]) {
            [self resignFirstResponder];
        }
        
        [self _setAppearanceNeedsUpdate];
        [self willMoveToWindow:toWindow];

        for (UIView *subview in self.subviews) {
            [subview _willMoveFromWindow:fromWindow toWindow:toWindow];
        }
    }
}

- (void)_didMoveToScreen
{
    if (_implementsDrawRect && self.contentScaleFactor != self.window.screen.scale) {
        self.contentScaleFactor = self.window.screen.scale;
    } else {
        [self setNeedsDisplay];
    }
    
    for (UIView *subview in self.subviews) {
        [subview _didMoveToScreen];
    }
}

- (void)_didMoveFromWindow:(UIWindow *)fromWindow toWindow:(UIWindow *)toWindow
{
    if (fromWindow != toWindow) {
        [self didMoveToWindow];

        for (UIView *subview in self.subviews) {
            [subview _didMoveFromWindow:fromWindow toWindow:toWindow];
        }
    }
}

- (BOOL)_subviewControllersNeedAppearAndDisappear
{
    UIView *view = self;

    while (view) {
        if ([view _viewController] != nil) {
            return NO;
        } else {
            view = [view superview];
        }
    }

    return YES;
}

- (void)addSubview:(UIView *)subview
{
    NSAssert((!subview || [subview isKindOfClass:[UIView class]]), @"the subview must be a UIView");

    if (subview && subview.superview != self) {
        UIWindow *oldWindow = subview.window;
        UIWindow *newWindow = self.window;
        
        subview->_needsDidAppearOrDisappear = [self _subviewControllersNeedAppearAndDisappear];
        
        if ([subview _viewController] && subview->_needsDidAppearOrDisappear) {
            [[subview _viewController] viewWillAppear:NO];
        }

        [subview _willMoveFromWindow:oldWindow toWindow:newWindow];
        [subview willMoveToSuperview:self];

        {
            [subview retain];

            if (subview.superview) {
                [subview.layer removeFromSuperlayer];
                [subview.superview->_subviews removeObject:subview];
            }
            
            [subview willChangeValueForKey:@"superview"];
            [_subviews addObject:subview];
            subview->_superview = self;
            [_layer addSublayer:subview.layer];
            [subview didChangeValueForKey:@"superview"];

            [subview release];
        }

        if (oldWindow.screen != newWindow.screen) {
            [subview _didMoveToScreen];
        }
        
        [subview _didMoveFromWindow:oldWindow toWindow:newWindow];
        [subview didMoveToSuperview];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIViewDidMoveToSuperviewNotification object:subview];

        [self didAddSubview:subview];
        
        if ([subview _viewController] && subview->_needsDidAppearOrDisappear) {
            [[subview _viewController] viewDidAppear:NO];
        }
    }
}

- (void)insertSubview:(UIView *)subview atIndex:(NSInteger)index
{
    [self addSubview:subview];
    [_layer insertSublayer:subview.layer atIndex:index];
}

- (void)insertSubview:(UIView *)subview belowSubview:(UIView *)below
{
    [self addSubview:subview];
    [_layer insertSublayer:subview.layer below:below.layer];
}

- (void)insertSubview:(UIView *)subview aboveSubview:(UIView *)above
{
    [self addSubview:subview];
    [_layer insertSublayer:subview.layer above:above.layer];
}

- (void)bringSubviewToFront:(UIView *)subview
{
    if (subview.superview == self) {
        [_layer insertSublayer:subview.layer above:[[_layer sublayers] lastObject]];
    }
}

- (void)sendSubviewToBack:(UIView *)subview
{
    if (subview.superview == self) {
        [_layer insertSublayer:subview.layer atIndex:0];
    }
}

- (void)removeFromSuperview
{
    if (_superview) {
        [self retain];
        
        [[UIApplication sharedApplication] _removeViewFromTouches:self];
        
        UIWindow *oldWindow = self.window;
        
        if (_needsDidAppearOrDisappear && [self _viewController]) {
            [[self _viewController] viewWillDisappear:NO];
        }
        
        [_superview willRemoveSubview:self];
        [self _willMoveFromWindow:oldWindow toWindow:nil];
        [self willMoveToSuperview:nil];
        
        [self willChangeValueForKey:@"superview"];
        [_layer removeFromSuperlayer];
        [_superview->_subviews removeObject:self];
        _superview = nil;
        [self didChangeValueForKey:@"superview"];
        
        [self _didMoveFromWindow:oldWindow toWindow:nil];
        [self didMoveToSuperview];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIViewDidMoveToSuperviewNotification object:self];
        
        if (_needsDidAppearOrDisappear && [self _viewController]) {
            [[self _viewController] viewDidDisappear:NO];
        }
        
        [self release];
    }
}

- (void)didAddSubview:(UIView *)subview
{
}

- (void)didMoveToSuperview
{
}

- (void)didMoveToWindow
{
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
}

- (void)willRemoveSubview:(UIView *)subview
{
}

- (CGPoint)convertPoint:(CGPoint)toConvert fromView:(UIView *)fromView
{
    // NOTE: this is a lot more complex than it needs to be - I just noticed the docs say this method requires fromView and self to
    // belong to the same UIWindow! arg! leaving this for now because, well, it's neat.. but also I'm too tired to really ponder
    // all the implications of a change to something so "low level".
    
    if (fromView) {
        // If the screens are the same, then we know they share a common parent CALayer, so we can convert directly with the layer's
        // conversion method. If not, though, we need to do something a bit more complicated.
        if (fromView && (self.window.screen == fromView.window.screen)) {
            return [fromView.layer convertPoint:toConvert toLayer:self.layer];
        } else {
            // Convert coordinate to fromView's window base coordinates.
            toConvert = [fromView.layer convertPoint:toConvert toLayer:fromView.window.layer];
            
            // Now convert from fromView's window to our own window.
            toConvert = [fromView.window convertPoint:toConvert toWindow:self.window];
        }
    }

    // Convert from our window coordinate space into our own coordinate space.
    return [self.window.layer convertPoint:toConvert toLayer:self.layer];
}

- (CGPoint)convertPoint:(CGPoint)toConvert toView:(UIView *)toView
{
    // NOTE: this is a lot more complex than it needs to be - I just noticed the docs say this method requires toView and self to
    // belong to the same UIWindow! arg! leaving this for now because, well, it's neat.. but also I'm too tired to really ponder
    // all the implications of a change to something so "low level".
    
    // See note in convertPoint:fromView: for some explaination about why this is done... :/
    if (toView && (self.window.screen == toView.window.screen)) {
        return [self.layer convertPoint:toConvert toLayer:toView.layer];
    } else {
        // Convert to our window's coordinate space.
        toConvert = [self.layer convertPoint:toConvert toLayer:self.window.layer];
        
        if (toView) {
            // Convert from one window's coordinate space to another.
            toConvert = [self.window convertPoint:toConvert toWindow:toView.window];
            
            // Convert from toView's window down to toView's coordinate space.
            toConvert = [toView.window.layer convertPoint:toConvert toLayer:toView.layer];
        }
        
        return toConvert;
    }
}

- (CGRect)convertRect:(CGRect)toConvert fromView:(UIView *)fromView
{
    CGPoint origin = [self convertPoint:CGPointMake(CGRectGetMinX(toConvert),CGRectGetMinY(toConvert)) fromView:fromView];
    CGPoint bottom = [self convertPoint:CGPointMake(CGRectGetMaxX(toConvert),CGRectGetMaxY(toConvert)) fromView:fromView];
    return CGRectMake(origin.x, origin.y, bottom.x-origin.x, bottom.y-origin.y);
}

- (CGRect)convertRect:(CGRect)toConvert toView:(UIView *)toView
{
    CGPoint origin = [self convertPoint:CGPointMake(CGRectGetMinX(toConvert),CGRectGetMinY(toConvert)) toView:toView];
    CGPoint bottom = [self convertPoint:CGPointMake(CGRectGetMaxX(toConvert),CGRectGetMaxY(toConvert)) toView:toView];
    return CGRectMake(origin.x, origin.y, bottom.x-origin.x, bottom.y-origin.y);
}

- (void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = [self sizeThatFits:frame.size];
    self.frame = frame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return size;
}

- (UIView *)viewWithTag:(NSInteger)tagToFind
{
    UIView *foundView = nil;
    
    if (self.tag == tagToFind) {
        foundView = self;
    } else {
        for (UIView *view in [self.subviews reverseObjectEnumerator]) {
            foundView = [view viewWithTag:tagToFind];
            if (foundView)
                break;
        }
    }
    
    return foundView;
}

- (BOOL)isDescendantOfView:(UIView *)view
{
    if (view) {
        UIView *testView = self;
        while (testView) {
            if (testView == view) {
                return YES;
            } else {
                testView = testView.superview;
            }
        }
    }
    return NO;
}

- (void)setNeedsDisplay
{
    [_layer setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)invalidRect
{
    [_layer setNeedsDisplayInRect:invalidRect];
}

- (void)drawRect:(CGRect)rect
{
}

- (void)displayLayer:(CALayer *)theLayer
{
    // Okay, this is some crazy stuff right here. Basically, the real UIKit avoids creating any contents for its layer if there's no drawRect:
    // specified in the UIView's subview. This nicely prevents a ton of useless memory usage and likley improves performance a lot on iPhone.
    // It took great pains to discover this trick and I think I'm doing this right. By having this method empty here, it means that it overrides
    // the layer's normal display method and instead does nothing which results in the layer not making a backing store and wasting memory.
    
    // Here's how CALayer appears to work:
    // 1- something call's the layer's -display method.
    // 2- arrive in CALayer's display: method.
    // 2a-  if delegate implements displayLayer:, call that.
    // 2b-  if delegate doesn't implement displayLayer:, CALayer creates a buffer and a context and passes that to drawInContext:
    // 3- arrive in CALayer's drawInContext: method.
    // 3a-  if delegate implements drawLayer:inContext:, call that and pass it the context.
    // 3b-  otherwise, does nothing
    
    // So, what this all means is that to avoid causing the CALayer to create a context and use up memory, our delegate has to lie to CALayer
    // about if it implements displayLayer: or not. If we say it does, we short circuit the layer's buffer creation process (since it assumes
    // we are going to be setting it's contents property ourselves). So, that's what we do in the override of respondsToSelector: below.
    
    // backgroundColor is influenced by all this as well. If drawRect: is defined, we draw it directly in the context so that blending is all
    // pretty and stuff. If it isn't, though, we still want to support it. What the real UIKit does is it sets the layer's backgroundColor
    // iff drawRect: isn't specified. Otherwise it manages it itself. Again, this is for performance reasons. Rather than having to store a
    // whole bitmap the size of view just to hold the backgroundColor, this allows a lot of views to simply act as containers and not waste
    // a bunch of unnecessary memory in those cases - but you can still use background colors because CALayer manages that effeciently.
    
    // note that the last time I checked this, the layer's background color was being set immediately on call to -setBackgroundColor:
    // when there was no -drawRect: implementation, but I needed to change this to work around issues with pattern image colors in HiDPI.
    _layer.backgroundColor = [self.backgroundColor _bestRepresentationForProposedScale:self.window.screen.scale].CGColor;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    // For notes about why this is done, see displayLayer: above.
    if (aSelector == @selector(displayLayer:)) {
        return !_implementsDrawRect;
    } else {
        return [super respondsToSelector:aSelector];
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    // We only get here if the UIView subclass implements drawRect:. To do this without a drawRect: is a huge waste of memory.
    // See the discussion in drawLayer: above.

    const CGRect bounds = CGContextGetClipBoundingBox(ctx);

    UIGraphicsPushContext(ctx);
    CGContextSaveGState(ctx);
    
    if (_clearsContextBeforeDrawing) {
        CGContextClearRect(ctx, bounds);
    }

    if (_backgroundColor) {
        [_backgroundColor setFill];
        CGContextFillRect(ctx,bounds);
    }

    /*
     NOTE: This kind of logic would seem to be ideal and result in the best font rendering when possible. The downside here is that
     the rendering is then inconsistent throughout the app depending on how certain views are constructed or configured.
     I'm not sure what to do about this. It appears to be impossible to subpixel render text drawn into a transparent layer because
     of course there are no pixels behind the text to use when doing the subpixel blending. If it is turned on in that case, it looks
     bad depending on what is ultimately composited behind it. Turning it off everywhere makes everything "equally bad," in a sense,
     but at least stuff doesn't jump out as obviously different. However this doesn't look very nice on OSX. iOS appears to not use
     any subpixel smoothing anywhere but doesn't seem to look bad when using it. There are many possibilities for why. Some I can
     think of are they are setting some kind of graphics context mode I just haven't found yet, the rendering engines are
     fundamentally different, the fonts themselves are actually different, the DPI of the devices, voodoo, or the loch ness monster.
     */

    /*
     UPDATE: I've since flattened some of the main views in Twitterrific/Ostrich and so now I'd like to have subpixel turned on for
     the Mac, so I'm putting this code back in here. It tries to be smart about when to do it (because if it's on when it shouldn't
     be the results look very bad). As the note above said, this can and does result in some inconsistency with the rendering in
     the app depending on how things are done. Typical UIKit code is going to be lots of layers and thus text will mostly look bad
     with straight ports but at this point I really can't come up with a much better solution so it'll have to do.
     */
    
    /*
     UPDATE AGAIN: So, subpixel with light text against a dark background looks kinda crap and we can't seem to figure out how
     to make it not-crap right now. After messing with some fonts and things, we're currently turning subpixel off again instead.
     I have a feeling this may go round and round forever because some people can't stand subpixel and others can't stand not
     having it - even when its light-on-dark. We could turn it on here and selectively disable it in Twitterrific when using the
     dark theme, but that seems weird, too. We'd all rather there be just one approach here and skipping smoothing at least means
     that the whole app is consistent (views that aren't flattened won't look any different from the flattened views in terms of
     text rendering, at least). Bah.
     */

    //const BOOL shouldSmoothFonts = (_backgroundColor && (CGColorGetAlpha(_backgroundColor.CGColor) == 1)) || self.opaque;
    //CGContextSetShouldSmoothFonts(ctx, shouldSmoothFonts);

    CGContextSetShouldSmoothFonts(ctx, NO);

    CGContextSetShouldSubpixelPositionFonts(ctx, YES);
    CGContextSetShouldSubpixelQuantizeFonts(ctx, YES);
    
    [[UIColor blackColor] set];
    [self drawRect:bounds];

    CGContextRestoreGState(ctx);
    UIGraphicsPopContext();
}

- (id)actionForLayer:(CALayer *)theLayer forKey:(NSString *)event
{
    if (_animationsEnabled && [_animationGroups lastObject] && theLayer == _layer) {
        return [[_animationGroups lastObject] actionForView:self forKey:event] ?: (id)[NSNull null];
    } else {
        return [NSNull null];
    }
}

- (void)_superviewSizeDidChangeFrom:(CGSize)oldSize to:(CGSize)newSize
{
    if (_autoresizingMask != UIViewAutoresizingNone) {
        CGRect frame = self.frame;
        const CGSize delta = CGSizeMake(newSize.width-oldSize.width, newSize.height-oldSize.height);
        
#define hasAutoresizingFor(x) ((_autoresizingMask & (x)) == (x))
        
        /*
         
         top + bottom + height      => y = floor(y + (y / HEIGHT * delta)); height = floor(height + (height / HEIGHT * delta))
         top + height               => t = y + height; y = floor(y + (y / t * delta); height = floor(height + (height / t * delta);
         bottom + height            => height = floor(height + (height / (HEIGHT - y) * delta))
         top + bottom               => y = floor(y + (delta / 2))
         height                     => height = floor(height + delta)
         top                        => y = floor(y + delta)
         bottom                     => y = floor(y)

         */

        if (hasAutoresizingFor(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin)) {
            frame.origin.y = floorf(frame.origin.y + (frame.origin.y / oldSize.height * delta.height));
            frame.size.height = floorf(frame.size.height + (frame.size.height / oldSize.height * delta.height));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight)) {
            const CGFloat t = frame.origin.y + frame.size.height;
            frame.origin.y = floorf(frame.origin.y + (frame.origin.y / t * delta.height));
            frame.size.height = floorf(frame.size.height + (frame.size.height / t * delta.height));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight)) {
            frame.size.height = floorf(frame.size.height + (frame.size.height / (oldSize.height - frame.origin.y) * delta.height));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin)) {
            frame.origin.y = floorf(frame.origin.y + (delta.height / 2.f));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleHeight)) {
            frame.size.height = floorf(frame.size.height + delta.height);
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleTopMargin)) {
            frame.origin.y = floorf(frame.origin.y + delta.height);
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleBottomMargin)) {
            frame.origin.y = floorf(frame.origin.y);
        }

        if (hasAutoresizingFor(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin)) {
            frame.origin.x = floorf(frame.origin.x + (frame.origin.x / oldSize.width * delta.width));
            frame.size.width = floorf(frame.size.width + (frame.size.width / oldSize.width * delta.width));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth)) {
            const CGFloat t = frame.origin.x + frame.size.width;
            frame.origin.x = floorf(frame.origin.x + (frame.origin.x / t * delta.width));
            frame.size.width = floorf(frame.size.width + (frame.size.width / t * delta.width));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth)) {
            frame.size.width = floorf(frame.size.width + (frame.size.width / (oldSize.width - frame.origin.x) * delta.width));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin)) {
            frame.origin.x = floorf(frame.origin.x + (delta.width / 2.f));
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleWidth)) {
            frame.size.width = floorf(frame.size.width + delta.width);
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleLeftMargin)) {
            frame.origin.x = floorf(frame.origin.x + delta.width);
        } else if (hasAutoresizingFor(UIViewAutoresizingFlexibleRightMargin)) {
            frame.origin.x = floorf(frame.origin.x);
        }

        self.frame = frame;
    }
}

- (void)_boundsDidChangeFrom:(CGRect)oldBounds to:(CGRect)newBounds
{
    if (!CGRectEqualToRect(oldBounds, newBounds)) {
        // setNeedsLayout doesn't seem like it should be necessary, however there was a rendering bug in a table in Flamingo that
        // went away when this was placed here. There must be some strange ordering issue with how that layout manager stuff works.
        // I never quite narrowed it down. This was an easy fix, if perhaps not ideal.
        [self setNeedsLayout];

        if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
            if (_autoresizesSubviews) {
                for (UIView *subview in [_subviews allObjects]) {
                    [subview _superviewSizeDidChangeFrom:oldBounds.size to:newBounds.size];
                }
            }
        }
    }
}

+ (NSSet *)keyPathsForValuesAffectingFrame
{
    return [NSSet setWithObject:@"center"];
}

- (CGRect)frame
{
    return _layer.frame;
}

- (void)setFrame:(CGRect)newFrame
{
    if (!CGRectEqualToRect(newFrame,_layer.frame)) {
        CGRect oldBounds = _layer.bounds;
        _layer.frame = newFrame;
        [self _boundsDidChangeFrom:oldBounds to:_layer.bounds];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIViewFrameDidChangeNotification object:self];
    }
}

- (CGRect)bounds
{
    return _layer.bounds;
}

- (void)setBounds:(CGRect)newBounds
{
    if (!CGRectEqualToRect(newBounds,_layer.bounds)) {
        CGRect oldBounds = _layer.bounds;
        _layer.bounds = newBounds;
        [self _boundsDidChangeFrom:oldBounds to:newBounds];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIViewBoundsDidChangeNotification object:self];
    }
}

- (CGPoint)center
{
    return _layer.position;
}

- (void)setCenter:(CGPoint)newCenter
{
    if (!CGPointEqualToPoint(newCenter,_layer.position)) {
        _layer.position = newCenter;
    }
}

- (CGAffineTransform)transform
{
    return _layer.affineTransform;
}

- (void)setTransform:(CGAffineTransform)transform
{
    if (!CGAffineTransformEqualToTransform(transform,_layer.affineTransform)) {
        _layer.affineTransform = transform;
    }
}

- (CGFloat)alpha
{
    return _layer.opacity;
}

- (void)setAlpha:(CGFloat)newAlpha
{
    if (newAlpha != _layer.opacity) {
        _layer.opacity = newAlpha;
    }
}

- (BOOL)isOpaque
{
    return _layer.opaque;
}

- (void)setOpaque:(BOOL)newO
{
    if (newO != _layer.opaque) {
        _layer.opaque = newO;
    }
}

- (void)setBackgroundColor:(UIColor *)newColor
{
    if (_backgroundColor != newColor) {
        [_backgroundColor release];
        _backgroundColor = [newColor retain];
        self.opaque = [_backgroundColor _isOpaque];
    }
}

- (BOOL)clipsToBounds
{
    return _layer.masksToBounds;
}

- (void)setClipsToBounds:(BOOL)clips
{
    if (clips != _layer.masksToBounds) {
        _layer.masksToBounds = clips;
    }
}

- (void)setContentStretch:(CGRect)rect
{
    if (!CGRectEqualToRect(rect,_layer.contentsCenter)) {
        _layer.contentsCenter = rect;
    }
}

- (CGRect)contentStretch
{
    return _layer.contentsCenter;
}

- (void)setContentScaleFactor:(CGFloat)scale
{
    if (scale <= 0 && _implementsDrawRect) {
        scale = [UIScreen mainScreen].scale;
    }
    
    if (scale > 0 && scale != self.contentScaleFactor) {
        if ([_layer respondsToSelector:@selector(setContentsScale:)]) {
            [_layer setContentsScale:scale];
            [self setNeedsDisplay];
        }
    }
}

- (CGFloat)contentScaleFactor
{
    return [_layer respondsToSelector:@selector(contentsScale)]? [_layer contentsScale] : 1;
}

- (void)setHidden:(BOOL)h
{
    if (h != _layer.hidden) {
        _layer.hidden = h;
        [[NSNotificationCenter defaultCenter] postNotificationName:UIViewHiddenDidChangeNotification object:self];
    }
}

- (BOOL)isHidden
{
    return _layer.hidden;
}

- (void)setNeedsLayout
{
    [_layer setNeedsLayout];
}

- (void)layoutIfNeeded
{
    [_layer layoutIfNeeded];
}

- (void)layoutSubviews
{
}

- (void)_layoutSubviews
{
    [self _updateAppearanceIfNeeded];
    [[self _viewController] viewWillLayoutSubviews];
    [self layoutSubviews];
    [[self _viewController] viewDidLayoutSubviews];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return CGRectContainsPoint(self.bounds, point);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.hidden || !self.userInteractionEnabled || self.alpha < 0.01 || ![self pointInside:point withEvent:event]) {
        return nil;
    } else {
        for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
            UIView *hitView = [subview hitTest:[subview convertPoint:point fromView:self] withEvent:event];
            if (hitView) {
                return hitView;
            }
        }
        return self;
    }
}

- (void)setContentMode:(UIViewContentMode)mode
{
    if (mode != _contentMode) {
        _contentMode = mode;
        switch(_contentMode) {
            case UIViewContentModeScaleToFill:
                _layer.contentsGravity = kCAGravityResize;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeScaleAspectFit:
                _layer.contentsGravity = kCAGravityResizeAspect;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeScaleAspectFill:
                _layer.contentsGravity = kCAGravityResizeAspectFill;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeRedraw:
                _layer.needsDisplayOnBoundsChange = YES;
                break;
                
            case UIViewContentModeCenter:
                _layer.contentsGravity = kCAGravityCenter;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeTop:
                _layer.contentsGravity = kCAGravityTop;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeBottom:
                _layer.contentsGravity = kCAGravityBottom;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeLeft:
                _layer.contentsGravity = kCAGravityLeft;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeRight:
                _layer.contentsGravity = kCAGravityRight;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeTopLeft:
                _layer.contentsGravity = kCAGravityTopLeft;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeTopRight:
                _layer.contentsGravity = kCAGravityTopRight;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeBottomLeft:
                _layer.contentsGravity = kCAGravityBottomLeft;
                _layer.needsDisplayOnBoundsChange = NO;
                break;

            case UIViewContentModeBottomRight:
                _layer.contentsGravity = kCAGravityBottomRight;
                _layer.needsDisplayOnBoundsChange = NO;
                break;
        }
    }
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (![_gestureRecognizers containsObject:gestureRecognizer]) {
        [gestureRecognizer.view removeGestureRecognizer:gestureRecognizer];
        [_gestureRecognizers addObject:gestureRecognizer];
        [gestureRecognizer _setView:self];
    }
}

- (void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_gestureRecognizers containsObject:gestureRecognizer]) {
        [gestureRecognizer _setView:nil];
        [_gestureRecognizers removeObject:gestureRecognizer];
    }
}

- (void)setGestureRecognizers:(NSArray *)newRecognizers
{
    for (UIGestureRecognizer *gesture in [_gestureRecognizers allObjects]) {
        [self removeGestureRecognizer:gesture];
    }

    for (UIGestureRecognizer *gesture in newRecognizers) {
        [self addGestureRecognizer:gesture];
    }	
}

- (NSArray *)gestureRecognizers
{
    return [_gestureRecognizers allObjects];
}

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    const BOOL ignoreInteractionEvents = !((options & UIViewAnimationOptionAllowUserInteraction) == UIViewAnimationOptionAllowUserInteraction);
    const BOOL repeatAnimation = ((options & UIViewAnimationOptionRepeat) == UIViewAnimationOptionRepeat);
    const BOOL autoreverseRepeat = ((options & UIViewAnimationOptionAutoreverse) == UIViewAnimationOptionAutoreverse);
    const BOOL beginFromCurrentState = ((options & UIViewAnimationOptionBeginFromCurrentState) == UIViewAnimationOptionBeginFromCurrentState);
    UIViewAnimationCurve animationCurve;
    
    if ((options & UIViewAnimationOptionCurveEaseInOut) == UIViewAnimationOptionCurveEaseInOut) {
        animationCurve = UIViewAnimationCurveEaseInOut;
    } else if ((options & UIViewAnimationOptionCurveEaseIn) == UIViewAnimationOptionCurveEaseIn) {
        animationCurve = UIViewAnimationCurveEaseIn;
    } else if ((options & UIViewAnimationOptionCurveEaseOut) == UIViewAnimationOptionCurveEaseOut) {
        animationCurve = UIViewAnimationCurveEaseOut;
    } else {
        animationCurve = UIViewAnimationCurveLinear;
    }
    
    // NOTE: As of iOS 5 this is only supposed to block interaction events for the views being animated, not the whole app.
    if (ignoreInteractionEvents) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    UIViewBlockAnimationDelegate *delegate = [[UIViewBlockAnimationDelegate alloc] init];
    delegate.completion = completion;
    delegate.ignoreInteractionEvents = ignoreInteractionEvents;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDelay:delay];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationBeginsFromCurrentState:beginFromCurrentState];
    [UIView setAnimationDelegate:delegate];	// this is retained here
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
    [UIView setAnimationRepeatCount:(repeatAnimation? FLT_MAX : 0)];
    [UIView setAnimationRepeatAutoreverses:autoreverseRepeat];
    
    animations();
    
    [UIView commitAnimations];
    [delegate release];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    [self animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                   animations:animations
                   completion:completion];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    [self animateWithDuration:duration animations:animations completion:NULL];
}

+ (void)transitionWithView:(UIView *)view duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completio
{
}

+ (void)transitionFromView:(UIView *)fromView toView:(UIView *)toView duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion
{
}

+ (void)beginAnimations:(NSString *)animationID context:(void *)context
{
    [_animationGroups addObject:[UIViewAnimationGroup animationGroupWithName:animationID context:context]];
}

+ (void)commitAnimations
{
    if ([_animationGroups count] > 0) {
        [[_animationGroups lastObject] commit];
        [_animationGroups removeLastObject];
    }
}

+ (void)setAnimationBeginsFromCurrentState:(BOOL)beginFromCurrentState
{
    [[_animationGroups lastObject] setAnimationBeginsFromCurrentState:beginFromCurrentState];
}

+ (void)setAnimationCurve:(UIViewAnimationCurve)curve
{
    [[_animationGroups lastObject] setAnimationCurve:curve];
}

+ (void)setAnimationDelay:(NSTimeInterval)delay
{
    [[_animationGroups lastObject] setAnimationDelay:delay];
}

+ (void)setAnimationDelegate:(id)delegate
{
    [[_animationGroups lastObject] setAnimationDelegate:delegate];
}

+ (void)setAnimationDidStopSelector:(SEL)selector
{
    [[_animationGroups lastObject] setAnimationDidStopSelector:selector];
}

+ (void)setAnimationDuration:(NSTimeInterval)duration
{
    [[_animationGroups lastObject] setAnimationDuration:duration];
}

+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses
{
    [[_animationGroups lastObject] setAnimationRepeatAutoreverses:repeatAutoreverses];
}

+ (void)setAnimationRepeatCount:(float)repeatCount
{
    [[_animationGroups lastObject] setAnimationRepeatCount:repeatCount];
}

+ (void)setAnimationWillStartSelector:(SEL)selector
{
    [[_animationGroups lastObject] setAnimationWillStartSelector:selector];
}

+ (void)setAnimationTransition:(UIViewAnimationTransition)transition forView:(UIView *)view cache:(BOOL)cache
{
    [[_animationGroups lastObject] setAnimationTransition:transition forView:view cache:cache];
}

+ (BOOL)areAnimationsEnabled
{
    return _animationsEnabled;
}

+ (void)setAnimationsEnabled:(BOOL)enabled
{
    _animationsEnabled = enabled;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; frame = %@; hidden = %@; layer = %@>", [self className], self, NSStringFromCGRect(self.frame), (self.hidden ? @"YES" : @"NO"), self.layer];
}

@end
