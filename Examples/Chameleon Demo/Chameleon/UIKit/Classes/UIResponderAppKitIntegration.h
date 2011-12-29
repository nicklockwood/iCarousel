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

#import "UIResponder.h"

@class UIKey;

@interface UIResponder (AppKitIntegration)
// This message is sent up the responder chain so that views behind other views can make use of the scroll wheel (such as UIScrollView).
- (void)scrollWheelMoved:(CGPoint)delta withEvent:(UIEvent *)event;

// This is sent up the responder chain when the app gets a rightMouseDown-like event from OSX. There is no rightMouseDragged or rightMouseUp.
- (void)rightClick:(UITouch *)touch withEvent:(UIEvent *)event;

// This message is sent up (down?) the responder chain. You may get these often - especially when the mouse moves over a view that has a lot
// of smaller subviews in it as the messages will be sent each time the view under the cursor changes. These only happen during normal mouse
// movement - not when clicking, click-dragging, etc so it won't happen in all possible cases that might maybe make sense. Also, due to the
// bolted-on nature of this, I'm not entirely convinced it is delivered from the best spot - but in practice, it'll probably be okay.
// NOTE: You might get this message twice since the message is sent both to the view being left and the one being exited and they could
// ultimately share the same superview or controller or something.
// If the mouse came in from outside the hosting UIKitView, the enteredView is nil. If the mouse left the UIKitView, the exitedView is nil.
- (void)mouseExitedView:(UIView *)exited enteredView:(UIView *)entered withEvent:(UIEvent *)event;

// This passed along the responder chain like everything else.
- (void)mouseMoved:(CGPoint)delta withEvent:(UIEvent *)event;

// Return an NSCursor if you want to modify it or nil to use the default arrow. Follows responder chain.
- (id)mouseCursorForEvent:(UIEvent *)event;	// return an NSCursor if you want to modify it, return nil to use default

// This is a rough guess as to what might be coming in the future with UIKit. I suspect it'll be similar but perhaps more detailed. UIKey
// may or may not exist, etc. This will work for now in case it is needed. This is only triggered by keyDown: events and is not extensively
// implemented or tested at this point. This is sent to the firstResponder in the keyWindow.
// Note, that the UIEvent here will be an empty non-touch one and has no real purpose in the present implementation :)
- (void)keyPressed:(UIKey *)key withEvent:(UIEvent *)event;

@end


@interface NSObject (UIResponderAppKitIntegrationKeyboardActions)
// This is triggered from AppKit's cancelOperation: so it should be sent in largely the same circumstances. Generally you can think of it as mapping
// to the ESC key, but CMD-. (period) also maps to it.
- (void)cancel:(id)sender;

// This is mapped to CMD-Return and Enter and does not come from AppKit since it has no such convention as far as I've found. However it seemed like
// a useful thing to define, really, so that's what I'm doing. :)
- (void)commit:(id)sender;
@end


