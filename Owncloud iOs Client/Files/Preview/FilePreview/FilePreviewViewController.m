//
//  FilePreviewViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/11/2012.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "FilePreviewViewController.h"
#import "FileDto.h"
#import "MBProgressHUD.h"
#import "UIColor+Constants.h"
#import "constants.h"
#import "AppDelegate.h"
#import "EditAccountViewController.h"
#import "UtilsDtos.h"
#import "UIImage+Resize.h"
#import "UserDto.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "ManageFilesDB.h"
#import "FilesViewController.h"
#import "UploadUtils.h"
#import "CWStatusBarNotification.h"
#import "UIAlertView+Blocks.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "ManageFavorites.h"
#import "UtilsUrls.h"
#import "ReaderDocument.h"
#import "ReaderViewController.h"
#import "ShareMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SyncFolderManager.h"
#import "DownloadUtils.h"
#import "ManageCapabilitiesDB.h"
#import "EditFileViewController.h"
#import "UtilsBrandedOptions.h"
#import "UtilsFramework.h"
#import "CheckAccessToServer.h"

//Constant for iOS7
#define k_status_bar_height 20
#define k_navigation_bar_height 44
#define k_navigation_bar_height_in_iphone_landscape 32
#define k_iphone_plus_correction 10


NSString * iPhoneCleanPreviewNotification = @"iPhoneCleanPreviewNotification";
NSString * iPhoneShowNotConnectionWithServerMessageNotification = @"iPhoneShowNotConnectionWithServerMessageNotification";

@interface FilePreviewViewController ()

@end

@implementation FilePreviewViewController


