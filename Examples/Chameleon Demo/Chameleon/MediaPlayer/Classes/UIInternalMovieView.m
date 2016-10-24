//
//  UIInternalMovieView.m
//  MediaPlayer
//
//  Created by Michael Dales on 08/07/2011.
//  Copyright 2011 Digital Flapjack Ltd. All rights reserved.
//

#import "UIInternalMovieView.h"


@implementation UIInternalMovieView

@synthesize movie=_movie;
@synthesize scalingMode=_scalingMode;


///////////////////////////////////////////////////////////////////////////////
//
- (void)setScalingMode:(MPMovieScalingMode)scalingMode
{
    _scalingMode = scalingMode;
    
    switch (scalingMode)
    {
        case MPMovieScalingModeNone:
            movieLayer.contentsGravity = kCAGravityCenter;
            break;
            
        case MPMovieScalingModeAspectFit:
            movieLayer.contentsGravity = kCAGravityResizeAspect;
            break;
            
        case MPMovieScalingModeAspectFill:
            movieLayer.contentsGravity = kCAGravityResizeAspectFill;
            break;
            
        case MPMovieScalingModeFill:
            movieLayer.contentsGravity = kCAGravityResize;
            break;
            
    }
}


///////////////////////////////////////////////////////////////////////////////
//
- (id)initWithMovie:(QTMovie *)movie
{
    if ((self = [super init]) != nil)
    {
        self.movie = movie;
        
        movieLayer = [[QTMovieLayer alloc] initWithMovie: movie];
        
        [self.layer addSublayer: movieLayer];
    }
    
    return self;
}


///////////////////////////////////////////////////////////////////////////////
//
- (void)dealloc
{
    [_movie release];
    [super dealloc];
}



///////////////////////////////////////////////////////////////////////////////
//
- (void)setFrame:(CGRect)frame
{
    [super setFrame: frame];
    [movieLayer setFrame: frame];
}

@end
