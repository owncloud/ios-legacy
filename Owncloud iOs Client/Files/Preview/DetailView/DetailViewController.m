//
//  DetailViewController.m
//  MGSplitView
//
//  Created by Gonzalo Gonzalez on 10/11/2012.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DetailViewController.h"

#import "AppDelegate.h"
#import "UIColor+Constants.h"
#import "constants.h"
#import "EditAccountViewController.h"
#import "UtilsDtos.h"
#import "UIImage+Resize.h"
#import "FileNameUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Customization.h"
#import "ManageFilesDB.h"
#import "FilesViewController.h"
#import "UploadUtils.h"
#import "OCNavigationController.h"
#import "UIAlertView+Blocks.h"
#import "ShareFileOrFolder.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "ManageFavorites.h"
#import "SettingsViewController.h"
#import "UtilsUrls.h"
#import "ReaderDocument.h"
#import "ReaderViewController.h"
#import "OCSplitViewController.h"


NSString * IpadFilePreviewViewControllerFileWasDeletedNotification = @"IpadFilePreviewViewControllerFileWasDeletedNotification";
NSString * IpadFilePreviewViewControllerFileWasDownloadNotification = @"IpadFilePreviewViewControllerFileWasDownloadNotification";
NSString * IpadFilePreviewViewControllerFileWhileDonwloadingNotification = @"IpadFilePreviewViewControllerFileWhileDonwloadingNotification";
NSString * IpadFilePreviewViewControllerFileFinishDownloadNotification = @"IpadFilePreviewViewControllerFileFinishDownloadNotification";
NSString * IpadSelectRowInFileListNotification = @"IpadSelectRowInFileListNotification";
NSString * IpadCleanPreviewNotification = @"IpadCleanPreviewNotification";
NSString * IpadShowNotConnectionWithServerMessageNotification = @"IpadShowNotConnectionWithServerMessageNotification";

#define k_delta_width_for_split_transition 320.0
#define k_delta_height_toolBar_split_transition 64.0

@interface DetailViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

- (void)configureView;

@end


@implementation DetailViewController

@synthesize  toolbar;


#pragma mark - Load view methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Enable toolBar
    [toolbar setUserInteractionEnabled:YES];
    
    //Init global atributes
    _progressView.progress = 0.0;
    _progressView.hidden = YES;
    _cancelButton.hidden = YES;
    _progressLabel.hidden = YES;
    _previewImageView.hidden = YES;
    _isDownloading = NO;
    _isViewBlocked = NO;
    self.isSizeChanging = NO;
    _isFileCharged = NO;
    _isOverwritedFile = NO;
    _isUpdatingFile = NO;
    self.hideMaster = NO;
    _controllerManager = noManagerController;
    
    //Init notificacion in status bar
    _notification = [CWStatusBarNotification new];
    _updatingFileView.hidden = YES;
   
    //MainScroll View autoresizing
    [_mainScrollView setTranslatesAutoresizingMaskIntoConstraints:YES];
   
    self.edgesForExtendedLayout = UIRectCornerAllCorners;
    
    //Bar items. Set buttons
    [_openButtonBar setImageInsets:UIEdgeInsetsMake(10, 0, -10, 0)];
    [_favoriteButtonBar setImageInsets:UIEdgeInsetsMake(10, 0, -10, 0)];
    [_shareLinkButtonBar setImageInsets:UIEdgeInsetsMake(10, 0, -10, 0)];
    [_deleteButtonBar setImageInsets:UIEdgeInsetsMake(10, 0, -10, 0)];
    
    //Set Constraints
    _topMarginTitleLabelConstraint.constant = 32;
    _progressViewHeightConstraint.constant = 2;
    _fileTypeCenterHeightConstraint.constant = -40;
    

    //Set title and the font of the label of the toolBar
    [_titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [_titleLabel setText:@""];
    
    //Set color of background
    self.view.backgroundColor = [UIColor colorOfBackgroundDetailViewiPad];
    
    //Set notifications for communication betweenViews
    [self setNotificationForCommunicationBetweenViews];
    
    //Add gesture for the full screen support
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchTransitionProcessForFullScreen)];
    self.singleTap.numberOfTapsRequired = 1;
    self.singleTap.numberOfTouchesRequired = 1;
    self.singleTap.delegate = self;
    
    [self.splitViewController setPresentsWithGesture:NO];
    
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _isViewBlocked = NO;
    _isCancelDownloadClicked = NO;
    //Configure view
    [self configureView];
}


- (void)configureView
{
    DLog(@"Detail Configure view");
    
    //TitleLabel
    if (_file) {
        [_titleLabel setText:[_file.fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]];
    } else if (_isFileCharged==NO && _file==nil){
        [_titleLabel setText:_linkTitle];
    } else {
        [_titleLabel setText:@""];
    }
    
    //Favorite
    [self putTheFavoriteStatus];
    
    NSMutableArray *items = [NSMutableArray new];
    [items insertObject:_spaceBar atIndex:0];
    
    if (self.isFileCharged ) {
        [items insertObject:_openButtonBar atIndex:1];
        [items insertObject:_spaceBar1 atIndex:2];
        [items insertObject:_favoriteButtonBar atIndex:3];
        [items insertObject:_spaceBar2 atIndex:4];
        
        if (k_hide_share_options) {
             [items insertObject:_deleteButtonBar atIndex:5];
        }else{
            [items insertObject:_shareLinkButtonBar atIndex:5];
            [items insertObject:_spaceBar3 atIndex:6];
            [items insertObject:_deleteButtonBar atIndex:7];
        }
        
        
    }
    [toolbar setItems:items animated:YES];
    
}

- (CGRect) getTheCorrectSize{
    
    CGRect originFrame = self.mainScrollView.frame;
    CGRect sizeFrame = self.view.bounds;
    
    CGRect correctFrame = CGRectMake(originFrame.origin.x, originFrame.origin.y, sizeFrame.size.width, (sizeFrame.size.height - originFrame.origin.y));
    
    return correctFrame;
}

#pragma mark - Handle file methods

///-----------------------------------
/// @name Handle File
///-----------------------------------

/**
 * This method is the main of the class to handle a file and send this to the 
 * correct controller
 *
 * @param myFile -> FileDto
 * @param controller -> enum type
 */
