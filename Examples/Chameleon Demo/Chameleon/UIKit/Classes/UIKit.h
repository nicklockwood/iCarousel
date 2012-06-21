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

#ifndef IBAction
#define IBAction void
#endif

#ifndef IBOutlet
#define IBOutlet
#endif

#import "UIApplicationDelegate.h"
#import "UIScreen.h"
#import "UIGeometry.h"
#import "UIGraphics.h"
#import "UIEvent.h"
#import "UIResponder.h"
#import "UIImage.h"
#import "UIColor.h"
#import "UIView.h"
#import "UIWindow.h"
#import "UITouch.h"
#import "UIApplication.h"
#import "UIInterface.h"
#import "UIImageView.h"
#import "UIScrollView.h"
#import "UITableView.h"
#import "UITableViewCell.h"
#import "UIFont.h"
#import "UILabel.h"
#import "UIStringDrawing.h"
#import "UIDevice.h"
#import "UIAccessibility.h"
#import "UIAccessibilityElement.h"
#import "UIControl.h"
#import "UIButton.h"
#import "UIBezierPath.h"
#import "UIViewController.h"
#import "UIScreenMode.h"
#import "UIActionSheet.h"
#import "UIAlertView.h"
#import "UITextField.h"
#import "UINavigationItem.h"
#import "UINavigationController.h"
#import "UIBarItem.h"
#import "UIBarButtonItem.h"
#import "UIPasteboard.h"
#import "UITextInputTraits.h"
#import "UIWebView.h"
#import "UIToolbar.h"
#import "UITabBar.h"
#import "UITabBarItem.h"
#import "UISegmentedControl.h"
#import "UIActivityIndicatorView.h"
#import "UIPopoverController.h"
#import "UINavigationBar.h"
#import "UITextView.h"
#import "UIDataDetectors.h"
#import "UITableViewController.h"
#import "UISearchBar.h"
#import "UISearchDisplayController.h"
#import "UIImagePickerController.h"
#import "UINibLoading.h"
#import "UIGestureRecognizer.h"
#import "UITapGestureRecognizer.h"
#import "UILongPressGestureRecognizer.h"
#import "UISplitViewController.h"
#import "UITabBarController.h"
#import "UISwitch.h"
#import "UISlider.h"
#import "UIAcceleration.h"
#import "UIAccelerometer.h"
#import "UIMenuController.h"
#import "UIMenuItem.h"
#import "UIViewAdapter.h"
#import "UIPageControl.h"
#import "UIProgressView.h"
#import "UIPickerView.h"
#import "UIPanGestureRecognizer.h"
#import "UIPinchGestureRecognizer.h"
#import "UIRotationGestureRecognizer.h"
#import "UISwipeGestureRecognizer.h"
#import "UIDatePicker.h"
#import "UIAppearance.h"

// non-standard imports
#import "UIKey.h"
#import "UIScrollWheelGestureRecognizer.h"

// only add if core data is included on 10.6
#import "NSFetchedResultsController.h"

// SystemConfiguration-Helper
#define kSCNetworkReachabilityFlagsIsWWAN kSCNetworkReachabilityFlagsConnectionOnDemand
