//
//  FilesViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
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
#import "UtilsFramework.h"
#import "ShareMainViewController.h"
#import "SyncFolderManager.h"
#import "IndexedForest.h"
#import "ManageCapabilitiesDB.h"
#import "CheckCapabilities.h"
#import "SortManager.h"
#import "EditFileViewController.h"
#import "CheckFeaturesSupported.h"

//Constant for iOS7
#define k_status_bar_height 20
#define k_navigation_bar_height 44
#define k_navigation_bar_height_in_iphone_landscape 32

@interface FilesViewController ()

@property (nonatomic, strong) ELCAlbumPickerController *albumController;
@property (nonatomic, strong) ELCImagePickerController *elcPicker;
@property (nonatomic) BOOL didLayoutSubviews;
@property (nonatomic) BOOL willLayoutSubviews;

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
    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = self;
    
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
    
    self.didLayoutSubviews = false;
    self.willLayoutSubviews = false;
    
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
        _currentLocalFolder = [NSString stringWithFormat:@"%@%@", _currentLocalFolder, [_fileIdToShowFiles.fileName stringByRemovingPercentEncoding]];
        DLog(@"CurrentLocalFolder: %@", _currentLocalFolder);
    }
    
    DLog(@"self.currentRemoteFolder: %@",_currentRemoteFolder);
    
    //Store the new active user, maybe can be different in the future in this same view
    _mUser = app.activeUser;
    
    //Add a more button
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more-filled"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];
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

}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.didLayoutSubviews = true;
    
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
            [_tableView setContentOffset:CGPointMake(0,-(k_navigation_bar_height + k_status_bar_height)) animated:animated];
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
    
    self.willLayoutSubviews = true;
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = true;
    self.automaticallyAdjustsScrollViewInsets = true;

    
    //Appear the tabBar
    self.tabBarController.tabBar.hidden=NO;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *currentUser = [ManageUsersDB getActiveUser];
    //ErrorLogin
    if ([UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:currentUser.predefinedUrl]) {
        [self errorLogin];
    }
    
    app.currentViewVisible = self;
    
    // if we are migrating the url no relaunch pending uploads
    if (![UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:app.activeUser.predefinedUrl]) {
        
        [self initFilesView];
        
    }

    //Assign this class to presentFilesViewController
    app.presentFilesViewController=self;
    
    //Add loading screen if it's necessary (Used by restoring the loading view after a rotate when the uploading processing)
    if (app.isLoadingVisible==YES) {
        [self initLoading];
        
    }

}

- (void)initFilesView {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *currentUser = [ManageUsersDB getActiveUser];
    //Flag to know when the view change automatic to root view
    BOOL isGoToRootView = NO;
    
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
         [currentUser.url isEqualToString:_mUser.url] &&
         currentUser.idUser == _mUser.idUser)) {
        //We are changing of user
        //Show the file list in the correct place
        [self.tableView setContentOffset:CGPointMake(0,0) animated:YES];
        
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
            [self.navigationController popToRootViewControllerAnimated:YES];
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
        
        //Refresh the shared data
        [self refreshSharedPath];
        
        //Checking the etag
        NSString *path = _currentRemoteFolder;
        path = [path stringByRemovingPercentEncoding];
        
        [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            if (currentUser.idUser == app.activeUser.idUser) {
                DLog(@"Operation response code: %ld", (long)response.statusCode);
                
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
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
            } else {
                DLog(@"User changed while check a folder");
                [UtilsFramework deleteAllCookies];
            }
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            DLog(@"error: %@", error);
            DLog(@"Operation error: %ld", (long)response.statusCode);
            
            BOOL isSamlCredentialsError = NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                if (isSamlCredentialsError) {
                    [self errorLogin];
                }
            }
            if (!isSamlCredentialsError) {
                [self manageServerErrors:response.statusCode and:error];
            }
            
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
        NSString *folderName =  [currentFolder.fileName stringByRemovingPercentEncoding];
        
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
                                       style:UIBarButtonItemStylePlain
                                       target:nil
                                       action:nil];
        
        self.navigationItem.backBarButtonItem = backButton;
        
    } else if(_fileIdToShowFiles.isRootFolder) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithImage:[UIImage imageNamed:@""]
                                       style:UIBarButtonItemStylePlain
                                       target:nil
                                       action:nil];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        backButton.title = NSLocalizedString(appName, nil);
        self.navigationItem.backBarButtonItem = backButton;
    } else {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                       initWithImage:[UIImage imageNamed:@""]
                                       style:UIBarButtonItemStylePlain
                                       target:nil
                                       action:nil];
        self.navigationItem.backBarButtonItem = backButton;
    }
    
    // Deselect the selected row
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    self.didLayoutSubviews = true;
    
    _isEtagRequestNecessary = YES;
    
    //Cancel all the get thumbnails in visible cells
    UITableView *tableView = self.tableView; // Or however you get your table view
    NSArray *paths = [tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *path in paths) {
        [self cancelGetThumbnailByCell:[tableView cellForRowAtIndexPath:path]];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


-(void)viewDidLayoutSubviews
{
     [super viewDidLayoutSubviews];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    
    CGRect rect = self.navigationController.navigationBar.frame;
    float y = rect.size.height + rect.origin.y;
    self.tableView.contentInset = UIEdgeInsetsMake(y,0,0,0);
    
    if (self.didLayoutSubviews == false){
        self.didLayoutSubviews = true;
        [self viewDidAppear:true];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (self.willLayoutSubviews == false){
        self.willLayoutSubviews = true;
        [self viewWillAppear:true];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
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
        [self.plusActionSheet dismissWithClickedButtonIndex:4 animated:NO];
    }
    
    if(self.sortingActionSheet){
        [self.sortingActionSheet dismissWithClickedButtonIndex:2 animated:NO];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.HUD) {
            [self.HUD removeFromSuperview];
            self.HUD=nil;
        }
        
        if (IS_IPHONE) {
            self.HUD = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
            self.HUD.delegate = self;
            [[UIApplication sharedApplication].keyWindow addSubview:self.HUD];
        } else {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            
            _HUD = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
            _HUD.delegate = self;
            [app.splitViewController.view.window addSubview:_HUD];
        }
        
        self.HUD.labelText = NSLocalizedString(@"loading", nil);
        
        if (IS_IPHONE) {
            self.HUD.dimBackground = NO;
        }else {
            self.HUD.dimBackground = NO;
        }
        
        [self.HUD show:YES];
        
    });
}


