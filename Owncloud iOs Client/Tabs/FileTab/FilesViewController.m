//
//  FilesViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "FilesViewController.h"
#import "AppDelegate.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "FileDto.h"
#import "FilePreviewViewController.h"
#import "UserDto.h"
#import "MBProgressHUD.h"
#import "PrepareFilesToUpload.h"
#import "CustomCellFileAndDirectory.h"
#import "DeleteFile.h"
#import "CheckAccessToServer.h"
#import "RenameFile.h"
#import "NSString+Encoding.h"
#import "Reachability.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Constants.h"
#import "SelectFolderNavigation.h"
#import "SelectFolderViewController.h"
#import "constants.h"
#import "EditAccountViewController.h"
#import "UtilsDtos.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "FileListDBOperations.h"
#import "OCErrorMsg.h"
#import "ManageFilesDB.h"
#import "OCNavigationController.h"
#import "OCCommunication.h"
#import "ShareFileOrFolder.h"
#import "OCSharedDto.h"
#import "ManageSharesDB.h"
#import "InfoFileUtils.h"
#import "ManageFavorites.h"
#import "EmptyCell.h"
#import "UtilsTableView.h"
#import "DownloadUtils.h"
#import "UploadUtils.h"
#import "ManageNetworkErrors.h"
#import "UIAlertView+Blocks.h"
#import "UtilsUrls.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "ManageUsersDB.h"


//Constant for iOS7
#define k_status_bar_height 20
#define k_navigation_bar_height 44
#define k_navigation_bar_height_in_iphone_landscape 32
#define k_footer_label_width 320


@interface FilesViewController ()

@property (nonatomic, strong) ELCAlbumPickerController *albumController;
@property (nonatomic, strong) ELCImagePickerController *elcPicker;

@end

@implementation FilesViewController


#pragma mark - Memory method

- (void)dealloc
{
    [_tableView setDelegate:nil];
    [_tableView setDataSource:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Init Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}


/*
 * Init Method to load the view from a nib with an array of files
 */
- (id) initWithNibName:(NSString *) nibNameOrNil onFolder:(NSString *) currentFolder andFileId:(NSInteger) fileIdToShowFiles andCurrentLocalFolder:(NSString *)currentLocalFoler
{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];    
    //If is 0 is root folder
    if(fileIdToShowFiles == 0) {
        _fileIdToShowFiles = [ManageFilesDB getRootFileDtoByUser:app.activeUser];
    } else {
        _fileIdToShowFiles = [ManageFilesDB getFileDtoByIdFile:fileIdToShowFiles];
    }
    
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
    
    _currentRemoteFolder = currentFolder;
    _currentLocalFolder = currentLocalFoler;

   // DLog(@"self.fileIdToShowFiles: %lld", _fileIdToShowFiles.etag);
  //  DLog(@"self.fileIdToShowFiles: %ld", (long)_fileIdToShowFiles.idFile);
    
    _showLoadingAfterChangeUser = NO;
    _checkingEtag = NO;
    
    if(_mCheckAccessToServer == nil) {
        self.mCheckAccessToServer = [[CheckAccessToServer alloc] init];
        self.mCheckAccessToServer.delegate = self;
    }
    
    //We check if the user have root folder at true on the DB
    if(!self.fileIdToShowFiles || self.fileIdToShowFiles.isRootFolder) {
        if([ManageFilesDB isExistRootFolderByUser:app.activeUser]) {
            DLog(@"Root folder exist");
            self.currentFileShowFilesOnTheServerToUpdateTheLocalFile = [ManageFilesDB getRootFileDtoByUser:app.activeUser];
            DLog(@"IdFile:%ld etag: %@", (long)self.currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile, self.currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag);
        } else {
            //We need the current folder refresh with the right etag
            DLog(@"Root folder not exist");  
            self.fileIdToShowFiles = [FileListDBOperations createRootFolderAndGetFileDtoByUser:app.activeUser];
            self.currentFileShowFilesOnTheServerToUpdateTheLocalFile = self.fileIdToShowFiles;
        }
    } else {
        self.currentFileShowFilesOnTheServerToUpdateTheLocalFile = [ManageFilesDB getFileDtoByIdFile:fileIdToShowFiles];
    }
    
    DLog(@"currentRemoteFolder: %@ and fileIdToShowFiles: %ld", currentFolder, (long)self.fileIdToShowFiles.idFile);
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    return self;
}

#pragma mark Load View Life

- (void)viewDidLoad 
{
    
    [super viewDidLoad];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //We set the currentLocalFolder when the folder is not the root
    if(_fileIdToShowFiles.idFile != 0) {
        _currentLocalFolder = [NSString stringWithFormat:@"%@%@", _currentLocalFolder, [_fileIdToShowFiles.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        DLog(@"CurrentLocalFolder: %@", _currentLocalFolder);
    }
    
    DLog(@"self.currentRemoteFolder: %@",_currentRemoteFolder);
    
    //Store the new active user, maybe can be different in the future in this same view
    _mUser = app.activeUser;
    
    //Add a plus button
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showOptions)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    
    // Create a searchBar and a displayController "Future Option"
    //UISearchBar *searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
    //NSArray *buttonTitles = [NSArray arrayWithObjects:@"Filename", @"Text", nil];
    //[searchBar setScopeButtonTitles:buttonTitles];    
    //self.displayController = [[UISearchDisplayController alloc]initWithSearchBar:searchBar contentsController:self];    
    // Adding searchBar to the tableView's header 
    // The next commented line is for the version with searchField
    //self.tableView.tableHeaderView = self.displayController.searchBar;
    
    
    //Set notifications for communication betweenViews
    [self setNotificationForCommunicationBetweenViews];
    
    //Init Refresh Control
    UIRefreshControl *refresh = [UIRefreshControl new];
    //For the moment in the iOS 7 GM the attributedTitle not show properly.
    //refresh.attributedTitle =[[NSAttributedString alloc] initWithString: NSLocalizedString(@"pull_down_refresh", nil)];
    refresh.attributedTitle =nil;
    [refresh addTarget:self
                 action:@selector(pullRefreshView:)
                 forControlEvents:UIControlEventValueChanged];

    _refreshControl = refresh;
    
    
    [_tableView addSubview:_refreshControl];

    //Only for iOS 7
    if (IS_IOS7) {
        //This new feature of iOS 7 indicate the extend of the edges of the view
        self.edgesForExtendedLayout = UIRectEdgeAll;//UIRectCornerAllCorners;
    }
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if(_showLoadingAfterChangeUser) {
        _showLoadingAfterChangeUser = NO;
        [self initLoading];
    }
    
    //We check after load the view if the file view on the preview of iPad still existing on the device
    if (!IS_IPHONE) {
        
        if (app.detailViewController.file!=nil) {
            if (![ManageFilesDB isFileOnDataBase:app.detailViewController.file]) {
                [self hidePreviewOniPad];
            }
        }
    }
    
    //If it is the root folder show the icon of root folder
    if(self.fileIdToShowFiles.isRootFolder) {
        
        if(k_show_logo_on_title_file_list) {
            UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]];
            self.navigationItem.titleView=imageView;
        }
    }
    
    //If is a new user set the file list
    if (app.isNewUser) {
        //We are changing of user
        //Show the file list in the correct place
        if (!IS_IPHONE){
            [_tableView setContentOffset:CGPointMake(0,-k_navigation_bar_height) animated:animated];
        } else if (IS_IPHONE && !IS_PORTRAIT) {
            [_tableView setContentOffset:CGPointMake(0,-(k_navigation_bar_height_in_iphone_landscape + k_status_bar_height)) animated:animated];
        } else {
            [_tableView setContentOffset:CGPointMake(0,-(k_status_bar_height + k_navigation_bar_height)) animated:animated];
        }
        app.isNewUser = NO;
    }
}