#pragma mark - Init methods
- (id) initWithNibName:(NSString *) nibNameOrNil selectedFile:(FileDto *) file andIsForceDownload:(BOOL) isForceDownload {
    
    if (file.isDownload == downloading) {
        isForceDownload = YES;
    }
    
    [[AppDelegate sharedSyncFolderManager] cancelDownload:file];
    
    if (!isForceDownload) {
        isForceDownload = [[AppDelegate sharedManageFavorites] isInsideAFavoriteFolderThisFile:file] || file.isFavorite;
    }
    
    
    //Assing the file
    self.file = file;
    self.isForceDownload = isForceDownload;
    
    DLog(@"File to preview: %@ with File id: %ld", self.file.fileName, (long)file.idFile);
    
    
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Load view methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Enable toolBar and navBar
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
    
    _progressViewHeightConstraint.constant = 2;
    
    if (!_file.isNecessaryUpdate) {
        [self putTitleInNavBarByName:_file.fileName];
    }
    
    //Init global attributes
    _progressView.progress = 0.0;
    _progressView.hidden = YES;
    _cancelButton.hidden = YES;
    _progressLabel.hidden = YES;
    _previewImageView.hidden = NO;
    
    //Init notificacion in status bar
    _notification = [CWStatusBarNotification new];
    
    //Set notifications for communication betweenViews
    [self setNotificationForCommunicationBetweenViews];
    
    //Get current local folder
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    _currentLocalFolder = [NSString stringWithFormat:@"%@%ld/%@", [UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser]];
    _currentLocalFolder = [_currentLocalFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //Obtain the type of file
    _typeOfFile = [FileNameUtils checkTheTypeOfFile:_file.fileName];
    
    if(self.file.isDownload == notDownload && !self.isForceDownload && self.typeOfFile == videoFileType && ([[CheckAccessToServer sharedManager] getSslStatus] != sslStatusSelfSigned)) {
        //Not show options
        NSMutableArray *customItems = [NSMutableArray arrayWithArray:self.toolBar.items];
        [customItems removeObjectIdenticalTo:_openInButtonBar];
        [customItems removeObjectIdenticalTo:_flexibleSpaceAfterOpenInButtonBar];
        [customItems removeObjectIdenticalTo:_favoriteButtonBar];
        [customItems removeObjectIdenticalTo:_flexibleSpaceAfterFavoriteButtonBar];
        self.toolBar.items = customItems;
    }
    
    //Check if share link button should be appear.
    if ((k_hide_share_options) || (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled)) {
        NSMutableArray *customItems = [NSMutableArray arrayWithArray:self.toolBar.items];
        [customItems removeObjectIdenticalTo:_shareButtonBar];
        [customItems removeObjectIdenticalTo:_flexibleSpaceAfterShareButtonBar];
        self.toolBar.items = customItems;
    }
    
    //Method that managed every type of file
    [self handleFile];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (app.isSharedToOwncloudPresent == NO && _notification.notificationIsShowing) {
        //Stop the notification
        [self stopNotificationUpdatingFile];
        
        if (_notification) {
            _notification = nil;
        }
    }
    
    //Quit the player if exist
    if (self.avMoviePlayer) {
        [self.avMoviePlayer.contentOverlayView removeObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen]];
        [self.avMoviePlayer.player pause];
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _isCancelDownloadClicked = NO;
    
    [self setEditBarButtonInTextFiles];
    
    //Set the navigation bar to not translucent
    [self.navigationController.navigationBar setTranslucent:YES];
    
    //Configure view depend device orientation
    [self configureView];
    
    //Quit the player if exist
    if (self.avMoviePlayer) {
        [self.avMoviePlayer.contentOverlayView addObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}


#pragma mark - Edit file option

- (void) setEditBarButtonInTextFiles {
    
    if ([FileNameUtils isEditTextViewSupportedThisFile:self.file.fileName]) {

        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(didSelectEditView)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}


- (void) didSelectEditView {
    
    if (self.file.isDownload == downloaded && !self.isDownloading) {
        EditFileViewController *viewController = [[EditFileViewController alloc] initWithFileDto:self.file andModeEditing:YES];
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.navigationBar.translucent = NO;
        
        if (IS_IPHONE) {
            viewController.hidesBottomBarWhenPushed = YES;
            [self presentViewController:navController animated:YES completion:nil];
        } else {
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navController animated:YES completion:nil];
        }
    } else {
        [self showAlertView:NSLocalizedString(@"no_file_downloaded", nil)];
    }

}


///-----------------------------------
/// @name Set Type of Extend With Option
///-----------------------------------

/**
 * Method that set the type of extend
 * option 0 -> Not extend
 * option 1 -> Extend all corners
 *
 * @param option -> NSInteger wiht the number of option
 */
- (void)setTypeOfLayoutExtendWithOption:(NSInteger)option{
    
    switch (option) {
        case 0:
            self.edgesForExtendedLayout = UIRectEdgeNone;
            break;
            
        case 1:
            self.edgesForExtendedLayout = UIRectCornerAllCorners;
            break;
            
        default:
            break;
    }
}

/*
 * Method that put a title label in navBar.
 */
- (void)putTitleInNavBarByName:(NSString *) name {
    
    self.navigationItem.titleView = [UtilsBrandedOptions getCustomLabelForNavBarByName:name];
}

///-----------------------------------
/// @name putTheFavoriteStatus
///-----------------------------------

/**
 * This method puts the favorite star on starred or unstarred state on the preview view
 */
- (void) putTheFavoriteStatus {
    if (_file.isFavorite || [DownloadUtils isSonOfFavoriteFolder:self.file]) {
        //Change the image to unstarred
        _favoriteButtonBar.image = [UIImage imageNamed:@"available_offline_TB-filled"];
    } else {
        //Change the image to starred
        _favoriteButtonBar.image = [UIImage imageNamed:@"available_offline_TB"];
    }
}


///-----------------------------------
/// @name Put the updated progress bar in the navigation bar
///-----------------------------------

/**
 * This method put the progress bar and the cancel button in the
 * navigation bar instead of the file name
 */
- (void) putUpdateProgressInNavBar {
    _isDownloading = YES;
    DLog(@"Include the progress view in the navigation bar");
    nameFileToUpdate = _file.fileName;
    [self putTitleInNavBarByName:@""];
    _updatingFileView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 44)];
    //Elements in the updating bar
    _updatingFileProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 21, 180, 2)];
    _updatingFileProgressView.progress = 0.0;
    _updatingCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_updatingCancelButton setFrame:CGRectMake(220, 12, 20, 20)];
    [_updatingCancelButton addTarget:self action:@selector(didPressUpdatingCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if(k_is_text_status_bar_white){
        [_updatingCancelButton setImage:[UIImage imageNamed:@"cancel_download_white.png"] forState:UIControlStateNormal];
    }
    else{
          [_updatingCancelButton setImage:[UIImage imageNamed:@"cancel_download.png"] forState:UIControlStateNormal];
    }
    
    [_updatingFileView addSubview:_updatingFileProgressView];
    [_updatingFileView addSubview:_updatingCancelButton];
    
    [self.navigationItem setTitleView:_updatingFileView];
    
    [self performSelector:@selector(showTextInStatusBar) withObject:nil afterDelay:0.0];
}



///-----------------------------------
/// @name Show a text in the status bar
///-----------------------------------

/**
 * This method shows a text in the status bar of the device
 */
- (void) showTextInStatusBar {

    if ([self isDownloadingImageOrFile] && nameFileToUpdate == _file.fileName) {
        DLog(@"Show a notification text in the status bar");
        //Notificacion style
        _notification.notificationLabelBackgroundColor = [[UIColor colorOfNavigationBar] colorWithAlphaComponent:1.0f];
        _notification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
        _notification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
        
        if(k_is_text_status_bar_white) {
            _notification.notificationLabelTextColor = [UIColor whiteColor];
        }
        else {
            _notification.notificationLabelTextColor = [UIColor blackColor];
        }
        
        //File name
        NSString *notificationText = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"updating", nil), [nameFileToUpdate stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        DLog(@"name: %@",notificationText);
        [_notification displayNotificationWithMessage:notificationText completion:nil];
    }
}


- (BOOL) isDownloadingImageOrFile {

    if ((self.galleryView != nil && [self.galleryView isCurrentImageDownloading]) || (self.galleryView == nil && self.isDownloading)) {
        return YES;
    }
    return NO;
}

///-----------------------------------
/// @name Stop notification in status bar
///-----------------------------------

/**
 * This method removes the notification in the status bar
 * and put the name of the file in the title of the navigation bar
 */
- (void) stopNotificationUpdatingFile {
    DLog(@"Stop the notification in the status bar");
    [_notification dismissNotification];
    [self putTheFavoriteStatus];
    [self putTitleInNavBarByName:_file.fileName];
    
}

/*
 * Method that clean the preview
 */

- (void)cleanView{
    
    DLog(@"Clean view");
    
    //Clean the view
    //Hidden download elements
    _progressView.hidden = YES;
    _cancelButton.hidden = YES;
    _progressLabel.hidden = YES;
    _progressLabel.text = @"";
    _progressView.progress = 0.0;
    
    //Enable back button
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
    
    DLog(@"finish to clean view");
}

#pragma mark - Rotation Methods

-(void)potraitView{
    if (self.avMoviePlayer) {
        UIScreen *screen = [UIScreen mainScreen];
        CGSize screenSize = screen.bounds.size;
        
        if ([screen respondsToSelector:@selector(fixedCoordinateSpace)]) {
            screenSize = [screen.coordinateSpace convertRect:screen.bounds toCoordinateSpace:screen.fixedCoordinateSpace].size;
        }
        
        if (self.avMoviePlayer.isFullScreen) {
            self.avMoviePlayer.view.frame = CGRectMake(0,0, screenSize.width, (screenSize.height - _toolBar.frame.size.height - k_navigation_bar_height));
        } else {
            self.avMoviePlayer.view.frame = CGRectMake(0,0, screenSize.width, (screenSize.height - _toolBar.frame.size.height - k_status_bar_height - k_navigation_bar_height));
        }
    }
}

-(void)landscapeView{
    if (self.avMoviePlayer) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        CGSize screenSize = mainScreen.bounds.size;
        
        if ([mainScreen respondsToSelector:@selector(fixedCoordinateSpace)]) {
            screenSize = [mainScreen.coordinateSpace convertRect:mainScreen.bounds toCoordinateSpace:mainScreen.fixedCoordinateSpace].size;
        }
        
        NSInteger iPhoneCorrection = 0;
        
        if (IS_IPHONE_PLUS) {
            iPhoneCorrection = k_iphone_plus_correction;
        }
        
        if (self.avMoviePlayer.isFullScreen) {
            self.avMoviePlayer.view.frame = CGRectMake(0,0, screenSize.height, (screenSize.width - _toolBar.frame.size.height - k_navigation_bar_height_in_iphone_landscape - iPhoneCorrection));
        } else {
            self.avMoviePlayer.view.frame = CGRectMake(0,0, screenSize.height, (screenSize.width - _toolBar.frame.size.height - k_status_bar_height - k_navigation_bar_height_in_iphone_landscape - iPhoneCorrection));
        }
        
    }
}