/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isLoadingForNavigate) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            //Check if the loading should be visible
            if (app.isLoadingVisible==NO) {
                // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
                if (self.HUD) {
                    [self.HUD removeFromSuperview];
                }
            }
            
            //Check if the app is wainting to show the upload from other app view
            if (app.isFileFromOtherAppWaitting && app.isPasscodeVisible == NO) {
                [app performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.3];
            }
            
            if (!self.rename.renameAlertView.isVisible) {
                self.rename = nil;
            }
        }
    });

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
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableFileListAfterCapabilitiesUpdated) name:CapabilitiesUpdatedNotification object:nil];

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

#pragma mark - Create Text File

/*
 * This method show a view to enter text for new text file
 */
- (void)showCreateTextFile{
    
    EditFileViewController *viewController = [[EditFileViewController alloc] initWithFileDto:self.fileIdToShowFiles andModeEditing:NO];
    OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.translucent = NO;
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self presentViewController:navController animated:YES completion:nil];
    } else {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
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
    string = [string stringByRemovingPercentEncoding];
    
    NSString *dicName;
    
    for (int i=0; i<[_currentDirectoryArray count]; i++) {
        
        FileDto *fileDto = [_currentDirectoryArray objectAtIndex:i];       
        
        //DLog(@"%@", fileDto.fileName);       
        
        dicName=fileDto.fileName;
        dicName=[dicName stringByRemovingPercentEncoding];        
        
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
            
            NSString *pathOfNewFolder = [NSString stringWithFormat:@"%@%@",[self.currentRemoteFolder stringByRemovingPercentEncoding], name ];
            
            [[AppDelegate sharedOCCommunication] createFolder:pathOfNewFolder onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                DLog(@"Folder created");
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                    if (isSamlCredentialsError) {
                        [self errorLogin];
                    }
                }
                if (!isSamlCredentialsError) {
                    [self refreshTableFromWebDav];
                }
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                DLog(@"error: %@", error);
                DLog(@"Operation error: %ld", (long)response.statusCode);
                
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                    if (isSamlCredentialsError) {
                        [self errorLogin];
                    }
                }
                if (!isSamlCredentialsError) {
                    [self manageServerErrors:response.statusCode and:error];
                }
 
            } errorBeforeRequest:^(NSError *error) {
                if (error.code == OCErrorForbiddenCharacters) {
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


#pragma mark - UIAlertView and UIAlertViewDelegate
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

- (void) showAlertView:(NSString*)string {
    _alert = nil;
    _alert = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [_alert show];
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
    self.elcPicker.imagePickerDelegate = self;
    
    
    //Info of account and location path   
    NSArray *splitedUrl = [_currentRemoteFolder componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *folder = [NSString stringWithFormat:@"%@",[splitedUrl objectAtIndex:([splitedUrl count]-2)]];
    
    DLog(@"Folder selected to upload photos is:%@", folder);
    if (_fileIdToShowFiles.isRootFolder) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        folder=appName;
    }
    
    self.albumController.currentRemoteFolder=_currentRemoteFolder;
    self.albumController.locationInfo=folder;
    
    if (IS_IPHONE) {
        [self presentViewController:self.elcPicker animated:YES completion:nil];
    } else {
        
        self.elcPicker.modalPresentationStyle = UIModalPresentationFormSheet;
       
        if (IS_IOS8 || IS_IOS9)  {
            [app.detailViewController presentViewController:self.elcPicker animated:YES completion:nil];
        } else {
            [app.splitViewController presentViewController:self.elcPicker animated:YES completion:nil];
        }
    }
    
}

/*
 * Method that show the options when the user tap ... button
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
                            otherButtonTitles:NSLocalizedString(@"menu_upload", nil), NSLocalizedString(@"menu_folder", nil), NSLocalizedString(@"menu_text_file", nil), NSLocalizedString(@"sort_menu_title", nil), nil];
    
    self.plusActionSheet.actionSheetStyle=UIActionSheetStyleDefault;
    self.plusActionSheet.tag=100;
    
    if (IS_IPHONE) {
        [self.plusActionSheet showInView:self.tabBarController.view];
    } else {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (IS_IOS8 || IS_IOS9)  {
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
    [self initLoading];
    
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
    
    path = [path stringByRemovingPercentEncoding];
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }

    NSString *rootFolder =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
    
    
    [[AppDelegate sharedOCCommunication] checkServer:rootFolder onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        [self endLoading];
        NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
                               (NSArray *) info, @"info",
                               (NSString *) remoteURLToUpload, @"remoteURLToUpload", nil];
        
        [self performSelectorInBackground:@selector(initUploadFileFromGalleryInOtherThread:) withObject:args];
        
        app.isUploadViewVisible = NO;
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        [self endLoading];
        
        app.isUploadViewVisible = NO;
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [self manageServerErrors:response.statusCode and:error];
        }
    }];
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
    [app.prepareFiles addAssetsToUploadFromArray:info andRemoteFoldersToUpload: arrayOfRemoteurl];
    
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
        if (IS_IOS8 || IS_IOS9)  {
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
    FileDto *selectedFile = (FileDto *)[[[self.sortedArray copy] objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    selectedFile = [ManageFilesDB getFileDtoByFileName:selectedFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:selectedFile.filePath andUser:app.activeUser] andUser:app.activeUser];
    _selectedFileDto = selectedFile;
    
    if (IS_IPHONE){
        [self goToSelectedFileOrFolder:selectedFile andForceDownload:NO];
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
            [app.detailViewController handleFile:selectedFile fromController:fileListManagerController andIsForceDownload:NO];
            
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
        
        if (!IS_IPHONE) {
            fileCell.labelTitle.adjustsFontSizeToFitWidth=YES;
            fileCell.labelTitle.minimumScaleFactor=0.7;
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
        

        if (![file isDirectory]) {
            //Is file
            //Font for file
            UIFont *fileFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
            fileCell.labelTitle.font = fileFont;
            fileCell.labelTitle.text = [file.fileName stringByRemovingPercentEncoding];
            
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
            
            NSString *folderName = [file.fileName stringByRemovingPercentEncoding];
            //Quit the last character
            folderName = [folderName substringToIndex:[folderName length]-1];
            
            //Put the namefileCell.labelTitle.text
            fileCell.labelTitle.text = folderName;
            fileCell.labelInfoFile.text = [NSString stringWithFormat:@"%@", fileDateString];
        }
        
        file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
        
        fileCell = [InfoFileUtils getTheStatusIconOntheFile:file onTheCell:fileCell andCurrentFolder:self.fileIdToShowFiles andIsSonOfFavoriteFolder:self.isCurrentFolderSonOfFavoriteFolder ofUser:APP_DELEGATE.activeUser];
        
        //Thumbnail
        fileCell.thumbnailSessionTask = [InfoFileUtils updateThumbnail:file andUser:APP_DELEGATE.activeUser tableView:tableView cellForRowAtIndexPath:indexPath];
        
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
        
        //Put the new files son of favorites to download
        if (self.isCurrentFolderSonOfFavoriteFolder && !file.isDirectory && (file.isDownload == notDownload || file.isNecessaryUpdate)) {
            [[AppDelegate sharedManageFavorites] downloadSingleFavoriteFileSonOfFavoriteFolder:file];
        }
    }
    return cell;
}

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [SortManager numberOfSectionsInTableViewForUser:APP_DELEGATE.activeUser withFolderList:_currentDirectoryArray];
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SortManager numberOfRowsInSection:section forUser:APP_DELEGATE.activeUser  withCurrentDirectoryArray:_currentDirectoryArray andSortedArray:_sortedArray needsExtraEmptyRow:YES];
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
   return [SortManager titleForHeaderInTableViewSection:section forUser:APP_DELEGATE.activeUser  withCurrentDirectoryArray:_currentDirectoryArray andSortedArray:_sortedArray];
}


// Returns the titles for the sections for a table view.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // The commented part is for the version with searchField
    
    /*NSArray *titles = [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
     NSMutableArray *array = [NSMutableArray arrayWithArray:titles];
     [array insertObject:UITableViewIndexSearch atIndex:0];
     return [NSArray arrayWithArray:array];*/
    
    return [SortManager sectionIndexTitlesForTableView:tableView forUser:APP_DELEGATE.activeUser  withCurrentDirectoryArray:_currentDirectoryArray];
    

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

- (void) tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self cancelGetThumbnailByCell:cell];
}

