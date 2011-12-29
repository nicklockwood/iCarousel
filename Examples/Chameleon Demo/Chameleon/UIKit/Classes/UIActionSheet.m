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

#import "UIActionSheet.h"
#import "UIWindow.h"
#import "UIScreenAppKitIntegration.h"
#import "UIKitView.h"
#import "UIApplication+UIPrivate.h"
#import "UIBarButtonItem.h"
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSEvent.h>

@implementation UIActionSheet
@synthesize delegate=_delegate, destructiveButtonIndex=_destructiveButtonIndex, cancelButtonIndex=_cancelButtonIndex, title=_title;
@synthesize firstOtherButtonIndex=_firstOtherButtonIndex, actionSheetStyle = _actionSheetStyle;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _menuTitles = [[NSMutableArray alloc] init];
        _separatorIndexes = [[NSMutableArray alloc] init];
        _destructiveButtonIndex = -1;
        _cancelButtonIndex = -1;
        _firstOtherButtonIndex = -1;
    }
    return self;
}

- (id)initWithTitle:(NSString *)title delegate:(id < UIActionSheetDelegate >)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    if ((self=[self initWithFrame:CGRectZero])) {
        self.delegate = delegate;

        _firstOtherButtonIndex = -1;	// sort of a hack to reset this because the addButtonWithTitle's above can change it's value :)

        if (otherButtonTitles) {
            [self addButtonWithTitle:otherButtonTitles];

            id buttonTitle = nil;
            va_list argumentList;
            va_start(argumentList, otherButtonTitles);

            while ((buttonTitle=(__bridge NSString *)va_arg(argumentList, void *))) {
                [self addButtonWithTitle:buttonTitle];
            }
            
            va_end(argumentList);
        }
        
        if (destructiveButtonTitle) {
            self.destructiveButtonIndex = [self addButtonWithTitle:destructiveButtonTitle];
        }
        
        if (cancelButtonTitle) {
            self.cancelButtonIndex = [self addButtonWithTitle:cancelButtonTitle];
        }
    }
    return self;
}

- (void)dealloc
{
    [_title release];
    [_menu release];
    [_menuTitles release];
    [_separatorIndexes release];
    [super dealloc];
}

- (void)setDelegate:(id<UIActionSheetDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.clickedButtonAtIndex = [_delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)];
    _delegateHas.willPresentActionSheet = [_delegate respondsToSelector:@selector(willPresentActionSheet:)];
    _delegateHas.didPresentActionSheet = [_delegate respondsToSelector:@selector(didPresentActionSheet:)];
    _delegateHas.willDismissWithButtonIndex = [_delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)];
    _delegateHas.didDismissWithButtonIndex = [_delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)];
    _delegateHas.actionSheetCancel = [_delegate respondsToSelector:@selector(actionSheetCancel:)];
}

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    [_menuTitles addObject:title ?: @""];
    NSInteger index = [_menuTitles count]-1;

    if (_firstOtherButtonIndex == -1 ) {
        _firstOtherButtonIndex = index;
    }
    
    return index;
}

- (void)addSeparator
{
    [_separatorIndexes addObject:[NSNumber numberWithInt:[_menuTitles count]]];
}

- (void)setDestructiveButtonIndex:(NSInteger)index
{
    if (index != _destructiveButtonIndex) {
        if (index >= 0) {
            assert(index<[_menuTitles count]);
        } else {
            index = -1;
        }

        _destructiveButtonIndex = index;
    }
}

- (void)setCancelButtonIndex:(NSInteger)index
{
    if (index != _cancelButtonIndex) {
        if (index >= 0) {
            assert(index<[_menuTitles count]);
        } else {
            index = -1;
        }
        
        _cancelButtonIndex = index;
    }
}

- (BOOL)isVisible
{
    return (_menu != nil);
}

- (NSInteger)numberOfButtons
{
    return [_menuTitles count];
}

