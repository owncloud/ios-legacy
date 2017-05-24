//
//  SharedViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 17/01/14.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "SharedViewController.h"
#import "ShareLinkCell.h"
#import "EmptyCell.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsDtos.h"
#import "OCSharedDto.h"
#import "ManageSharesDB.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "OCErrorMsg.h"
#import "ManageFilesDB.h"
#import "FileDto.h"
#import "FilePreviewViewController.h"
#import "UtilsDtos.h"
#import "FileNameUtils.h"
#import "FileListDBOperations.h"
#import "UtilsTableView.h"
#import "UtilsUrls.h"
#import "ShareMainViewController.h"
#import "OCNavigationController.h"
#import "ManageCapabilitiesDB.h"
#import "CheckFeaturesSupported.h"


//Three sections {shared items - not shared items msg - not share api support msg}
#define k_number_table_sections 3

@interface SharedViewController ()

@property (nonatomic,strong)NSArray *sharedLinkItems;
//Selected file for iPad
@property(nonatomic, strong) NSIndexPath *selectedCell;

@end

@implementation SharedViewController 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.manageNetworkErrors = [ManageNetworkErrors new];
        self.manageNetworkErrors.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set variables
    _isRefreshSharedInProgress = NO;
    
    //Set title
    self.title = NSLocalizedString(@"shared_tab", nil);
    
    //Init array
    _sharedLinkItems = [NSArray new];
    
    //Init Refresh Control
    UIRefreshControl *refresh = [UIRefreshControl new];
    refresh.attributedTitle =nil;
    [refresh addTarget:self
                action:@selector(pullRefreshView:)
      forControlEvents:UIControlEventValueChanged];
    
    _refreshControl = refresh;
    
    [_sharedTableView addSubview:_refreshControl];
    
    //Add observer to notification that select a shared cell in list, only in iPad
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCellWithThisFile:) name:IpadSelectRowInFileListNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = true;
    self.automaticallyAdjustsScrollViewInsets = true;
    
    //Get offline data
    [self refreshWithDataBaseSharedItems];

    
    //Set the table footer
    [self setTheLabelOnTheTableFooter];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Do operations in background thread
        //If the server has not been checked, do it
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        if (app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
            [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
        }
        
        //Do the request to get the shared items
        [self performSelector:@selector(refreshSharedItems) withObject:nil];
       
    });
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (_selectedCell) {
        //Deselect selected cell
        ShareLinkCell *newRow = (ShareLinkCell*) [_sharedTableView cellForRowAtIndexPath:_selectedCell];
        [newRow setSelectedStrong:NO];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    //Stop pull refresh
    [self stopPullRefresh];
}