- (void) cancelGetThumbnailByCell:(UITableViewCell *) cell {
    @try {
        CustomCellFileAndDirectory *customCell = (CustomCellFileAndDirectory *) cell;
        
        if (!IS_IOS9) {
            if ([customCell isKindOfClass:[CustomCellFileAndDirectory class]] && customCell.thumbnailSessionTask) {
           
                DLog(@"Cancel thumbnailOperation");
                [customCell.thumbnailSessionTask cancel];
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"Exception: %@", exception);
    }
    @finally {
    }
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
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40 + self.tabBarController.tabBar.frame.size.height)];
    footerView.backgroundColor = [UIColor clearColor];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [footerView addSubview:footerLabel];
        [_tableView setTableFooterView:footerView];
    });
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
- (void) goToSelectedFileOrFolder:(FileDto *) selectedFile andForceDownload:(BOOL) isForceDownload {
    
    [self initLoading];
    
    if(selectedFile.isDirectory) {
        [self performSelector: @selector(goToFolder:) withObject:selectedFile];
    } else {
        self.navigationItem.backBarButtonItem = nil;

        // If the file is in root folder, show icon instead of folder name.
        if(self.fileIdToShowFiles.isRootFolder){
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                           initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]
                                           style:UIBarButtonItemStylePlain
                                           target:nil
                                           action:nil];
            self.navigationItem.backBarButtonItem = backButton;
        }else{
            NSString *folderName = [[selectedFile.filePath stringByRemovingPercentEncoding] lastPathComponent];
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(folderName, nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        }
        
        FilePreviewViewController *viewController = [[FilePreviewViewController alloc]initWithNibName:@"FilePreviewViewController" selectedFile:selectedFile andIsForceDownload:isForceDownload];
        
        //Hide tabbar
        viewController.hidesBottomBarWhenPushed = YES;
        viewController.sortedArray=_sortedArray;

        [self.navigationController pushViewController:viewController animated:NO];
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
    
    //Set if the selected folder is favorite or if we are in a son of a favorite one
    if (self.isCurrentFolderSonOfFavoriteFolder) {
        filesViewController.isCurrentFolderSonOfFavoriteFolder = self.isCurrentFolderSonOfFavoriteFolder;
    } else {
        filesViewController.isCurrentFolderSonOfFavoriteFolder = self.selectedFileDto.isFavorite;
    }
    
    [[self navigationController] pushViewController:filesViewController animated:NO];
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
        
        if ([[CheckAccessToServer sharedManager]isNetworkIsReachable]){
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
    
   path = [path stringByRemovingPercentEncoding];
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }
    
    [[AppDelegate sharedOCCommunication] readFolder:path withUserSessionToken:app.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                self.isLoadingForNavigate = NO;
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError && [app.userSessionCurrentToken isEqualToString:token]) {
           //Pass the items with OCFileDto to FileDto Array
           NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
           [self prepareForNavigationWithData:directoryList];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        _isLoadingForNavigate = NO;
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [self manageServerErrors:response.statusCode and:error];
        }
        
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
    _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
    
    //update gallery array
    [self updateArrayImagesInGallery];
    
    //Update the table footer
    [self setTheLabelOnTheTableFooter];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Reload data in the table
        [self reloadTableFileList];
    });
    
    //TODO: Remove this to prevent duplicate files
    /*if([_currentDirectoryArray count] != 0) {
        [self endLoading];
    }*/
}


