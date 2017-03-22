//
//  SimpleFileListTableViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 04/11/14.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "SimpleFileListTableViewController.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "UserDto.h"
#import "FileDto.h"
#import "CustomCellFileAndDirectory.h"
#import "InfoFileUtils.h"
#import "constants.h"
#import "FileNameUtils.h"
#import "EmptyCell.h"
#import "Customization.h"
#import "OCCommunication.h"
#import "UtilsDtos.h"
#import "OCFileDto.h"
#import "OCErrorMsg.h"
#import "UtilsUrls.h"
#import "FileListDBOperations.h"
#import "UIColor+Constants.h"
#import "SortManager.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "EditAccountViewController.h"
#import "OCNavigationController.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "DocumentPickerViewController.h"
#endif

@interface SimpleFileListTableViewController ()

@end

@implementation SimpleFileListTableViewController

- (id) initWithNibName:(NSString *)nibNameOrNil onFolder:(FileDto *)currentFolder {
    
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    
    if (self) {
        
        self.manageNetworkErrors = [ManageNetworkErrors new];
        self.manageNetworkErrors.delegate = self;
        self.currentFolder = currentFolder;
        self.user = [ManageUsersDB getActiveUser];
        
        [self fillTheArraysFromDatabase];
    }
    return self;
}

#pragma mark Load View Life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.user = [ManageUsersDB getActiveUser];
    
    //If it is the root folder show the icon of root folder
    if(self.currentFolder.isRootFolder) {
        
        if(k_show_logo_on_title_file_list) {
            UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[FileNameUtils getTheNameOfTheBrandImage]]];
            self.navigationItem.titleView = imageView;
        }
    } else {
        //We remove the las character / and the URL encoding
        NSString *title = [self.currentFolder.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([title length] > 0) {
            title = [title substringToIndex:[title length] - 1];
        }
        
        [self.navigationItem setTitle:title];
    }
    
    [self addPullDownRefresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadFolderByEtag];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    //Cancel all the get thumbnails in visible cells
    UITableView *tableView = self.tableView; // Or however you get your table view
    NSArray *paths = [tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *path in paths) {
        [self cancelGetThumbnailByCell:[tableView cellForRowAtIndexPath:path]];
    }
}

#pragma mark - Fill the arrays from Database

- (void) fillTheArraysFromDatabase {
    
    self.currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser: (int)self.currentFolder.idFile];
    self.sortedArray = [SortManager getSortedArrayFromCurrentDirectoryArray:self.currentDirectoryArray forUser:self.user];
}



#pragma mark - TableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [SortManager numberOfSectionsInTableViewForUser:self.user withFolderList:self.currentDirectoryArray];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SortManager numberOfRowsInSection:section forUser:self.user withCurrentDirectoryArray:self.currentDirectoryArray andSortedArray:self.sortedArray needsExtraEmptyRow:YES];
}

// Returns the table view managed by the controller object.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [SortManager titleForHeaderInTableViewSection:section forUser:self.user withCurrentDirectoryArray:self.currentDirectoryArray andSortedArray:self.sortedArray];
}

// Asks the data source to return the titles for the sections for a table view.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [SortManager sectionIndexTitlesForTableView:tableView forUser:self.user withCurrentDirectoryArray:self.currentDirectoryArray];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    
    if ([_currentDirectoryArray count] == 0) {
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
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
        
        fileCell = [InfoFileUtils getTheStatusIconOntheFile:file onTheCell:fileCell andCurrentFolder:self.currentFolder andIsSonOfFavoriteFolder:NO ofUser:self.user];
        
        //Thumbnail
        fileCell.thumbnailSessionTask = [InfoFileUtils updateThumbnail:file andUser:self.user tableView:tableView cellForRowAtIndexPath:indexPath];
        
        //Custom cell for SWTableViewCell with right swipe options
        fileCell.containingTableView = tableView;
        [fileCell setCellHeight:fileCell.frame.size.height];
        
        fileCell.rightUtilityButtons = nil;
        
        //Selection style gray
        fileCell.selectionStyle=UITableViewCellSelectionStyleGray;
        
        cell = fileCell;
    }
    return cell;
}

//Return the row height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    //If the _currentDirectoryArray doesn't have object it will have a big row
    if ([self.currentDirectoryArray count] == 0) {
        
        height = self.tableView.bounds.size.height;
    } else {
        height = 54.0;
    }
    return height;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Method to be overwritten
}

