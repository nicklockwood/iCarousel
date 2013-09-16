//
//  MPMoviewPlayerController.m
//  MediaPlayer
//
//  Created by Michael Dales on 08/07/2011.
//  Copyright 2011 Digital Flapjack Ltd. All rights reserved.
//

#import "MPMoviePlayerController.h"
#import "UIInternalMovieView.h"

NSString *const MPMoviePlayerPlaybackDidFinishReasonUserInfoKey = @"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey";

// notifications
NSString *const MPMoviePlayerPlaybackStateDidChangeNotification = @"MPMoviePlayerPlaybackStateDidChangeNotification";
NSString *const MPMoviePlayerPlaybackDidFinishNotification = @"MPMoviePlayerPlaybackDidFinishNotification";
NSString *const MPMoviePlayerLoadStateDidChangeNotification = @"MPMoviePlayerLoadStateDidChangeNotification";
NSString *const MPMovieDurationAvailableNotification = @"MPMovieDurationAvailableNotification";

@implementation MPMoviePlayerController

@synthesize view=_view;
@synthesize loadState=_loadState;
@synthesize contentURL=_contentURL;
@synthesize controlStyle=_controlStyle;
@synthesize movieSourceType=_movieSourceType;
@synthesize backgroundView;
@synthesize playbackState=_playbackState;
@synthesize repeatMode=_repeatMode;
@synthesize shouldAutoplay;
@synthesize scalingMode=_scalingMode;



///////////////////////////////////////////////////////////////////////////////
//
- (void)setScalingMode:(MPMovieScalingMode)scalingMode
{
    _scalingMode = scalingMode;
    movieView.scalingMode = scalingMode;
}


///////////////////////////////////////////////////////////////////////////////
//
- (void)setRepeatMode:(MPMovieRepeatMode)repeatMode
{
    _repeatMode = repeatMode;
    [movie setAttribute: [NSNumber numberWithBool: repeatMode == MPMovieRepeatModeOne]
                 forKey: QTMovieLoopsAttribute];
}


///////////////////////////////////////////////////////////////////////////////
//
- (NSTimeInterval)duration
{
    QTTime time = [movie duration];
    NSTimeInterval interval;
    
    if (QTGetTimeInterval(time, &interval))
        return interval;
    else
        return 0.0;
}


///////////////////////////////////////////////////////////////////////////////
//
- (UIView*)view
{
    return movieView;
}



///////////////////////////////////////////////////////////////////////////////
//
- (MPMovieLoadState)loadState
{    
    NSNumber* loadState = [movie attributeForKey: QTMovieLoadStateAttribute];        
    
    switch ([loadState intValue]) {
        case QTMovieLoadStateError:            
        {
            NSLog(@"woo");
            NSNumber *stopCode = [NSNumber numberWithInt: MPMovieFinishReasonPlaybackError];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                                 forKey: MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
            
            // if there's a loading error we generate a stop notification
            [[NSNotificationCenter defaultCenter] postNotificationName: MPMoviePlayerPlaybackDidFinishNotification
                                                                object: self 
                                                              userInfo: userInfo];
            
            
            _loadState = MPMovieLoadStateUnknown;                        
        }
            break;

        
        
        case QTMovieLoadStateLoading:             
            _loadState = MPMovieLoadStateUnknown;            
            break;
            
    
        
        case QTMovieLoadStateLoaded:            
            // we have the meta data, so post the duration available notification
            [[NSNotificationCenter defaultCenter] postNotificationName: MPMovieDurationAvailableNotification
                                                                object: self];
            
            _loadState = MPMovieLoadStateUnknown;            
            break;
            
        case QTMovieLoadStatePlayable:
            _loadState = MPMovieLoadStatePlayable;
            break;
            
        case QTMovieLoadStatePlaythroughOK:
            _loadState = MPMovieLoadStatePlaythroughOK;            
            break;
            
        case QTMovieLoadStateComplete:
            _loadState = MPMovieLoadStatePlaythroughOK;
            
            break;                                
    }
    
    return _loadState;
}


#pragma mark - notifications



///////////////////////////////////////////////////////////////////////////////
//
- (void)didEndOccurred: (NSNotification*)notification
{
    if (notification.object != movie)
        return;

    _playbackState = MPMoviePlaybackStateStopped;
        
    NSNumber *stopCode = [NSNumber numberWithInt: MPMovieFinishReasonPlaybackEnded];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                         forKey: MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: MPMoviePlayerPlaybackDidFinishNotification
                                                        object: self
                                                      userInfo: userInfo];
}


///////////////////////////////////////////////////////////////////////////////
//
- (void)loadStateChangeOccurred: (NSNotification*)notification
{
    if (notification.object != movie)
        return;
        
    [[NSNotificationCenter defaultCenter] postNotificationName: MPMoviePlayerLoadStateDidChangeNotification
                                                        object: self];
}

#pragma mark - constructor/destructor

///////////////////////////////////////////////////////////////////////////////
//
- (id)initWithContentURL:(NSURL *)url
{
    self = [super init];
    if (self) 
    {
        _contentURL = [url retain];
        _loadState = MPMovieLoadStateUnknown;
        _controlStyle = MPMovieControlStyleDefault;
        _movieSourceType = MPMovieSourceTypeUnknown;
        _playbackState = MPMoviePlaybackStateStopped;
        _repeatMode = MPMovieRepeatModeNone;
        
        NSError *error = nil;
        movie = [[QTMovie alloc] initWithURL: url
                                       error: &error];
        
        movieView = [[UIInternalMovieView alloc] initWithMovie: movie];
        
        self.scalingMode = MPMovieScalingModeAspectFit;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(loadStateChangeOccurred:)
                                                     name: QTMovieLoadStateDidChangeNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didEndOccurred:)
                                                     name: QTMovieDidEndNotification 
                                                   object: nil];
    }
    
    return self;
}


///////////////////////////////////////////////////////////////////////////////
//
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [_view release];
    [super dealloc];
}


#pragma mark - MPMediaPlayback


///////////////////////////////////////////////////////////////////////////////
//
- (void)play
{
    [movie play];
    _playbackState = MPMoviePlaybackStatePlaying;
}


///////////////////////////////////////////////////////////////////////////////
//
- (void)pause
{
    [movie stop];
    _playbackState = MPMoviePlaybackStatePaused;
}

///////////////////////////////////////////////////////////////////////////////
//
- (void)prepareToPlay {
    // Do nothing
}

///////////////////////////////////////////////////////////////////////////////
//
- (void)stop
{
    [movie stop];
    _playbackState = MPMoviePlaybackStateStopped;
}

#pragma mark - Pending

- (void) setShouldAutoplay:(BOOL)shouldAutoplay {
    NSLog(@"[CHAMELEON] MPMoviePlayerController.shouldAutoplay not implemented");
}

- (UIView*) backgroundView {
    NSLog(@"[CHAMELEON] MPMoviePlayerController.backgroundView not implemented");
    return nil;
}


@end
