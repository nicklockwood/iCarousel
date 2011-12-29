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

#import "UIPopoverView.h"
#import "UIImageView.h"
#import "UIImage+UIPrivate.h"
#import <QuartzCore/QuartzCore.h>

typedef struct {
    CGPoint from;
    CGPoint to;
} LineSegment;

static LineSegment LineSegmentMake(CGPoint from, CGPoint to)
{
    LineSegment segment;
    segment.from = from;
    segment.to = to;
    return segment;
}

static BOOL LineSegmentsIntersect(LineSegment line1, LineSegment line2, CGPoint *intersection)
{
    /*
     E = B-A = ( Bx-Ax, By-Ay )
     F = D-C = ( Dx-Cx, Dy-Cy ) 
     P = ( -Ey, Ex )
     h = ( (A-C) * P ) / ( F * P )
     
     I = C + F*h
     */
    
    const CGPoint A = line1.from;
    const CGPoint B = line1.to;
    const CGPoint C = line2.from;
    const CGPoint D = line2.to;
    
    const CGPoint E = CGPointMake(B.x-A.x, B.y-A.y);
    const CGPoint F = CGPointMake(D.x-C.x, D.y-C.y);
    const CGPoint P = CGPointMake(-E.y, E.x);
    
    const CGPoint AC = CGPointMake(A.x-C.x, A.y-C.y);
    const CGFloat h2 = F.x * P.x + F.y * P.y;
    
    // if h2 is 0, the lines are parallel
    if (h2 != 0) {
        const CGFloat h1 = AC.x * P.x + AC.y * P.y;
        const CGFloat h = h1 / h2;
        
        // if h is exactly 0 or 1, the lines touched on the end - we won't consider that an intersection
        if (h > 0 && h < 1) {
            if (intersection) {
                const CGPoint I = CGPointMake(C.x+F.x*h, C.y+F.y*h);
                intersection->x = I.x;
                intersection->y = I.y;
            }
            return YES;
        }
    }
    
    return NO;
    
}

static CGFloat DistanceBetweenTwoPoints(CGPoint A, CGPoint B)
{
    CGFloat a = B.x - A.x;
    CGFloat b = B.y - A.y;
    return sqrtf((a*a) + (b*b));
}

@implementation UIPopoverView
@synthesize contentView=_contentView;

+ (UIEdgeInsets)insetForArrows
{
    return UIEdgeInsetsMake(17,12,8,12);
}

+ (CGRect)backgroundRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect(bounds, [self insetForArrows]);
}

+ (CGRect)contentRectForBounds:(CGRect)bounds withNavigationBar:(BOOL)hasNavBar
{
    const CGFloat navBarOffset = hasNavBar? 32 : 0;
    return UIEdgeInsetsInsetRect(CGRectMake(14,9+navBarOffset,bounds.size.width-28,bounds.size.height-28-navBarOffset), [self insetForArrows]);
}

+ (CGSize)frameSizeForContentSize:(CGSize)contentSize withNavigationBar:(BOOL)hasNavBar
{
    UIEdgeInsets insets = [self insetForArrows];
    CGSize frameSize;
    
    frameSize.width = contentSize.width + 28 + insets.left + insets.right;
    frameSize.height = contentSize.height + 28 + (hasNavBar? 32 : 0) + insets.top + insets.bottom;
    
    return frameSize;
}


- (id)initWithContentView:(UIView *)aView size:(CGSize)aSize
{	
    if ((self=[super initWithFrame:CGRectMake(0,0,320,480)])) {
        _contentView = [aView retain];
        
        UIImage *backgroundImage = [UIImage _popoverBackgroundImage];
        _backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        
        _arrowView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        _contentContainerView = [[UIView alloc] init];
        _contentContainerView.layer.cornerRadius = 3;
        _contentContainerView.clipsToBounds = YES;

        [self addSubview:_backgroundView];
        [self addSubview:_arrowView];
        [self addSubview:_contentContainerView];
        [_contentContainerView addSubview:_contentView];
        
        self.contentSize = aSize;
    }
    return self;
}

