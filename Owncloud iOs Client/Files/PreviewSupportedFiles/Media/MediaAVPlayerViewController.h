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

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic) BOOL isMusic;
@property (nonatomic) BOOL isFullScreen;

+(NSString *)observerKeyFullScreen;

@end