- (void) tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self cancelGetThumbnailByCell:cell];
}

- (void) cancelGetThumbnailByCell:(UITableViewCell *) cell {
    @try {
        CustomCellFileAndDirectory *customCell = (CustomCellFileAndDirectory *) cell;
        
        if ([customCell isKindOfClass:[CustomCellFileAndDirectory class]] && customCell.thumbnailSessionTask) {
            DLog(@"Cancel thumbnailSessionTask");
            [customCell.thumbnailSessionTask cancel];
        }
    }
    @catch (NSException *exception) {
        DLog(@"Exception: %@", exception);
    }
    @finally {
    }
}

#pragma mark - Navigation

- (void) checkBeforeNavigationToFolder:(FileDto *) file {
    
    if ([ManageFilesDB getFilesByFileIdForActiveUser: (int)file.idFile].count > 0) {
        [self navigateToFile:file];
    } else {
        [self initLoading];
        [self loadRemote:file andNavigateIfIsNecessary:YES];
    }
}

- (void) navigateToFile:(FileDto *) file {
    //Method to be overwritten
    _simpleFilesViewController = [[SimpleFileListTableViewController alloc] initWithNibName:@"SimpleFileListTableViewController" onFolder:file];
    
    [[self navigationController] pushViewController:_simpleFilesViewController animated:NO];
}

- (void) reloadCurrentFolder {
    [self loadRemote:self.currentFolder andNavigateIfIsNecessary:NO];
}

- (void) loadRemote:(FileDto *) file andNavigateIfIsNecessary:(BOOL) isNecessaryNavigate {
    
    OCCommunication *sharedCommunication;
    
#ifdef CONTAINER_APP
    sharedCommunication = [AppDelegate sharedOCCommunication];
#elif SHARE_IN
    sharedCommunication = Managers.sharedOCCommunication;
#else
    sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
#endif
    
    //Set the right credentials
    if (k_is_sso_active) {
        [sharedCommunication setCredentialsWithCookie:self.user.password];
    } else if (k_is_oauth_active) {
        [sharedCommunication setCredentialsOauthWithToken:self.user.password];
    } else {
        [sharedCommunication setCredentialsWithUser:self.user.username andPassword:self.user.password];
    }
    
    [sharedCommunication setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *remotePath = [UtilsUrls getFullRemoteServerFilePathByFile:file andUser:self.user];
    remotePath = [remotePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
     [sharedCommunication readFolder:remotePath withUserSessionToken:nil onCommunication:sharedCommunication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        
        DLog(@"Operation response code: %d", (int)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        
        if(response.statusCode != kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            

            //Pass the items with OCFileDto to FileDto Array
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
            
            //Change the filePath from the library to our format
            for (FileDto *currentFile in directoryList) {
                //Remove part of the item file path
                NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:self.user];
                if([currentFile.filePath length] >= [partToRemove length]){
                    currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
                }
            }
            
            for (int i = 0 ; i < directoryList.count ; i++) {
                
                FileDto *currentFile = [directoryList objectAtIndex:i];
                
                if (currentFile.fileName == nil) {
                    //This is the fileDto of the current father folder
                    self.currentFolder.etag = currentFile.etag;
                    
                    //We update the current folder with the new etag
                    [ManageFilesDB updateEtagOfFileDtoByid:file.idFile andNewEtag: file.etag];
                }
            }
            
            [FileListDBOperations makeTheRefreshProcessWith:directoryList inThisFolder:file.idFile];
            
            //Send the data to DB and refresh the table
            
            //This process can not be executed twice at the same time
            if (self.isRefreshInProgress == NO) {
                self.isRefreshInProgress=YES;
                [InfoFileUtils createAllFoldersInFileSystemByFileDto:file andUserDto:self.user];
            }
            
            if (isNecessaryNavigate) {
                
                [self endLoading];
            
                [self navigateToFile:file];
            } else {
                
                [self fillTheArraysFromDatabase];
                [self.tableView reloadData];    
                
                [self stopPullRefresh];
                [self endLoading];
            }
            
            self.isRefreshInProgress = NO;
        } else {
            [self endLoading];
            [self stopPullRefresh];
        }
        
     } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        DLog(@"response: %@", response);
        DLog(@"error: %@", error);
         
        [self endLoading];
        [self stopPullRefresh];
         
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
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:self.user];
        }
  
    }];
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
    
    _HUD = [[MBProgressHUD alloc]initWithView:self.view];
    _HUD.delegate = self;
    [self.view.window addSubview:_HUD];
    
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
    
    // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
    [_HUD removeFromSuperview];
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [self.view.window setUserInteractionEnabled:YES];
    
}

