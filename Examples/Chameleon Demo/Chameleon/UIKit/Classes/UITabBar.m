//
//  UITabBar.m
//  UIKit
//
//  Created by Peter Steinberger on 23.03.11.
//
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

#import "UITabBar.h"
#import "UIImageView.h"
#import "UIImage+UIPrivate.h"
#import <QuartzCore/QuartzCore.h>

#define TABBAR_HEIGHT 60.0

@implementation UITabBar

@synthesize items = _items, delegate = _delegate;

- (id)initWithFrame:(CGRect)rect
{
    if ((self = [super initWithFrame:rect])) {
        rect.size.height = TABBAR_HEIGHT; // tabbar is always fixed
        _selectedItemIndex = -1;
        UIImage *backgroundImage = [UIImage _popoverBackgroundImage];
        UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        backgroundView.frame = rect;
        [self addSubview:backgroundView];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [_items release];
    [super dealloc];
}

- (UITabBarItem *)selectedItem
{
    if (_selectedItemIndex >= 0) {
        return [_items objectAtIndex:_selectedItemIndex];
    }
    return nil;
}

- (void)setSelectedItem:(UITabBarItem *)selectedItem
{
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
}

- (void)beginCustomizingItems:(NSArray *)items
{
}

- (BOOL)endCustomizingAnimated:(BOOL)animated
{
    return YES;
}

- (BOOL)isCustomizing
{
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; selectedItem = %@; items = %@; delegate = %@>", [self className], self, self.selectedItem, self.items, self.delegate];
}

@end
