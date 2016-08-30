//
//  MediaViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 05/02/13.
//  Light refactor by Gonzalo Gonzalez on 05/05/15
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "MediaViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define k_bottonHUD_height 50.0

//Slider

#define k_slider_height 20.0
#define k_slider_origin_x 100.0
#define k_slider_origin_y 0.0
#define k_slider_width_diference_iPhone 210.0
#define k_slider_width_diference_iPad 160.0

//Play/Pause Button

#define k_play_button_origin_x 5.0
#define k_play_button_origin_y 0.0
#define k_play_button_width 46.0
#define k_play_button_height 46.0

//Progress Label

#define k_progress_label_origin_x 40.0
#define k_progress_label_origin_y 13.0
#define k_progress_label_width 50.0
#define k_progress_label_height 20.0

//Rigth Label

#define k_right_label_origin_x_difference_iPhone 100.0
#define k_right_label_origin_x_difference_iPad 50.0
#define k_right_label_origin_y 13.0
#define k_right_label_width 60.0
#define k_right_label_height 20.0

//Full Screen Button

#define k_full_screen_button_origin_x_difference_iPhone 50.0
#define k_full_screen_button_origin_y 0.0
#define k_full_screen_width 46.0
#define k_full_screen_height 46.0


static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    return [NSString stringWithFormat:@"%@%ld:%0.2ld:%0.2ld", isLeft ? @"-" : @"", (long)h, (long)m, (long)s];
}


@implementation MediaViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Suspended app methods

/*
 * Method that can the screen with timer disabled or enabled
 * This is used to does not show a black screen during the reproduction
 */

-(void)putTheScreenTimerDisabled:(BOOL) isEnabled{
    [[UIApplication sharedApplication] setIdleTimerDisabled:isEnabled];
}


#pragma mark - HUD view
/*
 * Create and put the control panel in the screen
 */
- (void) initHudView{
 
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //Bounds
    CGRect bounds = self.moviePlayer.view.frame;
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
    //ThumbnailView
    self.thumbnailView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, width, height)];
    self.thumbnailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnailView.userInteractionEnabled = NO;
    self.thumbnailView.backgroundColor = [UIColor clearColor];
    self.thumbnailView.hidden = YES;
    
    [self.moviePlayer.view addSubview:self.thumbnailView];
    
    //Bottom HUD
    self.bottomHUD = [[UIView alloc] initWithFrame:CGRectMake(0, height-k_bottonHUD_height, width, k_bottonHUD_height)];
    self.bottomHUD.opaque = NO;
    self.bottomHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    
    
    CGFloat sliderWidthSize = width - k_slider_width_diference_iPhone;
    if (!IS_IPHONE) {
        sliderWidthSize = width - k_slider_width_diference_iPad;
    }
    
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(k_slider_origin_x, k_slider_origin_y, sliderWidthSize, k_bottonHUD_height)];
    self.progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.progressSlider.continuous = YES;
    self.progressSlider.value = 0;
    
    [self.progressSlider addTarget:self
                        action:@selector(playbackSliderMoved:)
              forControlEvents:UIControlEventValueChanged];
    
   
    //PlayButton
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.frame = CGRectMake(k_play_button_origin_x, k_play_button_origin_y, k_play_button_width, k_play_button_height);
    self.playButton.backgroundColor = [UIColor clearColor];
    self.playButton.showsTouchWhenHighlighted = YES;
    [self.playButton setImage:[UIImage imageNamed:@"playback_play.png"] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];

    
    //Progress label
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(k_progress_label_origin_x,k_progress_label_origin_y, k_progress_label_width, k_progress_label_height)];
    self.progressLabel.backgroundColor = [UIColor clearColor];
    self.progressLabel.opaque = NO;
    self.progressLabel.adjustsFontSizeToFitWidth = NO;
    self.progressLabel.textAlignment = NSTextAlignmentRight;
    self.progressLabel.textColor = [UIColor whiteColor];
    self.progressLabel.text = @"";
    self.progressLabel.font = [UIFont systemFontOfSize:12];
    
    
    //Right label
    
    CGFloat leftLabelXPosition = width - k_right_label_origin_x_difference_iPhone;
    if (!IS_IPHONE) {
        leftLabelXPosition = width - k_right_label_origin_x_difference_iPad;
    }
    
    self.rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftLabelXPosition, k_right_label_origin_y, k_right_label_width, k_right_label_height)];
    self.rightLabel.backgroundColor = [UIColor clearColor];
    self.rightLabel.opaque = NO;
    self.rightLabel.adjustsFontSizeToFitWidth = NO;
    self.rightLabel.textAlignment = NSTextAlignmentLeft;
    self.rightLabel.textColor = [UIColor whiteColor];
    self.rightLabel.text = @""; //@"-99:59:59";
    self.rightLabel.font = [UIFont systemFontOfSize:12];
    self.rightLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
   
    if (IS_IPHONE) {
        //Full screen button
        self.fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.fullScreenButton.frame= CGRectMake(width-k_full_screen_button_origin_x_difference_iPhone, k_full_screen_button_origin_y, k_full_screen_width, k_full_screen_height);
        self.fullScreenButton.backgroundColor=[UIColor clearColor];
        self.fullScreenButton.showsTouchWhenHighlighted=YES;
        self.fullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.fullScreenButton setImage:[UIImage imageNamed:@"fullScreen.png"] forState:UIControlStateNormal];
        
        [self.fullScreenButton addTarget:self action:@selector(fullScreenDidTouch:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.bottomHUD addSubview:self.fullScreenButton];
    }
    
    
    [self.bottomHUD addSubview:self.progressSlider];
    [self.bottomHUD addSubview:self.playButton];
    [self.bottomHUD addSubview:self.progressLabel];
    [self.bottomHUD addSubview:self.rightLabel];
    
    
    self.bottomHUD.backgroundColor= [UIColor clearColor];
    
    [self.moviePlayer.view addSubview:self.bottomHUD];
    
    
    //Init flags
    self.isPlaying=NO;
    self.isFullScreen=NO;
    
    //Add observer for a MPMovieDurationAvailableNotification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(movieDurationAvailable:)
     name:MPMovieDurationAvailableNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    //One Tap Gesture to show/hide the HUD
    self.oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.oneTap.numberOfTapsRequired = 1;
    
    
    self.oneTap.delegate = self;
   
    [self.moviePlayer.view addGestureRecognizer:self.oneTap];
    
    self.hiddenHUD = NO;
    
    [self startHUDTimer];
    
}