// Notifies the view controller that its view is about to be added to a view hierarchy.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set the navigation bar to translucent
    if (IS_IOS7){
        [self.navigationController.navigationBar setTranslucent:YES];
    }
    
    //Flag to know when the view change automatic to root view
    BOOL isGoToRootView = NO;
    
    //Appear the tabBar
    self.tabBarController.tabBar.hidden=NO;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *currentUser = app.activeUser;
    //ErrorLogin
    app.isErrorLoginShown = NO;
    
    app.currentViewVisible = self;
    
    //Relaunch the uploads that failed before
    [app performSelector:@selector(relaunchUploadsFailedNoForced) withObject:nil afterDelay:5.0];
    
    //If it is the root folder show the name of root folder
    if(self.fileIdToShowFiles.isRootFolder) {
        if(!k_show_logo_on_title_file_list) {
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            self.navigationItem.title = appName;
        }
    }
    
    DLog(@"currentUser.username: %@", currentUser.username);
    DLog(@"self.mUser.username: %@", _mUser.username);
    
    if(!([currentUser.username isEqualToString:_mUser.username] &&
         [currentUser.password isEqualToString:_mUser.password] &&
         [currentUser.url isEqualToString:_mUser.url])) {
        //We are changing of user
        //Show the file list in the correct place
        //Only for iOS 7
        if (IS_IOS7){
            if (!IS_IPHONE){
                [_tableView setContentOffset:CGPointMake(0,-k_navigation_bar_height) animated:animated];
            } else if (IS_IPHONE && !IS_PORTRAIT) {
                [_tableView setContentOffset:CGPointMake(0,-(k_navigation_bar_height_in_iphone_landscape + k_status_bar_height)) animated:animated];
            } else {
                [_tableView setContentOffset:CGPointMake(0,-(k_status_bar_height + k_navigation_bar_height)) animated:animated];
            }
        } else {
            [_tableView setContentOffset:CGPointMake(0,0) animated:animated];
        }
        
        //We check if the user have root folder at true on the DB
        if([ManageFilesDB isExistRootFolderByUser:app.activeUser]) {
            DLog(@"Root folder exist");
            _currentFileShowFilesOnTheServerToUpdateTheLocalFile = [ManageFilesDB getRootFileDtoByUser:app.activeUser];
            _fileIdToShowFiles = _currentFileShowFilesOnTheServerToUpdateTheLocalFile;
            DLog(@"IdFile:%ld etag: %@", (long)_currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile, _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag);
        } else {
            //We need the current folder refresh with the right etag
            DLog(@"Root folder not exist");
            
            //[self createRootFolder];
            _fileIdToShowFiles = [FileListDBOperations createRootFolderAndGetFileDtoByUser:app.activeUser];
            _currentFileShowFilesOnTheServerToUpdateTheLocalFile = _fileIdToShowFiles;
        }
        
        //Know if is the root view or need to go to the root view
        if ([[self.navigationController.viewControllers objectAtIndex:0]isEqual:self]) {
            //its root view
            isGoToRootView=NO;
        } else {
            //Set this flag to yes, to indicate that the user change the account and this view should be dissaper
            isGoToRootView=YES;
            [self.navigationController popToRootViewControllerAnimated:animated];
        }
        
        _currentRemoteFolder = [UtilsUrls getFullRemoteServerPathWithWebDav:currentUser];
        
        //We get the current folder to create the local tree
        _currentLocalFolder = [NSString stringWithFormat:@"%@%ld/", [UtilsUrls getOwnCloudFilePath],(long)currentUser.idUser];
        _currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile];
        //Update de actual active user
        _mUser = currentUser;
        //Update the table footer
        [self setTheLabelOnTheTableFooter];
        
        if ([[ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile] count] == 0) {
            [self initLoading];
        }
        
        //Reload table from DB
        [self reloadTableFromDataBase];
        
        _isEtagRequestNecessary = YES;
    } else {
        [self reloadTableFromDataBase];
    }
    
    //Update active user
    _mUser = currentUser;
    
    if(_isEtagRequestNecessary && isGoToRootView==NO) {
        _checkingEtag = YES;
        
        //Refresh the shared data
        [self refreshSharedPath];
        
        //Checking the etag
        NSString *path = _currentRemoteFolder;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            DLog(@"Operation response code: %ld", (long)response.statusCode);
            
            BOOL isSamlCredentialsError = NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    [self errorLogin];
                }
            }
            if(response.statusCode < kOCErrorServerUnauthorized && !isSamlCredentialsError) {
                //Pass the items with OCFileDto to FileDto Array
                NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                [self checkEtagBeforeMakeRefreshFolderRequest:directoryList];
                
            } else {
                [self endLoading];
                [self stopPullRefresh];
                _showLoadingAfterChangeUser = NO;
            }
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            
            DLog(@"error: %@", error);
            DLog(@"Operation error: %ld", (long)response.statusCode);
            [self manageServerErrors:response.statusCode and:error];
        
        }];
        
    } else {
        [self endLoading];
    }
    
    DLog(@"self.fileIdToShowFiles: %ld",(long)self.fileIdToShowFiles.idFile);
    
    if(self.fileIdToShowFiles.isRootFolder) {
        
        //We update the files from root folder with fileId 0 to the right fileId from root fileDto.
        if([[ManageFilesDB getFilesByFileIdForActiveUser:0] count] > 0) {
            [ManageFilesDB updateFilesWithFileId:0 withNewFileId:_fileIdToShowFiles.idFile];
            [self reloadTableFromDataBase];
        }
    } else {
        
        //We check if the selected folder exist. Maybe the ID has change when we create a folder on move or upload.
        FileDto *currentFolder = [ManageFilesDB getFileDtoByIdFile:_fileIdToShowFiles.idFile];
        
        NSArray *splitedUrl = [_currentRemoteFolder componentsSeparatedByString:@"/"];
        
        NSString *currentFolderFilePath = @"";
        
        for(int i = 3 ; i < [splitedUrl count] ; i ++) {
            currentFolderFilePath = [NSString stringWithFormat:@"%@/%@", currentFolderFilePath, [splitedUrl objectAtIndex:i]];
        }
        
        DLog(@"Url: %@", currentFolderFilePath);
        
        if (currentFolder == nil) {
            //If is nil update the currentFolder
            currentFolder = [ManageFilesDB getFolderByFilePath:currentFolderFilePath andFileName:currentFolder.fileName];
            _fileIdToShowFiles = [ManageFilesDB getFileDtoByIdFile:currentFolder.idFile];
        }
        
        //Is directory
        NSString *folderName =  [currentFolder.fileName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
        
        //Quit the last character, the slash (/)
        folderName = [folderName substringToIndex:[folderName length]-1];
        
        self.navigationItem.title =  folderName;
    }
    
    //Now we create the all folders of the current directory
    [FileListDBOperations createAllFoldersByArrayOfFilesDto:_currentDirectoryArray andLocalFolder:_currentLocalFolder];
    
    if(self.navigationItem.title == nil) {
        // in MyTableViewController's tableView:didSelectRowAtIndexPath method...
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]
                                       style:UIBarButtonItemStyleBordered
                                       target:nil
                                       action:nil];
        
        self.navigationItem.backBarButtonItem = backButton;
        
    } else if(_fileIdToShowFiles.isRootFolder) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithImage:[UIImage imageNamed:@""]
                                       style:UIBarButtonItemStyleBordered
                                       target:nil
                                       action:nil];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        backButton.title = NSLocalizedString(appName, nil);
        self.navigationItem.backBarButtonItem = backButton;
    } else {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithImage:[UIImage imageNamed:@""]
                                       style:UIBarButtonItemStyleBordered
                                       target:nil
                                       action:nil];
        self.navigationItem.backBarButtonItem = backButton;
    }
    
    // Deselect the selected row
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //Assign this class to presentFilesViewController
    app.presentFilesViewController=self;
    
    //Add loading screen if it's necessary (Used by restoring the loading view after a rotate when the uploading processing)
    if (app.isLoadingVisible==YES) {
        [self initLoading];
    }
}

// Notifies the view controller that its view is about to be removed from a view hierarchy.
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_selectedCell) {
        //Deselect selected cell
        CustomCellFileAndDirectory *newRow = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:_selectedCell];
        [newRow setSelectedStrong:NO];
    }
    
    [self stopPullRefresh];
    [self endLoading];
}

// Notifies the view controller that its view was removed from a view hierarchy.
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _isEtagRequestNecessary = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

}


-(void)viewDidLayoutSubviews
{
    
    if (IS_IOS8) {
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 9, 0, 0)];
        }
        
        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (IS_IOS8) {
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 9, 0, 0)];
        }
        
        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
    }
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE){
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }else {
        return YES;
    }
}

//Only for ios6
- (NSUInteger)supportedInterfaceOrientations
{
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

//Only for ios 6
- (BOOL)shouldAutorotate {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (IS_IPHONE){
        return (orientation != UIDeviceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}




- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    if (self.openWith && !IS_IPHONE) {
        [self.openWith.activityView dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (self.plusActionSheet) {
        [self.plusActionSheet dismissWithClickedButtonIndex:2 animated:NO];
    }
    
    DLog(@"Files view Controller willRotate");
    if (IS_PORTRAIT) {
        //Vertical
        if (_downloadView) {
            [_downloadView potraitView];
        }
    }else {
        //Horizontal
        if (_downloadView) {
            [_downloadView landscapeView];
        }
    }
    
    //Cancel TSAlert View of Create Folder and Close keyboard
    if (_folderView) {
        [_folderView dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    if (_alert) {
        [_alert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    if(_rename) {
        [_rename.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    if(_moveFile) {
        [_moveFile.overWritteOption.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    //Avoid the overwrite message
    if(_moveFile.overWritteOption) {
        [_moveFile.overWritteOption.overwriteOptionsActionSheet dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    //Close the openWith option in FileViewController
    if (!IS_IPHONE && self.mShareFileOrFolder && self.mShareFileOrFolder.activityPopoverController) {
        [self.mShareFileOrFolder.activityPopoverController dismissPopoverAnimated:NO];
    }
    
    //Close the shareActionSheet in order to not have errors after rotate and click
    if (!IS_IPHONE && self.mShareFileOrFolder) {

        [self.mShareFileOrFolder.shareActionSheet dismissWithClickedButtonIndex:self.mShareFileOrFolder.shareActionSheet.cancelButtonIndex animated:NO];
    }
    
    //Close the _moreActionSheet in order to not have errors after rotate and click
    if (!IS_IPHONE && _moreActionSheet) {
        [self.moreActionSheet dismissWithClickedButtonIndex:self.moreActionSheet.cancelButtonIndex animated:NO];
    }
}


#pragma mark Loading view methods

/*
 * Method that launch the loading screen and block the view
 */
-(void)initLoading {
    
    if (_HUD) {
        [_HUD removeFromSuperview];
        _HUD=nil;
    }
    
    if (IS_IPHONE) {
        _HUD = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        _HUD.delegate = self;
        [self.view.window addSubview:_HUD];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        _HUD = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        _HUD.delegate = self;
        [app.splitViewController.view.window addSubview:_HUD];
    }
    
    _HUD.labelText = NSLocalizedString(@"loading", nil);
    
    if (IS_IPHONE) {
        _HUD.dimBackground = NO;
    }else {
        _HUD.dimBackground = NO;
    }
    
    [_HUD show:YES];
    
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    [self.view.window setUserInteractionEnabled:NO];
}


/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    
    if (!_isLoadingForNavigate) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        //Check if the loading should be visible
        if (app.isLoadingVisible==NO) {
            // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
            [_HUD removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            self.navigationController.navigationBar.userInteractionEnabled = YES;
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            [self.view.window setUserInteractionEnabled:YES];
        }
        
        //Check if the app is wainting to show the upload from other app view
        if (app.isFileFromOtherAppWaitting && app.isPasscodeVisible == NO) {
            [app performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.3];
        }
        
        if (!_rename.renameAlertView.isVisible) {
            _rename = nil;
        }
    }
}


#pragma mark - Notifications methods

/*
 * This method addObservers for notifications to this class.
 * The notifications added in viewDidLoad
 */
- (void) setNotificationForCommunicationBetweenViews {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFromDataBase) name:IpadFilePreviewViewControllerFileWasDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFromDataBase) name:IpadFilePreviewViewControllerFileWasDownloadNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFromDataBaseWithFileDto:) name:fileWasDownloadNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockViewWhileFileIsDownloading) name:IpadFilePreviewViewControllerFileWhileDonwloadingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unBlockViewWhileFileIsDownloading) name:IpadFilePreviewViewControllerFileFinishDownloadNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unBlockViewWhileFileIsDownloading) name:IpadFinishDownloadStateWhenApplicationDidEnterBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCellWithThisFile:) name:IpadSelectRowInFileListNotification object:nil];
    //Add a observer to the end loading, init loading and reloadTableFromDataBase
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endLoading) name:EndLoadingFileListNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initLoading) name:InitLoadingFileListNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFromDataBase) name:ReloadFileListFromDataBaseNotification object:nil];
    
    //Add an observer for know when the LoginViewController rotate
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotateToInterfaceOrientation:duration:) name:loginViewControllerRotate object:nil];
    
    //Add an observer for know when the Checked Share of server is done
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSharedPath) name:RefreshSharesItemsAfterCheckServerVersion object:nil];
    
    //Add an observer for update the file sync
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFromDataBaseWithFileDto:) name:FavoriteFileIsSync object:nil];
}


/*
 * Method that block this view while file is download in the preview of ipad
 */
-(void)blockViewWhileFileIsDownloading{
    self.navigationController.navigationBar.userInteractionEnabled=NO;
    self.tabBarController.tabBar.userInteractionEnabled=NO; 
    _tableView.userInteractionEnabled=NO;
}

/*
 * Method that unBlock this view when the file is finish download or fail
 */
