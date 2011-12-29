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

#import "UIThreePartImage.h"
#import "AppKitIntegration.h"
#import "UIGraphics.h"
#import <AppKit/AppKit.h>

@implementation UIThreePartImage

- (id)initWithNSImage:(id)theImage capSize:(NSInteger)capSize vertical:(BOOL)isVertical
{
    if ((self=[super initWithNSImage:theImage])) {
        const CGSize size = self.size;

        _vertical = isVertical;
        
        if (_vertical) {
            const CGFloat stretchyHeight = (capSize < size.height)? 1 : 0;
            const CGFloat bottomCapHeight = size.height - capSize - stretchyHeight;
            
            _startCap = _NSImageCreateSubimage(theImage, CGRectMake(0,0,size.width,capSize));
            _centerFill = _NSImageCreateSubimage(theImage, CGRectMake(0,capSize,size.width,stretchyHeight));
            _endCap = _NSImageCreateSubimage(theImage, CGRectMake(0,size.height-bottomCapHeight,size.width,bottomCapHeight));
        } else {
            const CGFloat stretchyWidth = (capSize < size.width)? 1 : 0;
            const CGFloat rightCapWidth = size.width - capSize - stretchyWidth;

            _startCap = _NSImageCreateSubimage(theImage, CGRectMake(0,0,capSize,size.height));
            _centerFill = _NSImageCreateSubimage(theImage, CGRectMake(capSize,0,stretchyWidth,size.height));
            _endCap = _NSImageCreateSubimage(theImage, CGRectMake(size.width-rightCapWidth,0,rightCapWidth,size.height));
        }
    }
    return self;
}

- (void)dealloc
{
    [_startCap release];
    [_centerFill release];
    [_endCap release];
    [super dealloc];
}

- (NSInteger)leftCapWidth
{
    return _vertical? 0 : [_startCap size].width;
}

- (NSInteger)topCapHeight
{
    return _vertical? [_startCap size].height : 0;
}

- (void)drawInRect:(CGRect)rect
{
    // There aren't enough NSCompositingOperations to map all possible CGBlendModes, so rather than have gaps in the support,
    // I am drawing the multipart image into a new image context which is then drawn in the usual way which results in the draw
    // obeying the currently active CGBlendMode and doing the expected thing. This is no doubt more expensive than it could be,
    // but I suspect it's pretty irrelevant in the grand scheme of things.
    UIGraphicsBeginImageContext(rect.size);
    NSDrawThreePartImage(NSMakeRect(0,0,rect.size.width,rect.size.height), _startCap, _centerFill, _endCap, _vertical, NSCompositeCopy, 1, YES);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [img drawInRect:rect];
}

@end