-(void)reloadTableFileListAfterCapabilitiesUpdated {
    _currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:_fileIdToShowFiles.idFile];
    _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadTableFileList];
    });
}
-(void)reloadTableFileList{
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
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
    _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
    
    //update gallery array
    [self updateArrayImagesInGallery];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Reload data in the table
        [_tableView reloadData];
    });
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (app.detailViewController.galleryView) {
                [app.detailViewController.galleryView updateImagesArrayWithNewArray:_sortedArray];
            }
        });
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
    //[self performSelectorInBackground:@selector(syncFavoritesByFolder:) withObject:self.fileIdToShowFiles];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshControl endRefreshing];
    });
}

/*
 * Method to sync favorites of the current path. 
 * Usually we call this method in a background mode
 */
- (void) syncFavoritesByFolder:(FileDto *) folder {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //Launch the method to sync the favorites files with specific path
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [[AppDelegate sharedManageFavorites] syncFavoritesOfFolder:folder withUser:app.activeUser.idUser];
    
    });
    
}

/*
 * Method to launch the method to init the refresh process with the server
 */
- (void)refreshTableFromWebDav {
    DLog(@"self.currentFileShowFilesOnTheServerToUpdateTheLocalFile: %ld", (long)self.currentFileShowFilesOnTheServerToUpdateTheLocalFile.idFile);
    
    [self performSelector:@selector(sendRequestToReloadTableView) withObject:nil];
    
    //Refresh the shared data
    //[self performSelector:@selector(refreshSharedPath) withObject:nil afterDelay:1.0];
    
    [self performSelectorInBackground:@selector(syncFavoritesByFolder:) withObject:self.fileIdToShowFiles];
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
    
    path = [path stringByRemovingPercentEncoding];
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }
    
     [[AppDelegate sharedOCCommunication] readFolder:path withUserSessionToken:app.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
         
         DLog(@"Operation response code: %ld", (long)response.statusCode);
         BOOL isSamlCredentialsError = NO;
         
         //Check the login error in shibboleth
         if (k_is_sso_active) {
             //Check if there are fragmens of saml in url, in this case there are a credential error
             isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
             if (isSamlCredentialsError) {
                 [self errorLogin];
             }
         }
         
         if(response.statusCode != kOCErrorServerUnauthorized && !isSamlCredentialsError && [app.userSessionCurrentToken isEqualToString:token]) {
             
             //Pass the items with OCFileDto to FileDto Array
             NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
             
             if (response.statusCode == 200 && directoryList.count == 0) {
                 [self errorLogin];
             } else {
                 //Send the data to DB and refresh the table
                 [self deleteOldDataFromDBBeforeRefresh:directoryList];
             }
         } else {
             [self stopPullRefresh];
             _showLoadingAfterChangeUser = NO;
         }
         
         [self performSelector:@selector(refreshSharedPath) withObject:nil];

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [self manageServerErrors:response.statusCode and:error];
        }
        
    }];
}