-(void)unBlockViewWhileFileIsDownloading{
    self.navigationController.navigationBar.userInteractionEnabled=YES;
    self.tabBarController.tabBar.userInteractionEnabled=YES;
    _tableView.userInteractionEnabled=YES;
}

/*
 * Method that hide the preview page on iPad.
 */
-(void) hidePreviewOniPad{
    if (!IS_IPHONE) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [app.detailViewController unselectCurrentFile];
    }
}


#pragma mark - Create Folder

/*
 * This method show an pop up view to create folder
 */
- (void)showCreateFolder{
    _folderView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"create_folder", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"save", nil), nil];
    _folderView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_folderView textFieldAtIndex:0].delegate = self;
    [[_folderView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[_folderView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    [_folderView show];
}

/*
 * This method check for the folder with the same name that the user want create.
 * string -> it's the string to compare
 */
-(BOOL)checkForSameName:(NSString *)string
{
    string = [string stringByAppendingString:@"/"];
    string = [string stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    
    NSString *dicName;
    
    for (int i=0; i<[_currentDirectoryArray count]; i++) {
        
        FileDto *fileDto = [_currentDirectoryArray objectAtIndex:i];       
        
        //DLog(@"%@", fileDto.fileName);       
        
        dicName=fileDto.fileName;
        dicName=[dicName stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];        
        
        if([string isEqualToString:dicName]) {
            return YES;
        }
    }
    return NO;
}

/*
 * This method create new folder in path
 * @name -> it is the name of the new folder
 */
-(void) newFolderSaveClicked:(NSString*)name {
    
    if (![FileNameUtils isForbiddenCharactersInFileName:name withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]]) {
        
        //Check if exist a folder with the same name
        if ([self checkForSameName:name] == NO) {
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            //Set the right credentials
            if (k_is_sso_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
            } else if (k_is_oauth_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
            } else {
                [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
            }
            
            [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];

            NSString *newURL = [NSString stringWithFormat:@"%@%@",self.currentRemoteFolder,[name encodeString:NSUTF8StringEncoding]];
            NSString *rootPath = [UtilsUrls getFilePathOnDBByFullPath:newURL andUser:app.activeUser];
            
            NSString *pathOfNewFolder = [NSString stringWithFormat:@"%@%@",[self.currentRemoteFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], name ];
            
            [[AppDelegate sharedOCCommunication] createFolder:pathOfNewFolder onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                DLog(@"Folder created");
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active && redirectedServer) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                    if (isSamlCredentialsError) {
                        [self errorLogin];
                    }
                }
                if (!isSamlCredentialsError) {
                    
                    //Obtain the path where the folder will be created in the file system
                    NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@/%ld/%@",[UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser,[rootPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    
                    DLog(@"Name of the folder: %@ to create in: %@",name, currentLocalFileToCreateFolder);
                    
                    //Create the new folder in the file system
                    [FileListDBOperations createAFolder:name inLocalFolder:currentLocalFileToCreateFolder];
                    [self refreshTableFromWebDav];
                }
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                DLog(@"error: %@", error);
                DLog(@"Operation error: %ld", (long)response.statusCode);
                [self manageServerErrors:response.statusCode and:error];
            } errorBeforeRequest:^(NSError *error) {
                if (error.code == OCErrorForbidenCharacters) {
                    [self endLoading];
                    DLog(@"The folder have problematic characters");
                    
                    NSString *msg = nil;
                    msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
                    
                    _alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [_alert show];
                } else {
                    [self endLoading];
                    DLog(@"The folder have problems under controlled");
                    _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unknow_response_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [_alert show];
                }
            }];
        }else {
            [self endLoading];
            DLog(@"Exist a folder with the same name");
            _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folder_exist", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [_alert show];
        }

    }else{
        [self endLoading];
        //Forbidden characters found after the request.
        NSString *msg = nil;
        msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
        
        _alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [_alert show];
        
    }
}


#pragma mark - UIAlertViewDelegate
- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    switch (alertView.tag) {
        case k_alertview_for_download_error: {
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            app.downloadErrorAlertView = nil;
            
            break;
        }
        default: {
            // cancel
            if( buttonIndex == 1 ){
                //Save "Create Folder"
                
                NSString* result = [alertView textFieldAtIndex:0].text;
                [self initLoading];
                [self performSelector:@selector(newFolderSaveClicked:) withObject:result];
                
            }else if (buttonIndex == 0) {
                //Cancel
                
            }else {
                //Nothing
            }
            break;
        }
    }
}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    
    NSString *stringNow = [alertView textFieldAtIndex:0].text;
    
    
    //Active button of folderview only when the textfield has something.
    NSString *rawString = stringNow;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        output = NO;
    }
    
    //Button save disable when the textfield is empty
    if ([stringNow isEqualToString:@""]) {
        output = NO;
    }
    
    return output;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    //DLog(@"editing textfield");
    return YES;
}

#pragma mark - Add a Photo or Video

/*
 * This method open the view to select photo/video folder
 */
- (void)addPhotoOrVideo {
	
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    app.isUploadViewVisible = YES;
    
    if (self.albumController) {
        self.albumController = nil;
    }
    
    if (self.elcPicker) {
        self.elcPicker = nil;
    }
    
    self.albumController = [[ELCAlbumPickerController alloc] initWithNibName: nil bundle: nil];
    self.elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:self.albumController];
    [self.albumController setParent: self.elcPicker];
	[self.elcPicker setDelegate:self];
    
    
    //Info of account and location path   
    NSArray *splitedUrl = [_currentRemoteFolder componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *folder = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-2)]];
    
    DLog(@"Folder is:%@", folder);
    if (_fileIdToShowFiles.isRootFolder) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        folder=appName;
    }
    
    //TODO: create subclass to include those variables
    
    self.albumController.currentRemoteFolder=_currentRemoteFolder;
    self.albumController.locationInfo=folder;
    /*
    albumController.locationInfo=folder;
    albumController.accountInfo=app.activeUser.username;
     */
    
    if (IS_IPHONE) {
        [self presentViewController:self.elcPicker animated:YES completion:nil];
    } else {
        
        self.elcPicker.modalPresentationStyle = UIModalPresentationFormSheet;
       
        if (IS_IOS8) {
            [app.detailViewController presentViewController:self.elcPicker animated:YES completion:nil];
        } else {
            [app.splitViewController presentViewController:self.elcPicker animated:YES completion:nil];
        }
    }
    
}

/*
 * Method that show the options when the user tap + button
 */
- (void)showOptions {
    
    if (self.plusActionSheet) {
        self.plusActionSheet = nil;
    }
    
    self.plusActionSheet = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                            destructiveButtonTitle:nil
                            otherButtonTitles:NSLocalizedString(@"menu_upload", nil), NSLocalizedString(@"menu_folder", nil), nil];
    
    self.plusActionSheet.actionSheetStyle=UIActionSheetStyleDefault;
    self.plusActionSheet.tag=100;
    
    if (IS_IPHONE) {
        [self.plusActionSheet showInView:self.tabBarController.view];
    } else {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (IS_IOS8) {
            [self.plusActionSheet showInView:app.splitViewController.view];
        } else {
            [self.plusActionSheet showInView:app.detailViewController.view];
        }
    }
}


#pragma mark - ELCImagePickerControllerDelegate Methods

/*
 * Method Delegate of the upload file selector to bring the selected files
 * @info -> array with the items
 * @remoteURLToUpload -> server path to upload selected files
 */
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info inURL:(NSString*)remoteURLToUpload
{
	//[self dismissModalViewControllerAnimated:YES];
    
    //[self dismissModalViewControllerAnimated:YES];
	/*if(uploadingFilesArray != nil){
     uploadingFilesArray = nil;
     }*/   
    
    NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
                           (NSArray *) info, @"info",
                           (NSString *) remoteURLToUpload, @"remoteURLToUpload", nil];
    
    [self performSelectorInBackground:@selector(initUploadFileFromGalleryInOtherThread:) withObject:args];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    app.isUploadViewVisible = NO;
    
    //[self endLoading];
}

- (void)initUploadFileFromGalleryInOtherThread:(NSDictionary *) args {
    
    NSArray *info = [args objectForKey:@"info"];
    NSString *remoteURLToUpload = [args objectForKey:@"remoteURLToUpload"];
        
    /*
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [self dismissModalViewControllerAnimated:YES];
        
        
    } else {
        [app.splitViewController dismissModalViewControllerAnimated:YES];
    }*/
    
    if([info count]>0){
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if(app.prepareFiles == nil) {
            app.prepareFiles = [[PrepareFilesToUpload alloc] init];
            app.prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
            app.prepareFiles.listOfAssetsToUpload = [[NSMutableArray alloc] init];
            app.prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
            app.prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
        }
        app.prepareFiles.delegate = app;
        app.prepareFiles.counterUploadFiles = 0;
        app.uploadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            // If you’re worried about exceeding 10 minutes, handle it here
        }];
        
        NSMutableArray *arrayOfRemoteurl = [[NSMutableArray alloc] init];
        
        for (int i = 0 ; i < [info count] ; i++) {
            [arrayOfRemoteurl addObject:remoteURLToUpload];
        }
        
        [self performSelector:@selector(initPrepareFiles:andArrayOFfolders:) withObject:info withObject: arrayOfRemoteurl];
    }
}

- (void) initPrepareFiles:(NSArray *) info andArrayOFfolders: (NSMutableArray *)  arrayOfRemoteurl{
   
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app.prepareFiles addFilesToUpload:info andRemoteFoldersToUpload: arrayOfRemoteurl];
    
    //Init loading to prepare files to upload
    [self initLoading];
    //Set global loading screen global flag to YES (only for iPad)
    app.isLoadingVisible = YES;
}

/*
 * The user tap the cancel button
 */
- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {   
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (IS_IPHONE){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        if (IS_IOS8) {
            [app.detailViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [app.splitViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    app.isUploadViewVisible = NO;
}

#pragma mark - UITableView delegate

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    // If the selected cell is showing the SwipeMenu, we don´t navigate further
    FileDto *selectedFile = (FileDto *)[[_sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    selectedFile = [ManageFilesDB getFileDtoByFileName:selectedFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:selectedFile.filePath andUser:app.activeUser] andUser:app.activeUser];
    _selectedFileDto = selectedFile;
    
    if (IS_IPHONE){
        
        [self goToSelectedFileOrFolder:selectedFile];
    } else {
        
        //Select in detail view
        if (_selectedCell) {
            CustomCellFileAndDirectory *temp = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:_selectedCell];
            [temp setSelectedStrong:NO];
        }
        
        if(selectedFile.isDirectory){
            [self initLoading];
            [self goToFolder:selectedFile];
        } else {
            //Select in detail
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            app.detailViewController.sortedArray=_sortedArray;
            [app.detailViewController handleFile:selectedFile fromController:fileListManagerController];
            
            CustomCellFileAndDirectory *sharedLink = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:indexPath];
            [sharedLink setSelectedStrong:YES];
            _selectedCell = indexPath;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView datasource

// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    

    if ([_currentDirectoryArray count] == 0) {
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        //If the _currentDirectoryArray doesn't have object will show a message
        //Identifier
        static NSString *CellIdentifier = @"EmptyCell";
        EmptyCell *emptyFileCell = (EmptyCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (emptyFileCell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"EmptyCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            emptyFileCell = (EmptyCell *)[topLevelObjects objectAtIndex:0];
        }
        
        //Autoresizing width when the iPhone is on landscape
        if (IS_IPHONE) {
            [emptyFileCell.textLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        }
        
        NSString *message = NSLocalizedString(@"message_not_files", nil);
        emptyFileCell.textLabel.text = message;
        emptyFileCell.textLabel.textAlignment = NSTextAlignmentCenter;
        //Disable the tap
        emptyFileCell.userInteractionEnabled = NO;
        cell = emptyFileCell;
        emptyFileCell = nil;
        
    } else {
    
        static NSString *CellIdentifier = @"FileAndDirectoryCell";
        
        CustomCellFileAndDirectory *fileCell = (CustomCellFileAndDirectory *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (fileCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CustomCellFileAndDirectory" owner:self options:nil];
            fileCell = (CustomCellFileAndDirectory *)[topLevelObjects objectAtIndex:0];
        }
        
        fileCell.indexPath = indexPath;
        
        //Autoresizing width when the iphone is landscape. Not in iPad.
        if (IS_IPHONE) {
            [fileCell.labelTitle setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [fileCell.labelInfoFile setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        }
        
        
        FileDto *file = (FileDto *)[[_sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
        
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:file.date];
        NSString *fileDateString;
        if (file.date > 0) {
            fileDateString = [InfoFileUtils getTheDifferenceBetweenDateOfUploadAndNow:date];
        } else {
            fileDateString = @"";
        }
        
        //Add a FileDownloadedIcon.png in the left of cell when the file is in device
        if (![file isDirectory]) {
            //Is file
            //Font for file
            UIFont *fileFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
            fileCell.labelTitle.font = fileFont;
            fileCell.labelTitle.text = [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSString *fileSizeString = @"";
            //Obtain the file size from the data base
            DLog(@"Size: %ld", file.size);
            float lenghSize = file.size;
            
            //If size is <0 we do not have the size
            if (file.size >= 0) {
                if (file.size < 1024) {
                    //Bytes
                    fileSizeString = [NSString stringWithFormat:@"%.f B", lenghSize];
                } else if ((file.size/1024) < 1024){
                    //KB
                    fileSizeString = [NSString stringWithFormat:@"%.1f KB", (lenghSize/1024)];
                } else {
                    //MB
                    fileSizeString = [NSString stringWithFormat:@"%.1f MB", ((lenghSize/1024)/1024)];
                }
            }
            
            if(file.isNecessaryUpdate) {
                fileCell.labelInfoFile.text = NSLocalizedString(@"this_file_is_older", nil);
            } else {
                if ([fileDateString isEqualToString:@""]) {
                    fileCell.labelInfoFile.text = [NSString stringWithFormat:@"%@", fileSizeString];
                } else {
                    fileCell.labelInfoFile.text = [NSString stringWithFormat:@"%@, %@", fileDateString, fileSizeString];
                }
            }
        } else {
            //Is directory
            //Font for folder
            UIFont *fileFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
            fileCell.labelTitle.font = fileFont;
            
            NSString *folderName = [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            //Quit the last character
            folderName = [folderName substringToIndex:[folderName length]-1];
            
            //Put the namefileCell.labelTitle.text
            fileCell.labelTitle.text = folderName;
            fileCell.labelInfoFile.text = [NSString stringWithFormat:@"%@", fileDateString];
        }
        
        fileCell = [InfoFileUtils getTheStatusIconOntheFile:file onTheCell:fileCell andCurrentFolder:self.fileIdToShowFiles];
        
        //Custom cell for SWTableViewCell with right swipe options
        fileCell.containingTableView = tableView;
        [fileCell setCellHeight:fileCell.frame.size.height];
        fileCell.leftUtilityButtons = [self setSwipeLeftButtons];
        
        fileCell.rightUtilityButtons = nil;
        fileCell.delegate = self;
        
        //Selection style gray
        fileCell.selectionStyle=UITableViewCellSelectionStyleGray;
        
        //Check if set selected previously
        if (_selectedCell && [_selectedCell compare: indexPath] == NSOrderedSame) {
            [fileCell setSelectedStrong:YES];
        }else{
            [fileCell setSelectedStrong:NO];
        }
        
        cell = fileCell;
        
        //Set the table footer
        [self setTheLabelOnTheTableFooter];
    }
    return cell;
}

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //If the _currentDirectoryArray doesn't have object it will have one section
    NSInteger sections = 1;
    if ([_currentDirectoryArray count] > 0) {
        sections = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
    }
    return sections;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //If the _currentDirectoryArray doesn't have object it will have one row
    NSInteger rows = 1;
    if ([_currentDirectoryArray count] > 0) {
        rows = [[_sortedArray objectAtIndex:section] count];
    }
    return rows;
}

//Return the row height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    //If the _currentDirectoryArray doesn't have object it will have a big row
    if ([_currentDirectoryArray count] == 0) {
        height = [UtilsTableView getUITableViewHeightForSingleRowByNavigationBatHeight:self.navigationController.navigationBar.bounds.size.height andTabBarControllerHeight:self.tabBarController.tabBar.bounds.size.height andTableViewHeight:_tableView.bounds.size.height];
    } else {
        height = 54.0;
    }
    return height;
}

// Returns the table view managed by the controller object.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //Only show the section title if there are rows in it
    BOOL showSection = [[_sortedArray objectAtIndex:section] count] != 0;
    NSArray *titles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
    
    if(k_minimun_files_to_show_separators > [_currentDirectoryArray count]) {
        showSection = NO;
    }
    return (showSection) ? [titles objectAtIndex:section] : nil;
}


// Asks the data source to return the titles for the sections for a table view.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // The commented part is for the version with searchField
    
    /*NSArray *titles = [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
     NSMutableArray *array = [NSMutableArray arrayWithArray:titles];
     [array insertObject:UITableViewIndexSearch atIndex:0];
     return [NSArray arrayWithArray:array];*/
    
    if(k_minimun_files_to_show_separators > [_currentDirectoryArray count]) {
        return nil;
    } else {
        tableView.sectionIndexColor = [UIColor colorOfSectionIndexColorFileList];
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
}

// Change the color of the header section on the table
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    //Only on iOS7 include transparency on the header section
    if (IS_IOS7) {
        view.tintColor = [UIColor colorOfHeaderTableSectionFileList];
    }
}


// Asks the data source to return the index of the section having the given title and section title index.
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    // The commented part is for the version with searchField
    
    /*if ([title isEqualToString:UITableViewIndexSearch])
     {
     [self.tableView scrollRectToVisible:self.displayController.searchBar.frame animated:NO];
     return -1;
     }
     else
     {
     return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index]-1;
     }*/
    
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

///-----------------------------------
/// @name setTheLabelOnTheTableFooter
///-----------------------------------

/**
 * This method set the label on the table footer with the quantity of files and folder
 */
- (void) setTheLabelOnTheTableFooter {
    [self obtainTheQuantityOfFilesAndFolders];
    
    //Set the text of the footer section
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, k_footer_label_width, 40)];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, k_footer_label_width, 40)];
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    
    footerLabel.font = appFont;
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    
    NSString *folders;
    NSString *files;
    NSString *footerText;
    if (_numberOfFiles > 1) {
        folders = [NSString stringWithFormat:@"%d %@", _numberOfFiles, NSLocalizedString(@"files", nil)];
    } else if (_numberOfFiles == 1){
        folders = [NSString stringWithFormat:@"%d %@", _numberOfFiles, NSLocalizedString(@"file", nil)];
    } else {
        folders = @"";
    }
    if (_numberOfFolders > 1) {
        files = [NSString stringWithFormat:@"%d %@", _numberOfFolders, NSLocalizedString(@"folders", nil)];
    } else if (_numberOfFolders == 1){
        files = [NSString stringWithFormat:@"%d %@", _numberOfFolders, NSLocalizedString(@"folder", nil)];
    } else {
        files = @"";
    }
    if ([folders isEqualToString:@""]) {
        footerText = files;
    } else if ([files isEqualToString:@""]) {
        footerText = folders;
    } else {
        footerText = [NSString stringWithFormat:@"%@, %@", folders, files];
    }
    footerLabel.text = footerText;
    
    [footerView addSubview:footerLabel];
    [_tableView setTableFooterView:footerView];
}



#pragma mark - Navigation methods

/*
 * Method that recevie NSData from the request and parse 
 * this data with XML parser and get the directory array
 * @requestArray --> Array of OCFileDto of path
 */

-(void)prepareForNavigationWithData:(NSArray *) requestArray {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

   // DLog(@"idFile: %d", _selectedFileDto.idFile);
   // DLog(@"name: %@", _selectedFileDto.fileName);
   // DLog(@"self.nextRemoteFolder: %@", _nextRemoteFolder);
    
    _selectedFileDto = [ManageFilesDB getFileDtoByFileName:_selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
    
    //Change the filePath from the library to our format
    for (FileDto *currentFile in directoryList) {
        //Remove part of the item file path
        NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
        if([currentFile.filePath length] >= [partToRemove length]){
            currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
        }
    }
    
   // DLog(@"The directory List have: %d elements", directoryList.count);
   // DLog(@"Directoy list: %@", directoryList);
    
    [ManageFilesDB insertManyFiles:directoryList andFileId:_selectedFileDto.idFile];
    
    [self navigateToUrl:_nextRemoteFolder andFileId:_selectedFileDto.idFile];
}

/*
 * Method calle from didSelectRow to indicate the selected file
 * If is directory navigation to the folder
 * if is file open preview 
 * @selectedFile -> FileDto object selected by the user
 */
- (void) goToSelectedFileOrFolder:(FileDto *) selectedFile {
    
    [self initLoading];
    
    if(selectedFile.isDirectory) {
        [self performSelector: @selector(goToFolder:) withObject:selectedFile];
    } else {
        self.navigationItem.backBarButtonItem = nil;

        //Depend of the iOS version 
        if (IS_IOS7) {
            //iOS 7 - only the arrow
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        } else {
            //iOS 6 - back button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        }
        FilePreviewViewController *viewController = [[FilePreviewViewController alloc]initWithNibName:@"FilePreviewViewController" selectedFile:selectedFile];
        
        //Hide tabbar
        viewController.hidesBottomBarWhenPushed = YES;
        viewController.sortedArray=_sortedArray;

        //Set the navigation bar to not translucent
        if (IS_IOS7) {
            [self.navigationController.navigationBar setTranslucent:NO];
        }
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

/*
 * Method called to indicate the url and the folder id to navigation to ther view
 * @url -> folder path
 * @fileIdToShowFiles -> folder id
 */
-(void)navigateToUrl:(NSString *) url andFileId:(NSInteger)fileIdToShowFiles {
    _isLoadingForNavigate = NO;
    [self endLoading];
    
    FilesViewController *filesViewController = [[FilesViewController alloc] initWithNibName:@"FilesViewController" onFolder:url andFileId:fileIdToShowFiles andCurrentLocalFolder:_currentLocalFolder];
    
    filesViewController.isEtagRequestNecessary = YES;
    
    [[self navigationController] pushViewController:filesViewController animated:YES];
}



#pragma mark - Navigation throught folders

//we search data to navigate to the clicked folder
/*
 * Method called to search data to navigated to clicked folder 
 * @selectedFile -> folder selected by the user
 */
- (void) goToFolder:(FileDto *) selectedFile {
    
    NSMutableArray *allFiles = [ManageFilesDB getFilesByFileIdForActiveUser:selectedFile.idFile];
    
    //TODO:Refactor other utils methods
    
    NSArray *splitedUrl = [[UtilsUrls getFullRemoteServerPath:_mUser] componentsSeparatedByString:@"/"];

    _nextRemoteFolder = [NSString stringWithFormat:@"%@//%@%@", [splitedUrl objectAtIndex:0], [splitedUrl objectAtIndex:2], [NSString stringWithFormat:@"%@%@",selectedFile.filePath, selectedFile.fileName]];
    
    //if no files we ask for it else go to the next folder
    if([allFiles count] <= 0) {
        
        _selectedFileDto = selectedFile;
        [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
        
        if ([_mCheckAccessToServer isNetworkIsReachable]){
            [self goToFolderWithoutCheck];
        } else {
            
            [self performSelectorOnMainThread:@selector(showAlertView:)
                                   withObject:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                waitUntilDone:YES];
            [self endLoading];
        }
    } else {
        [self navigateToUrl:_nextRemoteFolder andFileId:selectedFile.idFile];
    }
    
    //Launch the method to sync the favorites files with specific path
    NSNumber *folderId = [NSNumber numberWithInteger:selectedFile.idFile];
    [self performSelectorInBackground:@selector(syncFavoritesOfFolderId:) withObject:folderId];
}

/*
 * Request to the server to get the array files of the next remote folder
 */
-(void) goToFolderWithoutCheck {
    
    _isLoadingForNavigate = YES;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
     [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *path = _nextRemoteFolder;
    
   path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFolder:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
           //Pass the items with OCFileDto to FileDto Array
           NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
           [self prepareForNavigationWithData:directoryList];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        _isLoadingForNavigate = NO;
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        [self manageServerErrors:response.statusCode and:error];
    }];
}

#pragma mark - Refresh Methods

- (void) reloadTableFromDataBaseWithFileDto:(NSNotification *)notification {
    //int pass = [[[notification userInfo] valueForKey:@"pass"] intValue];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    FileDto *file = [notification object];
    
    //Update the filesDto
    _fileIdToShowFiles = [ManageFilesDB getFileDtoByFileName:_fileIdToShowFiles.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_fileIdToShowFiles.filePath andUser:app.activeUser] andUser:app.activeUser];
    file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if (file.fileId == _fileIdToShowFiles.idFile) {
        [self reloadTableFromDataBase];
    }
}

/*
 * Method that prepare the data of the database and
 * show this data in the tableview.
 */
-(void)reloadTableFromDataBase {
        
  //  DLog(@"self.fileIdToShowFiles.idFile: %d", self.fileIdToShowFiles.idFile);
    
    //Ad the files of the folder
    _currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile];
   // DLog(@"self.fileIdToShowFiles: %d", [self.currentDirectoryArray count]);
    
    //Sorted the files array
    _sortedArray = [self partitionObjects: _currentDirectoryArray collationStringSelector:@selector(fileName)];
    
    //update gallery array
    [self updateArrayImagesInGallery];
    
    //Update the table footer
    [self setTheLabelOnTheTableFooter];
        
    //Reload data in the table
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    
    //TODO: Remove this to prevent duplicate files
    /*if([_currentDirectoryArray count] != 0) {
        [self endLoading];
    }*/
}

/*
 * Method that prepare the data of the database and
 * show this data in the tableview but not remove the loading view.
 */
-(void)reloadTableFromDataBaseWithoutEndLoading {
    
    //  DLog(@"self.fileIdToShowFiles.idFile: %d", self.fileIdToShowFiles.idFile);
    
    //Ad the files of the folder
    _currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile];
    // DLog(@"self.fileIdToShowFiles: %d", [self.currentDirectoryArray count]);
    
    //Sorted the files array
    _sortedArray = [self partitionObjects: _currentDirectoryArray collationStringSelector:@selector(fileName)];
    
    //update gallery array
    [self updateArrayImagesInGallery];
    
    //Reload data in the table
    [_tableView reloadData];
}


///-----------------------------------
/// @name Update Array Images in Gallery
///-----------------------------------

/**
 * This method is for update all the time the 
 * array of images in galleryview in iPad
 *
 */
-(void)updateArrayImagesInGallery{
    
    if (!IS_IPHONE) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (app.detailViewController.galleryView) {
            [app.detailViewController.galleryView updateImagesArrayWithNewArray:_sortedArray];
        }
    }
}

///-----------------------------------
/// @name Pull Refresh Table View
///-----------------------------------

/**
 * This method is called when the user do a pull refresh
 * In this method call a method where does a server request.
 * @param refresh -> UIRefreshControl object
 */

-(void)pullRefreshView:(UIRefreshControl *)refresh {
    //refresh.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"loading_refresh", nil)];
    refresh.attributedTitle = nil;
    
    [self performSelector:@selector(refreshTableFromWebDav) withObject:nil];
}

///-----------------------------------
/// @name Stop the Pull Refresh
///-----------------------------------

/**
 * Method called when the server refresh is done in order to
 * terminate the pull refresh animation
 */
- (void)stopPullRefresh{
    
    //_refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"pull_down_refresh", nil)];
    [_refreshControl endRefreshing];
}

/*
 * Method to sync favorites of the current path. 
 * Usually we call this method in a background mode
 */
- (void) syncFavoritesOfFolderId:(NSNumber*)idFolder{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //Do operations in background thread
        NSInteger folder = [idFolder integerValue];
        
        //Launch the method to sync the favorites files with specific path
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [app.manageFavorites syncFavoritesOfFolder:folder withUser:app.activeUser.idUser];
        
    });
    
}

/*
 * Method to launch the method to init the refresh process with the server
 */
- (void)refreshTableFromWebDav {
    DLog(@"self.currentFileShowFilesOnTheServerToUpdateTheLocalFile: %ld", (long)self.currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile);
    
    [self performSelector:@selector(sendRequestToReloadTableView) withObject:nil];
    
    //Refresh the shared data
    [self performSelector:@selector(refreshSharedPath) withObject:nil];
    
    //Pass NSInteger to NSNumber in order to pass an object with performselectorinbackground
    NSNumber *folderId = [NSNumber numberWithInteger:self.currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile];
    [self performSelectorInBackground:@selector(syncFavoritesOfFolderId:) withObject:folderId];
}

/*
 * Method to check the access to the server:
 * if there are connection, send Webdav request.
 * if there are not connection, show a pop up.
 */
- (void)sendRequestToReloadTableView {
   
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *path = _currentRemoteFolder;
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFolder:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        
        if(response.statusCode != kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            
            //Pass the items with OCFileDto to FileDto Array
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
            
            //Send the data to DB and refresh the table
            [self deleteOldDataFromDBBeforeRefresh:directoryList];
        } else {
            [self stopPullRefresh];
            _showLoadingAfterChangeUser = NO;
        }

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        [self manageServerErrors:response.statusCode and:error];
        
    }];
}

