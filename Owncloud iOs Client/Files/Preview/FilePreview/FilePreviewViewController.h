//
//  FilePreviewViewController.h
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

#import <UIKit/UIKit.h>
#import "FileDto.h"
#import "Download.h"
#import "OpenWith.h"
#import "DeleteFile.h"
#import "MediaAVPlayerViewController.h"
#import "OfficeFileView.h"
#import "GalleryView.h"
#import "CheckAccessToServer.h"
#import "OCToolBar.h"
#import "CWStatusBarNotification.h"
#import "ManageFavorites.h"
#import "FLAnimatedImage.h"
#import <AVKit/AVKit.h>

@class ReaderDocument;
@class ReaderViewController;

extern NSString * iPhoneCleanPreviewNotification;
extern NSString * iPhoneShowNotConnectionWithServerMessageNotification;


@interface FilePreviewViewController : UIViewController <UIAlertViewDelegate, DeleteFileDelegate, CheckAccessToServerDelegate, DownloadDelegate, GalleryViewDelegate, OfficeFileDelegate, ManageFavoritesDelegate, AVAssetResourceLoaderDelegate>
{
    //Autolayout attributes
    IBOutlet NSLayoutConstraint *_progressViewHeightConstraint;
    IBOutlet UIBarButtonItem *_openInButtonBar;
    IBOutlet UIBarButtonItem *_flexibleSpaceAfterOpenInButtonBar;
    IBOutlet UIBarButtonItem *_favoriteButtonBar;
    IBOutlet UIBarButtonItem *_flexibleSpaceAfterFavoriteButtonBar;
    IBOutlet UIBarButtonItem *_shareButtonBar;
    IBOutlet UIBarButtonItem *_flexibleSpaceAfterShareButtonBar;
    IBOutlet UIBarButtonItem *_deleteButtonBar;
    
    
    NSString *nameFileToUpdate;
}

//File object
@property(nonatomic, strong) FileDto *file;

//Objects of the screen
@property(nonatomic, strong) IBOutlet UIImageView *previewImageView;
@property(nonatomic, strong) IBOutlet UIProgressView *progressView;
@property(nonatomic, strong) IBOutlet UIButton *cancelButton;
@property(nonatomic, strong) IBOutlet UILabel *progressLabel;

//View for show the updating progress bar
@property (nonatomic, strong) IBOutlet UIView *updatingFileView;
@property (nonatomic, strong) IBOutlet UIProgressView *updatingFileProgressView;
@property (nonatomic, strong) IBOutlet UIButton *updatingCancelButton;
@property (nonatomic, strong) CWStatusBarNotification *notification;

@property(nonatomic, strong) IBOutlet OCToolBar *toolBar;

//Features objects
@property(nonatomic, strong) DeleteFile *mDeleteFile;
@property(nonatomic) OpenWith *openWith;

//Local folder
@property(nonatomic, strong) NSString *currentLocalFolder;

//Owncloud preview objects
@property(nonatomic, strong) OfficeFileView *officeView;
@property(nonatomic, strong) MediaAVPlayerViewController *avMoviePlayer;
@property(nonatomic, strong) AVURLAsset *asset;
@property(nonatomic, strong) GalleryView *galleryView;
//Control the type of files
@property(nonatomic) NSInteger typeOfFile;

@property(nonatomic) BOOL isDownloading;
//Flag to check if the cancel was clicked before launch automatically the favorite download
@property(nonatomic) BOOL isCancelDownloadClicked;
@property(nonatomic) BOOL isForceDownload;

//GALLERY
//Array with the order images to the Gallery
@property(nonatomic, strong) NSArray *sortedArray;

//Fullscreen option for the Gallery
@property(nonatomic) CGRect transitionFrame;

//VFR Pdf reader
@property(nonatomic, strong) ReaderDocument *documentPDF;
@property(nonatomic, strong) ReaderViewController *readerPDFViewController;


//Gif View
@property(nonatomic, strong) FLAnimatedImageView *gifView;

//Favorites
@property(nonatomic, strong) ManageFavorites *manageFavorites;

@property(nonatomic, strong) NSMutableArray *pendingRequests;
@property(nonatomic, strong) NSMutableData *receivedData;
@property(nonatomic, strong) NSURLConnection *connection;
@property(nonatomic, strong) NSHTTPURLResponse *response;

/*
 * Init method
 */
- (id) initWithNibName:(NSString *) nibNameOrNil selectedFile:(FileDto *) file andIsForceDownload:(BOOL) isForceDownload;

/*
 * Open With feature. Action to show the apps that can open the selected file
 */
- (IBAction)didPressOpenWithButton:(id)sender;

/*
 * Share by link feature. Action to share the selected file by link.
 */
- (IBAction)didPressShareLinkButton:(id)sender;

/*
 * Future option
 */
- (IBAction)didPressFavoritesButton:(id)sender;

/*
 * Delete feaure. Action to show a menu to select one delete option of a selected file
 */
- (IBAction)didPressDeleteButton:(id)sender;

/*
 * Cancel download feature. Action to cancel the download of a selected file.
 */
- (IBAction)didPressCancelButton:(id)sender;

/*
 * Action button. Cancel the current download in progress
 */
- (IBAction)didPressUpdatingCancelButton:(id)sender;


@end
