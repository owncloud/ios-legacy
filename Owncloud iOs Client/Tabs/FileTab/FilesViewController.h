//
//  FilesViewController.h
//  Owncloud iOs Client
//
//  This class controlled the view of the file list with all of it's options
//  - Show files an folders
//  - Navigation between the folders
//  - Refresh with pull down to refresh
//  - Show options of + menu:
//      - Upload files
//      - Create folder
//  - Swipe and long press gestures support
//  - Open with option with download file if it's necessary
//  - Move file/folder option
//  - Rename file/folder option
//  - Delete file/folder option
//  
//
//  Created by Javier Gonzalez on 7/11/12.
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
#import "UserDto.h"
#import "MBProgressHUD.h"
#import "DeleteFile.h"
#import "OpenWith.h"
#import "DownloadViewController.h"
#import "CheckAccessToServer.h"
#import "ELCImagePickerController.h"
#import "PrepareFilesToUpload.h"
#import "RenameFile.h"
#import "MoveFile.h"
#import "SWTableViewCell.h"
#import "OverwriteFileOptions.h"
#import "ManageNetworkErrors.h"
#import "SelectFolderViewController.h"
#import "SelectFolderNavigation.h"
#import "ManageFavorites.h"
#import "DetectUserData.h"
#import "TSMessage.h"
#import "TSMessageView.h"

#ifdef CONTAINER_APP
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif


@class UniversalViewController;
@class ManageAccounts;

@interface FilesViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate,
ELCImagePickerControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate, MBProgressHUDDelegate, UITextFieldDelegate, DeleteFileDelegate, OpenWithDelegate, DownloadViewControllerDelegate, CheckAccessToServerDelegate, RenameDelegate, MoveFileDelegate, SWTableViewCellDelegate, ManageNetworkErrorsDelegate, ManageFavoritesDelegate, TSMessageViewProtocol>

//Table view
@property(nonatomic, strong) IBOutlet UITableView *tableView;

// Array that contains the files ordered alphabetically
@property(nonatomic, strong) NSMutableArray *sortedArray;
//The current directory array
@property(nonatomic, strong) NSMutableArray *currentDirectoryArray;
//Path for remote folder for upload
@property(nonatomic, strong) NSString *remoteFolderToUpload;
//Path for remote folder
@property(nonatomic, strong) NSString *currentRemoteFolder;
//Path for current local folder
@property(nonatomic, strong) NSString *currentLocalFolder;
//Path for next remote folder
@property(nonatomic, strong) NSString *nextRemoteFolder;
//The user of the file list
@property(nonatomic, strong) UserDto *mUser;
//FileDto for the selected file
@property(nonatomic, strong) FileDto *selectedFileDto;
//FileDto file to show files
@property(nonatomic, strong) FileDto *fileIdToShowFiles;
//View for Create Folder
@property(nonatomic, strong) UIAlertView *folderView;
//Delete file/folder option
@property(nonatomic, strong) DeleteFile *mDeleteFile;
//OpenWith option
@property(nonatomic, strong) OpenWith *openWith;
//Download view for the open with option
@property(nonatomic, strong) DownloadViewController *downloadView;
//Rename file/folder option
@property(nonatomic, strong) RenameFile *rename;
//Move file or folder option
@property(nonatomic, strong) MoveFile *moveFile;
//FilDto current file show files on the server to update
@property(nonatomic, strong) FileDto *currentFileShowFilesOnTheServerToUpdateTheLocalFile;
//View for loading screen
@property(nonatomic, strong) MBProgressHUD  *HUD;
//Move task in background
@property(nonatomic)UIBackgroundTaskIdentifier moveTask;
//Refresh Control
@property(nonatomic, strong) UIRefreshControl *refreshControl;
//UIActionSheet for "more" option on swipe
@property (nonatomic,strong) UIActionSheet *moreActionSheet;
//UIActionSheet for + button
@property (nonatomic,strong) UIActionSheet *plusActionSheet;
//An exist file
@property (nonatomic, strong) OverwriteFileOptions *overWritteOption;
//Class to manage the Network erros
@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;
@property (nonatomic, strong) UIView *viewToShow;
//UIActionSheet for sorting files and folders
@property(nonatomic, strong) UIActionSheet *sortingActionSheet;

//Select folder views used by move options
@property (nonatomic, strong) SelectFolderViewController *selectFolderViewController;
@property (nonatomic, strong) SelectFolderNavigation *selectFolderNavigation;

//Flags
//Boleean that indicate if the loading screen is showing
@property(nonatomic) BOOL showLoadingAfterChangeUser;
//Boleean that indicate if is necesary etag request
@property(nonatomic) BOOL isEtagRequestNecessary;
//Alert to show any alert on Files view. Property to can cancel it on rotate
@property(nonatomic) UIAlertView *alert;
//Select indexpath to indicate the cell where we have to put the arrow of the popover
@property(nonatomic) NSIndexPath *selectedIndexPath;
//Selected file for iPad
@property(nonatomic, strong) NSIndexPath *selectedCell;
//Number of folders and files in the file list
@property (nonatomic) int numberOfFolders;
@property (nonatomic) int numberOfFiles;

@property (nonatomic) BOOL isLoadingForNavigate;

//This flag help us to have the UX as a favorite files and folders because are son of a favorite folder
@property (nonatomic) BOOL isCurrentFolderSonOfFavoriteFolder;

//Favorites
@property(nonatomic, strong) ManageFavorites *manageFavorites;


// init method to load view from nib with an array of files
- (id) initWithNibName:(NSString *) nibNameOrNil onFolder:(NSString *) currentFolder andFileId:(NSInteger) fileIdToShowFiles andCurrentLocalFolder:(NSString *)currentLocalFoler;

- (void)initLoading;
- (void)endLoading;
- (void)refreshTableFromWebDav;
- (void)reloadTableFromDataBase;
- (void)reloadCellByFile:(FileDto *) file;
- (void)reloadTableFileList;
- (void)goToSelectedFileOrFolder:(FileDto *) selectedFile andForceDownload:(BOOL) isForceDownload;
- (void)initFilesView;

@end;