/*
 * Method used for quit the flag about the refresh
 * and the system can be a new refresh action
 */
- (void)disableRefreshInProgress{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isRefreshInProgress=NO;
    
    [self reloadTableFromDataBase];
}

/*
 * This method receive the new array of the server and store the changes
 * in the Database and in the tableview
 * @param requestArray -> NSArray of path items
 */
-(void)deleteOldDataFromDBBeforeRefresh:(NSArray *) requestArray {
    
    //We update the current folder with the new etag
    [ManageFilesDB updateEtagOfFileDtoByid:_currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile andNewEtag: _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.isRefreshInProgress==NO) {
        app.isRefreshInProgress=YES;
        
        NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
        
        //Change the filePath from the library to our db format
        for (FileDto *currentFile in directoryList) {
            currentFile.filePath = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFile.filePath andUser:app.activeUser];
        }
        
        // DLog(@"The directory List have: %d elements", directoryList.count);
        // DLog(@"Directoy list: %@", directoryList);
     
        for (int i = 0 ; i < directoryList.count ; i++) {
            
            FileDto *currentFile = [directoryList objectAtIndex:i];
        
            if (currentFile.fileName == nil) {
                //This is the fileDto of the current father folder
                _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag = currentFile.etag;
                
                //We update the current folder with the new etag
                [ManageFilesDB updateEtagOfFileDtoByid:_currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile andNewEtag: _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag];
            }
        }
        
        self.fileIdToShowFiles = [ManageFilesDB getFileDtoByFileName:self.fileIdToShowFiles.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.fileIdToShowFiles.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        [FileListDBOperations makeTheRefreshProcessWith:directoryList inThisFolder:_fileIdToShowFiles.idFile];
        
        //Get from database all the files of the current folder (fileIdToShowFiles)
        _currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile];
        
        [FileListDBOperations createAllFoldersByArrayOfFilesDto:_currentDirectoryArray andLocalFolder:_currentLocalFolder];
        
        //Sorted the files array
        _sortedArray = [self partitionObjects: _currentDirectoryArray collationStringSelector:@selector(fileName)];
        
        //update gallery array
        [self updateArrayImagesInGallery];
        
        //Update the table footer
        [self setTheLabelOnTheTableFooter];
      
        [_tableView reloadData];
        [self stopPullRefresh];
        _showLoadingAfterChangeUser = NO;

        //TODO: Remove this to prevent duplicate files
        [self endLoading];
        
        [self performSelector:@selector(disableRefreshInProgress) withObject:nil afterDelay:0.5];
        
    } else {
        DLog(@"Inflag");
       [self stopPullRefresh];
       [self endLoading];
    }
}

#pragma mark - Shared methods

///-----------------------------------
/// @name Refresh Shared Path
///-----------------------------------

/**
 * This method do the request to the server, get the shared data of the all files
 * Then update the DataBase with the shared data in the files of the current path
 * Finally, reload the file list with the database data
 */