- (void) removeNotificationObservation{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

/*
 * Method that show/hide the HUD controls with a little animation.
 */
- (void) showHUD: (BOOL) show
{
    //We hide the controls only for video
    if (!_isMusic) {
        _hiddenHUD = !show;
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                         animations:^{
                             
                             CGFloat alpha = _hiddenHUD ? 0 : 1;
                             _bottomHUD.alpha = alpha;
                         }
                         completion:nil];
        
        if (!_hiddenHUD) {
            [self startHUDTimer];
        }
    }
}

/*
 * Method called from _HUDTimer to Hidden the controls
 */
- (void)hiddenTheHUD{
    
    if (!_hiddenHUD) {
        [self showHUD:_hiddenHUD];
    }
    
    [_HUDTimer invalidate];
    _HUDTimer = nil;
}

/*
 * Method that receive the notification that the media file is available
 * and int the labels and start the timer.
 * @notification -> MPMovieDurationAvailableNotification
 */
- (void) movieDurationAvailable:(NSNotification*)notification {
    [self initTimeLabels];
    _progressSlider.minimumValue = 0.0;
    _progressSlider.maximumValue = [self.moviePlayer duration];
	
}

/* Method that receive the notification that the play back is finish
 * @notification -> MPMovieDidFinishNotification
 */
- (void) moviePlayBackDidFinish:(NSNotification*)notification {
    
    //_moviePlayer.moviePlayer = [notification object];

    self.moviePlayer.currentPlaybackTime = 0;
    [self pauseFile];
    
    [self showImageOfVideo];
    
    [_progressSlider setValue:self.moviePlayer.currentPlaybackTime];
    
    if (_isMusic) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [app disableReceiveExternalEvents];
        
    }
    
}


/*
 * Init the time labels with the data of the media file.
 */
-(void)initTimeLabels{
    
    float playbackTime = self.moviePlayer.currentPlaybackTime;
    float duration = self.moviePlayer.duration;
    float restTime = duration-playbackTime;
    
    self.progressLabel.text = formatTimeInterval(playbackTime, NO);
    self.rightLabel.text = formatTimeInterval(restTime, YES);
    
    DLog(@"Time labels. Progress: %@ - Duration: %@", self.progressLabel.text, self.rightLabel.text);
    
}


#pragma mark - Management timers

/*
 * Init the timer and assing to _playbackTimer variable
 */
- (void)initTimer{
    
    if (_playbackTimer == nil) {
		_playbackTimer =
        [NSTimer scheduledTimerWithTimeInterval:1.0f
                                         target:self
                                       selector:@selector(updatePlaybackTime:)
                                       userInfo:nil
                                        repeats:YES];
	}
    
}

/*
 * Stop the timer and free memory
 */
- (void)stopTimer{
    [_playbackTimer invalidate];
    _playbackTimer = nil;
}

/*
 * Start the timer to manage the hide of the control after than 2 seconds
 */
- (void)startHUDTimer{
    
    _HUDTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                                 target:self
                                               selector:@selector(hiddenTheHUD)
                                               userInfo:nil
                                                repeats:NO];

}

/*
 * Stop the HUDTimer and free memory
 */
- (void)stopHUDTimer{
    
    [_HUDTimer invalidate];
    _HUDTimer = nil;
}

#pragma mark - gesture recognizer

- (void)handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (sender == _oneTap) {
            DLog(@"ONE TAP");
           [self showHUD: _hiddenHUD];
        } 
    }
}

-(void)handleDoubleTap: (UITapGestureRecognizer *) sender{
    
    DLog(@"Nothing");
    
}

#pragma mark - gesture delegate
// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}
// this enables you to handle multiple recognizers on single view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Control of player

