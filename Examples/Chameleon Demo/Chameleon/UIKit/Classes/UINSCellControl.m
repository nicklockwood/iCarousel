//
//  UINSCellControl.m
//  UIKit
//
//  Created by Jim Dovey on 11-03-23.
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

#import "UINSCellControl.h"
#import "UIColor.h"
#import "UITouch.h"
#import "UIGraphics.h"
#import "UIImage+UIPrivate.h"
#import "UIFont+UIPrivate.h"
#import "UIControl+UIPrivate.h"
#import <AppKit/NSCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSGraphicsContext.h>

@interface NSCell (DrawInCGContext)
- (void)drawWithFrame:(NSRect)cellFrame inGraphicsContext:(CGContextRef)context;
@end

@implementation UINSCellControl

@synthesize cell=_cell;

+(UINSCellControl *)checkboxWithFrame:(CGRect)frame
{
    NSButtonCell *cell = [[NSButtonCell alloc] init];	// this is how NSButton/NSControl initializes its cells
    [cell setButtonType: NSSwitchButton];
    UINSCellControl * control = [[self alloc] initWithFrame:frame cell:cell];
    [cell release];
    return [control autorelease];
}

- (id)initWithFrame:(CGRect)frame
{
    // default cell type? Blech.
    [NSException raise:NSInternalInconsistencyException format:@"UINSCellControl cannot be initialized with just -initWithFrame:"];
    [self release];
    return nil;
}

- (id)initWithFrame:(CGRect)frame cell:(NSCell *)cell
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        _cell = [cell retain];
        [_cell setAction:@selector(_cellAction:)];
        [_cell setTarget:self];
        
        _enabled = [_cell isEnabled];
        _selected = ([_cell isSelectable] && ([_cell state] == NSOnState || [_cell state] == NSMixedState));
        _highlighted = [_cell isHighlighted];
        
        // this is closest to a standard NSCell-based control.
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [_cell release];
    [super dealloc];
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled == enabled)
        return;
    
    [self willChangeValueForKey:@"enabled"];
    [_cell setEnabled:enabled];
    _enabled = enabled;
    [self didChangeValueForKey:@"enabled"];
    [self _stateDidChange];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected)
        return;
    
    [self willChangeValueForKey:@"selected"];
    
    _selected = selected;
    if ( _selected )
        [_cell setState:NSOnState];
    else
        [_cell setState:NSOffState];
    
    [self didChangeValueForKey:@"selected"];
    [self _stateDidChange];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted == highlighted)
        return;
    
    [self willChangeValueForKey:@"highlighted"];
    _highlighted = highlighted;
    [_cell setHighlighted:_highlighted];
    [self didChangeValueForKey:@"highlighted"];
    [self _stateDidChange];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [_cell calcDrawInfo:NSRectFromCGRect(bounds)];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [_cell calcDrawInfo:NSRectFromCGRect(self.bounds)];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    NSRect rect = NSZeroRect;
    rect.size = NSSizeFromCGSize(size);
    NSSize cellSize = [_cell cellSizeForBounds:rect];
    return NSSizeToCGSize(cellSize);
}

- (void)sizeToFit
{
    NSSize cellSize = [_cell cellSize];
    if (cellSize.width == 10000 && cellSize.height == 10000)
    {
        // default massive size -- so use default UIView implementation
        [super sizeToFit];
        return;
    }
    
    CGRect rect = self.frame;
    rect.size = NSSizeToCGSize(cellSize);
    self.frame = rect;
}

- (void)drawRect:(CGRect)rect
{
    [_cell drawWithFrame:NSRectFromCGRect(self.bounds) inGraphicsContext:UIGraphicsGetCurrentContext()];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.enabled)
        self.highlighted = YES;
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.enabled)
    {
        self.highlighted = CGRectContainsPoint(self.bounds, [touch locationInView:self]);
    }
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.bounds, [touch locationInView:self])) {
        self.selected = !self.selected;
        [self sendActionsForControlEvents: UIControlEventValueChanged];
    }
    [super endTrackingWithTouch:touch withEvent:event];
}

- (NSString *)title
{
    return [_cell title];
}

- (void)setTitle:(NSString *)title
{
    [_cell setTitle:title];
    [_cell calcDrawInfo: NSRectFromCGRect(self.bounds)];
    [self _stateDidChange];
}

- (UIImage *)image
{
    NSImage *ns = [_cell image];
    if (ns == nil)
        return nil;
    
    return [UIImage _imageFromNSImage:ns];
}

- (void)setImage:(UIImage *)image
{
    NSImage *ns = nil;
    NSString *name = [UIImage _nameForCachedImage:image];
    if (name != nil)
        ns = [NSImage imageNamed:name];
    
    if (ns == nil) {
        ns = [[[NSImage alloc] initWithCGImage:image.CGImage size:NSSizeFromCGSize(image.size)] autorelease];
    }
    
    [_cell setImage:ns];
    [_cell calcDrawInfo: NSRectFromCGRect(self.bounds)];
    [self _stateDidChange];
}

- (UIFont *)font
{
    return [UIFont fontWithNSFont:[_cell font]];
}

- (void)setFont:(UIFont *)font
{
    [_cell setFont:[font NSFont]];
    [_cell calcDrawInfo: NSRectFromCGRect(self.bounds)];
    [self _stateDidChange];
}

@end

@implementation NSCell (DrawInCGContext)

- (void)drawWithFrame:(NSRect)cellFrame inGraphicsContext:(CGContextRef)context
{
    [NSGraphicsContext saveGraphicsState];
    
    // the semantically correct version:
    //NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
    // the optimized because we control the context stack (we control the vertical, we control the horizontal...) version:
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    if ( [ctx graphicsPort] != context ) {
        // fall back
        ctx = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES];
        [NSGraphicsContext setCurrentContext: ctx];
    }
    
    // The built-in methods of NSCell expect to draw in an NSView.
    // This sucks giant hairy monkey balls for our non-NSView-based stuff, however.
    // However, it appears that NSCell (currently) actually draws in the current context, so that helps
    [self drawWithFrame:cellFrame inView:nil];
    
    // revert to any prior graphics state
    [NSGraphicsContext restoreGraphicsState];
}

@end
