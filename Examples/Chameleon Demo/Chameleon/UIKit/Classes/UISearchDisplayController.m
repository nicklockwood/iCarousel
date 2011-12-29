//
//  UISearchDisplayController.m
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

#import "UISearchDisplayController.h"
#import "UISearchBar.h"
#import "UIViewController.h"


@implementation UISearchDisplayController

@synthesize searchContentsController = _viewController;
@synthesize searchBar = _searchBar;
@synthesize searchResultsTableView = _tableView;
@synthesize searchResultsDataSource = _tableViewDataSource;
@synthesize searchResultsDelegate = _tableViewDelegate;
@synthesize delegate = _delegate;

- (id)initWithSearchBar:(UISearchBar *)searchBar contentsController:(UIViewController *)viewController
{
    if ((self = [super init])) {
        _searchBar = [searchBar retain];
        _viewController = [viewController retain];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _tableViewDataSource = nil;
    _tableViewDelegate = nil;
    [_searchBar release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)isActive
{
    return NO;
}

- (void)setActive:(BOOL)active
{
    [self setActive:active animated:NO];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated
{
}

@end
