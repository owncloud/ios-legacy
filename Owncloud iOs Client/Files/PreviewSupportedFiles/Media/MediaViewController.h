//
//  MediaViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 05/02/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <MediaPlayer/MediaPlayer.h>

@protocol MediaViewControllerDelegate

@optional
- (void)fullScreenPlayer:(BOOL)isFullScreenPlayer;
@end

@interface MediaViewController : MPMoviePlayerViewController<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *bottomHUD;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UILabel *rightLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) BOOL hiddenHUD;
@property (nonatomic) BOOL isMusic;
@property (nonatomic, strong) NSTimer *playbackTimer;
@property (nonatomic, strong) NSTimer *HUDTimer;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic,strong) UITapGestureRecognizer *oneTap;
@property(nonatomic,weak) __weak id<MediaViewControllerDelegate> delegate;


/*
 * Init the control panel
 */
- (void) initHudView;

/*
 * Remove this object of observation center.
 */
- (void) removeNotificationObservation;

/*
 * Init the time labels to begin with the data of media file
 */
- (void)initTimeLabels;

/*
 * Method that manage when the user tap the play/pause button
 */
- (void) playDidTouch: (id) sender;

/*
 * Play selected file
 */
- (void) playFile;

/*
 * Pause selected file
 */
- (void) pauseFile;

/*
 * Show a frame in the middle of the video. 
 * It is called when the video finish
 */
- (void)showImageOfVideo;

/*
 * Change the playback time in the player
 */
- (void)changePlayBackTime:(float)currentTime;


/*
 * Method that indicate that the player not in use
 */
- (void)finalizePlayer;


@end