-(void)viewDidLayoutSubviews
{
    if ([self.sharedTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.sharedTableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
        
    if ([self.sharedTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.sharedTableView setLayoutMargins:UIEdgeInsetsZero];
    }
        
        
    CGRect rect = self.navigationController.navigationBar.frame;
    float y = rect.size.height + rect.origin.y;
    self.sharedTableView.contentInset = UIEdgeInsetsMake(y,0,0,0);
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sharedTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.sharedTableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    
    if ([self.sharedTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.sharedTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Data Base Data

///-----------------------------------
/// @name Refresh with data base shared items
///-----------------------------------

/**
 * This method is used for put in the screen the shared items
 * stored previously in the data base.
 *
 */
- (void) refreshWithDataBaseSharedItems{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    _sharedLinkItems = [ManageSharesDB getAllSharesByUser:app.activeUser.idUser anTypeOfShare:shareTypeLink];
    
    //Sorted by share time
    _sharedLinkItems = [self getArraySortByShareDate:_sharedLinkItems];
    
    DLog(@"_sharedLinkItems: %lu", (unsigned long) [_sharedLinkItems count]);
    //Refresh the list of share items
    [_sharedTableView reloadData];
    
}

#pragma mark - DetailViewController notifications

/*
 * Method that mark a cell of the send fileDto.
 * This method is called from DetailViewController
 * only for iPad
 * @notification -> in this case the notification bring a FileDto object of
 * what file is in detail view gallery.
 */
- (void)selectCellWithThisFile:(NSNotification*)notification{
    //Get the shared dto equivalent to this file dto
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Check if the gallery is for SharedView instead of FileList
    if (app.detailViewController.controllerManager == sharedViewManagerController) {
        
        //Deselect old selected row
        if (_selectedCell) {
            ShareLinkCell *selectedRow = (ShareLinkCell*) [_sharedTableView cellForRowAtIndexPath:_selectedCell];
            [selectedRow setSelectedStrong:NO];
        } else {
            DLog(@"_selectedCell is nil!");
        }
        
        FileDto *fileDto = (FileDto*)[notification object];
        
        NSString *path = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:fileDto.filePath andUser:app.activeUser];
        
        path = [NSString stringWithFormat:@"/%@%@", path, fileDto.fileName];
        OCSharedDto *sharedDto = [ManageSharesDB getSharedEqualWithFileDtoPath:path];
        
        __block NSInteger row = -1;
        
        [_sharedLinkItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            OCSharedDto *temp = (OCSharedDto*)obj;
            
            if ([temp.path isEqualToString:sharedDto.path]) {
                row = idx;
                *stop = YES;
            }
        }];
        
        //Check if selected row is > 0
        if (row >= 0) {
            
            //Get the indexpath of the selected row
            NSIndexPath *shareIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
            
            //Select the new row
            ShareLinkCell *newRow = (ShareLinkCell*) [_sharedTableView cellForRowAtIndexPath:shareIndexPath];
            [newRow setSelectedStrong:YES];
            
            //Store the selecte row
            _selectedCell = shareIndexPath;
        }
    }
}


#pragma mark - Get FileDto with OCShareDto

- (NSArray *)getFileDtoWithOCSharedDtoArray:(NSArray *)array{
    
    //Array only for OCSharedDto (images)
    NSMutableArray *images = [NSMutableArray new];
    
    //Get only array of images
    for (OCSharedDto *temp in array) {
        
        if ([FileNameUtils isImageSupportedThisFile:[temp.path lastPathComponent]]) {
            [images addObject:temp];
        }
    }
    //Access to global variables
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Array only for FileDto (images)
    NSMutableArray *fileImages = [NSMutableArray new];
    //Get the equal FileDto
    FileDto *file;
    for (OCSharedDto *temp in images) {
        file = [ManageFilesDB getFileEqualWithShareDtoPath:temp.path andByUser:app.activeUser];
        
        //Sometimes and when file is catched if neccesary create the intermetidate path, for example after a delete folder content action
        [self createFolderPathInFileSystemWithThisPath:[UtilsDtos getTheParentPathOfThePath:file.localFolder]];
        
        if (!file) {
            DLog(@"File not catched yet");
            file = [self getFileNotCatchedBySharedPath:temp];
        }
        if (file) {
            [fileImages addObject:file];
        }
    }
    
    //Free memory
    images = nil;
    
    return fileImages;
}

#pragma mark - Shared Link Calls
///-----------------------------------
/// @name Refresh Shared Path
///-----------------------------------

/**
 * This method do the request to the server, get the shared data of the all files
 * Then update the DataBase with the shared data in the files of the current path
 * Finally, reload the file list with the database data
 */
- (void) refreshSharedItems{
    
    if (!_isRefreshSharedInProgress) {
        _isRefreshSharedInProgress = YES;
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        //Check if the server has share support
        if (app.activeUser.hasShareApiSupport == serverFunctionalitySupported  || app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
            //Set the right credentials
            if (k_is_sso_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
            } else if (k_is_oauth_active) {
                [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
            } else {
                [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
            }
            
            [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
            
            //Checking the Shared files and folders
            [[AppDelegate sharedOCCommunication] readSharedByServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
                //SAML checking
                BOOL isSamlCredentialsError=NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                    
                    if (isSamlCredentialsError) {
                        
                        if (_refreshControl.refreshing) {
                            //Manage Server error
                            [self errorLogin];
                        }
                    }
                }
                
                if (!isSamlCredentialsError) {
                    
                    //Delete the shared files of a user
                    [ManageSharesDB deleteAllSharesOfUser:app.activeUser.idUser];
                    
                    //Insert the new shared files of a user
                    [ManageSharesDB insertSharedList:items];
                    
                    _sharedLinkItems = [ManageSharesDB getAllSharesByUser:app.activeUser.idUser anTypeOfShare:shareTypeLink];
                    //Sorted by share time
                    _sharedLinkItems = [self getArraySortByShareDate:_sharedLinkItems];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //Refresh the list of share items
                        [_sharedTableView reloadData];
                    
                        //Stop loading pull refresh
                        [self stopPullRefresh];
                     });
                }
                
                //Finish the refresh
                _isRefreshSharedInProgress = NO;
                
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                
                BOOL isSamlCredentialsError=NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                    
                    if (isSamlCredentialsError) {
                        
                        if (_refreshControl.refreshing) {
                            //Manage Server error
                            [self errorLogin];
                        }
                    }
                }
                
                if (!isSamlCredentialsError) {
                
                    _sharedLinkItems = [ManageSharesDB getAllSharesByUser:app.activeUser.idUser anTypeOfShare:shareTypeLink];
                    
                    //Sorted by share time
                    _sharedLinkItems = [self getArraySortByShareDate:_sharedLinkItems];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //Refresh the list of share items
                        [_sharedTableView reloadData];
                        
                        //Stop loading pull refresh
                        [self stopPullRefresh];
                    });
                    
                    DLog(@"error: %@", error);
                    DLog(@"Operation error: %ld", (long)response.statusCode);
                    
                    //Only if the user do refresh manually, same behaviour like in Foi
                    if (_refreshControl.refreshing) {

                        [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
                    }
                }
                
                //Finish the refresh
                _isRefreshSharedInProgress = NO;
                
            }];
        } else {
            //The Server not support Share API or is not checked yet
            _sharedLinkItems = nil;
            _sharedLinkItems = [NSArray new];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //Refresh the list of share items
                [_sharedTableView reloadData];
            
                //Stop loading pull refresh
                [self stopPullRefresh];
            });
            
            //Finish the refresh
            _isRefreshSharedInProgress = NO;
        }
    }
}