#pragma mark - Errors

/*
 * Method called when there are a fail connection with the server
 * @NSString -> Server error msg
 */
- (void)showError:(NSString *) message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        
        if (IS_IOS7) {
            
#ifdef CONTAINER_APP
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
#endif
            
        }else{
            UIAlertController *alert =   [UIAlertController
                                          alertControllerWithTitle:message
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"ok", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
            [alert addAction:ok];
            
            if ([self.navigationController isViewLoaded] && self.navigationController.view.window && self.resolveCredentialErrorViewController != nil) {
                [self.resolveCredentialErrorViewController presentViewController:alert animated:YES completion:nil];
            } else {
                [self presentViewController:alert animated:YES completion:nil];
            }
            
        }
    });
}

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser] andModeUpdateToPredefinedUrl:NO];
    [self.resolveCredentialErrorViewController setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
        
    } else {

        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    }

#endif

}

- (void) errorLogin {
    
    [self showEditAccount];
    
    if (k_is_sso_active) {
       [self showError:NSLocalizedString(@"session_expired", nil)];
    } else {
       [self showError:NSLocalizedString(@"error_login_message", nil)];
    }
}

#pragma mark - Pull Refresh

- (void) addPullDownRefresh {
    
    //Init Refresh Control
    UIRefreshControl *refresh = [UIRefreshControl new];
    //For the moment in the iOS 7 GM the attributedTitle not show properly.
    //refresh.attributedTitle =[[NSAttributedString alloc] initWithString: NSLocalizedString(@"pull_down_refresh", nil)];
    refresh.attributedTitle =nil;
    [refresh addTarget:self
                action:@selector(pullRefreshView:)
      forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refresh;
    
    [self.tableView addSubview:self.refreshControl];
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
    
    [self performSelector:@selector(reloadCurrentFolder) withObject:nil];
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
    [self.refreshControl endRefreshing];
}

#pragma mark - Etag

- (void) reloadFolderByEtag {
    
    OCCommunication *sharedCommunication;
    
#ifdef CONTAINER_APP
    sharedCommunication = [AppDelegate sharedOCCommunication];
#elif SHARE_IN
    sharedCommunication = Managers.sharedOCCommunication;
#else
    sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
#endif
    
    if (!self.isRefreshInProgress) {
        //Set the right credentials
        if (k_is_sso_active) {
            [sharedCommunication setCredentialsWithCookie:self.user.password];
        } else if (k_is_oauth_active) {
            [sharedCommunication setCredentialsOauthWithToken:self.user.password];
        } else {
            [sharedCommunication setCredentialsWithUser:self.user.username andPassword:self.user.password];
        }
        
        [sharedCommunication setUserAgent:[UtilsUrls getUserAgent]];
        
        NSString *remotePath = [UtilsUrls getFullRemoteServerFilePathByFile:self.currentFolder andUser:self.user];
        remotePath = [remotePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [sharedCommunication readFile:remotePath onCommunication:sharedCommunication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
            
            DLog(@"Operation response code: %d", (int)response.statusCode);
            
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
                
                if (directoryList.count > 0) {
                    FileDto *remoteFile = [directoryList objectAtIndex:0];
                    
                    DLog(@"remoteFile.etag: %@", remoteFile.etag);
                    DLog(@"self.currentFolder: %@", self.currentFolder.etag);
                    
                    if (remoteFile.etag != self.currentFolder.etag) {
                        [self reloadCurrentFolder];
                    } else {
                        DLog(@"It is the same etag");
                    }
                }
                
            }
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            DLog(@"error: %@", error);
            DLog(@"Operation error: %d", (int) response.statusCode);
        
            //Check the login error in shibboleth
            if (k_is_sso_active) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                if ([FileNameUtils isURLWithSamlFragment:response]) {
                    [self errorLogin];
                }
            }
            
        }];
    }
}

#pragma mark - CheckAccessToServerDelegate

-(void)connectionToTheServer:(BOOL)isConnection {

}

-(void)repeatTheCheckToTheServer {
    //We check the connection here because we need to accept the certificate on the self signed server before go to the files tab
    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = self;
    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).viewControllerToShow = self;
    [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:self.user.url];
}

-(void)badCertificateNoAcceptedByUser {
    DLog(@"Certificate refushed by user");
}

@end