-(void)configureView{

    [self putTheFavoriteStatus];
    
    if (IS_PORTRAIT) {
        [self potraitView];
    } else {
        [self landscapeView];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    if (_galleryView) {
        [_galleryView prepareScrollViewBeforeTheRotation];
    } else if (_readerPDFViewController) {
        [_readerPDFViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
 
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    if (_galleryView) {
        if (_galleryView.fullScreen) {
            CGRect frame = self.view.frame;           
            [_galleryView.scrollView setFrame:frame];
            _toolBar.hidden = YES;
        } else {
            CGRect frame = self.view.frame;
            [_galleryView.scrollView setFrame:frame];
            _toolBar.hidden = NO;
        }        
         [_galleryView adjustTheScrollViewAfterTheRotation];
    } else if (_readerPDFViewController) {
        [_readerPDFViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    } else if (_gifView) {
        
        CGRect frame = self.view.frame;
        frame.size.height = frame.size.height-(_toolBar.frame.size.height + self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height);
        frame.origin.y = self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
        self.gifView.frame = frame;
    } else if (_officeView) {
        CGRect frame = self.view.frame;
        _officeView.frame = frame;
        _toolBar.hidden = _officeView.isFullscreen;
    } else {
        _toolBar.hidden = NO;
    }
    
    if (toInterfaceOrientation  == UIInterfaceOrientationPortrait) {
        //Portrait
        [self potraitView];
    } else {
        //Landscape
        [self landscapeView];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (_readerPDFViewController) {
        [_readerPDFViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
    
    [self configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Handle file methods

- (void)handleFile {
    DLog(@"Handle file");
    /*Check the file
     *1.- Automatic download file
     *  1.1. Image file (gallery)
     *  1.2. Media file (audio, video)
     *  1.3. Office file (doc, xls, txt, docx...)
     *2.- Manual download file
     *  2.1. Other file types.
     */
    
    //Update the file
    self.file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if (_typeOfFile == imageFileType) {
        //black screen
        self.view.backgroundColor = [UIColor blackColor];
        [self performSelector:@selector(initGallery) withObject:nil afterDelay:0.1];
    } else {
        
        if (!self.file.isNecessaryUpdate) {
            [self previewFile];
        }
        
        DLog(@"ide file: %ld",(long)_file.idFile);
        DLog(@"is Donwloaded: %ld",(long)_file.isDownload);
        //Check if the file is in the device
        if (self.file.isDownload == notDownload) {
            if(!self.isForceDownload && self.typeOfFile == videoFileType && ([[CheckAccessToServer sharedManager] getSslStatus] != sslStatusSelfSigned)) {
                //Streaming video
                [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.5];
            } else {
                if (([[CheckAccessToServer sharedManager] getSslStatus] == sslStatusSelfSigned) && self.typeOfFile == videoFileType && !self.isForceDownload) {
                    [self showAlertView:NSLocalizedString(@"streaming_no_possible_ssl_self_signed", nil)];
                }
                //Download the file
                [self downloadTheFile];
            }
        } else if ((_file.isDownload == downloading) || (_file.isDownload == updating)) {
            //Continue the download
            if (_file.isDownload == updating) {
                //Preview the file
                if (_typeOfFile == videoFileType || _typeOfFile == audioFileType) {
                    [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.0];
                } else if (_typeOfFile == officeFileType) {
                    [self performSelectorOnMainThread:@selector(openFileOffice) withObject:nil waitUntilDone:YES];
                } else if (_typeOfFile == gifFileType) {
                    [self performSelectorOnMainThread:@selector(openGifFile) withObject:nil waitUntilDone:YES];
                } else {
                    [self cleanView];
                }
            }
            
            //Get download object
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            NSArray *downs = [appDelegate.downloadManager getDownloads];
            
            Download *download = nil;
            
            for (Download *temp in downs) {
                if ([temp.fileDto.localFolder isEqualToString:_file.localFolder]) {
                    download = temp;
                    break;
                }
            }
            
            
            if (download && download.downloadTask && download.downloadTask.state == NSURLSessionTaskStateRunning) {
                 [self contiueDownloadIfTheFileisDownloading];
            }else{
                 [self restartTheDownload];
            }
            
            
            
        } else {
            //If the file is downloaded
            //Check if there is a new version in server
            if (_file.isNecessaryUpdate) {
                //Download the new version of the file
                [self downloadTheFile];
            }

            //Preview the file
            if ((!_file.isFavorite)||(_file.isFavorite && !_file.isNecessaryUpdate)) {
                if (_typeOfFile == videoFileType || _typeOfFile == audioFileType) {
                    [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.0];
                } else if (_typeOfFile == officeFileType) {
                    [self performSelector:@selector(openFileOffice) withObject:nil afterDelay:0.1];
                } else if (_typeOfFile == gifFileType) {
                    [self performSelector:@selector(openGifFile) withObject:nil afterDelay:0.1];
                } else {
                    [self cleanView];
                }
            }
            
        }
    }
    if (_file.isFavorite && !_file.isNecessaryUpdate && _file.isDownload == downloaded) {
        [self performSelectorOnMainThread:@selector(checkIfThereIsANewFavoriteVersion) withObject:nil waitUntilDone:NO];
    }
    
    if (_typeOfFile == officeFileType || _typeOfFile == videoFileType || _typeOfFile == audioFileType) {
        [self setTypeOfLayoutExtendWithOption:0];
    } else {
        [self setTypeOfLayoutExtendWithOption:1];
    }
}


///-----------------------------------
/// @name checkIfThereIsANewFavoriteVersion
///-----------------------------------

/**
 * This method checks if there is on a favorite file a new version on the server
 */
- (void) checkIfThereIsANewFavoriteVersion {
    
    if (!self.manageFavorites) {
        self.manageFavorites = [ManageFavorites new];
        self.manageFavorites.delegate = self;
    }
    
    [self.manageFavorites thereIsANewVersionAvailableOfThisFile:self.file];
}

/*
 * Method that execute a image of type of file.
 */

- (void)previewFile {
    //Get the image preview name
    NSString *filePreviewName = [FileNameUtils getTheNameOfTheImagePreviewOfFileName:_file.fileName];
    _previewImageView.image = [UIImage imageNamed:filePreviewName];
    _previewImageView.hidden = NO;
}

/*
 * Method than call open with class
 */

- (void)openFile{
    
    //Openwith
    self.openWith = [[OpenWith alloc]init];
    self.openWith.parentView = self.view;
    self.openWith.parentButton = [self.toolBar.items objectAtIndex:0];
    [self.openWith openWithFile:self.file];
    

    
    //Enable back button
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
    
}


/*
 * Open a office file
 */
- (void)openFileOffice{
    
        NSString *ext = [FileNameUtils getExtension:_file.fileName];
        
        if ([ext isEqualToString:@"PDF"]) {
            
            _documentPDF = [ReaderDocument withDocumentFilePath:_file.localFolder password:@""];
            
            if (_documentPDF != nil) {
                _readerPDFViewController = [[ReaderViewController alloc] initWithReaderDocument:_documentPDF];
                
                CGRect frame = self.view.frame;
                frame.size.height = frame.size.height-_toolBar.frame.size.height;
                frame.origin.y = 0;
                
                [_readerPDFViewController.view setFrame:frame];
                
                [self.view addSubview:_readerPDFViewController.view];
                
            } else {
                DLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, _file.localFolder, @"");
            }
            
        } else {
            if (_file.localFolder != nil) {
                
                if (!_officeView) {
                    CGRect frame = self.view.frame;
                    frame.size.height = frame.size.height-_toolBar.frame.size.height;
                    frame.origin.y = 0;
                    _officeView=[[OfficeFileView alloc]initWithFrame:frame];
                    _officeView.delegate = self;
                }
                
                [_officeView openOfficeFileWithPath:_file.localFolder andFileName:_file.fileName];
                
                [self.view addSubview:_officeView];
                if (_file.isNecessaryUpdate) {
                    [self.view bringSubviewToFront:_updatingFileView];
                }
            }
        }
        
        //Enable back button
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        _toolBar.userInteractionEnabled = YES;

}

/*
 * Open a GIF file
 */

- (void) openGifFile {
    
    if (self.gifView){
        [self.gifView removeFromSuperview];
        self.gifView = nil;
    }
    
    self.gifView = [FLAnimatedImageView new];
    self.gifView.contentMode = UIViewContentModeScaleAspectFit;
    self.gifView.clipsToBounds = true;
    
    CGRect frame = self.view.frame;
    frame.size.height = frame.size.height-(_toolBar.frame.size.height + self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height);
    frame.origin.y = self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
    self.gifView.frame = frame;
    [self.view addSubview:self.gifView];
    
    NSData *gifData = [NSData dataWithContentsOfFile:_file.localFolder];
    
    if (gifData != nil) {
        FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
        self.gifView.animatedImage = gifImage;
    }
    
    //Enable back button
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
}

#pragma mark - Loading Methods

/*
 * Add loading screen and block the view
 */

-(void)initLoading {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud bringSubviewToFront:self.view];
    
    hud.labelText = NSLocalizedString(@"loading", nil);    
    hud.dimBackground = NO;
    
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}

/*
 * Remove loading screen and unblock the view
 */ 
- (void)endLoading {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}

#pragma mark - Gallery Methods

/*
 * Open the gallery image
 */
- (void)initGallery{
    //Quit the gallery view
    if (_galleryView) {
        [_galleryView.scrollView removeFromSuperview];
        _galleryView = nil;
    }    

    if (!_galleryView) {
        CGRect frame = self.view.frame;
        
        frame.size.height = frame.size.height-_toolBar.frame.size.height;
        
        DLog(@"Scroll view width: %f and height: %f", frame.size.width, frame.size.height);
        _galleryView = [[GalleryView alloc]initWithFrame:frame];
        //Pass the current file
        _galleryView.file = _file;
        _galleryView.delegate = self;
        //Init the array of images with the array of files (sort files of file list)
        [_galleryView initArrayOfImagesWithArrayOfFiles:_sortedArray];
        //Init the main scroll view of gallery
        [_galleryView initScrollView];
        //Run the gallery
        [_galleryView initGallery];
    }
    //Add Gallery to the preview
    [self.view addSubview:_galleryView.scrollView];
    
    //Put the toolBar and the labels in front of gallery view
    [self.view bringSubviewToFront:_toolBar];
    
    //Enable user interaction
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
}

#pragma mark - Gallery View Delegate Methods

/*
 * Delegate method that change the file selected from gallery
 */
- (void)selectThisFile:(FileDto*)file{
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSString *nextFile = [UtilsUrls getFullRemoteServerFilePathByFile:file andUser:app.activeUser];
    NSString *fileInGallery = [UtilsUrls getFullRemoteServerFilePathByFile:self.file andUser:app.activeUser];
    //If file is not the same that the previewed file, change the title
    if (![fileInGallery isEqualToString:nextFile]) {
        self.file = file;
        [self putTitleInNavBarByName:self.file.fileName];
        [self putTheFavoriteStatus];
    }
}

/*
 * Delegate method that change the fullScreen view mode from gallery
 */

- (void)setFullScreenGallery:(BOOL)isFullScreen{
    if (isFullScreen) {
        _galleryView.scrollView.frame = self.view.frame;
        
        //Hide the toolBar and the navigationBar with animation
        [self hideBars];
    } else {
        CGRect scrollFrame = self.view.frame;
        scrollFrame.size.height = scrollFrame.size.height-_toolBar.frame.size.height;
         _galleryView.scrollView.frame = scrollFrame;

        //Show the toolBar and the navigationBar with animation
        [self showBars];
    }   
}

///-----------------------------------
/// @name Hide the bars in the preview view
///-----------------------------------

/**
 * This method hides the bars located in the preview view:
 * navigationBar and toolBar, with an slide animation
 */
-(void) hideBars{
    //Set the position and the size of the tollBar
    _toolBar.frame = CGRectMake(0, self.view.frame.size.height-_toolBar.frame.size.height, self.view.frame.size.width, _toolBar.frame.size.height);
    //Set the animation of the bar
    [UIView animateWithDuration:0.2 animations:^{
        //Set the new position of the navigationBar
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        //Hide the backgroundview in nav bar
        OCNavigationController *nc = (OCNavigationController*)self.navigationController;
        [nc manageBackgroundView:YES];
        //Set the new position of the tollBar
        _toolBar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, _toolBar.frame.size.height);
    }];
}



///-----------------------------------
/// @name Show the bars in the preview view
///-----------------------------------

/**
 * This method shows the bars located in the preview view:
 * navigationBar and toolBar, with an slide animation
 */
-(void)showBars{
    //Set the position and the size of the toolBar
    _toolBar.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.view.frame.size.width, _toolBar.frame.size.height);
    //Set the animation of the bar
    
    [UIView animateWithDuration:0.2 animations:^{
        //Set the new position of the navigationBar
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        //Add the backgroundview in nav bar
        OCNavigationController *nc = (OCNavigationController*)self.navigationController;
        [nc manageBackgroundView:NO];
        //Set the new position of the toolBar
        _toolBar.frame = CGRectMake(0, self.view.frame.size.height-_toolBar.frame.size.height, self.view.frame.size.width, _toolBar.frame.size.height);
        [self.view bringSubviewToFront:_toolBar];
    } completion:^(BOOL finished){
        //When the animation finish, show the labels in the tollBar
        _toolBar.hidden = NO;
    }];

}



///-----------------------------------
/// @name Hide the status bar
///-----------------------------------

/**
 * Method that hiding the status bar in full screen mode in images and videos
 *
 * @return YES in images or video for hide the status bar; NO in the rest of the cases
 *
 */
- (BOOL)prefersStatusBarHidden {
    if (_galleryView.fullScreen) {
        return YES;
    } else {
        return NO;
    }
}

///-----------------------------------
/// @name Hide the status bar with animation
///-----------------------------------

/**
 * Method that set the animation for hide the status bar
 *
 * @return the type of the animation
 *
 */
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - Media player methods

/*
 * Launch the player for video and audio
 */

- (void)playMediaFile{
    
    //Know if mediaplayer is used
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    BOOL isNewMediaPlayer = YES;
    
    if (appDelegate.avMoviePlayer != nil) {
        
        //Know if the last media file played
        if ([appDelegate.avMoviePlayer.urlString isEqualToString:_file.localFolder]) {
            isNewMediaPlayer = NO;
        } else {
            [appDelegate.avMoviePlayer.contentOverlayView removeObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen]];
            [appDelegate.avMoviePlayer.player pause];
            appDelegate.avMoviePlayer.player = nil;
            [appDelegate.avMoviePlayer.view removeFromSuperview];
             appDelegate.avMoviePlayer = nil;
            isNewMediaPlayer = YES;
        }
    } else {
        isNewMediaPlayer = YES;
    }
    
    
    if (isNewMediaPlayer == NO) {
        
        self.avMoviePlayer = appDelegate.avMoviePlayer;
        [self.view addSubview: self.avMoviePlayer.view];
        
        [self configureView];
        
    } else {
        //If is audio file create a AVAudioSession objetct to enable the music in background
        if (_typeOfFile == audioFileType) {
            NSError *activationError = nil;
            AVAudioSession *mySession = [AVAudioSession sharedInstance];
            [mySession setCategory: AVAudioSessionCategoryPlayback error: &activationError];
            if (activationError) {
                DLog(@"AVAudioSession activation error: %@", activationError);
            }
            [mySession setActive: YES error: &activationError];
            if (activationError){
                DLog(@"AVAudioSession activation error: %@", activationError);
            }
        }
        
        AVPlayer *player;
        
        if (self.file.isDownload) {
            
            NSURL *url = [NSURL fileURLWithPath:_file.localFolder];
            player = [AVPlayer playerWithURL:url];
            
        } else {
            
            //FileName full path
            NSString *path = [UtilsUrls  getFullRemoteServerFilePathByFile:self.file andUser:APP_DELEGATE.activeUser];
            
            self.asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:path] options:@{@"AVURLAssetHTTPHeaderFieldsKey" : [UtilsNetworkRequest getHttpLoginHeaders]}];
            [self.asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
    
            player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        }
                
        // create a player view controller
        self.avMoviePlayer = [[MediaAVPlayerViewController alloc]init];
        
        self.avMoviePlayer.player = player;
        [player play];
        
        // show the view controller
        [self addChildViewController:self.avMoviePlayer];
        [self.view addSubview:self.avMoviePlayer.view];
        self.avMoviePlayer.view.frame = self.view.frame;
        
        [self.avMoviePlayer.contentOverlayView addObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        
        [self configureView];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context {
    if (object == self.avMoviePlayer.contentOverlayView) {
        if ([keyPath isEqualToString:[MediaAVPlayerViewController observerKeyFullScreen]]) {
            CGRect oldBounds = [change[NSKeyValueChangeOldKey] CGRectValue], newBounds = [change[NSKeyValueChangeNewKey] CGRectValue];
            BOOL wasFullscreen = CGRectEqualToRect(oldBounds, [UIScreen mainScreen].bounds), isFullscreen = CGRectEqualToRect(newBounds, [UIScreen mainScreen].bounds);
            if (isFullscreen && !wasFullscreen) {
                if (CGRectEqualToRect(oldBounds, CGRectMake(0, 0, newBounds.size.height, newBounds.size.width))) {
                    DLog(@"rotated fullscreen");
                    self.avMoviePlayer.isFullScreen = YES;
                } else {
                    DLog(@"entered fullscreen");
                    self.avMoviePlayer.isFullScreen = YES;
                }
            } else if (!isFullscreen && wasFullscreen) {
                DLog(@"exited fullscreen");
                self.avMoviePlayer.isFullScreen = NO;
            }
        }
    }
}

#pragma mark - Media player delegate methods

/*
 * Delegate method of media player that receive when the user tap the full screen button
 * @isFullScreenPlayer -> Boolean variable that indicate if the user tap over the fullscreen button
 */
- (void)fullScreenPlayer:(BOOL)isFullScreenPlayer{
    //Hide the backgroundview in nav bar
    OCNavigationController *nc = (OCNavigationController*)self.navigationController;
    
    if (isFullScreenPlayer) {
       
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [_toolBar setHidden:YES];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
         [nc manageBackgroundView:YES];
        [self configureView];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [_toolBar setHidden:NO];
         [nc manageBackgroundView:NO];
        [self configureView];
    }
}

#pragma mark - OfficeFileView Delegate Methods
- (void)setFullscreenOfficeFileView:(BOOL)isFullscreen {
    if (isFullscreen) {
        CGRect frame = self.view.bounds;
        CGFloat statusBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
        frame.origin.y = statusBarHeight;
        frame.size.height = UIScreen.mainScreen.bounds.size.height - statusBarHeight;

        _officeView.frame = frame;
        //Hide the toolBar and the navigationBar with animation
        [self hideBars];
    } else {
        CGRect frame = self.view.bounds;
        frame.size.height = frame.size.height-_toolBar.frame.size.height;
        _officeView.frame = frame;

        //Show the toolBar and the navigationBar with animation
        [self showBars];
    }
}



#pragma mark - Actions

/*
 * Action button. Open With option
 */
- (IBAction)didPressOpenWithButton:(id)sender {
    DLog(@"didPressOpenWithButton");
    
    //Update the file previewed
    _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
    
    if (!_isDownloading && (_file.isDownload != -1)) {
        //Update the file previewed
        _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
        
        if(_file.isDownload) {
            //This file is in the device
            DLog(@"The file is in the device");
            //Phase 2. Open the file with "Open with" class
            [self openFile];
        } else  if([[CheckAccessToServer sharedManager] isNetworkIsReachable]) {
            //Phase 1. Check if this file is in the device
            if ([_file isDownload] == notDownload) {
                //File is not in the device
                //Phase 1.1. Download the file
                DLog(@"Download the file");
                Download *download = [[Download alloc]init];
                download.delegate = self;
                download.currentLocalFolder = _currentLocalFolder;
                
                //View progress view and button
                _progressView.hidden = NO;
                _cancelButton.hidden = NO;
                _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
                _progressLabel.hidden = NO;
                
                //Block the toolBar
                [_toolBar setUserInteractionEnabled:NO];
                
                [download fileToDownload:_file];
                _isDownloading = YES;
            }
        }  else {
            [self downloadFailed:NSLocalizedString(@"not_possible_connect_to_server", nil)andFile:nil];
        }
    }
}

- (IBAction)didPressShareLinkButton:(id)sender
{
    
    DLog(@"Share Link Option");
    self.file = [ManageFilesDB getFileDtoByIdFile:self.file.idFile];
    ShareMainViewController *share = [[ShareMainViewController alloc] initWithFileDto:self.file];
    
    OCNavigationController *nav = [[OCNavigationController alloc] initWithRootViewController:share];
    
    if (IS_IPHONE) {
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:nav animated:YES completion:nil];
    }
    
}

/*
 * Method that launch the favorite options
 */
- (IBAction)didPressFavoritesButton:(id)sender {
    //Update the file from the DB
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if ([DownloadUtils isSonOfFavoriteFolder:self.file]) {
        [self showErrorMessageIfNotIsShowingWithString:NSLocalizedString(@"parent_folder_is_available_offline_file_child", nil)];
    } else {
        if (_file.isFavorite) {
            _file.isFavorite = NO;
            //Change the image to unstarred
            _favoriteButtonBar.image = [UIImage imageNamed:@"available_offline_TB"];
        } else {
            _file.isFavorite = YES;
            _isCancelDownloadClicked = NO;
            //Change the image to starred
            _favoriteButtonBar.image = [UIImage imageNamed:@"available_offline_TB-filled"];
            //Download the file if it's not downloaded and not pending to be download
            [self downloadTheFileIfIsnotDownloadingInOtherProcess];
        }
        
        //Update the DB
        [ManageFilesDB updateTheFileID:_file.idFile asFavorite:_file.isFavorite];
        [app.presentFilesViewController reloadTableFromDataBase];
        
        if (_file.isFavorite && _file.isDownload == downloaded) {
            [self checkIfThereIsANewFavoriteVersion];
        }
    }
}

//-----------------------------------
/// @name Download the file if is not downloading
///-----------------------------------

/**
 * We have this method to download the file after a few seconds in order to prevent download the file twice
 *
 */
- (void) downloadTheFileIfIsnotDownloadingInOtherProcess {
    
    if (!_isCancelDownloadClicked) {
        if (_file.isDownload == notDownload) {
            [self downloadTheFile];
        }
    }
}

/*
 * Action button. Delete file option
 */

- (IBAction)didPressDeleteButton:(id)sender {
    DLog(@"DidpressDeleteButton");
  
     if (!_isDownloading) {
        
        _mDeleteFile = [[DeleteFile alloc] init];
        _mDeleteFile.delegate = self;
        _mDeleteFile.viewToShow = self.view;
        _mDeleteFile.deleteFromFilePreview = YES;
         
         //Update the file
         _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
         
         [_mDeleteFile askToDeleteFileByFileDto:_file];
    }    
}

/*
 * Action button. Cancel the current download in progress
 */
- (IBAction)didPressCancelButton:(id)sender{
    DLog(@"didPressCancelButton");
    
    if (_isDownloading) {
        
        _isCancelDownloadClicked = YES;
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *downs = [appDelegate.downloadManager getDownloads];
        
        Download *download;
        
        for (download in downs) {
            if (download.fileDto.idFile == _file.idFile) {
                [download cancelDownload];
                _isDownloading = NO;
            }
        }
        
        //Update fileDto
        _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
        
        //Hidden download elements
        _progressView.hidden = YES;
        _cancelButton.hidden = YES;
        _progressLabel.hidden = YES;
        _progressLabel.text = @"";
        _progressView.progress = 0.0;
        
        //Enable back button
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        _toolBar.userInteractionEnabled = YES;
    }
}


///-----------------------------------
/// @name Action of updating cancel button
///-----------------------------------

/**
 * This method handle the updating cancel button
 *
 * @param sender
 */
- (IBAction)didPressUpdatingCancelButton:(id)sender {
    DLog(@"didPressUpdatingCancelButton");
    
    if (_isDownloading) {
        //Cancel the download
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        //Copy of the original array
        NSArray *downs = [NSArray arrayWithArray:[appDelegate.downloadManager getDownloads]];
        Download *download;
        
        for (download in downs) {
            if (download.fileDto.idFile == _file.idFile) {
                [download cancelDownload];
                _isDownloading = NO;
            }
        }
        //Stop the notification
        [self stopNotificationUpdatingFile];
        
        //Update that the file is downloaded
        [ManageFilesDB setFileIsDownloadState:_file.idFile andState:downloaded];
        _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
    }
}


#pragma mark - Delegate methods
/*
 * Delegate method of DeleteFile that indicate to close this view
 */
- (void)reloadTableFromDataBase
{   
    NSInteger noOfViewControllers = [self.navigationController.viewControllers count];
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:(noOfViewControllers-2)] animated:YES];
}

#pragma mark - DeleteFileDelegate

//-----------------------------------
/// @name removeSelectedIndexPath
///-----------------------------------

/**
 * Method to remove the selectedPath after delete the file localy
 *
 */

- (void) removeSelectedIndexPath {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.presentFilesViewController.selectedIndexPath = nil;
}

#pragma mark - Download Methods.

///-----------------------------------
/// @name Restart the download
///-----------------------------------

/**
 * This method restart the download of the current file
 *
 */
- (void) restartTheDownload{
    
    if (([_file isDownload] == downloading) || ([_file isDownload] == updating)){
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *downs = [appDelegate.downloadManager getDownloads];
        
        Download *tempDown;
        BOOL downloadIsInProgress = NO;
        //Check if the download is in progress
        for (tempDown in downs) {
            if (tempDown.fileDto.idFile == _file.idFile) {
                tempDown.delegate = self;
                downloadIsInProgress = YES;
                break;
            }
        }
        
        if (downloadIsInProgress) {
            
            if (!k_is_sso_active) {
                
                if (_file.isNecessaryUpdate) {
                    [self putUpdateProgressInNavBar];
                } else {
                    //View progress view and button
                    _progressView.hidden = NO;
                    _cancelButton.hidden = NO;
                    _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
                    _progressLabel.hidden = NO;
                }
                _isDownloading = YES;
                [tempDown fileToDownload:_file];
                
            }else{
                _isDownloading = YES;
                [self didPressCancelButton:nil];
                [self downloadTheFile];
            }
        }
        
    }
}

/*
 * Method that continue the download if is in progress or download again if the 
 * file is in the downloading database state
 */
- (void)contiueDownloadIfTheFileisDownloading {
    
    if (([_file isDownload] == downloading) || ([_file isDownload] == updating)){
        //Find the download in download global array
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *downs = [appDelegate.downloadManager getDownloads];
        
        Download *tempDown;
        BOOL downloadIsInProgress = NO;
        //Check if the download is in progress
        for (tempDown in downs) {           
            
            if ([tempDown.fileDto.localFolder isEqualToString: _file.localFolder]) {
                tempDown.fileDto = _file;
                tempDown.delegate = self;
                downloadIsInProgress = YES;
                break;
            }
        }
        if (!downloadIsInProgress) {
            //If the download not is in progress, download again
            
            //Set file like a not download and download again    
            [ManageFilesDB setFileIsDownloadState:_file.idFile andState:notDownload];
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
            
            [self downloadTheFile];
        } else {
            if ([_file isDownload] == updating) {
                [self putUpdateProgressInNavBar];
            } else {
                //If the download is in progress update de screen objects
                _progressView.hidden = NO;
                
                if (_progressView.progress == 0.0) {
                    _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
                }
                _cancelButton.hidden = NO;
                _progressLabel.hidden = NO;
                
            }
        }
        //Set downloading flag for the interface
        _isDownloading = YES;
    }
}

/*
 * This method prepare the download manager to download a selected file
 */
- (void)downloadTheFile{
    if ([_file isDownload] == notDownload || _file.isNecessaryUpdate) {
        //Phase 1.2. If the image isn't in the device, download image
        DLog(@"The file is not download");
        Download *download = nil;
        download = [[Download alloc]init];
        download.delegate = self;
        download.currentLocalFolder = _currentLocalFolder;
        if (_file.isNecessaryUpdate) {
            [self putUpdateProgressInNavBar];
        } else {
            //View progress view and button
            _progressView.hidden = NO;
            _cancelButton.hidden = NO;
            _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
            _progressLabel.hidden = NO;
        }
        _isDownloading = YES;
        [download fileToDownload:_file];
    }
}






#pragma mark - Download delegate methods

/*
 * This method receive the download progress and set valor to progressView.
 */

- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{    
    if (_file.isNecessaryUpdate) {
        _updatingFileProgressView.progress = percent;
    } else {
        _progressView.progress = percent;
    }
}

- (void) hiddenButtonsAfterDownload{
    [self stopNotificationUpdatingFile];
    
    _progressView.hidden = YES;
    _progressLabel.hidden = YES;
    
    //Enable back button
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
}


/*
 * This method tell this class to de file is in device
 */
- (void)downloadCompleted:(FileDto*)fileDto{
    DLog(@"Hey, file is in device, go to preview");

    _cancelButton.hidden = YES;
    _updatingCancelButton.userInteractionEnabled = NO;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update fileDto    
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if (_file.idFile == fileDto.idFile) {
        
        //Quit the player if exist
        if (app.avMoviePlayer) {
            [app.avMoviePlayer.contentOverlayView removeObserver:self forKeyPath:[MediaAVPlayerViewController observerKeyFullScreen]];
            [app.avMoviePlayer.player pause];
            app.avMoviePlayer.player = nil;
            [app.avMoviePlayer.view removeFromSuperview];
            app.avMoviePlayer = nil;
        }
        
        if(_typeOfFile == officeFileType) {
            [self performSelector:@selector(openFileOffice) withObject:nil afterDelay:0.5];
        } else if(_typeOfFile == audioFileType) {
            [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.5];
        } else if(_typeOfFile == videoFileType) {
            [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.5];
        } else if (_typeOfFile == gifFileType) {
            [self performSelector:@selector(openGifFile) withObject:nil afterDelay:0.5];
        } else if (_typeOfFile == imageFileType){
            DLog(@"Image file");
        } else {
            [self performSelector:@selector(openFile) withObject:nil afterDelay:0.5];
        }
        [self performSelector:@selector(hiddenButtonsAfterDownload) withObject:nil afterDelay:0.6];
    }
    
    _isDownloading = NO;
}


/*
 * This method tell this class that exist an error and the file doesn't down to the device
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    _isDownloading = NO;
    [self cleanView];
    
    //Enable interaction view
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    _toolBar.userInteractionEnabled = YES;
    
    if(string) {
        [self showErrorMessageIfNotIsShowingWithString:string];
        [self stopNotificationUpdatingFile];
    }
}

- (void) showErrorMessageIfNotIsShowingWithString:(NSString *)string{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!app.downloadErrorAlertView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            app.downloadErrorAlertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            app.downloadErrorAlertView.tag = k_alertview_for_download_error;
            [app.downloadErrorAlertView show];
        });
    }
}

- (void)showNotConnectionWithServerMessage{
    
    [self showErrorMessageIfNotIsShowingWithString:NSLocalizedString(@"not_possible_connect_to_server", nil)];
}

/*
 * This method receive the string of download progress
 */
- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
    if (_file.isNecessaryUpdate) {
        
    } else {
        [_progressLabel setText:string];
    }
}

///-----------------------------------
/// @name Update or Cancel the download file
///-----------------------------------

/**
 * This method is called when the download is updating a file
 * and the file has 0 bytes
 *
 * @param download -> id (dynamic type, really is Download class)
 */
- (void)updateOrCancelTheDownload:(id)download {
    
    Download *updatingDownload = (Download*)download;
    
    //UIAlertView with blocks
    [UIAlertView showWithTitle:NSLocalizedString(@"msg_update_file_0_bytes", nil) message:@"" cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"accept", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == [alertView cancelButtonIndex]) {
            //Cancel
            [updatingDownload cancelDownload];
            [self stopNotificationUpdatingFile];
        
        } else {
            //Update
            [updatingDownload updateDataDownload];
        }
        
    }];
   
}


