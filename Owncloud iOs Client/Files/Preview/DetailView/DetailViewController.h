//
//  DetailViewController.h
//  MGSplitView
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
#import "OfficeFileView.h"
#import "MediaAVPlayerViewController.h"
#import <AVKit/AVKit.h>
#import "GalleryView.h"
#import "OCToolBar.h"
#import "CWStatusBarNotification.h"
#import "ManageFavorites.h"
#import "FLAnimatedImage.h"

@class ReaderDocument;
@class ReaderViewController;

typedef enum {
    noManagerController = 0,
    fileListManagerController = 1,
    sharedViewManagerController =2,
} kindOfManageController;


@interface DetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate, DeleteFileDelegate, OfficeFileDelegate, GalleryViewDelegate, DownloadDelegate, UIAlertViewDelegate, ManageFavoritesDelegate, UIGestureRecognizerDelegate, AVAssetResourceLoaderDelegate> {
    
    //Bar buttons
    IBOutlet UIBarButtonItem *_spaceBar;
    IBOutlet UIBarButtonItem *_spaceBar1;
    IBOutlet UIBarButtonItem *_spaceBar2;
    IBOutlet UIBarButtonItem *_spaceBar3;
    IBOutlet UIBarButtonItem *_spaceBar4;
    IBOutlet UIBarButtonItem *_openButtonBar;
    IBOutlet UIBarButtonItem *_favoriteButtonBar;
    IBOutlet UIBarButtonItem *_shareLinkButtonBar;
    IBOutlet UIBarButtonItem *_deleteButtonBar;
    IBOutlet UIBarButtonItem *_editButtonBar;
    IBOutlet UIImageView *_companyImageView;
    
    OCToolBar *toolbar;
    
    //Autolayout constraints
    IBOutlet NSLayoutConstraint *_topMarginTitleLabelConstraint;
    IBOutlet NSLayoutConstraint *_leftMarginTitleLabelConstraint;
    IBOutlet NSLayoutConstraint *_toolBarHeightConstraint;
    IBOutlet NSLayoutConstraint *_progressViewHeightConstraint;
    
    IBOutlet NSLayoutConstraint *_topMarginUpdatingFileProgressView;
    IBOutlet NSLayoutConstraint *_topMarginUpdatingView;
    IBOutlet NSLayoutConstraint *_topMarginUpdatingButton;
    
    IBOutlet NSLayoutConstraint *toolBarTopMargin;
    
    IBOutlet NSLayoutConstraint *_titleLabelMarginRightConstraint;
    IBOutlet NSLayoutConstraint *_updatingProgressMarginUpdatingRightConstraint;
    
    NSString *nameFileToUpdate; 
    
}
//File object
@property (nonatomic, strong) FileDto *file;
//Interface
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *previewImageView;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UILabel *progressLabel;

//View for show the updating progress bar
@property (nonatomic, strong) IBOutlet UIView *updatingFileView;
@property (nonatomic, strong) IBOutlet UIProgressView *updatingFileProgressView;
@property (nonatomic, strong) IBOutlet UIButton *updatingCancelButton;
@property (nonatomic, strong) CWStatusBarNotification *notification;

//Local folder
@property (nonatomic, strong) NSString *currentLocalFolder;
//Features objects
@property (nonatomic, strong) OpenWith *openWith;
@property (nonatomic, strong) DeleteFile *mDeleteFile;

//Owncloud preview objects
@property (nonatomic, strong) OfficeFileView *officeView;
@property(nonatomic, strong) MediaAVPlayerViewController *avMoviePlayer;
@property(nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) GalleryView *galleryView;
//Control the type of files
@property(nonatomic) NSInteger typeOfFile;

//The title of the link when the detail view it's used for a help page for example
@property (nonatomic, strong) NSString *linkTitle;

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
//ScrolView in DetailView.xib to copy the frame to scroll view of GalleryView
@property(nonatomic, strong) IBOutlet UIScrollView *mainScrollView;
//Array with the order images to the Gallery
@property(nonatomic,strong) NSArray *sortedArray;