- (void) reloadCellByFile:(FileDto *) file {
   
    NSArray* indexArray = [NSArray arrayWithObjects:[self getIndexPathFromFilesTableViewByFile:file], nil];
    
    dispatch_queue_t mainThreadQueue = dispatch_get_main_queue();
    dispatch_async(mainThreadQueue, ^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    });
}

- (NSIndexPath*) getIndexPathFromFilesTableViewByFile:(FileDto *) file {
    
    NSIndexPath* indexPath;
    BOOL isFound = NO;
    
    for (NSInteger i = 0; i < self.sortedArray.count; i++) {
        
        NSMutableArray *currentListOfFilesOnSection = [[self.sortedArray objectAtIndex:i] mutableCopy];
        
        for (NSInteger j = 0 ; j < currentListOfFilesOnSection.count ; j++) {
            FileDto *current = [currentListOfFilesOnSection objectAtIndex:j];
            
            if ([current.localFolder isEqualToString: file.localFolder]) {
                indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                [currentListOfFilesOnSection replaceObjectAtIndex:j withObject:file];
                [self.sortedArray replaceObjectAtIndex:i withObject:currentListOfFilesOnSection.copy];
                isFound = YES;
                break;
            }
        }
        
        if (isFound) {
            break;
        }
    }
    
    return indexPath;
}

/*
 * Method used for quit the flag about the refresh
 * and the system can be a new refresh action
 */
- (void)disableRefreshInProgress {
    
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
        _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
        
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
        path = [path stringByRemovingPercentEncoding];
        
        //Checking the Shared files and folders
        [[AppDelegate sharedOCCommunication] readSharedByServer:app.activeUser.url andPath:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
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
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            DLog(@"error: %@", error);
            DLog(@"Operation error: %ld", (long)response.statusCode);
        }];

    } else if (app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
        //If the server has not been checked, do it
        [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
    }
}

#pragma mark - Sorting methods

/*
 * This method shows an action sheet to sort the files and folders list
 */
- (void)showSortingOptions{
    NSString * sortByTitle = NSLocalizedString(@"sort_menu_title", nil);
    
    if (self.sortingActionSheet) {
        self.sortingActionSheet = nil;
    }
    
    self.sortingActionSheet = [[UIActionSheet alloc]
                               initWithTitle:sortByTitle
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                               destructiveButtonTitle:nil
                               otherButtonTitles:NSLocalizedString(@"sort_menu_by_name_option", nil), NSLocalizedString(@"sort_menu_by_modification_date_option", nil), nil];
    
    self.sortingActionSheet.actionSheetStyle=UIActionSheetStyleDefault;
    self.sortingActionSheet.tag=300;
    
    if (IS_IPHONE) {
        [self.sortingActionSheet showInView:self.tabBarController.view];
    } else {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (IS_IOS8 || IS_IOS9)  {
            [self.sortingActionSheet showInView:app.splitViewController.view];
        } else {
            [self.sortingActionSheet showInView:app.detailViewController.view];
        }
    }
}


/*
 * This method stores in the DB the sorting option selected by the user
 */