#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (alertView.tag) {
        case k_alertview_for_download_error: {
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            app.downloadErrorAlertView = nil;
            
            break;
        }
        default:
            break;
    }
}

- (void) showAlertView:(NSString*)string{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - Error login delegate method

- (void) errorLogin {
    
    if (_updatingFileView) {
        [self stopNotificationUpdatingFile];
    }
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.downloadManager errorLogin];
    
    if(k_is_oauth_active) {
        NSURL *url = [NSURL URLWithString:k_oauth_login];
        [[UIApplication sharedApplication] openURL:url];
    } else {
        //Edit Account
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser andLoginMode:LoginModeExpire];
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];

    }
    [self didPressCancelButton:nil];
}

#pragma mark - Notifications methods

/*
 * This method addObservers for notifications to this class.
 * The notifications added in viewDidLoad
 */

- (void) setNotificationForCommunicationBetweenViews {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePreviewOverwriteFile:) name:PreviewFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePreviewFileWithNewIDFromDB:) name:UploadOverwriteFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanView) name:iPhoneCleanPreviewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotConnectionWithServerMessage) name:iPhoneShowNotConnectionWithServerMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissThisView) name:IPhoneDoneEditFileTextMessageNotification object:nil];
}


/*
 *Method that checks if the preview file is the same that the file that is contained in the notification object and updates the preview file view if the overwrite file was previewed
*/
-(void)updatePreviewOverwriteFile:(NSNotification *)notification{
    DLog(@"Update the previewed file with the overwritten one");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update the _file with DB
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    NSString *path = (NSString*)[notification object];
    NSString *pathPreview = [UtilsUrls getFullRemoteServerFilePathByFile:self.file andUser:app.activeUser];
    if ([path isEqualToString:pathPreview]) {
        DLog(@"The file is the same, update the preview");
        _file.isDownload = downloaded;
        [self handleFile];
    }
    DLog(@"id file: %ld",(long)_file.idFile);
}

/*
 *Method that update the preview file with the correct id from DB
 */
-(void)updatePreviewFileWithNewIDFromDB:(NSNotification *)notification {
    DLog(@"updatePreviewFileWithNewIDFromDB");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //Update the preview file with the new information in DB
    _file=[ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    app.isOverwriteProcess = NO;
}

#pragma mark - ManageFavoritesDelegate

- (void) fileHaveNewVersion:(BOOL)isNewVersionAvailable {
    
    if(isNewVersionAvailable) {
        
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        //Set if there is a new version of a favorite file and it's not checked
        
        //Set the file as isNecessaryUpdate
        [ManageFilesDB setIsNecessaryUpdateOfTheFile:_file.idFile];
        //Update the file on memory
        _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
        //Do the request to get the shared items
        [self handleFile];
    }
    
}


#pragma mark - dismiss notification

-(void) dismissThisView {
    [self cleanView];
    NSArray *allViewControllers = [self.navigationController viewControllers];
    for (UIViewController *aViewController in allViewControllers) {
        if ([aViewController isKindOfClass:[FilesViewController class]]) {
            [self.navigationController popToViewController:aViewController animated:NO];
        }
    }
}

@end
