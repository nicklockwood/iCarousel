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
#import "UIImageRep.h"

@implementation UINinePartImage

- (id)initWithRepresentations:(NSArray *)reps leftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    if ((self=[super _initWithRepresentations:reps])) {
        _leftCapWidth = leftCapWidth;
        _topCapHeight = topCapHeight;
    }
    return self;
}

- (NSInteger)leftCapWidth
{
    return _leftCapWidth;
}

- (NSInteger)topCapHeight
{
    return _topCapHeight;
}

- (void)_drawRepresentation:(UIImageRep *)rep inRect:(CGRect)rect
{
    const CGSize size = self.size;
    const CGFloat stretchyWidth = (_leftCapWidth < size.width)? 1 : 0;
    const CGFloat stretchyHeight = (_topCapHeight < size.height)? 1 : 0;
    const CGFloat bottomCapHeight = size.height - _topCapHeight - stretchyHeight;
    const CGFloat rightCapWidth = size.width - _leftCapWidth - stretchyWidth;
    
    //topLeftCorner
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), _leftCapWidth, _topCapHeight)
           fromRect:CGRectMake(0, 0, _leftCapWidth, _topCapHeight)];

    //topEdgeFill
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect)+_leftCapWidth, CGRectGetMinY(rect), rect.size.width-rightCapWidth-_leftCapWidth, _topCapHeight)
           fromRect:CGRectMake(_leftCapWidth, 0, stretchyWidth, _topCapHeight)];

    //topRightCorner
    [rep drawInRect:CGRectMake(CGRectGetMaxX(rect)-rightCapWidth, CGRectGetMinY(rect), rightCapWidth, _topCapHeight)
           fromRect:CGRectMake(size.width-rightCapWidth, 0, rightCapWidth, _topCapHeight)];
    
    //bottomLeftCorner
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMaxY(rect)-bottomCapHeight, _leftCapWidth, bottomCapHeight)
           fromRect:CGRectMake(0, size.height-bottomCapHeight, _leftCapWidth, bottomCapHeight)];
    
    //bottomEdgeFill
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect)+_leftCapWidth, CGRectGetMaxY(rect)-bottomCapHeight, rect.size.width-rightCapWidth-_leftCapWidth, bottomCapHeight)
           fromRect:CGRectMake(_leftCapWidth, size.height-bottomCapHeight, stretchyWidth, bottomCapHeight)];
    
    //bottomRightCorner
    [rep drawInRect:CGRectMake(CGRectGetMaxX(rect)-rightCapWidth, CGRectGetMaxY(rect)-bottomCapHeight, rightCapWidth, bottomCapHeight)
           fromRect:CGRectMake(size.width-rightCapWidth, size.height-bottomCapHeight, rightCapWidth, bottomCapHeight)];
    
    //leftEdgeFill
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect)+_topCapHeight, _leftCapWidth, rect.size.height-bottomCapHeight-_topCapHeight)
           fromRect:CGRectMake(0, _topCapHeight, _leftCapWidth, stretchyHeight)];
    
    //rightEdgeFill
    [rep drawInRect:CGRectMake(CGRectGetMaxX(rect)-rightCapWidth, CGRectGetMinY(rect)+_topCapHeight, rightCapWidth, rect.size.height-bottomCapHeight-_topCapHeight)
           fromRect:CGRectMake(size.width-rightCapWidth, _topCapHeight, rightCapWidth, stretchyHeight)];
    
    //centerFill
    [rep drawInRect:CGRectMake(CGRectGetMinX(rect)+_leftCapWidth, CGRectGetMinY(rect)+_topCapHeight, rect.size.width-rightCapWidth-_leftCapWidth, rect.size.height-bottomCapHeight-_topCapHeight)
           fromRect:CGRectMake(_leftCapWidth, _topCapHeight, stretchyWidth, stretchyHeight)];
}

@end