- (void) handleFile:(FileDto*)myFile fromController:(NSInteger)controller {
    DLog(@"HandleFile _file.fileName: %@", _file.fileName);
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Control if managedcontroller is not select
    if (_controllerManager == noManagerController) {
        _controllerManager = controller;
    }
    
    //The file came from other view
    if (_controllerManager != controller) {
        _controllerManager = controller;
        _file = nil;
    } else {
        _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    }
    
    //Get the current local folder
    _currentLocalFolder = [NSString stringWithFormat:@"%@%ld/%@", [UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:myFile.filePath andUser:app.activeUser]];
    _currentLocalFolder = [_currentLocalFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    //Quit the title
    _linkTitle=@"";
    
    //Obtain the type of file
    _typeOfFile = [FileNameUtils checkTheTypeOfFile:myFile.fileName];
    
    
    if ([self isTheSameFile:myFile]) {
        [self manageTheSameFileOnThePreview];
    } else {
        //Stop the notification
        [self stopNotificationUpdatingFile];
        //Put the title in the toolBar
        [_titleLabel setText:[_file.fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]];
        _isViewBlocked = NO;
        
        //Remove the views
        [self removeThePreviousViews];
        
        //Interface attributes for progress download info
        _progressLabel.text = @"";
        _progressView.progress = 0.0;
        _updatingFileProgressView.progress = 0.0;
        
        [self manageDistinctFileOnPreview];
    }
    
    //Set if there is a new version of a favorite file and it's not checked
    if (_file.isFavorite && !_file.isNecessaryUpdate && _file.isDownload == downloaded) {
        [self checkIfThereIsANewFavoriteVersion];
    }
}


///-----------------------------------
/// @name Is the same file
///-----------------------------------

/**
 * This method checks if the file is the same that the previewed
 *
 * @param FileDto > myFile, the file for check
 *
 * @return BOOL > YES, if it is the same file
 * @return BOOL > NO, if it is a different one
 */
- (BOOL) isTheSameFile: (FileDto*)myFile {
    //Check if the file is the same file
    BOOL isTheSameFile = NO;
    
    if (_file && !_isOverwritedFile) {
        if ([_file.localFolder isEqualToString: myFile.localFolder]) {
            //Check if the file is downloaded or not
            if (_file.isDownload == downloaded || _file.isDownload == updating || _file.isDownload == downloading)
                isTheSameFile = YES;
        } else {
            _file=myFile;
            isTheSameFile = NO;
        }
    } else {
        _file=myFile;
        isTheSameFile = NO;
        _isOverwritedFile = NO;
    }
    return isTheSameFile;
}


///-----------------------------------
/// @name manageTheSameFileOnThePreview
///-----------------------------------

/**
 * This method manages the file on the preview when the user taps on the same file which is previewed on the iPad view
 */
- (void) manageTheSameFileOnThePreview {
    
    //If the file is download and pending to be updated
    if (_file.isNecessaryUpdate && _file.isDownload == downloaded) {
        if (_typeOfFile != imageFileType) {
            //Update the file
            [self downloadTheFile];
        } else {
            [self openGalleryFileOnUpdatingProcess:YES];
        }
    } else if (_isUpdatingFile && _typeOfFile == imageFileType) {
        [self openGalleryFileOnUpdatingProcess:NO];
    }
}


///-----------------------------------
/// @name manageDistinctFileOnPreview
///-----------------------------------

/**
 * This method manages the file on the preview when the user taps on a distinct file that is previewed on the iPad view
 */
- (void) manageDistinctFileOnPreview {
    /*Check the file
     *1.- Automatic download file
     *  1.1. Image file (gallery)
     *  1.2. Media file (audio, video)
     *  1.3. Office file (doc, xls, txt, docx...)
     *2.- Manual download file
     *  2.1. Other file types.
     */
    
    if (_typeOfFile == imageFileType) {
        if (_file.isNecessaryUpdate) {
            _isUpdatingFile = YES;
        }
        [self initGallery];
    } else {
        
        [self previewFile];
        _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
        DLog(@"ide file: %ld",(long)_file.idFile);
        
        //Check if the file is in the device
        if (([_file isDownload] == notDownload) && _typeOfFile != otherFileType) {
            //Download the file
            [self downloadTheFile];
        } else if (([_file isDownload] == downloading) || ([_file isDownload] == updating)) {
            
            if ([_file isDownload] == updating) {
                //Preview the file if the file is on an updating process
                if (_typeOfFile == videoFileType || _typeOfFile == audioFileType) {
                    [self performSelectorOnMainThread:@selector(playMediaFile) withObject:nil waitUntilDone:YES];
                } else if (_typeOfFile == officeFileType) {
                    [self performSelectorOnMainThread:@selector(openFileOffice) withObject:nil waitUntilDone:YES];
                } else {
                    [self cleanViewWithoutBlock];
                }
            }
            
            //Get download object
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            NSArray *downs = [appDelegate.downloadManager getDownloads];
            
            __block Download *download = nil;
            
            [downs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                download = (Download*)obj;
                if ([download.fileDto.filePath isEqualToString:_file.filePath] && [download.fileDto.fileName isEqualToString:_file.fileName] && download.fileDto.userId == _file.userId){
                     *stop = YES;
                }
                
            }];
            
            //Check to know if it's in progress
            if ((download && [download.operation isExecuting]) || (download && download.downloadTask && download.downloadTask.state == NSURLSessionTaskStateRunning) ) {
                [self contiueDownloadIfTheFileisDownloading];
            }else{
                [self restartTheDownload];
            }
            
        } else {
            //If the file is downloaded
            [self downloadTheFile];
            
            //Preview the file
            if (_typeOfFile == videoFileType || _typeOfFile == audioFileType) {
                [self performSelectorOnMainThread:@selector(playMediaFile) withObject:nil waitUntilDone:YES];
            } else if (_typeOfFile == officeFileType) {
                //[self performSelector:@selector(openFileOffice) withObject:nil afterDelay:2.0];
                [self performSelectorOnMainThread:@selector(openFileOffice) withObject:nil waitUntilDone:YES];
            } else {
                [self cleanViewWithoutBlock];
            }
        }
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
    _companyImageView.hidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    _previewImageView.hidden = NO;
    
    //Get the image preview name
    NSString *filePreviewName = [FileNameUtils getTheNameOfTheImagePreviewOfFileName:_file.fileName];
    _previewImageView.image = [UIImage imageNamed:filePreviewName];
    
    _isFileCharged = YES;
    [self configureView];
}

/*
 * Method than call open with class
 */
- (void)openFile {
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    self.file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    
    if (!self.openWith) {
        self.openWith = [[OpenWith alloc]init];
    }
    
    self.openWith.parentButton=_openButtonBar;
    [self.openWith openWithFile:self.file];
    
    _isViewBlocked = NO;
}

/*
 * Method that show a office file in the screen
 */

- (void)openFileOffice{
    
    if (self.file.localFolder!=nil) {
        
        NSString *ext = [FileNameUtils getExtension:self.file.fileName];
        
        if ([ext isEqualToString:@"PDF"]) {
            
            self.documentPDF = [ReaderDocument withDocumentFilePath:self.file.localFolder password:@""];
            
            if (self.documentPDF != nil) {
                self.readerPDFViewController = [[ReaderViewController alloc] initWithReaderDocument:self.documentPDF];
                
                [self.readerPDFViewController.view addGestureRecognizer:self.singleTap];
          
                [self.view addSubview:self.readerPDFViewController.view];
                
                self.readerPDFViewController.view.frame = [self getTheCorrectSize];
                [self.readerPDFViewController updateContentViews];
                
            } else {
                DLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, self.file.localFolder, @"");
            }
            
        } else {
            if (!self.officeView) {
                self.officeView = [[OfficeFileView alloc]initWithFrame:[self getTheCorrectSize]];
            } else {
                [self.officeView.webView removeFromSuperview];
            }
            self.officeView.delegate = self;
            [self.officeView openOfficeFileWithPath:self.file.localFolder andFileName:self.file.fileName];
            
            [self.officeView.webView addGestureRecognizer:self.singleTap];
            
            [self.view addSubview:self.officeView.webView];
        }
        
    }
    self.isViewBlocked = NO;
}