#pragma mark - Error Messages about credentials of newtwork fails

/*
 * This method called the app delegate error login
 */
- (void)errorLogin{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Stop loading pull refresh
        [self stopPullRefresh];
    });
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [app errorLogin];
}


/*
 * This method is for show alert view in main thread.
 */
- (void) showAlertView:(NSString*)string{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

/*
 * Method called when there are a fail connection with the server
 * @NSString -> Server error msg
 */
- (void)showError:(NSString *) message {
    
    [self performSelectorOnMainThread:@selector(showAlertView:)
                           withObject:message
                        waitUntilDone:YES];
}


///-----------------------------------
/// @name Get Array Sort By Shared Date
///-----------------------------------

/**
 * This method sort an array by shared date
 *
 * @param array -> NSArray
 *
 * @return NSArray
 *
 */
- (NSArray *)getArraySortByShareDate:(NSArray*)array{
    
    array = [array sortedArrayUsingComparator:^NSComparisonResult(OCSharedDto *shared1, OCSharedDto *shared2) {
        
        NSNumber *first = [NSNumber numberWithLong:shared1.sharedDate];
        NSNumber *second = [NSNumber numberWithLong:shared2.sharedDate];
        
       // return [first compare:second];
        return [second compare:first];
    }];
    
    return array;
}

///-----------------------------------
/// @name Get File Not Catched By Shared Path
///-----------------------------------

/**
 * This method make the route of unexisted path. Make the rows in the DataBase and
 * the Folders in the file system if is necessary.
 *
 * @param path -> NSString (shared path9
 *
 * @return FileDto -> file
 *
 */
- (FileDto *) getFileNotCatchedBySharedPath:(OCSharedDto*)sharedDto {
    
    //Access to global variables
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //0.- Create the root folder on the data base
    if (![ManageFilesDB isExistRootFolderByUser:app.activeUser]) {
        DLog(@"Root folder not exist");
        [FileListDBOperations createRootFolderAndGetFileDtoByUser:app.activeUser];
    }
    
    //1.- Loop the shared path and get the not catched sub-paths
    
    //Elements of the path
    NSArray *splitPath = [sharedDto.path componentsSeparatedByString:@"/"];
    
    //To create then the file in DB
    NSString *finalFilePath = @"";
    NSString *finalFileName = [splitPath lastObject];
    
    //Remove fist elemement (white space) and last element because is the file and only we need the folders
    NSMutableArray *splitPathMutable = [NSMutableArray arrayWithArray:splitPath];
    [splitPathMutable removeObjectAtIndex:0];
    [splitPathMutable removeLastObject];
    splitPath = [NSArray arrayWithArray:splitPathMutable];
    splitPathMutable = nil;
    
    NSMutableArray *notCatchedPaths = [NSMutableArray new];
    __block NSString *checkPath = @"";
    __block NSString *oldCheckPath = @"";
    
    //Loop to get the not catched sub-paths
    [splitPath enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *element = (NSString *)obj;
        
        //element 0 is the first element of the check path
        if (idx == 0) {
            checkPath = [NSString stringWithFormat:@"%@/", element];
        } else {
            checkPath = [NSString stringWithFormat:@"%@%@/", checkPath, element];
        }
        
        //if check Path catched
        if (![ManageFilesDB isCatchedInDataBaseThisPath:checkPath]) {
            [notCatchedPaths addObject:checkPath];
            //DLog(@"Not catched path: %@", checkPath);
        }
        
        //Get the checkPath until the the system detect not catched path
        if (notCatchedPaths.count == 0) {
            oldCheckPath = checkPath;
        }
    }];

    //2. Create this sub-paths (Folders) in Data Base and File System
    
    //Get the parent FileDto
    oldCheckPath = [NSString stringWithFormat:@"/%@", oldCheckPath];
    FileDto *parentDto = [ManageFilesDB getFileEqualWithShareDtoPath:oldCheckPath andByUser:app.activeUser];
    
    //Modify the etag of parentDto with 0 in order that in the future the system refresh this folder automatcly
   [ManageFilesDB updateEtagOfFileDtoByid:parentDto.idFile andNewEtag:0];
    
    //Update the final file Path to create the File
    finalFilePath = [NSString stringWithFormat:@"%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:parentDto.filePath andUser:app.activeUser], parentDto.fileName];
    
    //Loop the not catched sub-paths in order to create this in DB and File System
    for (NSString *subPath in notCatchedPaths) {
        
        NSArray *splitSubPath = [subPath componentsSeparatedByString:@"/"];
        //Remove last object because is white space
        NSMutableArray *splitSubPathMutable = [NSMutableArray arrayWithArray:splitSubPath];
        [splitSubPathMutable removeLastObject];
        splitSubPath = [NSArray arrayWithArray:splitSubPathMutable];
        splitSubPathMutable = nil;
        
        __block NSString *filePath = @"";
        NSString *fileName = @"";
        
        //If only one element
        if (splitSubPath.count == 1) {
            filePath = @"";
            fileName = [NSString stringWithFormat:@"%@/", [splitSubPath objectAtIndex:0]];
        } else {
            
            //Last Element is for fileName
            fileName = [NSString stringWithFormat:@"%@/", [splitSubPath lastObject]];
            
            //Remove last element for the array
            NSMutableArray *mutableTempArray = [NSMutableArray arrayWithArray:splitSubPath];
            [mutableTempArray removeLastObject];
            splitSubPath = [NSArray arrayWithArray:mutableTempArray];
            mutableTempArray = nil;
            
            [splitSubPath enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *element = (NSString *)obj;
                
                //element 0 is the first element of the check path
                if (idx == 0) {
                    filePath = [NSString stringWithFormat:@"%@/", element];
                } else {
                    filePath = [NSString stringWithFormat:@"%@%@/", filePath, element];
                }

            }];
        }
        
        //DLog(@"FilePath: %@ - FileName: %@", filePath, fileName);
        
        //3. Insert the intermediate paths in the DB
        
        //Create FileDto object with subPath and parentDto data
        FileDto *newFolder = [FileDto new];
        newFolder.fileId = parentDto.idFile;
        newFolder.userId = app.activeUser.idUser;
        newFolder.filePath = filePath;
        newFolder.fileName = fileName;
        newFolder.isDirectory = YES;
        newFolder.isDownload = notDownload;
        newFolder.size = 0;
        newFolder.date = 0;
        newFolder.isFavorite = 0;
        newFolder.etag = @"";
        newFolder.isRootFolder = NO;
        newFolder.isNecessaryUpdate = NO;
        newFolder.sharedFileSource = 0;
        newFolder.permissions = @"";
        newFolder.taskIdentifier = -1;
        newFolder.providingFileId = 0;
        
        //Insert in the DataBase
        [ManageFilesDB insertFile:newFolder];
        
        //Update the parentDto with newFolder
        parentDto = [ManageFilesDB getFileDtoByFileName:newFolder.fileName andFilePath:newFolder.filePath andUser:app.activeUser];
        
        //Update the final file Path to create the File
        finalFilePath = [NSString stringWithFormat:@"%@%@", newFolder.filePath, newFolder.fileName];
        
        //4. Create intermediate folder in File System

        //Obtain the path where the folder will be created in the file system
        NSString *rootPath = [NSString stringWithFormat:@"%@", newFolder.filePath];
        NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@%ld/%@",[UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser,[rootPath stringByRemovingPercentEncoding]];
        //Remove the "/"
        NSString *name = [newFolder.fileName substringToIndex:[newFolder.fileName length]-1];
        
        //Create the new folder in the file system
        [FileListDBOperations createAFolder:name inLocalFolder:currentLocalFileToCreateFolder];
    }
    
    //5. Create in DB the file.
    FileDto *newFile = [FileDto new];
    newFile.fileId = parentDto.idFile;
    newFile.userId = app.activeUser.idUser;
    newFile.filePath = finalFilePath;
    newFile.fileName = finalFileName;
    newFile.isDirectory = NO;
    newFile.isDownload = notDownload;
    newFile.size = -1;
    newFile.date = 0;
    newFile.isFavorite = 0;
    newFile.etag = @"";
    newFile.isRootFolder = NO;
    newFile.isNecessaryUpdate = NO;
    newFile.sharedFileSource = sharedDto.fileSource;
    newFile.permissions = @"";
    newFile.taskIdentifier = -1;
    newFile.providingFileId = 0;
    
    //Insert in the DataBase
    [ManageFilesDB insertFile:newFile];
    
    //Get the file of the Data Base
    FileDto *file = [ManageFilesDB getFileDtoByFileName:newFile.fileName andFilePath:newFile.filePath andUser:app.activeUser];
    
    //Return FileDto object
    return file;
}

