//
//  UIPickerView.h
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

#import "UIView.h"

@protocol UIPickerViewDataSource, UIPickerViewDelegate;

@interface UIPickerView : UIView {
    __unsafe_unretained id<UIPickerViewDataSource> _dataSource;
    __unsafe_unretained id<UIPickerViewDelegate>   _delegate;
    BOOL _showsSelectionIndicator;
}

@property (nonatomic, assign) id<UIPickerViewDataSource> dataSource;
@property (nonatomic, assign) id<UIPickerViewDelegate>   delegate;
@property (nonatomic, assign) BOOL                       showsSelectionIndicator;
@property (nonatomic, readonly) NSInteger                numberOfComponents;

- (NSInteger) numberOfRowsInComponent: (NSInteger) component; // stub
- (void) reloadAllComponents; // stub
- (void) reloadComponent: (NSInteger) component; // stub
- (CGSize) rowSizeForComponent: (NSInteger) component; // stub
- (NSInteger) selectedRowInComponent: (NSInteger) component; // stub
- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated; // stub
- (UIView *) viewForRow: (NSInteger) row inComponent: (NSInteger) component; // stub

@end


@protocol UIPickerViewDataSource <NSObject>
@required

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

@end


@protocol UIPickerViewDelegate <NSObject>
@optional

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component;
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component;

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view;

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end
