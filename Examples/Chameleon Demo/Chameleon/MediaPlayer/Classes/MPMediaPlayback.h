//
//  MPMediaPlayback.h
//  MediaPlayer
//
//  Created by Michael Dales on 08/07/2011.
//  Copyright 2011 Digital Flapjack Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol MPMediaPlayback <NSObject>

- (void)play;
- (void)pause;
- (void)prepareToPlay;
- (void)stop;

@end