- (void)_showFromPoint:(CGPoint)point rightAligned:(BOOL)rightAligned inView:(UIView *)view
{
    [view addSubview:self];
    
    if (!_menu && self.window) {
        _menu = [[NSMenu alloc] initWithTitle:_title ?: @""];
        [_menu setAutoenablesItems:NO];
        [_menu setAllowsContextMenuPlugIns:NO];
        
        for (NSInteger index=0; index<[_menuTitles count]; index++) {
            if ([_separatorIndexes containsObject:[NSNumber numberWithInt:index]]) {
                [_menu addItem:[NSMenuItem separatorItem]];
            }
            
            // don't even bother putting a cancel menu item on there. I think on OSX it's always going to be pointless
            // as clicking outside of the menu is always the same thing as tapping the cancel button and that's just
            // how it's got to work, I think.
            if (index != _cancelButtonIndex) {				
                NSMenuItem *theItem = [[NSMenuItem alloc] initWithTitle:[_menuTitles objectAtIndex:index] action:@selector(_didSelectMenuItem:) keyEquivalent:@""];
                [theItem setTag:index];
                [theItem setTarget:self];
                [_menu addItem:theItem];
                [theItem release];
            }
        }

        // convert the point from view's coordinate space to the underlying NSView's coordinate space
        CGPoint windowPoint = [self convertPoint:point toView:nil];
        CGPoint screenPoint = [self.window convertPoint:windowPoint toWindow:nil];

        // then offset it if desired
        if (rightAligned) {
            screenPoint.x -= [_menu size].width;
        }

        if (_delegateHas.willPresentActionSheet) {
            [_delegate willPresentActionSheet:self];
        }
        
        // note that presenting an NSMenu is apparently modal. so, to pretend that it isn't, exactly, I'll delay the presentation
        // of the menu to the start of a new runloop. At least that way, code that may be expecting to run right after setting the
        // menu to visible would still run before the menu itself shows up on screen. Of course behavior is going to be pretty different
        // after that point since if the app is assuming it can keep on doing normal runloop stuff, it ain't gonna happen.
        // but since clicks outside of an NSMenu dismiss it, there's not a lot a user can do to an app to change state when a menu
        // is up in the first place.
        [self performSelector:@selector(_actuallyPresentTheMenuFromPoint:) withObject:[NSValue valueWithCGPoint:screenPoint] afterDelay:0];
    }
}

- (void)_clickedButtonAtIndex:(NSInteger)index
{
    if (_delegateHas.clickedButtonAtIndex){
        [_delegate actionSheet:self clickedButtonAtIndex:index];
    }
    
    if (index == _cancelButtonIndex && _delegateHas.actionSheetCancel) {
        [_delegate actionSheetCancel:self];
    }
    
    if (_delegateHas.willDismissWithButtonIndex) {
        [_delegate actionSheet:self willDismissWithButtonIndex:index];
    }
    
    [self dismissWithClickedButtonIndex:index animated:YES];
    
    if (_delegateHas.didDismissWithButtonIndex) {
        [_delegate actionSheet:self didDismissWithButtonIndex:index];
    }
}

- (void)_didSelectMenuItem:(NSMenuItem *)item
{
    [self _clickedButtonAtIndex:[item tag]];
}

- (void)_actuallyPresentTheMenuFromPoint:(NSValue *)aPoint
{
    // hard to say where best to put this, but I guess this makes some sense? I can't call it after it's actually
    // on screen because of the modal-ness of NSMenu
    if (_delegateHas.didPresentActionSheet) {
        [_delegate didPresentActionSheet:self];
    }

    // this goes modal... meh.
    BOOL itemSelected = [_menu popUpMenuPositioningItem:nil atLocation:NSPointFromCGPoint([aPoint CGPointValue]) inView:[self.window.screen UIKitView]];

    // because of the modal nature of NSMenu, if there's a touch active (like, being held down) when a menu is triggered, the modal NSMenu
    // takes over the event stream and so a mouseUp is never delivered to the UIKitView. This means it never gets to the app and it leaves
    // the "touch" tracking system in an inconsistent state. This triggers the touchesCancelled UIResponder stuff to allow UIKit code to clean
    // itself up after the menu is done.
    [[UIApplication sharedApplication] _cancelTouches];
    
    if (!itemSelected) {
        [self _clickedButtonAtIndex:_cancelButtonIndex];
    }
}

- (void)showInView:(UIView *)view
{
    // Since we're using an NSMenu to represent UIActionSheet on OSX, I'm going to make the assumption that a showInView: is triggered from
    // a click somewhere. If it's triggered on a delay, that might be a problem. However for a typical app, I suspect that is generally
    // not the case. I can't think of a better behavior right now, so I'm going to fetch the current mouse position and translate coords
    // so that the menu presents from there.
    [self showFromRect:CGRectNull inView:view animated:YES];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    // If the rect is NULL, use that as a flag to indicate that the menu should be presented from wherever the mouse cursor is
    // instead of a specific place on screen. This is not really normal UIKit behavior, of course, but I think it makes sense
    // here on the Mac.
    if (CGRectIsNull(rect)) {
        // translate them thar points!
        NSPoint mouseLocation = [NSEvent mouseLocation];
        CGPoint screenPoint = [view.window.screen convertPoint:NSPointToCGPoint(mouseLocation) fromScreen:nil];
        CGPoint windowPoint = [view.window convertPoint:screenPoint fromWindow:nil];
        CGPoint viewPoint = [view convertPoint:windowPoint fromView:nil];
        [self _showFromPoint:viewPoint rightAligned:NO inView:view];
    } else {
        [self _showFromPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height) rightAligned:YES inView:view];
    }
}

- (void)showFromToolbar:(UIToolbar *)view
{
}

- (void)showFromTabBar:(UITabBar *)view
{
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    if (animated) {
        [_menu cancelTracking];
    } else {
        [_menu cancelTrackingWithoutAnimation];
    }
    
    // kill off the menu
    [_menu release];
    _menu = nil;

    // remove ourself from the superview that we piggy-backed on
    [self removeFromSuperview];
}

@end
