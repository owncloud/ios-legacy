//
//  RecentViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 8/6/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "RecentViewController.h"
#import "FilesViewController.h"
#import "AppDelegate.h"
#import "UploadCell.h"
#import "UploadRecentCell.h"
#import "FailedUploadCell.h"
#import "UIColor+Constants.h"
#import "NSString+Encoding.h"
#import "constants.h"
#import "EditAccountViewController.h"
#import "ManageUsersDB.h"
#import "ManageUploadsDB.h"
#import "ManageFilesDB.h"
#import "SelectFolderViewController.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "UtilsDtos.h"
#import "UploadUtils.h"
#import "OCNavigationController.h"
#import "ManageUploadRequest.h"
#import "InfoFileUtils.h"
#import "EmptyCell.h"
#import "UtilsTableView.h"
#import "DownloadUtils.h"
#import "UtilsUrls.h"
#import "RenameFile.h"
#import "ManageThumbnails.h"

#define k_cell_height 72

@interface RecentViewController ()

@end

@implementation RecentViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.uploadsTableView = [[UITableView alloc] init];
        self.uploadsTableView.dataSource = self;
        self.uploadsTableView.delegate = self;
        [self.uploadsTableView reloadData];
       
        [self setNotificationForCommunicationBetweenViews];
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.title=NSLocalizedString(@"uploads_tab", nil);
    _progressViewArray=[[NSMutableArray alloc]init];

    //Add a more button
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more-filled"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    

}