- (void) refreshSharedPath{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Check if the server has share support
    if ((app.activeUser.hasShareApiSupport == serverFunctionalitySupported) && (app.activeUser.idUser == _mUser.idUser)) {
        //Set the right credentials
        if (k_is_sso_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
        } else if (k_is_oauth_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
        } else {
            [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
        }
        
        [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
        
        NSString *path = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_fileIdToShowFiles.filePath andUser:app.activeUser];
        path = [path stringByAppendingString:_fileIdToShowFiles.fileName];
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //Checking the Shared files and folders
        [[AppDelegate sharedOCCommunication] readSharedByServer:app.activeUser.url andPath:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    //We don't show a error login in this request.
                    //[self errorLogin];
                }
            }
            if (!isSamlCredentialsError) {
                
                //GCD to do things async in background queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    //Do operations in background thread
                    
                    //Workaround to find the _fileIdToShowFiles because some times there are problems with the changes active user, and this method is launched before the viewwillappear
                    if (app.activeUser) {
                        FileDto *rootFileDto = [ManageFilesDB getRootFileDtoByUser:app.activeUser];
                        NSString *pathActiveUser = rootFileDto.filePath;
                       
                        if ([_fileIdToShowFiles.filePath rangeOfString:pathActiveUser].location == NSNotFound) {
                            _fileIdToShowFiles = rootFileDto;
                            DLog(@"Changing between accounts, update _fileIdToShowFiles with root path with the active user");
                        }
                    }
                    
                    NSArray *itemsToDelete = [ManageSharesDB getSharesByFolderPath:[NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_fileIdToShowFiles.filePath andUser:app.activeUser], _fileIdToShowFiles.fileName]];
                    
                    //1. We remove the removed shared from the Files table of the current folder
                    [ManageFilesDB setUnShareFilesOfFolder:_fileIdToShowFiles];
                    //2. Delete all shared to not repeat them
                    [ManageSharesDB deleteLSharedByList:itemsToDelete];
                    //3. Delete all the items that we want to insert to not insert them twice
                    [ManageSharesDB deleteLSharedByList:items];
                    //4. We add the new shared on the share list
                    [ManageSharesDB insertSharedList:items];
                    //5. Update the files with shared info of this folder
                    [ManageFilesDB updateFilesAndSetSharedOfUser:app.activeUser.idUser];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        //Make operations in main thread
                        //Refresh the list of files
                        [self reloadTableFromDataBaseWithoutEndLoading];
                        
                    });
                });
            }
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            
            DLog(@"error: %@", error);
            DLog(@"Operation error: %ld", (long)response.statusCode);
        }];

    } else if (app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
        //If the server has not been checked, do it
        [app checkIfServerSupportThings];
    }
}

#pragma mark - Order methods

/*
 * Method that sorts alphabetically array by selector
 *@array -> array of sections and rows of tableview
 */
- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++) {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    //put each object into a section
    for (id object in array) {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections) {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }
    return sections;
}


/*
 * This method is for show alert view in main thread.
 * @string -> string wiht the message of the alert view.
 */

- (void) showAlertView:(NSString*)string {
    
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    //Upload, create folder, cancel options (+ menu)
    if (actionSheet.tag==100) {
        switch (buttonIndex) {
            case 0:
                [self addPhotoOrVideo]; 
                break;
            case 1:
                [self showCreateFolder];
                break;
            default:
                break;
        }
    }
    
    //Long press menu    
    if (actionSheet.tag==200) {
        if(_selectedFileDto.isDirectory) {
            switch (buttonIndex) {
                case 0:
                    [self didSelectRenameOption];
                    break;
                case 1:
                    [self didSelectMoveOption];
                    break;
                default:
                    break;
            }
        } else {
            switch (buttonIndex) {
                case 0:
                    
                    if (_selectedFileDto.isDownload || [_mCheckAccessToServer isNetworkIsReachable]){
                        [self didSelectOpenWithOptionAndFile:_selectedFileDto];
                    } else {
                        _alert = nil;
                        _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                        [_alert show];
                    }
                    break;
                case 1:
                    [self didSelectRenameOption];
                    break;
                case 2:
                    [self didSelectMoveOption];
                    break;
                case 3:
                    [self didSelectFavoriteOption];
                    break;
                default:
                    break;
            }
        }
    }
}

#pragma mark - File/Folder

///-----------------------------------
/// @name Obtain the quantity of files
///-----------------------------------

/**
 * This method obtains the total quantity of files and folder on the data base
 */
- (void) obtainTheQuantityOfFilesAndFolders {
    _numberOfFiles = 0;
    _numberOfFolders = 0;
    for (int i = 0 ; i < [_currentDirectoryArray count] ; i++) {
        FileDto *currentFile = [_currentDirectoryArray objectAtIndex:i];
        if(currentFile.isDirectory) {
            _numberOfFolders ++;
        } else {
            _numberOfFiles ++;
        }
    }
}

#pragma mark - Open With option
/*
 * Method called when the user select the open with option 
 */
- (void)didSelectOpenWithOption{
    
    if (_selectedFileDto.isDownload || [_mCheckAccessToServer isNetworkIsReachable]){
        [self didSelectOpenWithOptionAndFile:_selectedFileDto];
    } else {
        _alert = nil;
        _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [_alert show];
    }
}

/*
 * Method used to download the file if is neccessary and
 * show the open with menu
 */
- (void)didSelectOpenWithOptionAndFile:(FileDto *)file {
    
    //Update fileDto
    _selectedFileDto=[ManageFilesDB getFileDtoByIdFile:file.idFile];
    
    //Phase 0. Know if the file is in the device
    if ([_selectedFileDto isDownload] == notDownload) {
        
        //Phase 1. Init openWith
        _openWith = [[OpenWith alloc]init];
        _openWith.delegate=self;
        _openWith.currentLocalFolder=_currentLocalFolder;
        
        //If is iPad get the selected cell
        if (!IS_IPHONE) {
            UITableViewCell *cell;
            //We use _selectedIndexPath to identify the position where we have to put the arrow of the popover
            if (_selectedIndexPath) {
                cell = [_tableView cellForRowAtIndexPath:_selectedIndexPath];
                _openWith.parentView=_tableView;
                _openWith.cellFrame = cell.frame;
                _openWith.isTheParentViewACell = YES;
            } else {
                _openWith.parentView=self.tabBarController.view;
            }
        } else {
            _openWith.parentView=self.tabBarController.view;
        }
        
        //Phase 2. Add View to show the download
        _downloadView = [[DownloadViewController alloc]init];       
        
        _downloadView.delegate=self;
        
        //Only iOS6
        if (IS_IOS7 || IS_IOS8) {
            _downloadView.view.frame = _tableView.frame;
            
        } else {
            _downloadView.view.frame = self.view.window.frame;
        }
        
        _downloadView.view.opaque=YES;
        _downloadView.view.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:0.5f];
        
        //Phase 3. Block view
        //self.tableView.userInteractionEnabled=NO;         
        self.navigationController.navigationBar.userInteractionEnabled=NO;
        self.tabBarController.tabBar.userInteractionEnabled=NO;
        
        //[self.view addSubview:_downloadView.view];
        [self.tabBarController.view addSubview:_downloadView.view];
        
        _downloadView.view.userInteractionEnabled=YES;
        
        [_downloadView configureView];
        
        //Phase 4. Download
        [_openWith downloadAndOpenWithFile:_selectedFileDto];
        
    } else if ([_selectedFileDto isDownload] == downloading) {
        
        //if the file is downloading alert the user
        _alert = nil;
        _alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"file_is_downloading", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [_alert show];
        
    } else {
        //Open the file
        _openWith = [OpenWith new];
        
        //Phase 1.5. Check is iPad or iPhone
        //If is iPad get the selected cell
        if (!IS_IPHONE) {
            UITableViewCell *cell;
            //We use _selectedIndexPath to identify the position where we have to put the arrow of the popover
            if (_selectedIndexPath) {
                cell = [_tableView cellForRowAtIndexPath:_selectedIndexPath];
                _openWith.parentView =_tableView;
                _openWith.cellFrame = cell.frame;
                _openWith.isTheParentViewACell = YES;
                
            } else {
                 _openWith.parentView=self.tabBarController.view;
            }
        } else {
            _openWith.parentView=self.tabBarController.view;
        }
        [_openWith openWithFile:_selectedFileDto];
    }
}

#pragma mark - CheckEtag Delegate

/*
 * Called from OpenWith class 
 */
/*- (void)openWithFileAfterCheckEtag:(BOOL) isUpdate {
    
    if(isUpdate) {
        //Open the file
        self.openWith = [[OpenWith alloc]init];
        self.openWith.parentView=self.tabBarController.view;
        
        [self.openWith openWithFile:self.selectedFileDto];
    } else {
        [ManageFilesDB setFileIsDownloadState:self.selectedFileDto.idFile andState:notDownload];
        self.selectedFileDto.isDownload = notDownload;
    }
    
}*/


#pragma mark - Delete option


/*
 * Method used to delete the selected file
 */
- (void)didSelectDeleteOption {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Update fileDto
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if ([self.selectedFileDto isDownload] == downloading) {
        //if the file is downloading alert the user
        self.alert = nil;
        self.alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"file_is_downloading", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [self.alert show];
        
    } else if ([self.selectedFileDto isDirectory]&& [DownloadUtils thereAreDownloadingFilesOnTheFolder: self.selectedFileDto]) {
        //if the user are downloading files from the server
        self.alert = nil;
        self.alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"msg_while_downloads", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [self.alert show];
        
    } else {
        
        self.mDeleteFile = [[DeleteFile alloc] init];
        self.mDeleteFile.delegate = self;
        self.mDeleteFile.currentLocalFolder = _currentLocalFolder;
        
        if(IS_IPHONE) {
            self.mDeleteFile.viewToShow = self.view;
        } else {
            self.mDeleteFile.viewToShow = app.detailViewController.view;
        }
        
        [self.mDeleteFile askToDeleteFileByFileDto:_selectedFileDto];
        
    }
}

#pragma mark - DeleteDelegate

- (void) removeSelectedIndexPath {
    self.selectedCell = nil;
}

#pragma mark - Rename option

// Called when the user selects the "Rename" option

/*
 * Method called when the user select the rename option
 * over the selected file
 */
- (void)didSelectRenameOption {
     AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Update fileDto
  self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if ([_selectedFileDto isDownload] == downloading) {
        //if the file is downloading alert the user
        self.alert = nil;
        self.alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"file_is_downloading", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [self.alert show];
        
    } else if ([self.selectedFileDto isDirectory] && [DownloadUtils thereAreDownloadingFilesOnTheFolder: self.selectedFileDto]) {
        //if the user are downloading files from the server
        self.alert = nil;
        self.alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"msg_while_downloads", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [self.alert show];
        
    } else {
        self.rename = [[RenameFile alloc] init];
        self.rename.delegate = self;
        self.rename.currentRemoteFolder = self.currentRemoteFolder;
        self.rename.currentDirectoryArray = self.currentDirectoryArray;
        self.rename.currentLocalFolder= self.currentLocalFolder;
        self.rename.mUser = self.mUser;
        [self.rename showRenameFile:self.selectedFileDto];
    }
    
}

