//
//  MPMoviewPlayerController.h
//  MediaPlayer
//
//  Created by Michael Dales on 08/07/2011.
//  Copyright 2011 Digital Flapjack Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPMediaPlayback.h"

#import <QTKit/QTKit.h>

enum {
    MPMovieLoadStateUnknown        = 0,
    MPMovieLoadStatePlayable       = 1 << 0,
    MPMovieLoadStatePlaythroughOK  = 1 << 1,
    MPMovieLoadStateStalled        = 1 << 2,
};
typedef NSInteger MPMovieLoadState;

enum {
    MPMovieControlStyleNone,
    MPMovieControlStyleEmbedded,
    MPMovieControlStyleFullscreen,
    MPMovieControlStyleDefault = MPMovieControlStyleFullscreen
};
typedef NSInteger MPMovieControlStyle;

enum {
    MPMovieFinishReasonPlaybackEnded,
    MPMovieFinishReasonPlaybackError,
    MPMovieFinishReasonUserExited
};
typedef NSInteger MPMovieFinishReason;

enum {
    MPMovieSourceTypeUnknown,
    MPMovieSourceTypeFile,
    MPMovieSourceTypeStreaming
};
typedef NSInteger MPMovieSourceType;

enum {
    MPMovieRepeatModeNone,
    MPMovieRepeatModeOne
};
typedef NSInteger MPMovieRepeatMode;

enum {
    MPMoviePlaybackStateStopped,
    MPMoviePlaybackStatePlaying,
    MPMoviePlaybackStatePaused,
    MPMoviePlaybackStateInterrupted,
    MPMoviePlaybackStateSeekingForward,
    MPMoviePlaybackStateSeekingBackward
};
typedef NSInteger MPMoviePlaybackState;


typedef enum {
    MPMovieScalingModeNone,
    MPMovieScalingModeAspectFit,
    MPMovieScalingModeAspectFill,
    MPMovieScalingModeFill
} MPMovieScalingMode;

extern NSString *const MPMoviePlayerPlaybackDidFinishReasonUserInfoKey;

// notifications
extern NSString *const MPMoviePlayerPlaybackStateDidChangeNotification;
extern NSString *const MPMoviePlayerPlaybackDidFinishNotification;
extern NSString *const MPMoviePlayerLoadStateDidChangeNotification;
extern NSString *const MPMovieDurationAvailableNotification;

@class UIInternalMovieView;

@interface MPMoviePlayerController : NSObject <MPMediaPlayback> 
{
@private
    UIInternalMovieView *movieView;
    
    QTMovie *movie;
}
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) MPMovieLoadState loadState;
@property (nonatomic, copy) NSURL *contentURL;
@property (nonatomic) MPMovieControlStyle controlStyle;
@property (nonatomic) MPMovieSourceType movieSourceType;

// A view for customization which is always displayed behind movie content.
@property(nonatomic, readonly) UIView *backgroundView;

@property (nonatomic, readonly) MPMoviePlaybackState playbackState;
@property (nonatomic) MPMovieRepeatMode repeatMode;

// Indicates if a movie should automatically start playback when it is likely to finish uninterrupted based on e.g. network conditions. Defaults to YES.
@property(nonatomic) BOOL shouldAutoplay;

@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic) MPMovieScalingMode scalingMode;


- (id)initWithContentURL: (NSURL*)url;

@end
