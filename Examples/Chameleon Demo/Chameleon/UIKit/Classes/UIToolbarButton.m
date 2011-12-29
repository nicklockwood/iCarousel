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

#import "UIToolbarButton.h"
#import "UIBarButtonItem.h"
#import "UIImage+UIPrivate.h"
#import "UILabel.h"
#import "UIFont.h"

// I don't like most of this... the real toolbar button lays things out different than a default button.
// It also seems to have some padding built into it around the whole thing (even the background)
// It centers images vertical and horizontal if not bordered, but it appears to be top-aligned if it's bordered
// If you specify both an image and a title, these buttons stack them vertically which is unlike default UIButton behavior
// This is all a pain in the ass and wrong, but good enough for now, I guess

static UIEdgeInsets UIToolbarButtonInset = {0,4,0,4};

@implementation UIToolbarButton

- (id)initWithBarButtonItem:(UIBarButtonItem *)item
{
    NSAssert(item != nil, @"bar button item must not be nil");
    CGRect frame = CGRectMake(0,0,24,24);
    
    if ((self=[super initWithFrame:frame])) {
        UIImage *image = nil;
        NSString *title = nil;
        
        if (item->_isSystemItem) {
            switch (item->_systemItem) {
                case UIBarButtonSystemItemAdd:
                    image = [UIImage _buttonBarSystemItemAdd];
                    break;
                    
                case UIBarButtonSystemItemReply:
                    image = [UIImage _buttonBarSystemItemReply];
                    break;
                    
                default:
                    break;
            }
        } else {
            image = [item.image _toolbarImage];
            title = item.title;

            if (item.style == UIBarButtonItemStyleBordered) {
                self.titleLabel.font = [UIFont systemFontOfSize:11];
                [self setBackgroundImage:[UIImage _toolbarButtonImage] forState:UIControlStateNormal];
                [self setBackgroundImage:[UIImage _highlightedToolbarButtonImage] forState:UIControlStateHighlighted];
                self.contentEdgeInsets = UIEdgeInsetsMake(0,7,0,7);
                self.titleEdgeInsets = UIEdgeInsetsMake(4,0,0,0);
                self.clipsToBounds = YES;
                self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            }
        }
        
        [self setImage:image forState:UIControlStateNormal];
        [self setTitle:title forState:UIControlStateNormal];
        [self addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];
        
        // resize the view to fit according to the rules, which appear to be that if the width is set directly in the item, use that
        // value, otherwise size to fit - but cap the total height, I guess?
        CGSize fitToSize = frame.size;

        if (item.width > 0) {
            frame.size.width = item.width;
        } else {
            frame.size.width = [self sizeThatFits:fitToSize].width;
        }
        
        self.frame = frame;
    }
    return self;
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect(bounds, UIToolbarButtonInset);
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect(bounds, UIToolbarButtonInset);
}

- (CGSize)sizeThatFits:(CGSize)fitSize
{
    fitSize = [super sizeThatFits:fitSize];
    fitSize.width += UIToolbarButtonInset.left + UIToolbarButtonInset.right;
    fitSize.height += UIToolbarButtonInset.top + UIToolbarButtonInset.bottom;
    return fitSize;
}

@end
