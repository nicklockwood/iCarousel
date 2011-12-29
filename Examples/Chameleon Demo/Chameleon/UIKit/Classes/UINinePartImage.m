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

#import "UINinePartImage.h"
#import "AppKitIntegration.h"
#import "UIGraphics.h"
#import <AppKit/AppKit.h>

@implementation UINinePartImage

- (id)initWithNSImage:(id)theImage leftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    if ((self=[super initWithNSImage:theImage])) {
        const CGSize size = self.size;
        const CGFloat stretchyWidth = (leftCapWidth < size.width)? 1 : 0;
        const CGFloat stretchyHeight = (topCapHeight < size.height)? 1 : 0;
        const CGFloat bottomCapHeight = size.height - topCapHeight - stretchyHeight;
        
        _topLeftCorner = _NSImageCreateSubimage(theImage, CGRectMake(0,0,leftCapWidth,topCapHeight));
        _topEdgeFill = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth,0,stretchyWidth,topCapHeight));
        _topRightCorner = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth+stretchyWidth,0,size.width-leftCapWidth-stretchyWidth,topCapHeight));
        
        _bottomLeftCorner = _NSImageCreateSubimage(theImage, CGRectMake(0,size.height-bottomCapHeight,leftCapWidth,bottomCapHeight));
        _bottomEdgeFill = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth,size.height-bottomCapHeight,stretchyWidth,bottomCapHeight));
        _bottomRightCorner = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth+stretchyWidth,size.height-bottomCapHeight,size.width-leftCapWidth-stretchyWidth,bottomCapHeight));

        _leftEdgeFill = _NSImageCreateSubimage(theImage, CGRectMake(0,topCapHeight,leftCapWidth,stretchyHeight));
        _centerFill = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth,topCapHeight,stretchyWidth,stretchyHeight));
        _rightEdgeFill = _NSImageCreateSubimage(theImage, CGRectMake(leftCapWidth+stretchyWidth,topCapHeight,size.width-leftCapWidth-stretchyWidth,stretchyHeight));
    }
    return self;
}

- (void)dealloc
{
    [_topLeftCorner release];
    [_topEdgeFill release];
    [_topRightCorner release];
    [_leftEdgeFill release];
    [_centerFill release];
    [_rightEdgeFill release];
    [_bottomLeftCorner release];
    [_bottomEdgeFill release];
    [_bottomRightCorner release];
    [super dealloc];
}

- (NSInteger)leftCapWidth
{
    return [_topLeftCorner size].width;
}

- (NSInteger)topCapHeight
{
    return [_topLeftCorner size].height;
}

- (void)drawInRect:(CGRect)rect
{
    // There aren't enough NSCompositingOperations to map all possible CGBlendModes, so rather than have gaps in the support,
    // I am drawing the multipart image into a new image context which is then drawn in the usual way which results in the draw
    // obeying the currently active CGBlendMode and doing the expected thing. This is no doubt more expensive than it could be,
    // but I suspect it's pretty irrelevant in the grand scheme of things.
    UIGraphicsBeginImageContext(rect.size);
    NSDrawNinePartImage(NSMakeRect(0,0,rect.size.width,rect.size.height), _topLeftCorner, _topEdgeFill, _topRightCorner, _leftEdgeFill, _centerFill, _rightEdgeFill, _bottomLeftCorner, _bottomEdgeFill, _bottomRightCorner, NSCompositeCopy, 1, YES);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [img drawInRect:rect];
    
}

@end