- (void) updateActiveUserSortingChoiceTo: (enumSortingType)sortingChoice{
    APP_DELEGATE.activeUser.sortingType = sortingChoice;
    [ManageUsersDB updateSortingWayForUserDto:APP_DELEGATE.activeUser];
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
            case 2:
                [self showCreateTextFile];
                break;
            case 3:
                [self showSortingOptions];
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
                case 2:
                    [self performSelectorInBackground:@selector(didSelectDownloadFolder) withObject:nil];
                    break;
                case 3:
                    
                    if (self.isCurrentFolderSonOfFavoriteFolder) {
                        [self performSelectorOnMainThread:@selector(showAlertView:)
                                               withObject:NSLocalizedString(@"parent_folder_is_available_offline_folder_child", nil)
                                            waitUntilDone:YES];
                    } else {
                        if (self.selectedFileDto.isFavorite) {
                            [self didSelectCancelFavoriteFolder];
                        } else {
                            [self didSelectFavoriteFolder];
                        }
                    }
                    
                    break;
                default:
                    break;
            }
        } else {
            switch (buttonIndex) {
                case 0:
                    
                    if (_selectedFileDto.isDownload || [[CheckAccessToServer sharedManager] isNetworkIsReachable]){
                        [self didSelectOpenWithOptionAndFile:_selectedFileDto];
                    } else {
                        [self performSelectorOnMainThread:@selector(showAlertView:)
                                               withObject:NSLocalizedString(@"not_possible_connect_to_server", nil)
                                            waitUntilDone:YES];
                    }
                    break;
                case 1:
                    [self didSelectRenameOption];
                    break;
                case 2:
                    [self didSelectMoveOption];
                    break;
                case 3:
                    if (self.isCurrentFolderSonOfFavoriteFolder) {
                        [self performSelectorOnMainThread:@selector(showAlertView:)
                                               withObject:NSLocalizedString(@"parent_folder_is_available_offline_file_child", nil)
                                            waitUntilDone:YES];
                    } else {
                        [self didSelectFavoriteOption];
                    }
                    break;
                case 4:
                    if ([[AppDelegate sharedManageFavorites] isInsideAFavoriteFolderThisFile:self.selectedFileDto] || self.selectedFileDto.isFavorite  ||
                        self.selectedFileDto.isDownload == downloaded) {
                        DLog(@"Cancel");
                    } else {
                        if (self.selectedFileDto.isDownload == downloading ||
                            self.selectedFileDto.isDownload == updating) {
                            [self didSelectCancelDownloadFileOption];
                        } else {
                            [self didSelectDownloadFileOption];
                        }
                    }
                default:
                    break;
            }
        }
    }
    
    if (actionSheet.tag==210) {
        switch (buttonIndex) {
            case 0:
                [self didSelectCancelDownloadFolder];
                break;
            default:
                break;
        }
    }
    
    if (actionSheet.tag==220) {
        switch (buttonIndex) {
            case 0:
                [self didSelectCancelFavoriteFolder];
                break;
            default:
                break;
        }
    }
    
    //Sorting options
    if (actionSheet.tag==300) {
        enumSortingType storedSorting = APP_DELEGATE.activeUser.sortingType;
        switch (buttonIndex) {
            case 0:
                if(storedSorting != sortByName){
                    [self updateActiveUserSortingChoiceTo:sortByName];
                    _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
                    [self reloadTableFileList];
                }
                break;
            case 1:
                if(storedSorting != sortByModificationDate){
                    [self updateActiveUserSortingChoiceTo:sortByModificationDate];
                    _sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:_currentDirectoryArray forUser:APP_DELEGATE.activeUser];
                    [self reloadTableFileList];
                }
                break;
            default:
                break;
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
    
    if (_selectedFileDto.isDownload || [[CheckAccessToServer sharedManager] isNetworkIsReachable]){
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
        
         _downloadView.view.frame = _tableView.frame;
        
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
        
    } else if (([self.selectedFileDto isDirectory] && [DownloadUtils thereAreDownloadingFilesOnTheFolder: self.selectedFileDto]) || ([self.selectedFileDto isDirectory] && [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded isFolderPendingToBeDownload:self.selectedFileDto])) {
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
 * Method called when the user select the move option
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
            
            
            //Remove all the views in the main screen for the iOS8 bug
            if (self.moreActionSheet) {
                [self.moreActionSheet dismissWithClickedButtonIndex:0 animated:YES];
            }

            [app.detailViewController presentViewController:self.selectFolderNavigation animated:YES completion:nil];
        }
        //Hide preview (only in iPad)
        [self hidePreviewOniPad];
    }
}

#pragma mark - Download Folder

/*
 * Method called when the user select the Download Folder
 */
- (void) didSelectDownloadFolder {
    DLog(@"Download Folder");
    
    [self initLoading];
    
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
    
    path = [path stringByRemovingPercentEncoding];
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }
    
    NSString *rootFolder =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
    
    [[AppDelegate sharedOCCommunication] checkServer:rootFolder onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        [self endLoading];
        //Update fileDto
        self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        [[AppDelegate sharedSyncFolderManager] addFolderToBeDownloaded:self.selectedFileDto];
        
        [self reloadTableFileList];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        [self endLoading];
        
        [self reloadTableFileList];
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [self manageServerErrors:response.statusCode and:error];
        }
    }];
}

/*
 *
 */

