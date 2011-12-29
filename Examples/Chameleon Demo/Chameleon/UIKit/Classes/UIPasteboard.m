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

#import "UIPasteboard.h"
#import "UIImageAppKitIntegration.h"
#import "UIColorAppKitIntegration.h"
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSColor.h>

static id FirstObjectOrNil(NSArray *items)
{
    return ([items count] > 0)? [items objectAtIndex:0] : nil;
}

@implementation UIPasteboard

- (id)initWithPasteboard:(NSPasteboard *)aPasteboard
{
    if ((self=[super init])) {
        pasteboard = [aPasteboard retain];
    }
    return self;
}

- (void)dealloc
{
    [pasteboard release];
    [super dealloc];
}

+ (UIPasteboard *)generalPasteboard
{
    static UIPasteboard *aPasteboard = nil;
    
    if (!aPasteboard) {
        aPasteboard = [[UIPasteboard alloc] initWithPasteboard:[NSPasteboard generalPasteboard]];
    }

    return aPasteboard;
}

- (void)_writeObjects:(NSArray *)objects
{
    [pasteboard clearContents];
    [pasteboard writeObjects:objects];
}

- (id)_objectsWithClasses:(NSArray *)types
{
    NSDictionary *options = [NSDictionary dictionary];
    return [pasteboard readObjectsForClasses:types options:options];
}

- (void)setStrings:(NSArray *)strings
{
    [self _writeObjects:strings];
}

- (NSArray *)strings
{
    return [self _objectsWithClasses:[NSArray arrayWithObject:[NSString class]]];
}

- (void)setString:(NSString *)aString
{
    [self setStrings:[NSArray arrayWithObject:aString]];
}

- (NSString *)string
{
    return FirstObjectOrNil([self strings]);
}

- (void)setURLs:(NSArray *)items
{
    [self _writeObjects:items];
}

- (NSArray *)URLs
{
    return [self _objectsWithClasses:[NSArray arrayWithObject:[NSURL class]]];
}

- (void)setURL:(NSURL *)aURL
{
    [self setURLs:[NSArray arrayWithObject:aURL]];
}

- (NSURL *)URL
{
    return FirstObjectOrNil([self URLs]);
}

- (void)setImages:(NSArray *)images
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[images count]];
    
    for (UIImage *image in images) {
        [items addObject:[image NSImage]];
    }
    
    [self _writeObjects:items];
}

- (NSArray *)images
{
    NSArray *rawImages = [self _objectsWithClasses:[NSArray arrayWithObject:[NSImage class]]];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[rawImages count]];
    
    for (NSImage *image in rawImages) {
        [images addObject:[[[UIImage alloc] initWithNSImage:image] autorelease]];
    }
    
    return images;
}

- (void)setImage:(UIImage *)anImage
{
    [self setImages:[NSArray arrayWithObject:anImage]];
}

- (UIImage *)image
{
    return FirstObjectOrNil([self images]);
}

- (void)setColors:(NSArray *)colors
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[colors count]];
    
    for (UIColor *color in colors) {
        [items addObject:[color NSColor]];
    }
    
    [self _writeObjects:items];
}

- (NSArray *)colors
{
    NSArray *rawColors = [self _objectsWithClasses:[NSArray arrayWithObject:[NSColor class]]];
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:[rawColors count]];
    
    for (NSColor *color in rawColors) {
        [colors addObject:[[[UIColor alloc] initWithNSColor:color] autorelease]];
    }
    
    return colors;
}

- (void)setColor:(UIColor *)aColor
{
    [self setColors:[NSArray arrayWithObject:aColor]];
}

- (UIColor *)color
{
    return FirstObjectOrNil([self colors]);
}

- (void)setItems:(NSArray *)items
{
    NSMutableArray *writeItems = [NSMutableArray arrayWithCapacity:[items count]];

    for (id item in items) {
        if ([item isKindOfClass:[UIImage class]]) {
            [writeItems addObject:[item NSImage]];
        } else if ([item isKindOfClass:[UIColor class]]) {
            [writeItems addObject:[item NSColor]];
        } else {
            [writeItems addObject:item];
        }
    }
    
    [self _writeObjects:writeItems];
}

- (NSArray *)items
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObjectsFromArray:[self strings]];
    [items addObjectsFromArray:[self URLs]];
    [items addObjectsFromArray:[self images]];
    [items addObjectsFromArray:[self colors]];
    return [items autorelease];
}

- (void)setValue:(id)value forPasteboardType:(NSString *)pasteboardType
{
	self.items = value;
}

@end