//Flags
@property(nonatomic) BOOL isViewBlocked;
@property(nonatomic) BOOL isSizeChanging;
@property(nonatomic) BOOL isDownloading;
@property(nonatomic) BOOL isFileCharged;

//Flag for know the overwrited file
@property (nonatomic) BOOL isOverwritedFile;
//Flag for know the updating process
@property (nonatomic) BOOL isUpdatingFile;
//Flag to know what manager controller called this view
@property (nonatomic)NSInteger controllerManager;
//Flag to check if the cancel was clicked before launch automatically the favorite download
@property(nonatomic) BOOL isCancelDownloadClicked;
@property(nonatomic) BOOL isForceDownload;

//VFR Pdf reader
@property(nonatomic, strong) ReaderDocument *documentPDF;
@property(nonatomic, strong) ReaderViewController *readerPDFViewController;

//Gif View
@property(nonatomic, strong) FLAnimatedImageView *gifView;

//Favorites
@property(nonatomic, strong) ManageFavorites *manageFavorites;

//Full Screen Support
@property(nonatomic) BOOL hideMaster;


///-----------------------------------
/// @name Handle File
///-----------------------------------

/**
 * This method is the main of the class to handle a file and send this to the
 * correct controller
 *
 * @param myFile -> FileDto
 * @param controller -> enumerate of types of controller in the app
 */
- (void) handleFile:(FileDto*)myFile fromController:(NSInteger)controller andIsForceDownload:(BOOL) isForceDownload;


///-----------------------------------
/// @name openGalleryFileOnUpdatingProcess
///-----------------------------------

/**
 * This method apen a gallery file on an updating process or not
 *
 * @param isUpdatingProcess -> BOOL, manage if it an updating process
 */
- (void) openGalleryFileOnUpdatingProcess: (BOOL) isUpdatingProcess;


/*
 * Method used for open link or path in the detail view like a web page
 * @urlString -> path of link
 */
- (void) openLink:(NSString*)urlString;

/*
 * Open With feature. Action to show the apps that can open the selected file
 */
- (IBAction)didPressOpenWithButton:(id)sender;

/*
 * Delete feaure. Action to show a menu to select one delete option of a selected file
 */
- (IBAction)didPressDeleteButton:(id)sender;

/*
 * Cancel download feature. Action to cancel the download of a selected file.
 */
- (IBAction)didPressCancelButton:(id)sender;

/*
 * Edit file feature. Action to edit the selected file.
 */
- (IBAction)didPressEditButton:(id)sender;


///-----------------------------------
/// @name Action of updating cancel button
///-----------------------------------
- (IBAction)didPressUpdatingCancelButton:(id)sender;

/*
 * Share by link feature. Action to share the selected file by link.
 */
- (IBAction)didPressShareLinkButton:(id)sender;


/*
 * Method that launch the favorite options
 */
- (IBAction)didPressFavoritesButton:(id)sender;

/*
 * Method called from FilesViewController after that unselect a cell and 
 * present a white view in detailView
 */
- (void) unselectCurrentFile;

/*
 * Method called from AppDelegate and FilesViewController to present a white view 
 * in detail screen without option buttons
 */
- (void)presentWhiteView;

/*
 * Method to configure the detail view depend that the orientation 
 * and depend that if detail view is extendend
 */
- (void)configureView;

/*
 * Method calle from MGSplitViewController to tell the GalleryView the adjust of the scroll
 */
- (void)adjustGalleryScrollView;



/*
 * Method that show a pop up error from other class
*/
- (void)showErrorOnIpadIfIsNecessaryCancelDownload;


/*
 * Method that manage the error login, show a pop up and then 
 * show a screen with name and password account to the user 
 * change the wrong data.
 */
- (void)errorLogin;


- (void)contiueDownloadIfTheFileisDownloading;

- (void)updateFavoriteIconWhenAFolderIsSelectedFavorite;

- (void) removeMediaPlayer;

@end