- (void) didSelectCancelDownloadFolder {
    DLog(@"Cancel Download Folder");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Update fileDto
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AppDelegate sharedSyncFolderManager] cancelDownloadsByFolder:self.selectedFileDto];
    });

}

- (void) didSelectFavoriteFolder {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Update fileDto
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    self.selectedFileDto.isFavorite = YES;
    
    [ManageFilesDB updateTheFileID:self.selectedFileDto.idFile asFavorite:self.selectedFileDto.isFavorite];
    [[AppDelegate sharedManageFavorites] setAllFilesAndFoldersAsNoFavoriteBehindFolder:self.selectedFileDto];
    
    [self didSelectDownloadFolder];
    
    if (!IS_IPHONE) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (app.detailViewController.file) {
            [app.detailViewController updateFavoriteIconWhenAFolderIsSelectedFavorite];
        }
    }
}

- (void) didSelectCancelFavoriteFolder {
    DLog(@"Cancel Download Folder");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Update fileDto
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    self.selectedFileDto.isFavorite = NO;
    
    [ManageFilesDB updateTheFileID:self.selectedFileDto.idFile asFavorite:self.selectedFileDto.isFavorite];
    
    [self didSelectCancelDownloadFolder];
    [app reloadCellByFile:self.selectedFileDto];
    
    if (!IS_IPHONE) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (app.detailViewController.file) {
            [app.detailViewController updateFavoriteIconWhenAFolderIsSelectedFavorite];
        }
    }
}

- (void) didSelectDownloadFileOption {
    
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if (IS_IPHONE){
        [self goToSelectedFileOrFolder:self.selectedFileDto andForceDownload:YES];
    } else {
        
        //Select in detail view
        if (_selectedCell) {
            CustomCellFileAndDirectory *temp = (CustomCellFileAndDirectory*) [_tableView cellForRowAtIndexPath:_selectedCell];
            [temp setSelectedStrong:NO];
        }
        
        //Select in detail
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        //Quit the player if exist
        if (app.detailViewController.avMoviePlayer) {
            [app.detailViewController removeMediaPlayer];
        }
        app.detailViewController.sortedArray=_sortedArray;
        [app.detailViewController handleFile:self.selectedFileDto fromController:fileListManagerController andIsForceDownload:YES];
    }
    
    //Select the cell
    NSIndexPath *indexPath = [self getIndexPathFromFilesTableViewByFile:self.selectedFileDto];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES];

}

- (void) didSelectCancelDownloadFileOption {
    DLog(@"Cancel download");
    
    if (IS_IPHONE) {
        for (Download *currentDownload in [APP_DELEGATE.downloadManager getDownloads]) {
            if (currentDownload.fileDto.idFile == self.selectedFileDto.idFile) {
                [currentDownload cancelDownload];
            }
        }
    } else {
        [APP_DELEGATE.detailViewController didPressCancelButton:nil];
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
    
    ShareMainViewController *share = [[ShareMainViewController alloc] initWithFileDto:_selectedFileDto];
    
    OCNavigationController *nav = [[OCNavigationController alloc] initWithRootViewController:share];
    
    if (IS_IPHONE) {
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:nav animated:YES completion:nil];
    }
    
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
- (void) downloadTheFile {
    
    
    [self initLoading];
    
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
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }
    
    NSString *rootFolder =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
    
    [[AppDelegate sharedOCCommunication] checkServer:rootFolder onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        [self endLoading];
        
        if ([_selectedFileDto isDownload] == notDownload || _selectedFileDto.isNecessaryUpdate) {
            //Phase 1.2. If the image isn't in the device, download image
            DLog(@"The file is not download");
            Download *download = nil;
            download = [[Download alloc]init];
            download.currentLocalFolder = _currentLocalFolder;
            [download fileToDownload:_selectedFileDto];
        }
        
        [self reloadTableFileList];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        [self endLoading];
        
        [self reloadTableFileList];
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [self manageServerErrors:response.statusCode and:error];
        }
    }];
}

/*
 * Cancel the actual download file.
 */
-(void) cancelDownload {
    if (_openWith) {
        DLog(@"CANCEL DOWNLOAD");
        [_openWith cancelDownload];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_downloadView.view removeFromSuperview];
            //Ublock view
            self.navigationController.navigationBar.userInteractionEnabled=YES;
            self.tabBarController.tabBar.userInteractionEnabled=YES;
        });
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
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
}

#pragma mark - Etag methods

/*
 * Method that check the etag before the folder request, called in willviewappear 
 * when the checketag flag is enable
 * @req --> NSData of the server request
 */