#pragma mark - Move option

/*
 * Method called when the user select de move option
 */
- (void)didSelectMoveOption {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    Download *downloadFile;
    NSArray *downloadsArrayCopy = [NSArray arrayWithArray:[app.downloadManager getDownloads]];
    
    for (downloadFile in downloadsArrayCopy) {
        DLog(@"File: %@", downloadFile.fileDto);
        DLog(@"File: %@", downloadFile.fileToDownload);
    }
    
    //Update fileDto
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if ([_selectedFileDto isDownload] == downloading) {
        //if the file is downloading alert the user
        _alert = nil;
        _alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"file_is_downloading", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [_alert show];
        
    } else if ([_selectedFileDto isDirectory] && [DownloadUtils thereAreDownloadingFilesOnTheFolder: _selectedFileDto]) {
        //if the user are downloading files from the server
        _alert = nil;
        _alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"msg_while_downloads", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [_alert show];
        
    } else {
        
        self.selectFolderViewController = [[SelectFolderViewController alloc]initWithNibName:@"SelectFolderViewController" onFolder:[ManageFilesDB getRootFileDtoByUser:app.activeUser]];
        self.selectFolderViewController.toolBarLabelTxt = @"";
        
        self.selectFolderNavigation = [[SelectFolderNavigation alloc]initWithRootViewController:self.selectFolderViewController];
        self.selectFolderViewController.parent=self.selectFolderNavigation;
        self.selectFolderViewController.currentRemoteFolder = _currentRemoteFolder;
        
        //We get the current folder to create the local tree
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        NSString *localRootUrlString = [NSString stringWithFormat:@"%@%ld/", [UtilsUrls getOwnCloudFilePath], (long)_mUser.idUser];
        
        self.selectFolderViewController.currentLocalFolder = localRootUrlString;
        self.selectFolderNavigation.delegate=self;
        
        _moveTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            // If you’re worried about exceeding 10 minutes, handle it here
            //The move option should not be exceeding than 10 minutoes.
        }];
        
        if (IS_IPHONE) {
            [self presentViewController:self.selectFolderNavigation animated:YES completion:nil];
            
        } else {
            self.selectFolderNavigation.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            self.selectFolderNavigation.modalPresentationStyle = UIModalPresentationFormSheet;
            
            if (IS_IOS8) {
                //Remove all the views in the main screen for the iOS8 bug
                if (self.moreActionSheet) {
                    [self.moreActionSheet dismissWithClickedButtonIndex:0 animated:YES];
                }
            }
            [app.detailViewController presentViewController:self.selectFolderNavigation animated:YES completion:nil];
        }
        //Hide preview (only in iPad)
        [self hidePreviewOniPad];
    }
}

/*
 * Delegate method of movefile to indicate that move is finish
 * this method close de backgroundtask
 */
- (void)endMoveBackGroundTask {
    
    if (_moveTask) {
        [[UIApplication sharedApplication] endBackgroundTask:_moveTask];
    }
}

#pragma mark - Favorite option

/*
 * Method called when the user select the favorite or unfavorite option
 */

- (void) didSelectFavoriteOption {
    
    //Update fileDto
    _selectedFileDto = [ManageFilesDB getFileDtoByIdFile:_selectedFileDto.idFile];
    
    if (IS_IPHONE) {
        [self setFavoriteOrUnfavorite];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (app.detailViewController.file &&
            [app.detailViewController.file.fileName isEqual:_selectedFileDto.fileName] &&
            [app.detailViewController.file.filePath isEqual:_selectedFileDto.filePath]) {
            
            app.detailViewController.file = _selectedFileDto;
            [app.detailViewController didPressFavoritesButton:nil];
            
        } else {
            [self setFavoriteOrUnfavorite];
        }
    }
}

- (void) setFavoriteOrUnfavorite {
    //Update the file from the DB
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _selectedFileDto = [ManageFilesDB getFileDtoByFileName:_selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    if (_selectedFileDto.isFavorite) {
        _selectedFileDto.isFavorite = NO;
    } else {
        _selectedFileDto.isFavorite = YES;
        //Download the file if it's not downloaded
        if (_selectedFileDto.isDownload == notDownload) {
            [self downloadTheFile];
        }
    }
    
    //Update the DB
    [ManageFilesDB updateTheFileID:_selectedFileDto.idFile asFavorite:_selectedFileDto.isFavorite];
    if (_selectedFileDto.isFavorite && _selectedFileDto.isDownload == downloaded) {
        [self checkIfThereIsANewFavoriteVersion];
    }
    [self reloadTableFromDataBase];
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
    
    [self.manageFavorites thereIsANewVersionAvailableOfThisFile:self.selectedFileDto];
}


#pragma mark - Share option

/*
 * Method called when the user select de move option
 */
- (void)didSelectShareLinkOption {
    DLog(@"Share Link Option");

    if (self.mShareFileOrFolder) {
        self.mShareFileOrFolder = nil;
    }
    
    self.mShareFileOrFolder = [ShareFileOrFolder new];
    self.mShareFileOrFolder.delegate = self;
    
    //If is iPad get the selected cell
    if (!IS_IPHONE) {
        
        self.mShareFileOrFolder.viewToShow = self.splitViewController.view;
        
        //We use _selectedIndexPath to identify the position where we have to put the arrow of the popover
        if (_selectedIndexPath) {
            UITableViewCell *cell;
            cell = [_tableView cellForRowAtIndexPath:_selectedIndexPath];
            self.mShareFileOrFolder.cellFrame = cell.frame;
            self.mShareFileOrFolder.parentView = _tableView;
            self.mShareFileOrFolder.isTheParentViewACell = YES;
        }
    } else {
        
        self.mShareFileOrFolder.viewToShow=self.tabBarController.view;
    }
    
    [self.mShareFileOrFolder showShareActionSheetForFile:_selectedFileDto];
}


#pragma mark Select Folder Navigation Delegate Methods
/*
 * Method that receive the folder selected in the 
 * view of selection folder for the move option.
 * @folder -> folder selected. 
 */
- (void)folderSelected:(NSString*)folder {

    DLog(@"Folder: %@", folder);
    
   // [self pauseDonwloadsQueue];
    
    _moveFile = [[MoveFile alloc] init];
    if(!IS_IPHONE) {
        _moveFile.viewToShow = self.splitViewController.view;
    } else {
        _moveFile.viewToShow = self.view;
    }
    
    _moveFile.delegate = self;
    _moveFile.selectedFileDto = _selectedFileDto;
    _moveFile.destinationFolder = folder;
    _moveFile.destinyFilename = _selectedFileDto.fileName;
    [_moveFile initMoveProcess];
}


#pragma mark DetailView Methods
/*
 * Cancell all downloads in curse in detail view.
 */
- (void)cancelDownloadInDetailView {
   AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];    
   [appDelegate cancelDonwloadInDetailView];
}

/*
 * Method that mark a cell of the send fileDto.
 * This method is called from DetailViewController
 * only for iPad
 * @notification -> in this case the notification bring a FileDto object of 
 * what file is in detail view gallery.
 */
- (void)selectCellWithThisFile:(NSNotification*)notification {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (app.detailViewController.controllerManager == fileListManagerController) {
        
        //Deselect old selected row
        if (_selectedCell) {
            CustomCellFileAndDirectory *selectedRow = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:_selectedCell];
            [selectedRow setSelectedStrong: NO];
        } else {
            DLog(@"_selectedCell IS NIL!!!!");
        }
        
        FileDto *fileDto = (FileDto*)[notification object];
        
        NSInteger row = -1;
        NSInteger section = -1;
        
        //Look for the idFile of fileDto in cells
        NSInteger sections = _sortedArray.count;
        NSArray *cells;
        FileDto *file;
        for (int i=0; i<sections; i++) {
            
            cells=[_sortedArray objectAtIndex:i];
            
            for (int j=0; j<cells.count; j++) {
                //Deselected cell
                file = (FileDto *)[cells objectAtIndex:j];
                if (!file.isDirectory) {
                    if (file.idFile==fileDto.idFile) {
                        section=i;
                        row=j;
                    }
                }
            }
        }
        
        if (row>=0 && section>=0) {
            NSIndexPath *fileIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
            _selectedCell = fileIndexPath;
            
            //Select the new row
            CustomCellFileAndDirectory *newRow = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:fileIndexPath];
            [newRow setSelectedStrong:YES];
        }
    }
}


#pragma mark - Download delegate of the openWith option
/*
 * This method prepare the download manager to download a selected file
 */
- (void)downloadTheFile{
    if ([_selectedFileDto isDownload] == notDownload || _selectedFileDto.isNecessaryUpdate) {
        //Phase 1.2. If the image isn't in the device, download image
        DLog(@"The file is not download");
        Download *download = nil;
        download = [[Download alloc]init];
        download.currentLocalFolder = _currentLocalFolder;
        [download fileToDownload:_selectedFileDto];
    }
}

/*
 * Cancel the actual download file.
 */
-(void)cancelDownload{
    if (_openWith) {
        DLog(@"CANCEL DOWNLOAD");
        [_openWith cancelDownload];
        [_downloadView.view removeFromSuperview];
        //Ublock view    
        self.navigationController.navigationBar.userInteractionEnabled=YES;
        self.tabBarController.tabBar.userInteractionEnabled=YES; 
    }
}
/*
 * Return the percentage download transfer
 * @percent -> percento of the download progress
 */
- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{    
    _downloadView.progressView.progress=percent;
}

/*
 * Return the string of download transfer.
 * @string -> string with the information about the download progress
 */
- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
    _downloadView.progressLabel.text=string;
    
}

/*
 * Download complete
 */
- (void)downloadCompleted:(FileDto*)fileDto {
    
    [_downloadView.view removeFromSuperview];
    //Unlock view 
    self.navigationController.navigationBar.userInteractionEnabled=YES;
    self.tabBarController.tabBar.userInteractionEnabled=YES;
    
    //Reload all the view
    [self viewWillAppear:YES];
}

/*
 * Download failed
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto {
    [_downloadView.view removeFromSuperview];
    //Unlock view
    self.navigationController.navigationBar.userInteractionEnabled=YES;
    self.tabBarController.tabBar.userInteractionEnabled=YES; 
    
    //Check the string in order to doesn't show an empty alert view.
    if (string) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (!app.downloadErrorAlertView) {
            
            app.downloadErrorAlertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            app.downloadErrorAlertView.tag = k_alertview_for_download_error;
            [app.downloadErrorAlertView show];
        }
    }
}

#pragma mark - Etag methods

/*
 * Method that check the etag before the folder request, called in willviewappear 
 * when the checketag flag is enable
 * @req --> NSData of the server request
 */