///-----------------------------------
/// @name Create Folder Path in file system with path
///-----------------------------------

/**
 * This method create a folder path in file system
 *
 * @param path -> NSString
 *
 */

- (void) createFolderPathInFileSystemWithThisPath:(NSString*)path{
    
    path = [path stringByRemovingPercentEncoding];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            DLog(@"Error Files: %@", [error localizedDescription]);
        }
    }
}

#pragma mark - UIRefreshControll

///-----------------------------------
/// @name Pull Refresh Table View
///-----------------------------------

/**
 * This method is called when the user do a pull refresh
 * In this method call a method where does a server request.
 * @param refresh -> UIRefreshControl object
 */
-(void)pullRefreshView:(UIRefreshControl *)refresh {
    
    //If the server has not been checked, do it
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
         [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
    }
    refresh.attributedTitle = nil;
    [self performSelector:@selector(refreshSharedItems) withObject:nil];
}

///-----------------------------------
/// @name Stop the Pull Refresh
///-----------------------------------

/**
 * Method called when the server refresh is done in order to
 * terminate the pull refresh animation
 */
- (void)stopPullRefresh{
    [_refreshControl endRefreshing];
}


#pragma mark - UITableView DataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return k_number_table_sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSInteger rows = 0;
    
    if (section == 0) {
        //Shared items
        if (app.activeUser.hasShareApiSupport == serverFunctionalitySupported) {
            if (_sharedLinkItems.count > 0) {
                rows = _sharedLinkItems.count;
            } else {
                rows = 0;
            }
        } else {
            rows = 0;
        }
        
    } else if (section == 1){
        //Has not shared links and has share support
        if (app.activeUser.hasShareApiSupport == serverFunctionalitySupported) {
            if (_sharedLinkItems.count == 0) {
                rows = 1;
            } else {
                rows = 0;
            }
        }else{
            rows = 0;
        }
        
    }else if (section == 2){
        //Has not Shared support
        if (app.activeUser.hasShareApiSupport == serverFunctionalityNotSupported || app.activeUser.hasShareApiSupport == serverFunctionalityNotChecked) {
            rows = 1;
        }else{
            rows = 0;
        }
    }
    return rows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    switch (indexPath.section) {
        case 0:
            //Section 0
            height = 54.0;
            break;
        case 1: case 2:
            //Section 1 & 2
            
            height = [UtilsTableView getUITableViewHeightForSingleRowByNavigationBatHeight:self.navigationController.navigationBar.bounds.size.height andTabBarControllerHeight:self.tabBarController.tabBar.bounds.size.height andTableViewHeight:_sharedTableView.bounds.size.height];
            break;
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UITableViewCell *cell;
    
    _sharedTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    if (indexPath.section == 0) {
        //Section 0
        ShareLinkCell *sharedLinkCell = nil;
        
        // Load the top-level objects from the custom cell XIB.
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ShareLinkCell" owner:self options:nil];
        // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
        sharedLinkCell = (ShareLinkCell *)[topLevelObjects objectAtIndex:0];

        
        //Custom cell for SWTableViewCell with right swipe options
        sharedLinkCell.containingTableView = tableView;
        [sharedLinkCell setCellHeight:sharedLinkCell.frame.size.height];
        sharedLinkCell.leftUtilityButtons = [self setSwipeLeftButtons];
        
        sharedLinkCell.rightUtilityButtons = nil;
        sharedLinkCell.delegate = self;
        
        //Autoresizing width when the iphone is landscape. Not in iPad.
        if (IS_IPHONE) {
            [sharedLinkCell.fileNameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [sharedLinkCell.parentPathLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        }
        
        OCSharedDto *sharedDto = [_sharedLinkItems objectAtIndex:indexPath.row];
        
        //Set this data
        sharedLinkCell.fileNameLabel.text = [FileNameUtils getTheNameOfSharedPath:sharedDto.path isDirectory:sharedDto.isDirectory];
        sharedLinkCell.parentPathLabel.text = [FileNameUtils getTheParentPathOfFullSharedPath:sharedDto.path isDirectory:sharedDto.isDirectory];
        
        
        UIFont *itemFont = nil;
        if (sharedDto.isDirectory) {
            itemFont=  [UIFont fontWithName:@"HelveticaNeue" size:17];
            //Folder image
            sharedLinkCell.fileImageView.image = [UIImage imageNamed:@"folder_icon.png"];
            //Selection style none
            sharedLinkCell.selectionStyle=UITableViewCellSelectionStyleNone;
            
        } else {
            //file
            itemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
            //file image

            //Selection style gray
            sharedLinkCell.selectionStyle=UITableViewCellSelectionStyleGray;
            sharedLinkCell.fileImageView.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[FileNameUtils getTheNameOfSharedPath:sharedDto.path isDirectory:sharedDto.isDirectory]]];
        }
        
        //Set the font
        sharedLinkCell.fileNameLabel.font = itemFont;
        
        cell = sharedLinkCell;
        sharedLinkCell = nil;
      
    }
    
    if (indexPath.section == 1 || indexPath.section == 2) {
        //Section 1 or Section 2
        
        //Identifier
        static NSString *CellIdentifier = @"EmptyCell";
        
        _sharedTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        EmptyCell *emptyShareCell = (EmptyCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (emptyShareCell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"EmptyCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            emptyShareCell = (EmptyCell *)[topLevelObjects objectAtIndex:0];
            
            //No selection style
            emptyShareCell.selectionStyle=UITableViewCellSelectionStyleNone;
        }
        
        //Autoresizing width when the iphone is landscape. Not in iPad.
        if (IS_IPHONE) {
            [emptyShareCell.textLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        }
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        NSString *message = @"";
        message = NSLocalizedString(@"message_not_shared_files", nil);
        
        if (app.activeUser.hasShareApiSupport == serverFunctionalityNotSupported)
            message = NSLocalizedString(@"message_not_shared_api_support", nil);
        
        emptyShareCell.textLabel.text = message;
        emptyShareCell.textLabel.textAlignment = NSTextAlignmentCenter;
        //Disable the tap
        emptyShareCell.userInteractionEnabled = NO;
        cell = emptyShareCell;
        emptyShareCell = nil;
    }
    
    [self setTheLabelOnTheTableFooter];
    
    return cell;
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
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _sharedTableView.bounds.size.width, 40 + self.tabBarController.tabBar.frame.size.height)];
    footerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _sharedTableView.bounds.size.width, 40)];
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    
    label.font = appFont;
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    
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
    label.text = footerText;    
    
    [footerView addSubview:label];
    [_sharedTableView setTableFooterView:footerView];
}




