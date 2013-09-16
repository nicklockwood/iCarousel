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

#import "UIWebView.h"
#import "UIViewAdapter.h"
#import <WebKit/WebKit.h>

@implementation UIWebView
@synthesize request=_request, delegate=_delegate, dataDetectorTypes=_dataDetectorTypes, scalesPageToFit=_scalesPageToFit;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _scalesPageToFit = NO;
        
        _webView = [(WebView *)[WebView alloc] initWithFrame:NSRectFromCGRect(self.bounds)];
        [_webView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        [_webView setPolicyDelegate:self];
        [_webView setFrameLoadDelegate:self];
        [_webView setUIDelegate:self];
        [_webView setDrawsBackground:NO];

        _webViewAdapter = [[UIViewAdapter alloc] initWithFrame:self.bounds];
        _webViewAdapter.NSView = _webView;
        _webViewAdapter.scrollEnabled = NO;		// WebView does its own scrolling :/
        
        [self addSubview:_webViewAdapter];
    }
    return self;
}

- (void)dealloc
{
    [_webView setPolicyDelegate:nil];
    [_webView setFrameLoadDelegate:nil];
    [_webView setUIDelegate:nil];
    [_webViewAdapter release];
    [_webView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _webViewAdapter.frame = self.bounds;
}

- (void)setDelegate:(id<UIWebViewDelegate>)newDelegate
{
    _delegate = newDelegate;
    _delegateHas.shouldStartLoadWithRequest = [_delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)];
    _delegateHas.didFailLoadWithError = [_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)];
    _delegateHas.didFinishLoad = [_delegate respondsToSelector:@selector(webViewDidFinishLoad:)];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    [[_webView mainFrame] loadHTMLString:string baseURL:baseURL];
}

- (void)loadRequest:(NSURLRequest *)request
{
    if (request != _request) {
        [_request release];
        _request = [request retain];
    }

    [[_webView mainFrame] loadRequest:_request];
}

- (void)stopLoading
{
    [_webView stopLoading:self];
}

- (void)reload
{
    [_webView reload:self];
}

- (void)goBack
{
    [_webView goBack];
}

- (void)goForward
{
    [_webView goForward];
}

- (BOOL)isLoading
{
    return [_webView isLoading];
}

- (BOOL)canGoBack
{
    return [_webView canGoBack];
}

- (BOOL)canGoForward
{
    return [_webView canGoForward];
}

- (BOOL)scalesPageToFit
{
    return false;
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit
{
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
    return [_webView stringByEvaluatingJavaScriptFromString:script];
}

// The only reason this is here is because Flamingo currently tries a hack to get at the web view's internals UIScrollView to get
// the desk ad view to stop stealing the scrollsToTop event. Lame, yes...
- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

#pragma mark -
#pragma mark WebView Policy Delegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    BOOL shouldStartLoad = NO;
    
    if (_delegateHas.shouldStartLoadWithRequest) {
        id navTypeObject = [actionInformation objectForKey:WebActionNavigationTypeKey];
        NSInteger navTypeCode = [navTypeObject intValue];
        UIWebViewNavigationType navType = UIWebViewNavigationTypeOther;

        switch (navTypeCode) {
            case WebNavigationTypeLinkClicked:		navType = UIWebViewNavigationTypeLinkClicked;		break;
            case WebNavigationTypeFormSubmitted:	navType = UIWebViewNavigationTypeFormSubmitted;		break;
            case WebNavigationTypeBackForward:		navType = UIWebViewNavigationTypeBackForward;		break;
            case WebNavigationTypeReload:			navType = UIWebViewNavigationTypeReload;			break;
            case WebNavigationTypeFormResubmitted:	navType = UIWebViewNavigationTypeFormResubmitted;	break;
        }
        
        shouldStartLoad = [_delegate webView:self shouldStartLoadWithRequest:request navigationType:navType];
    } else {
        shouldStartLoad = YES;
    }
    
    if (shouldStartLoad) {
        [listener use];
    } else {
        [listener ignore];
    }
}

#pragma mark -
#pragma mark WebView Frame Load Delegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (_delegateHas.didFinishLoad) {
        [_delegate webViewDidFinishLoad:self];
    }
//    [_webViewAdapter becomeFirstResponder];
//    [_webViewAdapter setNeedsDisplay];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if (_delegateHas.didFailLoadWithError) {
        [_delegate webView:self didFailLoadWithError:error];
    }
}

#pragma mark -
#pragma mark WebView UI Delegate

- (void)webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder
{
    [[_webViewAdapter.NSView window] makeFirstResponder:responder];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    return [NSArray array];
}

- (BOOL)webViewIsResizable:(WebView *)sender
{
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)webView:(WebView *)sender setFrame:(NSRect)frame
{
    // DO NOTHING to prevent WebView resize window
}

@end