///-----------------------------------
/// @name openGalleryFileOnUpdatingProcess
///-----------------------------------

/**
 * This method apen a gallery file on an updating process or not
 *
 * @param isUpdatingProcess -> BOOL, manage if it an updating process
 */
- (void) openGalleryFileOnUpdatingProcess: (BOOL) isUpdatingProcess {
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _isUpdatingFile = isUpdatingProcess;
    //Update the file
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    //Quit the gallery view
    if (_galleryView) {
        [_galleryView.scrollView removeFromSuperview];
        _galleryView = nil;
    }
    //Init the gallery
    [self initGallery];
}


/*
 * Delegate method of the OfficeFileView
 * Indicate that the link is load in the officeFileView
 * and set the name of the link.
 * We use this feature for example to charge Help page.
 */

- (void)finishLinkLoad {
    [_titleLabel setText:_linkTitle];
}

/*
 * Method that open a link in detail view.
 *
 */
- (void) openLink:(NSString*)urlString{
    
    DLog(@"3-Press Help");
    
    DLog(@"Open Link");
    _file = nil;
    _isFileCharged = NO;
    [self presentWhiteView];
    
    if (!_officeView) {
        _officeView = [[OfficeFileView alloc]initWithFrame:[self getTheCorrectSize]];
        _officeView.delegate = self;
    } else {
        [_officeView.webView removeFromSuperview];
    }
    
    [_officeView openLinkByPath:urlString];
    
    [self.view addSubview:_officeView.webView];
    
    //Enable view
    _isViewBlocked = NO;
}


#pragma mark - FilesViewController callBacks

/*
 * Method to reload the data of the file list.
 */
- (void)reloadFileList{
    [[NSNotificationCenter defaultCenter] postNotificationName: IpadFilePreviewViewControllerFileWasDownloadNotification object: nil];
}


/*
 * Method to block the file list.
 */
- (void) blockFileList{
    [[NSNotificationCenter defaultCenter] postNotificationName: IpadFilePreviewViewControllerFileWhileDonwloadingNotification object: nil];
}

/*
 * Method to unblock the file list.
 */
- (void) unBlockFileList{
    [[NSNotificationCenter defaultCenter] postNotificationName: IpadFilePreviewViewControllerFileFinishDownloadNotification object: nil];
    
}

/*
 * Method that post a notification that inform to file list or shared view the current selected file in the gallery.
 */
- (void) selectRowInFileList:(FileDto*)fileDto{
    
    [[NSNotificationCenter defaultCenter] postNotificationName: IpadSelectRowInFileListNotification object: fileDto];
    
}

#pragma mark - Delete File Delegate Implementation

- (void)reloadTableFromDataBase
{
    [self unselectCurrentFile];
    [self reloadFileList];
    
}

- (void)reloadTableAfterDonwload{
    
    [self reloadFileList];
}

//-----------------------------------
/// @name removeSelectedIndexPath
///-----------------------------------

/**
 * Method to remove the selectedPath after delete the file localy
 *
 */

- (void) removeSelectedIndexPath {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.presentFilesViewController.selectedCell = nil;
}


#pragma mark - Util methods

/*
 * Method that change the name of the toolBar title.
 */
- (void)putTitleInNavBarByName:(NSString *) fileName{
    
    [_titleLabel setText:[fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]];
}


///-----------------------------------
/// @name putTheFavoriteStatus
///-----------------------------------

/**
 * This method puts the favorite star on starred or unstarred state on the preview view
 */
