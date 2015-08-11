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
#import <AppKit/AppKit.h>

static id FirstObjectOrNil(NSArray *items)
{
    return ([items count] > 0)? [items objectAtIndex:0] : nil;
}

static BOOL IsUIPasteboardPropertyListType(id object)
{
    return [object isKindOfClass:[NSString class]] || 
            [object isKindOfClass:[NSArray class]] || 
            [object isKindOfClass:[NSDictionary class]] || 
            [object isKindOfClass:[NSDate class]] || 
            [object isKindOfClass:[NSNumber class]] || 
            [object isKindOfClass:[NSURL class]];
}

static NSPasteboardItem *PasteBoardItemWithDictionary(NSDictionary *item)
{
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
    
    for (NSString *type in [item allKeys]) {
        id object = [item objectForKey:type];
        
        if ([object isKindOfClass:[NSData class]]) {
            // this is a totally evil hack to support animated GIF.
            // for some reason just copying the data with the kUTTypeGIF to the pasteboard wasn't enough.
            // after much experimentation it would appear that building an NSAttributed string and embedding
            // the image into it is the way Safari does it so that pasting into iChat actually works.
            // this is really stupid. I don't know if this is really the best place for this or if there's a
            // more general rule for when something should be converted to an attributed string, but this
            // seemed to be the quickest way to get the job done at the time. Copying raw GIF NSData to the
            // pasteboard on iOS and tagging it as kUTTypeGIF seems to work just fine in the few places that
            // accept animated GIFs that I've tested so far on iOS so...... yeah.
            if (UTTypeEqual((CFStringRef)type, kUTTypeGIF)) {
                NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:object];
                [fileWrapper setPreferredFilename:@"image.gif"];
                NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:fileWrapper];
                NSAttributedString *str = [NSAttributedString attributedStringWithAttachment:attachment];
                [pasteboardItem setData:[str RTFDFromRange:NSMakeRange(0, [str length]) documentAttributes:@{}] forType:(NSString *)kUTTypeFlatRTFD];
                [attachment release];
                [fileWrapper release];
            }
            [pasteboardItem setData:object forType:type];
        } else if ([object isKindOfClass:[NSURL class]]) {
            [pasteboardItem setString:[object absoluteString] forType:type];
        } else {
            [pasteboardItem setPropertyList:object forType:type];
        }
    }
    
    return [pasteboardItem autorelease];
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

- (void)addItems:(NSArray *)items
{
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[items count]];
    
    for (NSDictionary *item in items) {
        [objects addObject:PasteBoardItemWithDictionary(item)];
    }
        
    [pasteboard writeObjects:objects];
}

- (void)setItems:(NSArray *)items
{
    [pasteboard clearContents];
    [self addItems:items];
}

// there's a good chance this won't work correctly for all cases and indeed it's very untested in its current incarnation
- (NSArray *)items
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:0];
    
    for (NSPasteboardItem *item in [pasteboard pasteboardItems]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        
        for (NSString *type in [item types]) {
            id object = nil;

            if (UTTypeConformsTo((CFStringRef)type, kUTTypeURL)) {
                object = [NSURL URLWithString:[item stringForType:type]];
            } else {
                object = [item propertyListForType:type] ?: [item dataForType:type];
            }

            if (object) {
                [dict setObject:object forKey:type];
            }
        }
        
        if ([dict count] > 0) {
            [items addObject:dict];
        }
    }
    
    return items;
}

- (void)setData:(NSData *)data forPasteboardType:(NSString *)pasteboardType
{
    if (data && pasteboardType) {
        [pasteboard clearContents];
        [pasteboard writeObjects:[NSArray arrayWithObject:PasteBoardItemWithDictionary([NSDictionary dictionaryWithObject:data forKey:pasteboardType])]];
    }
}

- (void)setValue:(id)value forPasteboardType:(NSString *)pasteboardType
{
    if (pasteboardType && IsUIPasteboardPropertyListType(value)) {
        [pasteboard clearContents];
        [pasteboard writeObjects:[NSArray arrayWithObject:PasteBoardItemWithDictionary([NSDictionary dictionaryWithObject:value forKey:pasteboardType])]];
    }
}

@end