-(void)checkEtagBeforeMakeRefreshFolderRequest:(NSArray *) requestArray {
    
    _checkingEtag = NO;
    
   //if(req.responseStatusCode < 401) {
    
    // OCXMLParser *parser = [[OCXMLParser alloc]init];
    // [parser initParserWithData:req];
    
    NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Change the filePath from the library to our format
    for (FileDto *currentFile in directoryList) {
        //Remove part of the item file path
        NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
        if([currentFile.filePath length] >= [partToRemove length]){
            currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
        }
    }
    
    DLog(@"The directory List have: %ld elements", (long)directoryList.count);
    
    DLog(@"Directoy list: %@", directoryList);
    
    
      //  NSMutableArray *directoryList = [[req getDirectoryList] mutableCopy];
    
    //If directoryList is 0 you are making the request to a URL without any ownCloud server
    if ([directoryList count] > 0) {
        FileDto *currentFileDto = [directoryList objectAtIndex:0];
        
        DLog(@"currentFileDto: %@ - %@", _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag ,currentFileDto.etag);
        
        if(![_currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag isEqual:currentFileDto.etag]) {
            
            DLog(@"The etag it's not the same, need refresh");
            
            //self.currentFileShowFilesOnTheServerToUpdateTheLocalFile = self.currentFileShowFiles;
            _currentFileShowFilesOnTheServerToUpdateTheLocalFile.etag = currentFileDto.etag;
            
            [self refreshTableFromWebDav];
        } else if ([_currentDirectoryArray count] == 0) {
            //This end loading is necessary when you change to a user with empty folder
            [self endLoading];
        }
    }
}



#pragma mark - Server connect methods

/*
 * Method called when receive a fail from server side
 * @errorCodeFromServer -> WebDav Server Error of NSURLResponse
 * @error -> NSError of NSURLConnection
 */

- (void)manageServerErrors: (NSInteger)errorCodeFromServer and:(NSError *)error {
    
    [self stopPullRefresh];
    [self endLoading];

    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [_manageNetworkErrors manageErrorHttp:errorCodeFromServer andErrorConnection:error andUser:app.activeUser];
}

/*
 * Method called when there are a fail connection with the server
 * @NSString -> Server error msg
 */
- (void)showError:(NSString *) message {
    
    if (!_checkingEtag) {
        
        [self performSelectorOnMainThread:@selector(showAlertView:)
                               withObject:message
                            waitUntilDone:YES];
    } else {
        _checkingEtag = NO;
    }
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
}

/*
 * Methods from the server side to inform about a error with the server
 * about login, connection or certificate
 */

-(void) errorLogin {
    
    DLog(@"Error Login");
    
    [self endLoading];
    
    //Flag to indicate that the error login is in the screen
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (app.isErrorLoginShown == NO && !_checkingEtag) {
        app.isErrorLoginShown = YES;
        
        //In SAML the error message is about the session expired
        if (k_is_sso_active) {
            //UIAlertView with blocks
            [UIAlertView showWithTitle:NSLocalizedString(@"session_expired", nil) message:@"" cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"ok", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
                [self showEditAccount];
            }];
        } else {
            //UIAlertView with blocks
            [UIAlertView showWithTitle:NSLocalizedString(@"error_login_message", nil) message:@"" cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"ok", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
                [self showEditAccount];
            }];
        }
    }
    
    if(!_checkingEtag) {
        [self stopPullRefresh];
        [self cancelDownload];
    }
    _checkingEtag = NO;
}

- (void) showEditAccount {
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Edit Account
    _resolvedCredentialError = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser];
    [_resolvedCredentialError setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:_resolvedCredentialError];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:_resolvedCredentialError];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }
}

-(void)connectionToTheServer:(BOOL)isConnection {
    if(isConnection) {
        DLog(@"Ok, we have connection to the server");
    } else {        
        //Error msg
        //Call showAlertView in main thread
        [self performSelectorOnMainThread:@selector(showAlertView:)
                               withObject:NSLocalizedString(@"not_possible_connect_to_server", nil)
                            waitUntilDone:YES];
    }
}

-(void)repeatTheCheckToTheServer {
    //ok, certificate accepted
}

-(void)badCertificateNoAcceptedByUser {
    DLog(@"Certificate refushed by user");
}

#pragma mark - SWTableViewDelegate  Datasource

///-----------------------------------
/// @name Set Swipe Right Buttons
///-----------------------------------

/**
 * This method set the two right buttons for the swipe
 * Share button in gray
 * UnShare button in red
 *
 */
- (NSArray *)setSwipeRightButtons
{
    //No Right buttons
    
    return nil;
}

///-----------------------------------
/// @name Set Swipe Left Buttons
///-----------------------------------

/**
 * This method is empty now because we don't need left swippe buttons
 *
 */

- (NSArray *)setSwipeLeftButtons
{
    //Share gray button
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    BOOL areTwoButtonsInTheSwipe = NO;
    
    if (!k_hide_share_options) {
        //Three buttons
        areTwoButtonsInTheSwipe = NO;
    }else{
        //Two buttons
        areTwoButtonsInTheSwipe = YES;
    }
    
    UIColor *normalColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0f];
    UIColor *destructiveColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f];
    
    
    //More
    [rightUtilityButtons sw_addUtilityOneLineButtonWithColor:normalColor title:NSLocalizedString(@"more_swipe", nil) andImage:[UIImage imageNamed:@"more-filled.png"]  forTwoButtons:areTwoButtonsInTheSwipe];
    
    if (!areTwoButtonsInTheSwipe) {
        //Share
        [rightUtilityButtons sw_addUtilityOneLineButtonWithColor:normalColor title:NSLocalizedString(@"share_link_long_press", nil) andImage:[UIImage imageNamed:@"sharedItemSwipe.png"]  forTwoButtons:areTwoButtonsInTheSwipe];
        
    }
    
    //Delete
    [rightUtilityButtons sw_addUtilityOneLineButtonWithColor:destructiveColor title:NSLocalizedString(@"delete_label", nil) andImage:[UIImage imageNamed:@"deleteBlack.png"] forTwoButtons:areTwoButtonsInTheSwipe];
    
    
    
    return rightUtilityButtons;
}

#pragma mark - SWTableViewDelegate

///-----------------------------------
/// @name Button of Left Called
///-----------------------------------

/**
 * This method is called when the user call a button of the left swipe. Not in user now
 *
 * @param cell -> SWTableViewCell (Cell selected)
 * @param index -> NSInteger (order of the button tapped)
 */
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
    //We use _selectedIndexPath to identify the position where we have to put the arrow of the popover
    _selectedIndexPath = [_tableView indexPathForCell:cell];
    _selectedFileDto = (FileDto *)[[_sortedArray objectAtIndex:_selectedIndexPath.section]objectAtIndex:_selectedIndexPath.row];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if ([_selectedFileDto.fileName isEqualToString:app.detailViewController.file.fileName] &&
        [_selectedFileDto.filePath isEqualToString:app.detailViewController.file.filePath] &&
        _selectedFileDto.userId == app.detailViewController.file.userId) {
        app.detailViewController.file = _selectedFileDto;
    }
    
    [cell hideUtilityButtonsAnimated:YES];
    
     if (!k_hide_share_options) {
         
     }
    
    switch (index) {
        case 0:
        {
            DLog(@"Click on index 0 - More");
            [self didSelectMoreOptions];
            break;
        }
        case 1:
        {
            if (!k_hide_share_options) {
                DLog(@"Click on index 1 - Share");
                [self didSelectShareLinkOption];
                break;
            }else{
                DLog(@"Click on index 2 - Delete");
                [self didSelectDeleteOption];
                break;
            }

        }
        case 2:
        {
            if (!k_hide_share_options) {
                DLog(@"Click on index 2 - Delete");
                [self didSelectDeleteOption];
                break;
            }
        }
        default:
            break;
    }
}

///-----------------------------------
/// @name Button of Right Called
///-----------------------------------

/**
 * This method is called when the user call a button of the right swipe
 *
 * @param cell -> SWTableViewCell (Cell selected)
 * @param index -> NSInteger (order of the button tapped)
 */
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    //Nothing
}

///-----------------------------------
/// @name Swipe Cell Should Hide Utility buttons on swipe
///-----------------------------------

/**
 * This method is called when a cell receive a swipe action
 * if return YES -> The before cell open will be hide
 * if return NO -> No actions. You can show all cell swipe options
 *
 * @param cell -> SWTableViewCell
 
 *
 * @return BOOL -> YES/NO
 *
 */
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    
    return YES;
}


///-----------------------------------
/// @name didSelectMoreOptions
///-----------------------------------

/**
 * Method to show the ActionSheet after click over "More" on the swipe menu
 *
 */
- (void) didSelectMoreOptions {
    
    if (self.moreActionSheet) {
        self.moreActionSheet = nil;
    }
    
    if(_selectedFileDto.isDirectory) {
        
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"rename_long_press", nil), NSLocalizedString(@"move_long_press", nil), nil];
        self.moreActionSheet.tag=200;
        
        if (IS_IPHONE) {
            [self.moreActionSheet showInView:self.tabBarController.view];
        }else {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            if (IS_IOS8) {
                [self.moreActionSheet showInView:app.splitViewController.view];
            } else {
                [self.moreActionSheet showInView:app.detailViewController.view];
            }
        }
    } else {
        
        NSString *favoriteOrUnfavoriteString = @"";
        
        if (_selectedFileDto.isFavorite) {
            favoriteOrUnfavoriteString = NSLocalizedString(@"unfavorite", nil);
        } else {
            favoriteOrUnfavoriteString = NSLocalizedString(@"favorite", nil);
        }
        
        self.moreActionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle: nil otherButtonTitles:NSLocalizedString(@"open_with_label", nil), NSLocalizedString(@"rename_long_press", nil), NSLocalizedString(@"move_long_press", nil), favoriteOrUnfavoriteString, nil];
        self.moreActionSheet.tag=200;
        
        if (IS_IPHONE) {
            [self.moreActionSheet showInView:self.tabBarController.view];
        }else {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            if (IS_IOS8) {
                [self.moreActionSheet showInView:app.splitViewController.view];
            } else {
                [self.moreActionSheet showInView:app.detailViewController.view];
            }
        }
    }
    
}

#pragma mark - ManageFavoritesDelegate

- (void) fileHaveNewVersion:(BOOL)isNewVersionAvailable {
    
    if (isNewVersionAvailable) {
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        //Set if there is a new version of a favorite file and it's not checked
        
        //Set the file as isNecessaryUpdate
        [ManageFilesDB setIsNecessaryUpdateOfTheFile:_selectedFileDto.idFile];
        //Update the file on memory
        _selectedFileDto = [ManageFilesDB getFileDtoByFileName:_selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];

        //Do the request to get the shared items
        [self downloadTheFile];
        
    }
}

@end
