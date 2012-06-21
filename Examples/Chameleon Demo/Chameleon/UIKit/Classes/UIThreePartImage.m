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
#import "UIImageRep.h"

@implementation UIThreePartImage

- (id)initWithRepresentations:(NSArray *)reps capSize:(NSInteger)capSize vertical:(BOOL)isVertical
{
    if ((self=[super _initWithRepresentations:reps])) {
        _capSize = capSize;
        _vertical = isVertical;
    }
    return self;
}

- (NSInteger)leftCapWidth
{
    return _vertical? 0 : _capSize;
}

- (NSInteger)topCapHeight
{
    return _vertical? _capSize : 0;
}

- (void)_drawRepresentation:(UIImageRep *)rep inRect:(CGRect)rect
{
    const CGSize size = self.size;
    
    if ((_vertical && size.height >= rect.size.height) || (!_vertical && size.width >= rect.size.width)) {
        [super _drawRepresentation:rep inRect:rect];
    } else if (_vertical) {
        const CGFloat stretchyHeight = (_capSize < size.height)? 1 : 0;
        const CGFloat bottomCapHeight = size.height - _capSize - stretchyHeight;
        
        [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), rect.size.width, _capSize)
               fromRect:CGRectMake(0, 0, size.width, _capSize)];

        [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect)+_capSize, rect.size.width, rect.size.height-_capSize-bottomCapHeight)
               fromRect:CGRectMake(0, _capSize, size.width, stretchyHeight)];

        [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)-bottomCapHeight, rect.size.width, bottomCapHeight)
               fromRect:CGRectMake(0, size.height-bottomCapHeight, size.width, bottomCapHeight)];
    } else {
        const CGFloat stretchyWidth = (_capSize < size.width)? 1 : 0;
        const CGFloat rightCapWidth = size.width - _capSize - stretchyWidth;
        
        [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), _capSize, rect.size.height)
               fromRect:CGRectMake(0, 0, _capSize, size.height)];

        [rep drawInRect:CGRectMake(CGRectGetMinX(rect)+_capSize, CGRectGetMinY(rect), rect.size.width-_capSize-rightCapWidth, rect.size.height)
               fromRect:CGRectMake(_capSize, 0, stretchyWidth, size.height)];
        
        [rep drawInRect:CGRectMake(CGRectGetMinX(rect)+rect.size.width-rightCapWidth, CGRectGetMinY(rect), rightCapWidth, rect.size.height)
               fromRect:CGRectMake(size.width-rightCapWidth, 0, rightCapWidth, size.height)];
    }
}

@end