-(void)checkEtagBeforeMakeRefreshFolderRequest:(NSArray *) requestArray {
    
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
 * @error -> NSError of NSURLSession
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
    
    [self performSelectorOnMainThread:@selector(showAlertView:)
                               withObject:message
                            waitUntilDone:YES];
  
     dispatch_async(dispatch_get_main_queue(), ^{
         [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
     });
}

/*
 * Methods from the server side to inform about a error with the server
 * about login, connection or certificate
 */

-(void) errorLogin {
    
    DLog(@"Error Login");
    
    [self endLoading];
    
    [self showEditAccount];
    
    [self stopPullRefresh];
    [self cancelDownload];
}

- (void) showEditAccount {
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Edit Account
    BOOL requiredUpdateUrl = [UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:[ManageUsersDB getActiveUser].predefinedUrl];
    if (requiredUpdateUrl) {
        self.resolvedCredentialError = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser andLoginMode:LoginModeMigrate];
    } else {
        self.resolvedCredentialError = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:app.activeUser andLoginMode:LoginModeExpire];
    }
    
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

#pragma mark - CheckAccessToServer
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
    DLog(@"Certificate accepted by the user");
    [[CheckAccessToServer sharedManager]isConnectionToTheServerByUrl:APP_DELEGATE.activeUser.url];
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
    
    BOOL areTwoButtonsInTheSwipe = false;
    if ( (k_hide_share_options) || (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled) ) {
        //Two buttons
        areTwoButtonsInTheSwipe = true;
    }else{
        //Three buttons
        areTwoButtonsInTheSwipe = false;
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
    
    switch (index) {
        case 0:
        {
            DLog(@"Click on index 0 - More");
            [self didSelectMoreOptions];
            break;
        }
        case 1:
        {
            if ((k_hide_share_options) || (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled)) {
                DLog(@"Click on index 2 - Delete");
                [self didSelectDeleteOption];
                break;
            }else{
                DLog(@"Click on index 1 - Share");
                [self didSelectShareLinkOption];
                break;
            }

        }
        case 2:
        {
            if ((k_hide_share_options) || (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled)) {
            }else{
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
    
    NSString *title = [self.selectedFileDto.fileName stringByRemovingPercentEncoding];
    
    if(self.selectedFileDto.isDirectory) {
        
        title = [title substringToIndex:[title length]-1];
        
        if ([[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded isFolderPendingToBeDownload:self.selectedFileDto]) {
            if (self.isCurrentFolderSonOfFavoriteFolder) {
                NSString *msg = NSLocalizedString(@"msg_while_downloads", nil);
                _alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [_alert show];
            } else if (self.selectedFileDto.isFavorite) {
                self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"not_available_offline", nil), nil];
                self.moreActionSheet.tag=220;
            } else {
                self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"cancel_download", nil), nil];
                self.moreActionSheet.tag=210;
            }
        } else {
            
            NSString *favoriteOrUnfavoriteString = @"";
            
            if (_selectedFileDto.isFavorite && !self.isCurrentFolderSonOfFavoriteFolder) {
                favoriteOrUnfavoriteString = NSLocalizedString(@"not_available_offline", nil);
            } else {
                favoriteOrUnfavoriteString = NSLocalizedString(@"available_offline", nil);
            }
            
            self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"rename_long_press", nil), NSLocalizedString(@"move_long_press", nil), NSLocalizedString(@"download_folder", nil), favoriteOrUnfavoriteString, nil];
            self.moreActionSheet.tag=200;
        }
        
        if (IS_IPHONE) {
            [self.moreActionSheet showInView:self.tabBarController.view];
        }else {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            if (IS_IOS8 || IS_IOS9) {
                [self.moreActionSheet showInView:app.splitViewController.view];
            } else {
                [self.moreActionSheet showInView:app.detailViewController.view];
            }
        }
    } else {
        
        NSString *availableOfflineOrNotString = @"";
        
        if (_selectedFileDto.isFavorite && !self.isCurrentFolderSonOfFavoriteFolder) {
            availableOfflineOrNotString = NSLocalizedString(@"not_available_offline", nil);
        } else {
            availableOfflineOrNotString = NSLocalizedString(@"available_offline", nil);
        }
        
        NSString *downloadFileCancelDownload;
        
        if ([[AppDelegate sharedManageFavorites] isInsideAFavoriteFolderThisFile:self.selectedFileDto] || self.selectedFileDto.isFavorite  ||
            self.selectedFileDto.isDownload == downloaded) {
            downloadFileCancelDownload = nil;
        } else {
            if (self.selectedFileDto.isDownload == downloading ||
                self.selectedFileDto.isDownload == updating) {
                downloadFileCancelDownload = NSLocalizedString(@"cancel_download", nil);
            } else {
                downloadFileCancelDownload = NSLocalizedString(@"download_file", nil);
            }
        }
        
        self.moreActionSheet = [[UIActionSheet alloc]initWithTitle:title delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle: nil otherButtonTitles:NSLocalizedString(@"open_with_label", nil), NSLocalizedString(@"rename_long_press", nil), NSLocalizedString(@"move_long_press", nil), availableOfflineOrNotString, downloadFileCancelDownload, nil];
        self.moreActionSheet.tag=200;
        
        if (IS_IPHONE) {
            [self.moreActionSheet showInView:self.tabBarController.view];
        }else {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            if (IS_IOS8 || IS_IOS9) {
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