- (void) putTheFavoriteStatus {
    if (_file.isFavorite) {
        //Change the image to unstarred
        _favoriteButtonBar.image = [UIImage imageNamed:@"favoriteTB-filled"];
    } else {
        //Change the image to starred
        _favoriteButtonBar.image = [UIImage imageNamed:@"favoriteTB"];
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
    
    //Constraint in updatingFileProgressView
    _topMarginUpdatingFileProgressView.constant = 10;
    
    _updatingFileView.backgroundColor = [UIColor clearColor];
    _updatingFileView.hidden = NO;
    _titleLabel.hidden = YES;
    _updatingFileProgressView.progress = 0.0;
    
    [_updatingFileView addSubview:_updatingFileProgressView];
    [_updatingFileView addSubview:_updatingCancelButton];
    
    [toolbar addSubview:_updatingFileView];
    
    [self performSelector:@selector(showTextInStatusBar) withObject:nil afterDelay:1.0];
}


///-----------------------------------
/// @name removeThePreviousViews
///-----------------------------------

/**
 * This method removes, if they exist, the previous view of video player, office and gallery view
 */
- (void) removeThePreviousViews {
    //Quit the player if exist
    if (self.moviePlayer) {
        [self.moviePlayer.view removeFromSuperview];
    }
    
    //Quit the office view
    if (self.officeView) {
        [self.officeView.webView removeFromSuperview];
        self.officeView = nil;
    }
    
    //Quit the gallery view
    if (self.galleryView) {
        [self.galleryView.scrollView removeFromSuperview];
        self.galleryView = nil;
    }
    
    if (self.readerPDFViewController) {
        [self.readerPDFViewController.view removeFromSuperview];
        self.readerPDFViewController = nil;
        self.documentPDF = nil;
    }
}

/*
 * Method that presents a white page without option buttons
 */
- (void)presentWhiteView {
    
    _progressView.hidden = YES;
    _cancelButton.hidden = YES;
    _progressLabel.hidden = YES;
    _progressLabel.text = @"";
    _progressView.progress = 0.0;
    _mainScrollView.hidden = YES;
    _previewImageView.hidden = YES;
    
    _companyImageView.hidden = NO;
    self.view.backgroundColor = [UIColor colorOfBackgroundDetailViewiPad];
    
    _titleLabel.text = @"";
    
    [_openWith.activityPopoverController dismissPopoverAnimated:YES];
    [_mShareFileOrFolder.activityPopoverController dismissPopoverAnimated:YES];
    
    [self removeThePreviousViews];
    
    _isFileCharged = NO;
    _file = nil;
    
    [self configureView];
    
    [self reloadFileList];
    
    [self stopNotificationUpdatingFile];
}

/*
 * Method that show a pop up error from other class
 */
- (void) showErrorOnIpadIfIsNecessaryCancelDownload {
    
    DLog(@"isDownloading: %ld", (long)_file.isDownload);
    
    //Call showAlertView in main thread
    [self performSelectorOnMainThread:@selector(showAlertView:)
                           withObject:NSLocalizedString(@"not_possible_connect_to_server", nil)
                        waitUntilDone:YES];
}

/*
 * Method that hidden the preview interface objects and block the screen
 */
- (void)cleanView{
    
    DLog(@"Clean view");
    
    //Clean the view
    //Hidden download elements
    _progressView.hidden=YES;
    _cancelButton.hidden=YES;
    _progressLabel.hidden=YES;
    _progressLabel.text=@"";
    _progressView.progress=0.0;
    
    [toolbar setUserInteractionEnabled:YES];
    _isViewBlocked=YES;
    [self reloadFileList];
}

/*
 *  Method that hidden the preview interface objects
 */

- (void)cleanViewWithoutBlock{
    
    DLog(@"Clean view");
    
    //Clean the view
    //Hidden download elements
    _progressView.hidden=YES;
    _cancelButton.hidden=YES;
    _progressLabel.hidden=YES;
    _progressLabel.text=@"";
    _progressView.progress=0.0;
    
    
    [toolbar setUserInteractionEnabled:YES];
    _isViewBlocked=NO;
    
}

/*
 * Method called from FilesViewController after that unselect a cell and
 * present a white view in detailView
 */
- (void) unselectCurrentFile {
    DLog(@"unselectCurrentFile");
    
    self.file=[ManageFilesDB getFileDtoByIdFile:self.file.idFile];
    _isFileCharged=NO;
    
    _titleLabel.text=@"";
    _linkTitle=@"";
    
    _isViewBlocked=YES;
    
    self.file=nil;
    
    [self presentWhiteView];
    
    if(_galleryView) {
        [self cleanView];
    }
    
}

#pragma mark - Gallery Methods

/*
 * Open the gallery image
 */
- (void)initGallery{
    
    //Enable user interaction
    _isFileCharged=YES;
    
    [self configureView];
    
    if (!_galleryView) {
        _galleryView=[[GalleryView alloc]initWithFrame:[self getTheCorrectSize]];
        //Pass the current file
        _galleryView.file=_file;
        _galleryView.delegate=self;
        //Init the array of images with the array of files (sort files of file list)
        [_galleryView initArrayOfImagesWithArrayOfFiles:_sortedArray];
        //Init the main scroll view of gallery
        [_galleryView initScrollView];
        //Run the gallery
        [_galleryView initGallery];
        
        [_galleryView.scrollView addGestureRecognizer:self.singleTap];
        
    }
    //Add Gallery to the preview
    [self.view addSubview:_galleryView.scrollView];
    
}

#pragma mark - Gallery View Delegate Methods

/*
 * Delegate method that change the file selected from gallery
 */
- (void)selectThisFile:(FileDto*)file{
    
    _file=file;
    
    //Put the name of the file in nav bar
    [self putTitleInNavBarByName:_file.fileName];
    [self putTheFavoriteStatus];
    
    //Inidcate to filelist the selected file
    [self selectRowInFileList:_file];
}


#pragma mark - Action Buttons

/*
 * Open With feature. Action to show the apps that can open the selected file
 */
- (IBAction)didPressOpenWithButton:(id)sender
{
    
    BOOL canOpenButton = NO;
    
    if (_isViewBlocked) {
        //The view is blocked, no actions
        DLog(@"isViewBlocked");
        canOpenButton=NO;
    } else {
        if (_galleryView) {
            if (![_galleryView isCurrentImageDownloading]) {
                canOpenButton=YES;
            } else {
                canOpenButton=NO;
            }
        } else {
            canOpenButton=YES;
        }
    }
    
    if (canOpenButton) {
        
        if ([_mShareFileOrFolder.activityPopoverController isPopoverVisible]) {
            [_mShareFileOrFolder.activityPopoverController dismissPopoverAnimated:YES];
        }
        
        CheckAccessToServer *mCheckAccessToServer = [[CheckAccessToServer alloc] init];
        
        if([_file isDownload]) {
            //This file is in the device
            DLog(@"The file is in the device");
            [self openFile];
        } else  if ([mCheckAccessToServer isNetworkIsReachable]) {
            //File is not in the device
            //Phase 1.1. Download the file
            DLog(@"Download the file");
            Download *download=nil;
            download = [[Download alloc]init];
            download.delegate=self;
            download.currentLocalFolder=_currentLocalFolder;
            
            //View progress view and button
            _progressView.hidden=NO;
            _cancelButton.hidden=NO;
            _progressLabel.text=NSLocalizedString(@"wait_to_download", nil);
            _progressLabel.hidden=NO;
            
            //Block the view
            _isViewBlocked=YES;
            
            [download fileToDownload:_file];
        } else {
            [self downloadFailed:NSLocalizedString(@"not_possible_connect_to_server", nil)andFile:nil];
        }
    }
}

/*
 * Method that launch the share options
 */
- (IBAction)didPressShareLinkButton:(id)sender {
    DLog(@"Share button clicked");
    
    if (_openWith && _openWith.activityView) {
        [_openWith.activityPopoverController dismissPopoverAnimated:YES];
    }
    
    _mShareFileOrFolder = [ShareFileOrFolder new];
    _mShareFileOrFolder.delegate = self;
    _mShareFileOrFolder.viewToShow = self.splitViewController.view;
    _mShareFileOrFolder.parentButton = _shareLinkButtonBar;
    
    _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
    [_mShareFileOrFolder showShareActionSheetForFile:_file];
}


/*
 * Method that launch the favorite options
 */
- (IBAction)didPressFavoritesButton:(id)sender {
    //Update the file from the DB
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if (_file.isFavorite) {
        _file.isFavorite = NO;
        //Change the image to unstarred
        _favoriteButtonBar.image = [UIImage imageNamed:@"favoriteTB"];
    } else {
        _file.isFavorite = YES;
        _isCancelDownloadClicked = NO;
        //Change the image to starred
        _favoriteButtonBar.image = [UIImage imageNamed:@"favoriteTB-filled"];
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
 * Delete feaure. Action to show a menu to select one delete option of a selected file
 */
- (IBAction)didPressDeleteButton:(id)sender
{
    
    BOOL canOpenButton = NO;
    
    if (_isViewBlocked) {
        //The view is blocked, no actions
        DLog(@"isViewBlocked");
        canOpenButton=NO;
    } else {
        if (_galleryView) {
            if (![_galleryView isCurrentImageDownloading]) {
                canOpenButton = YES;
            } else {
                canOpenButton = NO;
            }
        } else {
            canOpenButton = YES;
        }
    }
    if (canOpenButton) {
        self.mDeleteFile = [[DeleteFile alloc] init];
        self.mDeleteFile.delegate = self;
        self.mDeleteFile.viewToShow = self.view;
        
        DLog(@"idFile: %ld", (long)_file.idFile);
        DLog(@"fileName: %@", _file.fileName);
        
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        //Update the file
        _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        DLog(@"idFile: %ld", (long)_file.idFile);
        
        [self.mDeleteFile askToDeleteFileByFileDto:self.file];
    }
}

/*
 * Cancel download feature. Action to cancel the download of a selected file.
 */
- (IBAction)didPressCancelButton:(id)sender{
    
    if (_isDownloading) {
        
        _isCancelDownloadClicked = YES;
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *downs = [appDelegate.downloadManager getDownloads];
        
        Download *download;
        
        for (download in downs) {
             if ([download.fileDto.localFolder isEqualToString: _file.localFolder]) {
                [download cancelDownload];
                _isDownloading=NO;
            }
        }
        
        //Update fileDto
        _file=[ManageFilesDB getFileDtoByIdFile:_file.idFile];
        
        _progressView.hidden = YES;
        _cancelButton.hidden = YES;
        _progressLabel.hidden = YES;
        _progressLabel.text = @"";
        _progressView.progress = 0.0;
    }
    
    _isViewBlocked = NO;
    [self unBlockFileList];
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
    [self cancelTheUpdating];
}



///-----------------------------------
/// @name Cancel the updating
///-----------------------------------

/**
 * This method cancel the updating process
 */
- (void) cancelTheUpdating {
    DLog(@"cancelTheUpdating");
    if (_isDownloading) {
        
        //Update the download status of the files
        _file.isDownload = downloaded;
        [ManageFilesDB setFileIsDownloadState:_file.idFile andState:downloaded];
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        //Copy of the original array
        NSArray *downs = [NSArray arrayWithArray:[appDelegate.downloadManager getDownloads]];
        Download *download;

        for (download in downs) {
            if ([download.fileDto.filePath isEqualToString:_file.filePath] && [download.fileDto.fileName isEqualToString:_file.fileName] && download.fileDto.userId == _file.userId) {
                [download cancelDownload];
                _isDownloading = NO;
            }
        }
        //Stop the notification
        [self stopNotificationUpdatingFile];
    }
}



#pragma mark - Media player methods
/*
 * Launch the player for video and audio
 */

- (void)playMediaFile{
    
    BOOL needNewPlayer = NO;
    if (_file != nil) {
        if (self.moviePlayer) {
            DLog(@"Movie urlString: %@", _moviePlayer.urlString);
            DLog(@"File local folder: %@", _file.localFolder);
            if ([self.moviePlayer.urlString isEqualToString:self.file.localFolder]) {
                needNewPlayer = NO;
            } else {
                [self.moviePlayer removeNotificationObservation];
                [self.moviePlayer.moviePlayer stop];
                [self.moviePlayer finalizePlayer];
                [self.moviePlayer.view removeFromSuperview];
                self.moviePlayer = nil;
                needNewPlayer = YES;
            }
        } else {
            needNewPlayer = YES;
        }
        if (needNewPlayer) {
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
            
            NSURL *url = [NSURL fileURLWithPath:self.file.localFolder];
            
            self.moviePlayer = [[MediaViewController alloc]initWithContentURL:url];

            self.moviePlayer.view.frame = [self getTheCorrectSize];
            
            self.moviePlayer.urlString = self.file.localFolder;
            
            //if is audio file tell the controller the file is music
            self.moviePlayer.isMusic = YES;
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            appDelegate.mediaPlayer = self.moviePlayer;
            
            self.moviePlayer.moviePlayer.controlStyle = MPMovieControlStyleNone;
            
            [self.moviePlayer.moviePlayer setFullscreen:NO];
            
            self.moviePlayer.moviePlayer.shouldAutoplay = NO;
            
            [self.moviePlayer initHudView];
            
            [self.moviePlayer.moviePlayer setScalingMode:MPMovieScalingModeAspectFit];
            [self.moviePlayer.moviePlayer prepareToPlay];
            
            [self.moviePlayer.view addGestureRecognizer:self.singleTap];
            
            [self.view addSubview:self.moviePlayer.view];
            
            [self.moviePlayer playFile];
            
        } else {
            
            [self.moviePlayer.view addGestureRecognizer:self.singleTap];
            
            [self.view addSubview:self.moviePlayer.view];
        }
    }
}

#pragma mark - Download Methods


///-----------------------------------
/// @name Restart the download
///-----------------------------------

/**
 * This method restart the download of the current file
 *
 */
- (void) restartTheDownload{
    
    if (([_file isDownload] == downloading) || ([_file isDownload] == updating)) {
        
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
            
            if ((IS_IOS7 || IS_IOS8) && !k_is_sso_active) {
                
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
- (void) contiueDownloadIfTheFileisDownloading {
    
    if (_file.isDownload == downloading || _file.isDownload == updating) {
        //Find the download in download global array
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSArray *downs = [appDelegate.downloadManager getDownloads];
        
        Download *tempDown;
        BOOL downloadIsInProgress = NO;
        //Check if the download is in progress
        for (tempDown in downs) {
            if ([tempDown.fileDto.localFolder isEqualToString: _file.localFolder]) {
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
            if (_file.isDownload == updating) {
                //Show the progress bar and the notification
                [self performSelector:@selector(putUpdateProgressInNavBar) withObject:nil afterDelay:0.3];
            } else {
                //If the download is in progress update de screen objects
                _progressView.hidden = NO;
                
               // DLog(@"progress : %f", _progressView.progress);
                if (_progressView.progress == 0.0) {
                    _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
                }
                
                _cancelButton.hidden = NO;
                _progressLabel.hidden = NO;
                
                //If is downloadTask suspended
                if (tempDown.downloadTask.state == NSURLSessionTaskStateSuspended) {
                    [appDelegate.downloadManager addDownload:tempDown];
                }
            }
            _isDownloading = YES;
        }
    }
}

/*
 * This method prepare the download manager to download a selected file
 */
- (void)downloadTheFile {
    //0 = not download ; 1 = download ; -1 = downloading
    
    DLog(@"The download state of the file is: %ld", (long)_file.isDownload);
    
    if ([_file isDownload]==notDownload || _file.isNecessaryUpdate) {
        //Phase 1.2. If the file isn't in the device, download the file
        Download *download = nil;
        download = [[Download alloc]init];
        download.delegate = self;
        download.currentLocalFolder = _currentLocalFolder;
        
        if (_file.isNecessaryUpdate) {
            [self putUpdateProgressInNavBar];
        } else {
            //Block the view
            _isViewBlocked = YES;
            
            _progressView.hidden = NO;
            _cancelButton.hidden = NO;
            _progressLabel.text = NSLocalizedString(@"wait_to_download", nil);
            _progressLabel.hidden = NO;
        }
        
        _isDownloading = YES;
        [download fileToDownload:_file];
    }
}

/*
 * Method that cancel all current downloads
 */
- (void)cancelAllDownloads{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (app.isSharedToOwncloudPresent==NO) {
        //Cancel all downloads
        [app.downloadManager cancelDownloads];
    }
}



#pragma mark - Download delegate methods

/*
 * This method receive the download progress and set valor to progressView.
 */

- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    
    if ([fileDto.localFolder isEqualToString: _file.localFolder]) {
        if (_file.isNecessaryUpdate) {
            _updatingFileProgressView.progress = percent;
        } else {
            _progressView.progress = percent;
        }
        DLog(@"PERCENT OF DOWNLOAD IS:%f", percent);
    }
}

/*
 * Method that hidden the progress slider and the progress label after download
 */
- (void) hiddenButtonsAfterDownload {
    
    [self stopNotificationUpdatingFile];
    
        _progressView.hidden = YES;
        _progressLabel.hidden = YES;
        _isViewBlocked = NO;
}


/*
 * This method tell this class to de file is in device
 */
- (void)downloadCompleted:(FileDto *)fileDto {
    DLog(@"Hey, file is in device, go to preview");
    
    if (_typeOfFile == imageFileType) {
        _isUpdatingFile = NO;
    }
   
    //Update fileDto
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    //Only if the file is the same
     if ([fileDto.localFolder isEqualToString: _file.localFolder]) {
        
        _isDownloading = NO;
        
        _cancelButton.hidden = YES;
        _isFileCharged = YES;
        
        //Update fileDto
        _file=[ManageFilesDB getFileDtoByIdFile:_file.idFile];
        

        //Quit the player if exist
        if (self.moviePlayer) {
            [self.moviePlayer.moviePlayer stop];
            [self.moviePlayer finalizePlayer];
            [self.moviePlayer.view removeFromSuperview];
            self.moviePlayer = nil;
        }
        
        //Depend if the file is an image or other "openimage" or "openfile"
        
        if (_file != nil) {
            if (_typeOfFile == officeFileType) {
                [self performSelector:@selector(openFileOffice) withObject:nil afterDelay:0.0];
            } else if(_typeOfFile == audioFileType) {
                [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.0];
            } else if(_typeOfFile == videoFileType) {
                [self performSelector:@selector(playMediaFile) withObject:nil afterDelay:0.0];
            }  else if (_typeOfFile == imageFileType){
                DLog(@"Image file");
            } else {
                [self performSelector:@selector(openFile) withObject:nil afterDelay:0.0];
            }
        }
        
        [self performSelector:@selector(hiddenButtonsAfterDownload) withObject:nil afterDelay:0.0];
    }
    //Stop the notification
    [self stopNotificationUpdatingFile];
    //Enable view
    _isViewBlocked = NO;
    [self unBlockFileList];
}

/*
 * This method is for show alert view in main thread.
 */
- (void) showAlertView:(NSString*)string{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

/*
 * This method tell this class that exist an error and the file doesn't down to the device
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    _isDownloading = NO;
    
    [self cleanView];
    
    //Enable screen
    _isViewBlocked = NO;
    
    if(string) {
        [self showErrorMessageIfNotIsShowingWithString:string];
    }
    
    [self stopNotificationUpdatingFile];
    
    //Enable screen
    _isViewBlocked = NO;
    [self unBlockFileList];
    [self reloadFileList];
}

- (void) showErrorMessageIfNotIsShowingWithString:(NSString *)string{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!app.downloadErrorAlertView) {
        
        app.downloadErrorAlertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        app.downloadErrorAlertView.tag = k_alertview_for_download_error;
        [app.downloadErrorAlertView show];
    }
    
}

- (void)showNotConnectionWithServerMessage{
    
    [self showErrorMessageIfNotIsShowingWithString:NSLocalizedString(@"not_possible_connect_to_server", nil)];
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
- (void)updateOrCancelTheDownload:(id)download{
    
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


/*
 * This method receive the string of download progress
 */

- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
     if ([fileDto.localFolder isEqualToString: _file.localFolder]) {
        [_progressLabel setText:string];
    }
}



#pragma mark -
#pragma mark Rotation support


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

//Only for ios 6
- (BOOL)shouldAutorotate {
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    if (IS_IOS7) {
        [self customWillRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (IS_IOS7) {
       [self customWillAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
 
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    
    if (IS_IOS7) {
        [self customDidRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }

}

#pragma mark - Interface Rotations

- (void) customWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    DLog(@"Will rotate");
    
    if (self.galleryView && self.isSizeChanging == NO) {
        [self.galleryView prepareScrollViewBeforeTheRotation];
    }
    
    if (self.readerPDFViewController && self.isSizeChanging == NO) {
        [self.readerPDFViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    if (_mShareFileOrFolder && _mShareFileOrFolder.activityPopoverController) {
        [_mShareFileOrFolder.activityPopoverController dismissPopoverAnimated:NO];
    }
    
    if (_openWith) {
        [_openWith.activityPopoverController dismissPopoverAnimated:NO];
    }
    
}

-(void) customWillAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    DLog(@"will Animate Rotation");
    
    [_mDeleteFile.popupQuery dismissWithClickedButtonIndex:0 animated:YES];
    
    if (_readerPDFViewController) {
        [_readerPDFViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    if (self.galleryView) {
        [self adjustGalleryScrollView];
    }
    
}

- (void)customDidRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    
    DLog(@"did rotate");
    
    if (_readerPDFViewController) {
        [_readerPDFViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
    
}

#pragma mark - iOS 8 rotation method.

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    NSTimeInterval duration = 0.5;
    
    // willRotateToInterfaceOrientation code goes here
    [self customWillRotateToInterfaceOrientation:orientation duration:duration];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // willAnimateRotationToInterfaceOrientation code goes here
        [self customWillAnimateRotationToInterfaceOrientation:orientation duration:duration];
        
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // didRotateFromInterfaceOrientation goes here
        [self customDidRotateFromInterfaceOrientation:orientation];
        
    }];
    
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

/*
 * Method that tell to galleryView to adjust the scroll view after the rotation
 */
-(void) adjustGalleryScrollView {
    
    [self configureView];
    
    if (_galleryView) {
        [_galleryView.scrollView setFrame:[self getTheCorrectSize]];
        [_galleryView adjustTheScrollViewAfterTheRotation];
    }
}




#pragma mark - Error login delegate method

- (void)errorLogin {
    
    if (_updatingFileView) {
        [self stopNotificationUpdatingFile];
    }
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.downloadManager errorLogin];
    
    
    DLog(@"Error login");
    
    if(k_is_oauth_active) {
        NSURL *url = [NSURL URLWithString:k_oauth_login];
        [[UIApplication sharedApplication] openURL:url];
    } else {
        
        //Flag to indicate that the error login is in the screen
        if (appDelegate.isErrorLoginShown==NO) {
            appDelegate.isErrorLoginShown=YES;
            
            //In SAML the error message is about the session expired
            if (k_is_sso_active) {
                [self performSelectorOnMainThread:@selector(showAlertView:)
                                       withObject:NSLocalizedString(@"session_expired", nil)
                                    waitUntilDone:YES];
            } else {
                [self performSelectorOnMainThread:@selector(showAlertView:)
                                       withObject:NSLocalizedString(@"error_login_message", nil)
                                    waitUntilDone:YES];
            }
            
            EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:appDelegate.activeUser];
            [viewController setBarForCancelForLoadingFromModal];
            
            OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [appDelegate.splitViewController presentViewController:navController animated:YES completion:nil];
        }
    }
}

#pragma mark - Notifications methods

/*
 * This method addObservers for notifications to this class.
 * The notifications added in viewDidLoad
 */

- (void) setNotificationForCommunicationBetweenViews {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePreviewOverwriteFile:) name:PreviewFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePreviewFileWithNewIDFromDB:) name:uploadOverwriteFileNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updatePreviewFileWithNewIdFromDBWhenAFileISDelete:) name:fileDeleteInAOverwriteProcess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanView) name:IpadCleanPreviewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotConnectionWithServerMessage) name:IpadShowNotConnectionWithServerMessageNotification object:nil];
}


/*
 *Method that checks if the preview file is the same that the file that is contained in the notification object and updates the preview file view if the overwrite file was previewed
 */
-(void)updatePreviewOverwriteFile:(NSNotification *)notification{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update the _file with DB
    _file=[ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    NSString *path = (NSString*)[notification object];
    NSString *pathPreview = [UtilsUrls getFullRemoteServerFilePathByFile:self.file andUser:app.activeUser];
    
    if ([path isEqualToString:pathPreview]) {
        DLog(@"The file is the same, update the preview");
        _file.isDownload=downloaded;
        _isOverwritedFile = YES;
        [self handleFile:_file fromController:_controllerManager];
        DLog(@"id file: %ld", (long)_file.idFile);
    }    
}


- (void) receiveTestNotification:(NSNotification *) notification
{
    if ([notification.name isEqualToString:@"TestNotification"])
    {
        NSDictionary* userInfo = notification.userInfo;
        int messageTotal = [[userInfo objectForKey:@"total"] intValue];
        NSLog (@"Successfully received test notification! %i", messageTotal);
    }
}

/*
 *Method that update the preview file with the correct id from DB
 */
-(void)updatePreviewFileWithNewIDFromDB:(NSNotification *)notification{
    DLog(@"updatePreviewFileWithNewIDFromDB");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //Update the preview file with the new information in DB
    _file=[ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    app.isOverwriteProcess = NO;
}


/*
 *Method that update the preview file with the correct id from DB when a file in a upload process is cancel
 */
-(void)updatePreviewFileWithNewIdFromDBWhenAFileISDelete:(NSNotification *)notification{
    DLog(@"updatePreviewFileWithNewIdFromDBWhenAFileISDelete");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update the file with the new information in DB
    _file=[ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
    DLog(@"file id: %ld",(long)_file.idFile);

    
    NSString *path = (NSString*)[notification object];
    NSString *pathPreview = [UtilsUrls getFullRemoteServerFilePathByFile:self.file andUser:app.activeUser];
    
    //If the cancel file is the same that the previewed file, clean the view
    if ([path isEqualToString:pathPreview]) {
        [app.detailViewController presentWhiteView];
    }
}



///-----------------------------------
/// @name Show a text in the status bar
///-----------------------------------

/**
 * This method shows a text in the status bar of the device
 */
- (void) showTextInStatusBar {
    
    if (_isDownloading && _updatingFileView.hidden == NO && nameFileToUpdate == _file.fileName) {
        DLog(@"Show a notification text in the status bar");
        //Notificacion style
        _notification.notificationLabelBackgroundColor = [UIColor whiteColor];
        _notification.notificationLabelTextColor = [UIColor colorOfNavigationBar];
        _notification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
        _notification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
        //File name
        NSString *notificationText = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"updating", nil), [nameFileToUpdate stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        DLog(@"name: %@",notificationText);
        [_notification displayNotificationWithMessage:notificationText completion:nil];
    }
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
    _updatingFileView.hidden = YES;
    _titleLabel.hidden = NO;
}



#pragma mark - Loading Methods

/*
 * Add loading screen and block the view
 */
- (void) initLoading {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.splitViewController.view animated:YES];
    [hud bringSubviewToFront:self.view];
    
    hud.labelText = NSLocalizedString(@"loading", nil);
    hud.dimBackground = NO;
    
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
}

- (void) endLoading {
    [MBProgressHUD hideHUDForView:self.splitViewController.view animated:YES];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
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

#pragma mark - Transitions Methods for Full Screen Support

- (void) launchTransitionProcessForFullScreen{
    
    self.isSizeChanging = YES;
    
    if (self.hideMaster) {
        
        [self convertMasterViewInvisible:NO];
        
        [self.splitViewController.view setNeedsLayout];
        self.splitViewController.delegate = nil;
        self.splitViewController.delegate = self;
        
        CGRect selfFrame = self.splitViewController.view.frame;
        
        CGFloat deltaWidth = k_delta_width_for_split_transition;
        
        if (IS_IOS8) {
            
            selfFrame.size.width += deltaWidth;
            selfFrame.origin.x -= deltaWidth;
            
        }else{
            
            if (IS_PORTRAIT) {
                selfFrame.size.width += deltaWidth;
                selfFrame.origin.x -= deltaWidth;
            }else{
                selfFrame.size.height += deltaWidth;
                selfFrame.origin.y -= deltaWidth;
            }
            
        }
        
        [self.splitViewController.view setFrame:selfFrame];
        
        self.hideMaster = !self.hideMaster;
        
        [self.splitViewController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
        
        [self hideContainerView];
        
        [self toggleHideMaster:nil];
        
        [self toggleHideToolBar:^{
              [self showContainerView];
        }];
        
    }else{
        
        self.hideMaster = !self.hideMaster;
        
        [self hideContainerView];
        
        [self toggleHideMaster:nil];
        
        [self toggleHideToolBar:^{
            
            [self.splitViewController.view setNeedsLayout];
            self.splitViewController.delegate = nil;
            self.splitViewController.delegate = self;
            
            CGRect selfFrame = self.splitViewController.view.frame;
            
            CGFloat deltaWidth = k_delta_width_for_split_transition;
            
            if (IS_IOS8) {
                
                selfFrame.size.width -= deltaWidth;
                selfFrame.origin.x += deltaWidth;
                
            }else{
                
                if (IS_PORTRAIT) {
                    selfFrame.size.width -= deltaWidth;
                    selfFrame.origin.x += deltaWidth;
                }else{
                    selfFrame.size.height -= deltaWidth;
                    selfFrame.origin.y += deltaWidth;
                }
                
            }
            
            [self.splitViewController.view setFrame:selfFrame];
            
            [self.splitViewController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
            
            [self convertMasterViewInvisible:YES];
            
            [self showContainerView];
            
        }];
        
    }
    
    [self performSelector:@selector(updateStatusBar) withObject:nil afterDelay:0.0];
    
    [self performSelector:@selector(finishTransitionProcess) withObject:nil afterDelay:0.4];
    
}


- (void) hideContainerView{
    
    if (self.galleryView) {
        [self.galleryView prepareScrollViewBeforeTheRotation];
        
        self.mainScrollView.backgroundColor = [UIColor blackColor];
        self.view.backgroundColor = [UIColor blackColor];
        self.mainScrollView.hidden = NO;
        self.galleryView.scrollView.alpha = 0.0;
    }
    
    if (self.readerPDFViewController) {
        self.readerPDFViewController.isChangingSize = YES;
        
        self.mainScrollView.backgroundColor = [UIColor grayColor];
        self.view.backgroundColor = [UIColor grayColor];
        self.mainScrollView.hidden = NO;
        self.readerPDFViewController.view.alpha = 0.0;
    }
    
}

- (void) showContainerView{
    
    CGRect frame;
    
    if (self.hideMaster) {
        
        if (IS_IOS8) {
            frame = self.view.window.bounds;
        }else{
            
            if (IS_PORTRAIT) {
                frame = self.view.window.bounds;
            }else{
                frame = CGRectMake(0.0, 0.0, self.view.window.bounds.size.height, self.view.window.bounds.size.width);
            }
            
        }
        
    }else{
        frame = [self getTheCorrectSize];
    }
    
    if (self.galleryView) {
        [self.galleryView.scrollView setFrame:frame];
        [self.galleryView adjustTheScrollViewAfterTheRotation];
        
        self.mainScrollView.backgroundColor = [UIColor clearColor];
        self.view.backgroundColor = [UIColor whiteColor];
        self.galleryView.scrollView.alpha = 1.0;
        self.mainScrollView.hidden = YES;
    }
    
    if (self.readerPDFViewController) {
        self.readerPDFViewController.view.frame = frame;
        [self.readerPDFViewController updateContentViews];
        
        self.mainScrollView.backgroundColor = [UIColor clearColor];
        self.view.backgroundColor = [UIColor whiteColor];
        self.readerPDFViewController.view.alpha = 1.0;
        self.mainScrollView.hidden = YES;
    }
}


-(void)toggleHideMaster:(void(^)(void))completionBlock {
    
    // Adjust the detailView frame to hide/show the masterview
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void)
     {
         
         CGRect selfFrame = self.splitViewController.view.frame;
         
         CGFloat deltaWidth = k_delta_width_for_split_transition;
         
         if (IS_IOS8) {
             
             if (self.hideMaster)
             {
                 selfFrame.size.width += deltaWidth;
                 selfFrame.origin.x -= deltaWidth;
             }
             else
             {
                 selfFrame.size.width -= deltaWidth;
                 selfFrame.origin.x += deltaWidth;
             }

         }else{
             
             if (self.hideMaster)
             {
                 if (IS_PORTRAIT) {
                     selfFrame.size.width += deltaWidth;
                     selfFrame.origin.x -= deltaWidth;
                 }else{
                     selfFrame.size.height += deltaWidth;
                     selfFrame.origin.y -= deltaWidth;
                 }
 
             }
             else
             {
                 if (IS_PORTRAIT) {
                     selfFrame.size.width -= deltaWidth;
                     selfFrame.origin.x += deltaWidth;
                 }else{
                     selfFrame.size.height -= deltaWidth;
                     selfFrame.origin.y += deltaWidth;
                 }
             }

         }
         
         [self.splitViewController.view setFrame:selfFrame];
         
         
     }completion:^(BOOL finished){
         if (finished)
         {
             
             if (completionBlock)
             {
                 completionBlock();
             }
         }
     }];
    
}


- (void) toggleHideToolBar:(void(^)(void))completionBlock{
    
    CGFloat deltaHeigh = k_delta_height_toolBar_split_transition;
    
    if (self.hideMaster) {
        toolBarTopMargin.constant = -deltaHeigh;
        _topMarginUpdatingFileProgressView.constant = -deltaHeigh;
        _topMarginTitleLabelConstraint.constant = -deltaHeigh;
        toolBarHeight.constant = -deltaHeigh;
        _toolBarHeightConstraint.constant = -deltaHeigh;
    }else{
        toolBarTopMargin.constant = 0;
        _topMarginUpdatingFileProgressView.constant = 10;
        _topMarginTitleLabelConstraint.constant = k_delta_height_toolBar_split_transition/2;
        toolBarHeight.constant = 0;
        _toolBarHeightConstraint.constant = k_delta_height_toolBar_split_transition;
    }
    
    self.toolbar.alpha = 1.0;
    self.titleLabel.alpha = 1.0;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect toolFrame = self.toolbar.frame;
        CGRect scrollFrame = self.mainScrollView.frame;
        
        CGFloat deltaHeigh = k_delta_height_toolBar_split_transition;
        
        if (self.hideMaster) {
            toolFrame.origin.y -= deltaHeigh;
            scrollFrame.origin.y -= deltaHeigh;
            scrollFrame.size.height += deltaHeigh;
            
        }else{
            toolFrame.origin.y += deltaHeigh;
            scrollFrame.origin.y += deltaHeigh;
            scrollFrame.size.height -= deltaHeigh;
        }
        
        [self.toolbar setFrame:toolFrame];
        [self.mainScrollView setFrame:scrollFrame];
        
        [self.view layoutIfNeeded];
        
        if (self.officeView) {
            self.officeView.webView.frame = [self getTheCorrectSize];
        }
        
        if (self.moviePlayer) {
            self.moviePlayer.view.frame = [self getTheCorrectSize];
        }
 
        
    } completion:^(BOOL finished) {
       
        if (finished)
        {
            if (self.hideMaster) {
                self.toolbar.alpha = 0.0;
                self.titleLabel.alpha = 0.0;
            }
            
            if (completionBlock)
            {
                completionBlock();
            }
        }
        
    }];
    
}

- (void) convertMasterViewInvisible:(BOOL)isInvisible{
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    OCTabBarController *tabBar = [app.splitViewController.viewControllers objectAtIndex:0];
    UIViewController *viewController = tabBar.selectedViewController;
    
    if (isInvisible) {
        viewController.view.alpha = 0.0;
        tabBar.view.alpha = 0.0;
    }else{
        viewController.view.alpha = 1.0;
        tabBar.view.alpha = 1.0;
    }
}


- (void) finishTransitionProcess{
    
    self.isSizeChanging = NO;
    
    if (self.readerPDFViewController) {
        self.readerPDFViewController.isChangingSize = NO;
    }
    
}

- (void) updateStatusBar{
    
    OCSplitViewController *splitView = (OCSplitViewController *)self.splitViewController;
    splitView.isStatusBarHidden = self.hideMaster;
    [splitView setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UISplitViewDelegateMethods

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation{
    
    return self.hideMaster;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.readerPDFViewController) {
        if ([touch.view isDescendantOfView:self.readerPDFViewController.mainPagebar]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - ManageFavoritesDelegate

- (void) fileHaveNewVersion:(BOOL)isNewVersionAvailable {
    
    if (isNewVersionAvailable) {
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        //Set the file as isNecessaryUpdate
        [ManageFilesDB setIsNecessaryUpdateOfTheFile:_file.idFile];
        //Update the file on memory
        _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
        [self reloadFileList];
        [self manageTheSameFileOnThePreview];
    }
}


@end
