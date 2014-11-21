//
//  MediaViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 05/02/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "MediaViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define k_bottonHUD_height 50
#define k_slider_height 20
#define k_slider_height_ios7 6
#define k_slider_origin_x 100


static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    return [NSString stringWithFormat:@"%@%d:%0.2d:%0.2d", isLeft ? @"-" : @"", h,m,s];
}


@interface MediaViewController (){
    UIToolbar *_toolBar;
}

@end

@implementation MediaViewController
@synthesize bottomHUD=_bottomHUD;
@synthesize progressSlider=_progressSlider;
@synthesize playButton=_playButton;
@synthesize leftLabel=_leftLabel;
@synthesize progressLabel=_progressLabel;
@synthesize isPlaying=_isPlaying;
@synthesize isMusic=_isMusic;
@synthesize thumbnailView=_thumbnailView;
@synthesize urlString=_urlString;
@synthesize fullScreenButton=_fullScreenButton;
@synthesize isFullScreen=_isFullScreen;
@synthesize oneTap=_oneTap;
@synthesize hiddenHUD=_hiddenHUD;
@synthesize delegate=_delegate;

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
 
    //Bounds
    CGRect bounds = self.moviePlayer.view.bounds;
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    
    //ThumbnailView
    _thumbnailView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, width, height)];
    _thumbnailView.autoresizingMask= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    _thumbnailView.userInteractionEnabled=NO;
    _thumbnailView.backgroundColor=[UIColor clearColor];
    _thumbnailView.hidden=YES;
    
    [self.moviePlayer.view addSubview:_thumbnailView];
    
    //Bottom HUD
    _bottomHUD = [[UIView alloc] initWithFrame:CGRectMake(0,height-k_bottonHUD_height,width,k_bottonHUD_height)];
    _bottomHUD.opaque = NO;
    _bottomHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    
    float sliderYPosition = -2.0;
    
    sliderYPosition = 0.0;
    
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(k_slider_origin_x,sliderYPosition,width-212,k_bottonHUD_height)];
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.continuous = YES;
    _progressSlider.value = 0;
    
    [_progressSlider addTarget:self
                        action:@selector(playbackSliderMoved:)
              forControlEvents:UIControlEventValueChanged];
    
   
    //PlayButton
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(5,0,46,46);
    _playButton.backgroundColor = [UIColor clearColor];
    _playButton.showsTouchWhenHighlighted = YES;
    [_playButton setImage:[UIImage imageNamed:@"playback_play.png"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];

    
    //Progress label
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(40,13,50,20)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor whiteColor];
    _progressLabel.text = @"";
    _progressLabel.font = [UIFont systemFontOfSize:12];
    
    
    //Left label
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(width-108,13,60,20)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor whiteColor];
    _leftLabel.text = @""; //@"-99:59:59";
    _leftLabel.font = [UIFont systemFontOfSize:12];
    _leftLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
   
    //Full screen button
    _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _fullScreenButton.frame= CGRectMake(width-53, 0, 46, 46); //23 x 23 px
    _fullScreenButton.backgroundColor=[UIColor clearColor];
    _fullScreenButton.showsTouchWhenHighlighted=YES;
    _fullScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_fullScreenButton setImage:[UIImage imageNamed:@"fullScreen.png"] forState:UIControlStateNormal];
        
    [_fullScreenButton addTarget:self action:@selector(fullScreenDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_bottomHUD addSubview:_progressSlider];
    [_bottomHUD addSubview:_playButton];
    [_bottomHUD addSubview:_fullScreenButton];
    [_bottomHUD addSubview:_progressLabel];
    [_bottomHUD addSubview:_leftLabel];
    
    
    _bottomHUD.backgroundColor= [UIColor clearColor];
    
  
    [self.moviePlayer.view addSubview:_bottomHUD];
    
    
    //Init flags
     _isPlaying=NO;
    _isFullScreen=NO;
    
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
    _oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _oneTap.numberOfTapsRequired = 1;
    
    
    _oneTap.delegate=self;
   
    [self.moviePlayer.view addGestureRecognizer:_oneTap];
    
    _hiddenHUD=NO;
    
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
    _HUDTimer=nil;
    
    
}

/*
 * Method that receive the notification that the media file is available
 * and int the labels and start the timer.
 * @notification -> MPMovieDurationAvailableNotification
 */
- (void) movieDurationAvailable:(NSNotification*)notification {
    [self initTimeLabels];   
	
	
    _progressSlider.minimumValue=0.0;
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
    
    _progressLabel.text = formatTimeInterval(playbackTime, NO);
    _leftLabel.text = formatTimeInterval(restTime, YES);
    
    DLog(@"Time labels. Progress: %@ - Duration: %@", _progressLabel.text, _leftLabel.text);
    
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
    _HUDTimer=nil;
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
    _thumbnailView.image=thumbnail;
    _thumbnailView.backgroundColor=[UIColor blackColor];
    _thumbnailView.hidden=NO;
    
   
}


/*
 * Quit image of video
 */
- (void)quitImageOfVideo{
     _thumbnailView.backgroundColor=[UIColor clearColor];
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
		
    _progressLabel.text = formatTimeInterval(playbackTime, NO);
    _leftLabel.text = formatTimeInterval(restTime, YES);
    
    DLog(@"Progress video label: %@", _progressLabel.text);
    
    //This is to detect if the video/audio is stopped outside the App and the App do not know
    if(_progressSlider.value == playbackTime) {
        [self pauseFile];
    } else {
        [_progressSlider setValue:playbackTime];
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
    
    _progressLabel.text = formatTimeInterval(playbackTime, NO);
    _leftLabel.text = formatTimeInterval(restTime, YES);
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
    
    _progressLabel.text = formatTimeInterval(playbackTime, NO);
    _leftLabel.text = formatTimeInterval(restTime, YES);
    
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
    _isFullScreen=YES;
    [_fullScreenButton setImage:[UIImage imageNamed:@"exitFullScreen.png"] forState:UIControlStateNormal];
    [_delegate fullScreenPlayer:_isFullScreen];
    
}



/*
 * Method that tell to delegate class that the user tap the button to quit full screen
 */
- (void)exitFullScreen{
    _isFullScreen=NO;
    [_fullScreenButton setImage:[UIImage imageNamed:@"fullScreen.png"] forState:UIControlStateNormal];
    [_delegate fullScreenPlayer:_isFullScreen];
    
    
}


@end
