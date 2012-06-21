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

#import "UIImage.h"

@class NSImage, UIImageRep;

@interface UIImage (UIPrivate)
+ (void)_cacheImage:(UIImage *)image forName:(NSString *)name;
+ (UIImage *)_cachedImageForName:(NSString *)name;
+ (UIImage *)_backButtonImage;
+ (UIImage *)_highlightedBackButtonImage;
+ (UIImage *)_toolbarButtonImage;
+ (UIImage *)_highlightedToolbarButtonImage;
+ (UIImage *)_leftPopoverArrowImage;
+ (UIImage *)_rightPopoverArrowImage;
+ (UIImage *)_topPopoverArrowImage;
+ (UIImage *)_bottomPopoverArrowImage;
+ (UIImage *)_popoverBackgroundImage;
+ (UIImage *)_roundedRectButtonImage;
+ (UIImage *)_highlightedRoundedRectButtonImage;
+ (UIImage *)_windowResizeGrabberImage;
+ (UIImage *)_buttonBarSystemItemAdd;
+ (UIImage *)_buttonBarSystemItemReply;
+ (UIImage *)_tabBarBackgroundImage;
+ (UIImage *)_tabBarItemImage;

- (id)_initWithRepresentations:(NSArray *)reps;
- (UIImageRep *)_bestRepresentationForProposedScale:(CGFloat)scale;
- (void)_drawRepresentation:(UIImageRep *)rep inRect:(CGRect)rect;
- (NSArray *)_representations;
- (BOOL)_isOpaque;

- (UIImage *)_toolbarImage;		// returns a new image which is modified as required for toolbar buttons (turned into a solid color)
@end