- (void)showOptions
{
    if (self.plusActionSheet) {
        self.plusActionSheet = nil;
    }

    self.plusActionSheet = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                            destructiveButtonTitle:nil
                            otherButtonTitles:NSLocalizedString(@"clear_successful", nil), nil];

    self.plusActionSheet.actionSheetStyle=UIActionSheetStyleDefault;
    self.plusActionSheet.tag=100;

    // FIXMEL Refactor into a utility function, we do this quite a lot
    if (IS_IPHONE) {
        [self.plusActionSheet showInView:self.tabBarController.view];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [self.plusActionSheet showInView:app.splitViewController.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag==100) {
        switch (buttonIndex) {
            case 0: {
                NSMutableArray *toRemove = [NSMutableArray array];
                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                for (ManageUploadRequest* candidate in app.uploadArray) {
                    if (candidate.isCanceled || (candidate.currentUpload && candidate.currentUpload.status == uploaded)) {
                        [toRemove addObject:candidate];
                    }
                }
                [app.uploadArray removeObjectsInArray:toRemove];
                [ManageUploadsDB cleanTableUploadsOfflineTheFinishedUploads];
                [self updateRecents];
                break;
            }
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = true;
    self.automaticallyAdjustsScrollViewInsets = true;

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
     //Relaunch the uploads that failed before
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [app performSelector:@selector(relaunchUploadsFailedNoForced) withObject:nil afterDelay:5.0];
    
     [self updateRecents];
    

}

-(void)viewDidLayoutSubviews
{
    if ([self.uploadsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.uploadsTableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    
    if ([self.uploadsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.uploadsTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    CGRect rect = self.navigationController.navigationBar.frame;
    float y = rect.size.height + rect.origin.y;
    self.uploadsTableView.contentInset = UIEdgeInsetsMake(y,0,0,0);

}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([self.uploadsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.uploadsTableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
    }
    
    if ([self.uploadsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.uploadsTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (self.plusActionSheet) {
        [self.plusActionSheet dismissWithClickedButtonIndex:self.plusActionSheet.cancelButtonIndex animated:TRUE];
    }

    if(_overWritteOption) {
        if(!IS_IPHONE) {
            [_overWritteOption.overwriteOptionsActionSheet dismissWithClickedButtonIndex:0 animated:NO];
        }
        [_overWritteOption.renameAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

/*
 * Method that look for a unique progressview of cell and update the progress of this
 */
- (void) updateProgressView:(NSUInteger)num withPercent:(float)percent{
    
    
    __block UIProgressView *progressTemp=nil;
   
    [_progressViewArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        progressTemp = obj;
        
        if (progressTemp.tag==num) {
            progressTemp.progress=percent;
            DLog(@"progressTemp.progress: %f", progressTemp.progress);
            *stop=YES;
        }
    }];
    
    DLog(@"changes in progress view nº: %ld", (long)progressTemp.tag);
    
    if (percent==1) {
        [_progressViewArray removeObjectIdenticalTo:progressTemp];
        DLog(@"remove the progress view nº: %ld", (long)progressTemp.tag);
        DLog(@"after remove there are: %lu", (unsigned long)_progressViewArray.count);
    }
}

/*- (void) updateRowNumber:(NSUInteger)num{
    
     //NSIndexPath * myIndexPath = [(UITableView *)self.superview indexPathForCell:self]

    [self.uploadsTableView beginUpdates];
    [self.uploadsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.uploadsTableView endUpdates];
 
}*/

/*
 * This method is used to update the data of the update table with the current uploads info.
 * It's important method called in diferents parts of the app, mainly in this classes: PreparingFiles, AppDelegate, UploadsWithChunks, UploadNoChunks, RecentsViewController
 *
 * There are two parts:
 * 1.- This part is in background thread
 *     - Get the array of the all uploads of the app (current, failed and recents)
 *     - Add the apropiate uploads in three arrays (currentUploads, failedUploads and recentsUploads)
 *     - Order the diferrents arrays using sortDescriptors
 *
 * 2.- This part is in main thread 
 *     - Reload the table using a performselector in main thread.
 */
- (void)updateRecents{
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    DLog(@"Update Recents");
    
    //1 First part in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //Do operations in background thread
        
        //Create a 3 differents temporal arrays 
        NSMutableArray *currentUploadsTemp = [NSMutableArray new];
        NSMutableArray *failedUploadsTemp = [NSMutableArray new];
        NSMutableArray *recentsUploadsTemp = [NSMutableArray new];
        
        //Create an array with the data of all uploads
        __block NSArray *uploadsArray = [NSArray arrayWithArray:appDelegate.uploadArray];
        
        //Var to use the current ManageUploadRequest
        __block ManageUploadRequest *currentManageUploadRequest = nil;

        
        //Update uploads offline with error uploading of the current uploads in order to have update data in current uploads
        NSArray *uploadsOfflineArray = [ManageUploadsDB getUploads];
        
        //Make a dictionary of uploads offline
        NSMutableDictionary *uploadsOfflineDict = [NSMutableDictionary new];
        
        //Add array in dict
        for (UploadsOfflineDto *temp in uploadsOfflineArray) {
            [uploadsOfflineDict setObject:temp forKey:[NSNumber numberWithInteger:temp.idUploadsOffline]];
        }
        
        //Make a loop for all objects of uploadsArray.
        [uploadsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            currentManageUploadRequest = obj;
            
            //Check if the dictionary contains the upload offline key
            if ([[uploadsOfflineDict allKeys] containsObject:[NSNumber numberWithInteger:currentManageUploadRequest.currentUpload.idUploadsOffline]]) {
                //Update the upload offline data
                currentManageUploadRequest.currentUpload = [uploadsOfflineDict objectForKey:[NSNumber numberWithInteger:currentManageUploadRequest.currentUpload.idUploadsOffline]];
                currentManageUploadRequest.userUploading = [ManageUsersDB getUserByIdUser:currentManageUploadRequest.currentUpload.userId];
            }
            
            //Depends of kind of error we assings the upload to appropiate array
            if (currentManageUploadRequest.currentUpload.kindOfError != notAnError) {
                [failedUploadsTemp addObject:currentManageUploadRequest];
            } else if (currentManageUploadRequest.currentUpload.status == uploaded) {
                [recentsUploadsTemp addObject:currentManageUploadRequest];
            } else {
                [currentUploadsTemp addObject:currentManageUploadRequest];
                
               
            }
            
        }];
        
        //Order the _currentsUploads by id ascending //object.currentUpload.idUploadsOffline
        NSSortDescriptor *idAscSortDescriptor;
        idAscSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"currentUpload.idUploadsOffline"
                                                     ascending:YES];
        
        //Order the _currentsUploads by status {uploading, waiting for upload....}
        NSSortDescriptor *statusUploadSortDescriptor;
        statusUploadSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"currentUpload.status"
                                                          ascending:NO];
        
        
        //Order the _failedUploads and by id not ascending
        NSSortDescriptor *idDescSortDescriptor;
        idDescSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"currentUpload.idUploadsOffline"
                                                                        ascending:NO];
        
        //Order the _recentsUploads by date not ascending //object.date
        NSSortDescriptor *dateDescSortDescriptor;
        dateDescSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date"
                                                           ascending:NO];
        //Arrays of descriptors
        NSArray *currentUploadsSortDescriptors = [NSArray arrayWithObjects:statusUploadSortDescriptor, idAscSortDescriptor, nil];
        NSArray *failedUploadsSortDescriptors = [NSArray arrayWithObject:idDescSortDescriptor];
        
        NSArray *recentUploadsSortDescriptors = [NSArray arrayWithObject:dateDescSortDescriptor];
        
        //Apply the sort descritors
        _currentsUploads = [currentUploadsTemp sortedArrayUsingDescriptors:currentUploadsSortDescriptors];
        _failedUploads = [failedUploadsTemp sortedArrayUsingDescriptors:failedUploadsSortDescriptors];
       _recentsUploads = [recentsUploadsTemp sortedArrayUsingDescriptors:recentUploadsSortDescriptors];
        
        
        DLog(@"Uploads array: %lu", (unsigned long)[appDelegate.uploadArray count]);
        DLog(@"Current normal uploads: %lu", (unsigned long)[_currentsUploads count]);
        DLog(@"Failed uploads: %lu", (unsigned long)[_failedUploads count]);
        DLog(@"Recent normal uploads: %lu", (unsigned long)[_recentsUploads count]);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Make operations in main thread
            //Do reload data in safe mode (in this way the tableview not broken)
            [_uploadsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];            
            [self setTheTableFooter];
        });
    });

}

/*
 * This method cancel a current upload using the tag of the button
 * the tag it's the row. 
 * @button -> A button.
 */
- (IBAction)cancelUploadTapped:(UIButton*)button{
    
    DLog(@"indexPath row value: %ld", (long)button.tag);
    
    //Add control to know if the current file exist or not in the array
    BOOL existItem = NO;
    NSInteger numberOfCurrentsItems = _currentsUploads.count;
    if (button.tag < numberOfCurrentsItems) {
        existItem=YES;
    }
    
    if (existItem) {
        //Depends of the type of current upload apply the aproppiate cancel upload method
        ManageUploadRequest *currentManageUploadRequest = [_currentsUploads objectAtIndex:button.tag];
        DLog(@"upload name no chunks: %@", currentManageUploadRequest.currentUpload.uploadFileName);
        [currentManageUploadRequest cancelUpload];
    }
}


#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n=0;
    
    //Current uploads
    if (section==0) {
        
        if (_currentsUploads) {
            n=[_currentsUploads count];
        }else {
            n=0;
        }
        
       // DLog(@"Section nº: %d are %d rows", section, n);
    }
    
    //Failed uploads
    if (section==1) {
        
        if (_failedUploads) {
            n=[_failedUploads count];
        }else {
            n=0;
        }
        
        //  DLog(@"Section nº: %d are %d rows", section, n);
    }
    
    //Recent uploads
    if (section==2) {
        
        if (_recentsUploads) {
            n=[_recentsUploads count];
        }else {
            n=0;
        }
        
        //  DLog(@"Section nº: %d are %d rows", section, n);
        
    }
    
    //Nothing in list
    if (section==3) {
        
        if ([_recentsUploads count] == 0 && [_currentsUploads count] == 0 && [_failedUploads count] == 0) {
            n=1;
        }
        
         // DLog(@"Section nº: %d are %d rows", section, n);
        
    }
    
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    _uploadsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    //Current uploads
    if (indexPath.section==0) {
        static NSString *CellIdentifier = @"UploadFileCell";
        
       UploadCell *uploadCell = (UploadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
       
        
       if (uploadCell == nil)
        {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UploadCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            uploadCell = (UploadCell *)[topLevelObjects objectAtIndex:0];
              uploadCell.selectionStyle=UITableViewCellSelectionStyleNone;
            NSString *nameImage = @"genericFile_icon.png";
            uploadCell.fileImageView.image = [UIImage imageNamed:nameImage];
            uploadCell.progressView.tag=100+indexPath.row;
        }
        
        BOOL isUploading=NO;
        
        //Check if exists the object in current uploads
        if ([_currentsUploads count]>indexPath.row) {
            
            ManageUploadRequest *currentManageUploadRequest = [_currentsUploads objectAtIndex:indexPath.row];
            
            //[uploadCell.cancelButton addTarget:ub action:@selector(cancelUpload) forControlEvents:UIControlEventTouchUpInside];
            uploadCell.cancelButton.tag=indexPath.row;
            [uploadCell.cancelButton addTarget:self action:@selector(cancelUploadTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            uploadCell.labelTitle.text=[currentManageUploadRequest.currentUpload.uploadFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            uploadCell.progressView.progress=currentManageUploadRequest.transferProgress;
            currentManageUploadRequest.progressTag=uploadCell.progressView.tag;
            
            DLog(@"no chunks upload status is: %ld", (long)currentManageUploadRequest.currentUpload.status);
            
            switch (currentManageUploadRequest.currentUpload.status) {
                case errorUploading:
                    [uploadCell.labelErrorMessage setHidden:NO];
                    [uploadCell.progressView setHidden:YES];
                    uploadCell.labelErrorMessage.font=[uploadCell.labelErrorMessage.font fontWithSize:13];
                    [uploadCell.labelErrorMessage setText:NSLocalizedString(@"waiting_for_server", nil)];
                    break;
                    
                case uploading:
                    [uploadCell.labelErrorMessage setHidden:YES];
                    [uploadCell.progressView setHidden:NO];
                    isUploading=YES;
                    break;
                    
                case pendingToBeCheck:
                    [uploadCell.labelErrorMessage setHidden:NO];
                    [uploadCell.progressView setHidden:YES];
                    uploadCell.labelErrorMessage.font=[uploadCell.labelErrorMessage.font fontWithSize:13];
                    [uploadCell.labelErrorMessage setText:NSLocalizedString(@"waiting_for_server", nil)];
                    break;
                default:
                    [uploadCell.labelErrorMessage setHidden:NO];
                    [uploadCell.progressView setHidden:YES];
                    uploadCell.labelErrorMessage.font=[uploadCell.labelErrorMessage.font fontWithSize:13];
                    [uploadCell.labelErrorMessage setText:NSLocalizedString(@"waiting_for_upload", nil)];
                    break;
            }
            
            DLog(@"there are: %lu progress view", (unsigned long)_progressViewArray.count);
            
            if (isUploading) {
                //Check if exist the same _progressView and add or replace the new
                __block UIProgressView *pv =nil;
                __block BOOL existProgressView=NO;
                [_progressViewArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    pv=obj;
                    if (pv.tag==uploadCell.progressView.tag) {
                        existProgressView=YES;
                        *stop=YES;
                    }
                }];
                
                if (!existProgressView) {
                    //Store de progressView
                    [_progressViewArray addObject:uploadCell.progressView];
                }
            }
            
        } else {
            DLog(@"_current upload hasn't this object");
        }
        
        DLog(@"there are: %lu progress view", (unsigned long)_progressViewArray.count);
        
        cell=uploadCell;
        uploadCell=nil;
    }
    
    //Failed uploads
    if (indexPath.section==1) {
        static NSString *CellIdentifier = @"FailedUploadCell";
        
        FailedUploadCell *failedCell = (FailedUploadCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (failedCell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"FailedUploadCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            failedCell = (FailedUploadCell *)[topLevelObjects objectAtIndex:0];
            failedCell.selectionStyle=UITableViewCellSelectionStyleNone;
            failedCell.fileImageView.image = [UIImage imageNamed:@"genericFile_icon_error.png"];
        }
        
        if ([_failedUploads count]>indexPath.row) {
            
            ManageUploadRequest *currentManageUploadRequest = [_failedUploads objectAtIndex:indexPath.row];
            
            
            NSString *msgError=@"";
            
            //[msgError setTextC
            NSString *length = currentManageUploadRequest.lenghtOfFile;
            
            switch (currentManageUploadRequest.currentUpload.kindOfError) {
                case errorCredentials:
                    //In SAML the error message is about the session expired
                    if (k_is_sso_active) {
                        msgError=NSLocalizedString(@"session_expired", nil);
                    }
                    else{
                        msgError=NSLocalizedString(@"error_credential", nil);
                    }
                    break;
                case errorDestinyNotExist:
                    msgError=NSLocalizedString(@"error_destiny_does_not_exist", nil);
                    break;
                case errorFileExist:
                    msgError=NSLocalizedString(@"error_file_exists", nil);
                    break;
                case errorInvalidPath:
                    msgError=NSLocalizedString(@"error_file_invalid_characters", nil);
                    break;
                case errorNotPermission:
                    msgError=NSLocalizedString(@"error_permission", nil);
                    break;
                case errorUploadFileDoesNotExist:
                    msgError=NSLocalizedString(@"error_file_does_not_exist", nil);
                    failedCell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                case errorUploadInBackground:
                    msgError=NSLocalizedString(@"error_file_in_background", nil);
                    failedCell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                case errorInsufficientStorage:
                    msgError=NSLocalizedString(@"error_insufficient_storage", nil);
                    break;
                case errorFirewallRuleNotAllowUpload:
                    msgError=NSLocalizedString(@"error_not_allowed_by_firewall_rule", nil);
                    break;
                default:
                    msgError=NSLocalizedString(@"error", nil);
                    failedCell.accessoryType = UITableViewCellAccessoryNone;
                    break;
            }
            
            
            NSString *lengthAndError = [NSString stringWithFormat:@"%@, %@", length, msgError];
            
            failedCell.labelTitle.text=[currentManageUploadRequest.currentUpload.uploadFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            failedCell.labelLengthAndError.text=lengthAndError;
            failedCell.labelUserName.text=[UtilsUrls getFullRemoteServerPathWithoutProtocolBeginningWithUsername:currentManageUploadRequest.userUploading];
            //If there are SAML replacind the percents escapes with UTF8 coding
            if (k_is_sso_active) {
                failedCell.labelUserName.text = [failedCell.labelUserName.text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
            failedCell.labelPath.text=currentManageUploadRequest.pathOfUpload;
            
        } else {
            DLog(@"_faildeUpload hasn't this object");
        }
        
        cell=failedCell;
        failedCell=nil;
    }
    
    //Recent uploads
    if (indexPath.section==2) {
        static NSString *CellIdentifier = @"UploadRecentCell";
        
       UploadRecentCell *uploadRecentCell = (UploadRecentCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (uploadRecentCell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UploadRecentCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            
            uploadRecentCell = (UploadRecentCell *)[topLevelObjects objectAtIndex:0];
            
            uploadRecentCell.selectionStyle=UITableViewCellSelectionStyleNone;
            NSString *nameImage = @"genericFile_icon.png";
            uploadRecentCell.fileImageView.image = [UIImage imageNamed:nameImage];
        }
        
        if ([_recentsUploads count]>indexPath.row) {
            
            ManageUploadRequest *currentManageUploadRequest = [_recentsUploads objectAtIndex:indexPath.row];
            
            DLog(@"currentManageUploadRequest.currentUpload.uploadedDate: %ld", currentManageUploadRequest.currentUpload.uploadedDate);
            
            if (currentManageUploadRequest.currentUpload.uploadedDate == 0) {
                currentManageUploadRequest.currentUpload = [ManageUploadsDB getUploadOfflineById:currentManageUploadRequest.currentUpload.idUploadsOffline];
            }
            
            DLog(@"currentManageUploadRequest.currentUpload.uploadedDate BD: %ld", currentManageUploadRequest.currentUpload.uploadedDate);
            
            //Obtain the date of the upload file
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:currentManageUploadRequest.currentUpload.uploadedDate];
            NSString *timeAgo = [InfoFileUtils getTheDifferenceBetweenDateOfUploadAndNow:date];
            NSString *length = currentManageUploadRequest.lenghtOfFile;
            
            NSString *labelLengthAndDateString = [NSString stringWithFormat:@"%@, %@", length, timeAgo];
            
            uploadRecentCell.labelTitle.text=[currentManageUploadRequest.currentUpload.uploadFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            uploadRecentCell.labelLengthAndDate.text=labelLengthAndDateString;
            uploadRecentCell.labelPath.text=currentManageUploadRequest.pathOfUpload;
            uploadRecentCell.labelUserName.text=[NSString stringWithFormat:@"%@@%@", currentManageUploadRequest.userUploading.username, [UtilsUrls getUrlServerWithoutHttpOrHttps:currentManageUploadRequest.userUploading.url]];
            //If there are SAML replacind the percents escapes with UTF8 coding
            if (k_is_sso_active) {
                uploadRecentCell.labelUserName.text = [uploadRecentCell.labelUserName.text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
            
        } else {
            DLog(@"recents uploads hasn't this object");
        }
        
        cell=uploadRecentCell;
        uploadRecentCell=nil;
    }
    
    if (indexPath.section==3) {
        static NSString *CellIdentifier = @"EmptyCell";
        
        EmptyCell *nothingUploadCell = (EmptyCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        _uploadsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
       if (nothingUploadCell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"EmptyCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            nothingUploadCell = (EmptyCell *)[topLevelObjects objectAtIndex:0];
        }
        
        NSString *message = NSLocalizedString(@"nothing_was_upload_recently", nil);
        nothingUploadCell.textLabel.text = message;
        nothingUploadCell.textLabel.textAlignment = NSTextAlignmentCenter;
        //Disable the tap
        nothingUploadCell.userInteractionEnabled = NO;
        cell = nothingUploadCell;
        nothingUploadCell = nil;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = @"";   
    
    if (section==0) {
        if (_currentsUploads) {
            if ([_currentsUploads count]>0) {
                title=NSLocalizedString(@"current_section", nil);
            }else {
                title=@"";
            }
        }
    }
    
    if (section==1) {
        if (_failedUploads) {
            if ([_failedUploads count]>0) {
                title=NSLocalizedString(@"failed_uploader_section", nil);
            }else {
                title=@"";
            }
        }
    }
    
    if (section==2) {
        if (_recentsUploads) {
            if ([_recentsUploads count]>0) {
                title=NSLocalizedString(@"uploader_section", nil);
            }else {
                title=@"";
            }
        }
    }
    
    return title;
}




#pragma mark - UITableView delegate

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"Tap the row number: %ld", (long)indexPath.row);
    
    //Failed section
    if(indexPath.section==1){
        
        //Add control to know if the failed file exist or not
        BOOL existItem = NO;
        NSInteger numberOfFailedItems = _failedUploads.count;
        if (indexPath.row<numberOfFailedItems) {
            existItem=YES;
        }
        
    
        if (existItem) {
            DLog(@"Exist item to select");
            DLog(@"File error upload no chunks");
            ManageUploadRequest *selectedManageUploadRequest = (ManageUploadRequest *)[_failedUploads objectAtIndex:indexPath.row];
            
            switch (selectedManageUploadRequest.currentUpload.kindOfError) {
                case errorCredentials:
                    DLog(@"Credential errors");
                    [self resolveCredentialError:selectedManageUploadRequest.currentUpload];
                    break;
                case errorDestinyNotExist:
                    DLog(@"Destiny folder doesn't exist");
                    [self resolveFolderNotFoundError:selectedManageUploadRequest.currentUpload];
                    break;
                case errorFileExist:
                    [self resolveFileExistError:selectedManageUploadRequest.currentUpload];
                    DLog(@"File exists");
                    break;
                case errorNotPermission:
                    _selectedFileDtoToResolveNotPermission = selectedManageUploadRequest.currentUpload;
                    [self resolveNotHavePermission:selectedManageUploadRequest.currentUpload];
                    DLog(@"User not have permision");
                    break;
                case errorInsufficientStorage:
                    DLog(@"Not enough free space in your account");
                    [self resolveInsufficientStorage:selectedManageUploadRequest.currentUpload];
                    break;
                default:
                    break;
                    
            }
        } else {
            DLog(@"No Exist item to select");
        }
        
    }
    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CGFloat height = 0.0;
    
    //If the _currentDirectoryArray doesn't have object it will have a big row
    if (indexPath.section == 3) {
        height = [UtilsTableView getUITableViewHeightForSingleRowByNavigationBatHeight:self.navigationController.navigationBar.bounds.size.height andTabBarControllerHeight:self.tabBarController.tabBar.bounds.size.height andTableViewHeight:_uploadsTableView.bounds.size.height];
    } else {
        height = k_cell_height;
    }
    return height;
}


- (void) setTheTableFooter {
    
    //Set the footer section so that user can tap latest file if it's under the tabBar
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.uploadsTableView.frame.size.width, 40 + self.tabBarController.tabBar.frame.size.height)];
    footerView.backgroundColor = [UIColor clearColor];
    [self.uploadsTableView setTableFooterView:footerView];
}


#pragma mark - Methods to resolve the Failed Uploads

- (void) resolveFolderNotFoundError:(UploadsOfflineDto *) selectedUpload {
    //If the folder not exist we should choose other folder
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    DLog(@"user: %ld", (long)app.activeUser.idUser);
    DLog(@"user: %ld", (long)selectedUpload.userId);
    
    
    if(selectedUpload.userId == app.activeUser.idUser){
        
        _selectedUploadToResolveTheConflict=selectedUpload;
        SelectFolderViewController *sf = [[SelectFolderViewController alloc] initWithNibName:@"SelectFolderViewController" onFolder:[ManageFilesDB getRootFileDtoByUser:app.activeUser]];
        
        //sf.toolBarLabelTxt = NSLocalizedString(@"upload_label", nil);
        sf.toolBarLabelTxt = @"";
        
        SelectFolderNavigation *navigation = [[SelectFolderNavigation alloc]initWithRootViewController:sf];
        sf.parent=navigation;
        sf.currentRemoteFolder=self.currentRemoteFolder;
        navigation.delegate=self;
        
       // navigation.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
       // navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        
        if (IS_IPHONE)
        {
            [self presentViewController:navigation animated:YES completion:nil];
            
        } else {
            navigation.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            navigation.modalPresentationStyle = UIModalPresentationFormSheet;
            [app.detailViewController presentViewController:navigation animated:YES completion:nil];
        }
        
    } else {
        UserDto *userSelected = [ManageUsersDB getUserByIdUser:selectedUpload.userId];
        NSString *userName = userSelected.username;
        //if SAML is enabled replace the percent of the samlusername by utf8
        if (k_is_sso_active) {
            userName= [userName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        NSString* temp=[NSString stringWithFormat:@"%@ %@@%@", NSLocalizedString(@"change_active_user", nil), userName, [UtilsUrls getUrlServerWithoutHttpOrHttps:userSelected.url]];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:temp
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    }
}


///-----------------------------------
/// @name Fix the Credential Error
///-----------------------------------

/**
 * This method is called when the user tap to resolve a error in a file and
 * the error is an "credential error"
 * This method prepare and show the EditAccount Screen
 *
 * @param selectedUpload -> UploadsOfflineDto of the selected file by the user
 *
 */
- (void) resolveCredentialError:(UploadsOfflineDto *) selectedUpload {
    
    //Assign the select upload to a global attribute
    _selectedUploadToResolveTheConflict=selectedUpload;
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    //Get the update of the user
    UserDto *userSelected = [ManageUsersDB getUserByIdUser:selectedUpload.userId];
    
    if (selectedUpload.userId != (app.activeUser.idUser)) {
        NSString *userName = userSelected.username;
        //if SAML is enabled replace the percent of the samlusername by utf8
        if (k_is_sso_active) {
            userName= [userName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        NSString* temp=[NSString stringWithFormat:@"%@ %@@%@", NSLocalizedString(@"change_active_user", nil), userName, [UtilsUrls getUrlServerWithoutHttpOrHttps:userSelected.url]];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:temp
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    } else {
        //Show the Edit Account Screen
        EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:userSelected andLoginMode:LoginModeExpire];
        
        if (IS_IPHONE) {
            viewController.hidesBottomBarWhenPushed = YES;
            OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        } else {
            
            OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [app.splitViewController presentViewController:navController animated:YES completion:nil];
        }
    }
}

///-----------------------------------
/// @name Resolve file exist error
///-----------------------------------

/**
 * This method resolves a file exist error: When the user tries to put the same name that the other
 * without connection, this error appear in the Recent Tab
 *
 * @param selectedUpload -> UploadsOfflineDto, the upload with the conclict error
 *
 */
- (void) resolveFileExistError:(UploadsOfflineDto *) selectedUpload {
    
    if (IS_IPHONE && !IS_PORTRAIT) {
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:NSLocalizedString(@"not_show_potrait", nil)
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    } else {
        
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        if(selectedUpload.userId == app.activeUser.idUser){
            
            _selectedUploadToResolveTheConflict = selectedUpload;
            
            FileDto *file = [[FileDto alloc] init];
            file.fileName = [_selectedUploadToResolveTheConflict.uploadFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            file.isDirectory = NO;
            
            if (!self.overWritteOption) {
                _overWritteOption = [OverwriteFileOptions new];
            }
            
            if (IS_IPHONE) {
                _overWritteOption.viewToShow = self.view;
            } else {
                _overWritteOption.viewToShow = app.splitViewController.view;
            }
            _overWritteOption.delegate = self;
            _overWritteOption.fileDto = file;
            [_overWritteOption showOverWriteOptionActionSheet];
            
        } else {
            UserDto *userSelected = [ManageUsersDB getUserByIdUser:selectedUpload.userId];
            NSString *userName=userSelected.username;
            //if SAML is enabled replace the percent of the samlusername by utf8
            if (k_is_sso_active) {
                userName= [userName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }

            NSString* temp=[NSString stringWithFormat:@"%@ %@@%@", NSLocalizedString(@"change_active_user", nil), userName, [UtilsUrls getUrlServerWithoutHttpOrHttps:userSelected.url]];
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                               message:temp
                                                              delegate:nil
                                                     cancelButtonTitle:nil
                                                     otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
            [alertView show];
        }
    }
}

///-----------------------------------
/// showErrorNotHavePermission
///-----------------------------------

/**
 * Method to show the error message about the permission
 *
 * * @param selectedUpload -> UploadsOfflineDto of the selected file by the user
 */
- (void) resolveNotHavePermission:(UploadsOfflineDto *) selectedUpload {
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    DLog(@"user: %ld", (long)app.activeUser.idUser);
    DLog(@"user: %ld", (long)selectedUpload.userId);
    
    if(selectedUpload.userId == app.activeUser.idUser){
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_permission_alert_message", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"choose_folder", nil), nil];
        [alertView show];
        
    }else{
        UserDto *userSelected = [ManageUsersDB getUserByIdUser:selectedUpload.userId];
        NSString *userName = userSelected.username;
        //if SAML is enabled replace the percent of the samlusername by utf8
        if (k_is_sso_active) {
            userName= [userName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        NSString* temp=[NSString stringWithFormat:@"%@ %@@%@", NSLocalizedString(@"change_active_user", nil), userName, [UtilsUrls getUrlServerWithoutHttpOrHttps:userSelected.url]];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:temp
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    }
}

///-----------------------------------
/// @name Resolve insufficient storage
///-----------------------------------

/**
 * This method resolves a file insufficient error: 
 * When the user tries to upload and no free space available in their account
 * this error appear in the Recent Tab
 *
 * @param selectedUpload -> UploadsOfflineDto, the upload with the conclict error
 *
 */
- (void) resolveInsufficientStorage:(UploadsOfflineDto *) selectedUpload {
 
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    if(selectedUpload.userId == app.activeUser.idUser){
        [ManageUploadsDB updateErrorOfAllUploadsOfUser:selectedUpload.userId withCurrentError:errorInsufficientStorage toNewError:notAnError];
    } else {
        UserDto *userSelected = [ManageUsersDB getUserByIdUser:selectedUpload.userId];
        NSString *userName = userSelected.username;
        //if SAML is enabled replace the percent of the samlusername by utf8
        if (k_is_sso_active) {
            userName= [userName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        NSString* temp=[NSString stringWithFormat:@"%@ %@@%@", NSLocalizedString(@"change_active_user", nil), userName, [UtilsUrls getUrlServerWithoutHttpOrHttps:userSelected.url]];
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:temp
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    }

    //Reload data of uploads table
    [self updateRecents];
    
    //Relaunch the uploads that failed before
    [app performSelectorInBackground:@selector(relaunchUploadsFailedForced) withObject:nil];
}




#pragma mark - OverwriteFileOptionsDelegate

- (void) setNewNameToSaveFile:(NSString *)name {
    DLog(@"setNewNameToSaveFile: %@", name);
    
    _selectedUploadToResolveTheConflict.uploadFileName = name;
    
    [ManageUploadsDB updateErrorConflictFilesSetNewName:[name encodeString:NSUTF8StringEncoding] forUploadOffline:_selectedUploadToResolveTheConflict];
    
    //Remove this upload of upload array and update this tableview
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _selectedUploadToResolveTheConflict.kindOfError=notAnError;
    [self updateRecents];
    
    //Relaunch the uploads that failed before
    [app performSelectorInBackground:@selector(relaunchUploadsFailedForced) withObject:nil];
}


- (void) overWriteFile {
        
     AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    _selectedUploadToResolveTheConflict.isNotNecessaryCheckIfExist = YES;
    
    [ManageUploadsDB updateErrorConflictFilesSetOverwrite:YES forUploadOffline: _selectedUploadToResolveTheConflict];
    
    //A overwrite process is in progress
    app.isOverwriteProcess = YES;
    
    FileDto *file = [UploadUtils getFileDtoByUploadOffline:self.selectedUploadToResolveTheConflict];
    
    [[ManageThumbnails sharedManager] removeStoredThumbnailForFile:file];
    
    //Check if this file is being updated and cancel it
    Download *downloadFile;
    NSArray *downloadsArrayCopy = [NSArray arrayWithArray:[app.downloadManager getDownloads]];
    
    for (downloadFile in downloadsArrayCopy) {
        if (([downloadFile.fileDto.fileName isEqualToString: file.fileName]) && ([downloadFile.fileDto.filePath isEqualToString: file.filePath])) {
            [downloadFile cancelDownload];
        }
    }
    downloadsArrayCopy=nil;
    
    
    if (file.isDownload == downloaded) {
        //Set this file as an overwritten state
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:overwriting];
        //Calls the method that update the view when the user overwrite a file
        [UploadUtils updateOverwritenFile:file FromPath:_selectedUploadToResolveTheConflict.originPath];
    }    

    //Change the kind of error and update the recents tab
    _selectedUploadToResolveTheConflict.kindOfError=notAnError;
    //Reload data of uploads table
   [self updateRecents];
    
    //Relaunch the uploads that failed before
    [app performSelectorInBackground:@selector(relaunchUploadsFailedForced) withObject:nil];
}


#pragma mark Select Folder Navigation Delegate Methods

- (void)folderSelected:(NSString*)folder{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (self.selectedFileDtoToResolveNotPermission) {
        
        //If exist file related with the select upload put in downloaded state
        //UserDto *user = [ManageUsersDB getUserByIdUser:self.selectedFileDtoToResolveNotPermission.userId];
        
       // NSString *parentFolder = [UtilsUrls getFilePathOnDBByFullPath:self.selectedFileDtoToResolveNotPermission.destinyFolder andUser:user];
        
      //  FileDto *uploadFile = [ManageFilesDB getFileDtoByFileName:self.selectedFileDtoToResolveNotPermission.uploadFileName andFilePath:parentFolder andUser:user];
        
        FileDto *uploadFile = [UploadUtils getFileDtoByUploadOffline:self.selectedFileDtoToResolveNotPermission];
        
        if (uploadFile && uploadFile.isDownload == overwriting) {
            [ManageFilesDB setFileIsDownloadState:uploadFile.idFile andState:downloaded];
        }

    }
    
    DLog(@"Change Folder");
    //TODO. Change current Remote Folder
    _currentRemoteFolder=folder;
    
    NSArray *splitedUrl = [folder componentsSeparatedByString:@"/"];
    // int cont = [splitedUrl count];
    NSString *folderName = [NSString stringWithFormat:@"/%@",[splitedUrl objectAtIndex:([splitedUrl count]-2)]];
    
    DLog(@"Folder is:%@", folderName);
    if ([_currentRemoteFolder isEqualToString:[UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser]]) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        folderName=appName;
    }
    
    _locationInfo=folderName;

    _selectedUploadToResolveTheConflict.destinyFolder=folder;
    
    [ManageUploadsDB updateErrorFolderNotFoundFilesSetNewDestinyFolder:folder forUploadOffline:_selectedUploadToResolveTheConflict];
    
    //Change the kind of error and update the recents tab
    _selectedUploadToResolveTheConflict.kindOfError=notAnError;
    //update the uploads table
    [self updateRecents];
    
   // DLog(@"Destiny folder: %@",folder);
    //DLog(@"id file: %d",_selectedUploadToResolveTheConflict.idUploadsOffline);
    
    //Force to relaunch the uploads that failed before
    [app performSelectorInBackground:@selector(relaunchUploadsFailedForced) withObject:nil];
}

- (void)cancelFolderSelected{
    
    //Nothing
    DLog(@"Cancel folder");
}

#pragma mark - Edit row


- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    [self.uploadsTableView setEditing:editing animated:animated];
    if (editing) {
        // you might disable other widgets here... (optional)
        [self.uploadsTableView reloadData];
    } else {
        // re-enable disabled widgets (optional)
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section==1) {
        return YES;
    }else{
        return NO;
    }
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
        ManageUploadRequest *selectedUpload = (ManageUploadRequest *)[_failedUploads objectAtIndex:indexPath.row];
        [selectedUpload cancelUpload];
}


#pragma mark - Notification
/*
 * This method addObservers for notifications to this class
 */
-(void)setNotificationForCommunicationBetweenViews{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relaunchErrorCredentialFiles:) name:relaunchErrorCredentialFilesNotification object:nil];
}


///-----------------------------------
/// @name Relaunch Error Credential Uploads
///-----------------------------------

/**
 * This method is called when the object receive the notificacion "relaunchErrorCredentialFilesNotification"
 * First catch the user that change the credentials
 * And then change the status of the user uploads
 * Finally update the uploads view and relaunch the failed uploads
 *
 * @param notification -> UserDto envolved in NSNotification object
 *
 * @discussion Maybe could be better move this kind of method a singleton class inicilizated in appDelegate.
 *
 */
-(void)relaunchErrorCredentialFiles:(NSNotification*)notification{

    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
     UserDto *userDto = (UserDto*)[notification object];

    //Change the status of the Credencial files error on a specific user
    [app changeTheStatusOfCredentialsFilesErrorOfAnUserId:userDto.idUser];
    
    //Update the uploads table view
    [self updateRecents];
    
    //Forced to relaunch the failed upload files.
    [app relaunchUploadsFailedForced];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    // cancel
    if( buttonIndex == 1 ){
        //Choose folder
        [self resolveFolderNotFoundError:_selectedFileDtoToResolveNotPermission];
    }else if (buttonIndex == 0) {
        //Cancel
        
    }else {
        //Nothing
    }
}




@end