#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //Access to global variables
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Get the ocsharedDto object
    OCSharedDto *sharedDto = [_sharedLinkItems objectAtIndex:indexPath.row];
    
    //Check if is folder or file
    if (!sharedDto.isDirectory) {
        //Get the FileDto
        FileDto *file = [ManageFilesDB getFileEqualWithShareDtoPath:sharedDto.path andByUser:app.activeUser];
        
        if (!file) {
            DLog(@"File not catched yet");
            file = [self getFileNotCatchedBySharedPath:sharedDto];
        
        }
        
        //Sometimes and when file is catched if neccesary create the intermetidate path, for example after a delete folder content action
        [self createFolderPathInFileSystemWithThisPath:[UtilsDtos getTheParentPathOfThePath:file.localFolder]];
        
        //Files Array for gallery
        NSArray *filesArray = nil;
        
        if ([FileNameUtils isImageSupportedThisFile:file.fileName]) {
            filesArray = [self getFileDtoWithOCSharedDtoArray:_sharedLinkItems];
        }else{
            if (file) {
                filesArray = [NSArray arrayWithObject:file];
            }
        }

        
        if (file) {
            
            NSMutableArray *sortArray = [NSMutableArray new];
            if (filesArray) {
                [sortArray addObject:filesArray];
            };
            
            if (IS_IPHONE) {
                //iPhone
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                DLog(@"File name is: %@", file.fileName);
                FilePreviewViewController *viewController = [[FilePreviewViewController alloc]initWithNibName:@"FilePreviewViewController" selectedFile:file andIsForceDownload:NO];
                viewController.hidesBottomBarWhenPushed = YES;
                viewController.sortedArray=sortArray;
                
                [self.navigationController.navigationBar setTranslucent:NO];
                
                self.navigationItem.backBarButtonItem = nil;
                
                self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
                
                [self.navigationController pushViewController:viewController animated:NO];
                
            } else {
                //iPad
                //Select in detail view
                if (_selectedCell) {
                    ShareLinkCell *temp = (ShareLinkCell*) [_sharedTableView cellForRowAtIndexPath:_selectedCell];
                    [temp setSelectedStrong:NO];
                }
                
                //Set selected indexPath
                _selectedCell = indexPath;
                
                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                app.detailViewController.sortedArray=sortArray;
                [app.detailViewController handleFile:file fromController:sharedViewManagerController andIsForceDownload:NO];
                
                ShareLinkCell *sharedLink = (ShareLinkCell*) [_sharedTableView cellForRowAtIndexPath:indexPath];
                [sharedLink setSelectedStrong:YES];
                
            }
        }
    }
    
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
    //Check the share options should be presented
    if ((k_hide_share_options) || (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled)) {
        
        return nil;
        
    }else{
        
        //Share gray button
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        
        
        [rightUtilityButtons sw_addUtilityTwoLinesButtonWithColor:
         [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                            title:NSLocalizedString(@"share_link_long_press", nil)];
        
        //UnShare red button
        [rightUtilityButtons sw_addUtilityTwoLinesButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                            title:NSLocalizedString(@"unshare_link", nil)];
        
        return rightUtilityButtons;
        
    }
    
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
    
    //Get shared token and create the url
    NSIndexPath *cellIndexPath = [self.sharedTableView indexPathForCell:cell];
    OCSharedDto *sharedDto = [self.sharedLinkItems objectAtIndex:cellIndexPath.row];
    
    
    switch (index) {
        case 0: {
            DLog(@"Share Link Option");
            
            //Get the FileDto
            FileDto *file = [ManageFilesDB getFileEqualWithShareDtoPath:sharedDto.path andByUser:APP_DELEGATE.activeUser];
            
            if (!file) {
                file = [self getFileNotCatchedBySharedPath:sharedDto];
            }
            
            if (file) {
                
                ShareMainViewController *share = [[ShareMainViewController alloc] initWithFileDto:file];
                OCNavigationController *nav = [[OCNavigationController alloc] initWithRootViewController:share];
                
                if (IS_IPHONE) {
                    [self presentViewController:nav animated:YES completion:nil];
                } else {
                    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    nav.modalPresentationStyle = UIModalPresentationFormSheet;
                    [app.splitViewController presentViewController:nav animated:YES completion:nil];
                }
                
            }else{
                [self showError:NSLocalizedString(@"default_not_possible_msg", nil)];
            }
            
            [cell hideUtilityButtonsAnimated:YES];
            
            [self performSelector:@selector(refreshSharedItems) withObject:nil afterDelay:0.5];
            
            break;
        } case 1: {
            DLog(@"Unshare button pressed");
            
            if (_mShareFileOrFolder) {
                //Create new object
                self.mShareFileOrFolder = nil;
            }
            
            //Create new object
            self.mShareFileOrFolder = [ShareFileOrFolder new];
            self.mShareFileOrFolder.delegate = self;
            
            [self.mShareFileOrFolder unshareTheFileByIdRemoteShared:sharedDto.idRemoteShared];
            [cell hideUtilityButtonsAnimated:YES];
            
            //Refresh the list of share items
            [self performSelector:@selector(refreshSharedItems) withObject:nil afterDelay:0.5];
            
            break;
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
    for (int i = 0 ; i < [_sharedLinkItems count] ; i++) {
        FileDto *currentFile = [_sharedLinkItems objectAtIndex:i];
        if(currentFile.isDirectory) {
            _numberOfFolders ++;
        } else {
            _numberOfFiles ++;
        }
    }
}

@end