/*
 * Play the reproduction
 */
- (void) playFile{
    [self quitImageOfVideo];
    _isPlaying=YES;
    [_playButton setImage:[UIImage imageNamed:@"playback_pause.png"] forState:UIControlStateNormal];
    [self.moviePlayer play];
    [self putTheScreenTimerDisabled:YES];
    [self initTimer];
    [self stopHUDTimer];
    [self startHUDTimer];
    
    if (_isMusic) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [app canPlayerReceiveExternalEvents];
    }
}

/*
 * Pause the reproduction
 */
- (void) pauseFile{
    _isPlaying=NO;
    [_playButton setImage:[UIImage imageNamed:@"playback_play.png"] forState:UIControlStateNormal];
    [self.moviePlayer pause];
    [self putTheScreenTimerDisabled:NO];
    [self stopTimer];
    [self stopHUDTimer];
}

/*
 * User tap the play or pause button
 */
- (void) playDidTouch: (id) sender
{
    if (_isPlaying)
        [self pauseFile];
    else
        [self playFile];
}


/*
 * Method that indicate that the player not in use
 */
- (void)finalizePlayer{
    [self putTheScreenTimerDisabled:NO];
    [self stopTimer];    
}

/*
 * Show image of the middle of the video
 */
- (void)showImageOfVideo{
    
    NSNumber *middleTime = [NSNumber numberWithFloat:self.moviePlayer.duration/2];
    
    UIImage *thumbnail = [self.moviePlayer thumbnailImageAtTime:[middleTime floatValue] timeOption:MPMovieTimeOptionNearestKeyFrame];
    _thumbnailView.image = thumbnail;
    _thumbnailView.backgroundColor = [UIColor blackColor];
    _thumbnailView.hidden = NO;

}


/*
 * Quit image of video
 */
- (void)quitImageOfVideo{
    _thumbnailView.backgroundColor = [UIColor clearColor];
    _thumbnailView.hidden=YES;
}


/*
 * Method called for the nstimer to update the labels and slider
 * @theTimer -> The timer of the reproduction
 */
- (void)updatePlaybackTime:(NSTimer*)theTimer {
       
	float playbackTime = self.moviePlayer.currentPlaybackTime;
    float duration = self.moviePlayer.duration;
    float restTime = duration-playbackTime;
		
    self.progressLabel.text = formatTimeInterval(playbackTime, NO);
    self.rightLabel.text = formatTimeInterval(restTime, YES);
    
    DLog(@"Progress video label: %@", self.progressLabel.text);
    
    //This is to detect if the video/audio is stopped outside the App and the App do not know
    if(self.progressSlider.value == playbackTime) {
        [self pauseFile];
    } else {
        [self.progressSlider setValue:playbackTime];
    }
}

/*
 * Method called when the user move the slider
 * @sender -> UISlider
 */
- (void)playbackSliderMoved:(UISlider *)sender {
    
	if (self.moviePlayer.playbackState != MPMoviePlaybackStatePaused) {
		[self.moviePlayer pause];
	}
	self.moviePlayer.currentPlaybackTime = sender.value;
    
    if (_isPlaying) {
        [self.moviePlayer play];
    }
    
	float playbackTime = self.moviePlayer.currentPlaybackTime;
    float duration = self.moviePlayer.duration;
    float restTime = duration-playbackTime;
    
    self.progressLabel.text = formatTimeInterval(playbackTime, NO);
    self.rightLabel.text = formatTimeInterval(restTime, YES);
}

/*
 * Method to change the playBack time
 * @currentTime -> The new time
 */
- (void)changePlayBackTime:(float)currentTime{
    
    if (self.moviePlayer.playbackState != MPMoviePlaybackStatePaused) {
		[self.moviePlayer pause];
	}
	self.moviePlayer.currentPlaybackTime = currentTime;
    
    if (_isPlaying) {
        [self.moviePlayer play];
    }
	
	float playbackTime = self.moviePlayer.currentPlaybackTime;
    float duration = self.moviePlayer.duration;
    float restTime = duration-playbackTime;
    
    self.progressLabel.text = formatTimeInterval(playbackTime, NO);
    self.rightLabel.text = formatTimeInterval(restTime, YES);
    
}

#pragma mark - Full Screen Feature.
/*
 * User tap full screen button
 */
-(void)fullScreenDidTouch:(id)sender{
    if (_isFullScreen)
        [self exitFullScreen];
    else
        [self showFullScreen];
}

/*
 * Method that tell to delegate class that the user tap the button to show full screen
 */
-(void)showFullScreen{
    _isFullScreen = YES;
    [_fullScreenButton setImage:[UIImage imageNamed:@"exitFullScreen.png"] forState:UIControlStateNormal];
    [_delegate fullScreenPlayer:_isFullScreen];
    
}

/*
 * Method that tell to delegate class that the user tap the button to quit full screen
 */
- (void)exitFullScreen{
    _isFullScreen = NO;
    [_fullScreenButton setImage:[UIImage imageNamed:@"fullScreen.png"] forState:UIControlStateNormal];
    [_delegate fullScreenPlayer:_isFullScreen];
}


@end