- (void)dealloc
{
    [_backgroundView release];
    [_arrowView release];
    [_contentContainerView release];
    [_contentView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGRect bounds = self.bounds;	
    _backgroundView.frame = [isa backgroundRectForBounds:bounds];
    _contentContainerView.frame = [isa contentRectForBounds:bounds withNavigationBar:NO];
    _contentView.frame = _contentContainerView.bounds;
}

- (void)pointTo:(CGPoint)point inView:(UIView *)view
{
    // This math here is excessive. I went through a lot of effort because of an earlier idea I had about how to
    // get this stuff to point correctly. I'm reasonably sure that wasn't really necessary, but I'm going to leave it
    // here for now. It's neat stuff.. :) It takes an origin point within the popover view and then creates a line
    // between it and the destination point. It then finds where that line intersects with the sides of the popover
    // frame and uses that intersection point as the place to put the arrow image. There is also logic here to clamp
    // the position of the arrow images so that they don't extend beyond the popover's chrome. Cool, but excessive. :)
    const CGRect myBounds = self.bounds;

    // arrowPoint and myCenter should both be in self's coordinate space
    const CGPoint arrowPoint = [self convertPoint:point fromView:view];
    CGPoint myCenter = CGPointMake(CGRectGetMidX(myBounds), CGRectGetMidY(myBounds));

    // inset the bounds so that the bounding lines are at the center points of the arrow images
    const CGRect bounds = CGRectInset(myBounds, 11, 11);

    // check to see if the arrowPoint has any components that fall on lines which intersect the popover view itself.
    // if it does, then adjust myCenter accordingly - this makes the algorithm prefer a straight line whenever possible
    // which should ultimately look better - note that this was added well after all this complex math and is the
    // single simple thing which helps render most of the complex math moot. Sometimes the easy thing to do is not
    // the obvious thing if you're in the wrong frame of mind at the time. :/
    if (arrowPoint.x > CGRectGetMinX(bounds) && arrowPoint.x < CGRectGetMaxX(bounds)) {
        myCenter.x = arrowPoint.x;
    }
    if (arrowPoint.y > CGRectGetMinY(bounds) && arrowPoint.y < CGRectGetMaxY(bounds)) {
        myCenter.y = arrowPoint.y;
    }
    
    const CGPoint topRight = CGPointMake(bounds.origin.x+bounds.size.width, bounds.origin.y);
    const CGPoint bottomLeft = CGPointMake(bounds.origin.x, bounds.origin.y+bounds.size.height);
    const CGPoint bottomRight = CGPointMake(bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height);
    
    const LineSegment arrowLine = LineSegmentMake(arrowPoint, myCenter);
    const LineSegment rightSide = LineSegmentMake(topRight, bottomRight);
    const LineSegment topSide = LineSegmentMake(bounds.origin, topRight);
    const LineSegment bottomSide = LineSegmentMake(bottomLeft, bottomRight);
    const LineSegment leftSide = LineSegmentMake(bounds.origin, bottomLeft);
    
    CGPoint intersection = CGPointZero;
    CGPoint bestIntersection = CGPointZero;
    CGFloat bestDistance = CGFLOAT_MAX;
    CGRectEdge closestEdge = CGRectMinXEdge;
    
    if (LineSegmentsIntersect(arrowLine, rightSide, &intersection)) {
        const CGFloat distance = DistanceBetweenTwoPoints(intersection, arrowPoint);
        if (distance < bestDistance) {
            bestDistance = distance;
            closestEdge = CGRectMaxXEdge;
            bestIntersection = intersection;
        }
    }
    
    if (LineSegmentsIntersect(arrowLine, topSide, &intersection)) {
        const CGFloat distance = DistanceBetweenTwoPoints(intersection, arrowPoint);
        if (distance < bestDistance) {
            bestDistance = distance;
            closestEdge = CGRectMinYEdge;
            bestIntersection = intersection;
        }
    }
    
    if (LineSegmentsIntersect(arrowLine, bottomSide, &intersection)) {
        const CGFloat distance = DistanceBetweenTwoPoints(intersection, arrowPoint);
        if (distance < bestDistance) {
            bestDistance = distance;
            closestEdge = CGRectMaxYEdge;
            bestIntersection = intersection;
        }
    }
    
    if (LineSegmentsIntersect(arrowLine, leftSide, &intersection)) {
        const CGFloat distance = DistanceBetweenTwoPoints(intersection, arrowPoint);
        if (distance < bestDistance) {
            //bestDistance = distance;  -- commented out to avoid a harmless analyzer warning
            closestEdge = CGRectMinXEdge;
            bestIntersection = intersection;
        }
    }
    
    BOOL clampVertical = NO;
    
    if (closestEdge == CGRectMaxXEdge) {
        // right side
        _arrowView.image = [UIImage _rightPopoverArrowImage];
        clampVertical = YES;
    } else if (closestEdge == CGRectMaxYEdge) {
        // bottom side
        _arrowView.image = [UIImage _bottomPopoverArrowImage];
        clampVertical = NO;
    } else if (closestEdge == CGRectMinYEdge) {
        // top side
        _arrowView.image = [UIImage _topPopoverArrowImage];
        clampVertical = NO;
    } else {
        // left side
        _arrowView.image = [UIImage _leftPopoverArrowImage];
        clampVertical = YES;
    }

    // this will clamp where the arrow is positioned so that it doesn't slide off the edges of
    // the popover and look dumb and disconnected.
    const CGRect innerBounds = CGRectInset(myBounds, 42, 42);
    if (clampVertical) {
        if (bestIntersection.y < innerBounds.origin.y) {
            bestIntersection.y = innerBounds.origin.y;
        } else if (bestIntersection.y > innerBounds.origin.y+innerBounds.size.height) {
            bestIntersection.y = innerBounds.origin.y+innerBounds.size.height;
        }
    } else {
        if (bestIntersection.x < innerBounds.origin.x) {
            bestIntersection.x = innerBounds.origin.x;
        } else if (bestIntersection.x > innerBounds.origin.x+innerBounds.size.width) {
            bestIntersection.x = innerBounds.origin.x+innerBounds.size.width;
        }
    }
    
    [_arrowView sizeToFit];
    _arrowView.center = bestIntersection;
    CGRect arrowFrame = _arrowView.frame;
    arrowFrame.origin.x = roundf(arrowFrame.origin.x);
    arrowFrame.origin.y = roundf(arrowFrame.origin.y);
    _arrowView.frame = arrowFrame;
}

- (void)setContentView:(UIView *)aView animated:(BOOL)animated
{
    if (aView != _contentView) {
        [_contentView removeFromSuperview];
        [_contentView release];
        _contentView = [aView retain];
        [self addSubview:_contentView];
    }
}

- (void)setContentView:(UIView *)aView
{
    [self setContentView:aView animated:NO];
}

- (void)setContentSize:(CGSize)aSize animated:(BOOL)animated
{
    CGRect frame = self.frame;
    frame.size = [isa frameSizeForContentSize:aSize withNavigationBar:NO];

    [UIView animateWithDuration:animated? 0.2 : 0
                     animations:^(void) {
                         self.frame = frame;
                     }];
}

- (CGSize)contentSize
{
    return _contentContainerView.bounds.size;
}

- (void)setContentSize:(CGSize)newSize
{
    [self setContentSize:newSize animated:NO];
}

@end
