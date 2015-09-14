/*
 * Copyright (c) 2012, The Iconfactory. All rights reserved.
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

#import <Foundation/Foundation.h>

@class ALAssetsGroup, ALAsset;

typedef NSUInteger ALAssetsGroupType;

enum {
    ALAssetsGroupLibrary        = (1 << 0),
    ALAssetsGroupAlbum          = (1 << 1),
    ALAssetsGroupEvent          = (1 << 2),
    ALAssetsGroupFaces          = (1 << 3),
    ALAssetsGroupSavedPhotos    = (1 << 4),
    ALAssetsGroupPhotoStream    = (1 << 5),
    ALAssetsGroupAll            = 0xFFFFFFFF,
};

typedef enum {
    ALAssetOrientationUp,
    ALAssetOrientationDown,
    ALAssetOrientationLeft,
    ALAssetOrientationRight,
    ALAssetOrientationUpMirrored,
    ALAssetOrientationDownMirrored,
    ALAssetOrientationLeftMirrored,
    ALAssetOrientationRightMirrored,
} ALAssetOrientation;

typedef void (^ALAssetsLibraryGroupsEnumerationResultsBlock)(ALAssetsGroup *group, BOOL *stop);
typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryWriteImageCompletionBlock)(NSURL *assetURL, NSError *error);
typedef void (^ALAssetsLibraryWriteVideoCompletionBlock)(NSURL *assetURL, NSError *error);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);
typedef void (^ALAssetsLibraryGroupResultBlock)(ALAssetsGroup *group);

enum {
    ALAssetsLibraryUnknownError =               -1,
    
    ALAssetsLibraryWriteFailedError =           -3300,
    ALAssetsLibraryWriteBusyError =             -3301,
    ALAssetsLibraryWriteInvalidDataError =      -3302,
    ALAssetsLibraryWriteIncompatibleDataError = -3303,
    ALAssetsLibraryWriteDataEncodingError =     -3304,
    ALAssetsLibraryWriteDiskSpaceError =        -3305,
    
    ALAssetsLibraryDataUnavailableError =       -3310,
    
    ALAssetsLibraryAccessUserDeniedError =      -3311,
    ALAssetsLibraryAccessGloballyDeniedError =  -3312,
};

extern NSString *const ALAssetsLibraryErrorDomain;

extern NSString *const ALAssetsLibraryChangedNotification;

@interface ALAssetsLibrary : NSObject

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock;

@end
