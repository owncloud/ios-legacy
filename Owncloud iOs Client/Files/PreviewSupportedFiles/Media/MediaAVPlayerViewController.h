//
//  MediaAVPlayerViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez Perez on 14/2/17.
//
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

@interface MediaAVPlayerViewController : AVPlayerViewController

@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) BOOL hiddenHUD;
@property (nonatomic) BOOL isMusic;

@end
