//
//  FileListDocumentProviderViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 24/11/14.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "FileListDocumentProviderViewController.h"
#import "FileDto.h"
#import "UserDto.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "DocumentPickerCell.h"
#import "EmptyCell.h"
#import "InfoFileUtils.h"
#import "FFCircularProgressView.h"
#import "OCCommunication.h"
#import "Customization.h"
#import "UtilsDtos.h"
#import "ProvidingFileDto.h"
#import "ManageProvidingFilesDB.h"

#define k_Alpha_locked_cell 0.5
#define k_Alpha_normal_cell 1.0

NSString *userHasChangeNotification = @"userHasChangeNotification";
NSString *userHasCloseDocumentPicker = @"userHasCloseDocumentPicker";

@interface FileListDocumentProviderViewController ()

@end

@implementation FileListDocumentProviderViewController

#pragma mark Load View Life

- (void) viewWillAppear:(BOOL)animated {
    
    self.user = [ManageUsersDB getActiveUser];
    
    //We need to catch the rotation notifications only in iPhone.
    if (IS_IPHONE && self.isNecessaryAdjustThePositionAndTheSizeOfTheNavigationBar) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    
    if (self.mode == UIDocumentPickerModeMoveToService) {
        self.moveToThisLocationButton.title = NSLocalizedString(@"move_doc_provider_button", nil);
    }
    
    if (self.mode == UIDocumentPickerModeExportToService) {
        self.moveToThisLocationButton.title = NSLocalizedString(@"export_doc_provider_button", nil);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pickerIsClosing:) name:userHasCloseDocumentPicker object:nil];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    //When we rotate while make the push of the view does not get resized
    [self.navigationController.view setFrame: CGRectMake(0, 0, self.view.window.frame.size.width, self.view.window.frame.size.height)];

    
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
}

- (void) cancelButtonTapped: (UIButton *)sender {
    
    [self.delegate closeDocumentPicker];
    
}


- (void) setLockedApperance:(BOOL) isLocked{
    
    self.isLockedApperance = isLocked;
    [self.navigationController.navigationBar setUserInteractionEnabled:!isLocked];
    [self.tableView setScrollEnabled:!isLocked];
    [self fillTheArraysFromDatabase];
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}


- (void) checkBeforeNavigationToFolder:(FileDto *) file {
    
    //Check if the user is the same and does not change
    if ([self isTheSameUserHereAndOnTheDatabase]) {
        
        if ([ManageFilesDB getFilesByFileIdForActiveUser: (int)file.idFile].count > 0) {
            [self navigateToFile:file];
        } else {
            [self initLoading];
            [self loadRemote:file andNavigateIfIsNecessary:YES];
        }
        
    } else {
        [self showErrorUserHasChange];
    }
}

- (void) reloadCurrentFolder {
   
    if ((!self.download) || (self.download.state == downloadComplete || self.download.state == downloadFailed)) {
         //Check if the user is the same and does not change
        if ([self isTheSameUserHereAndOnTheDatabase]) {
            [self loadRemote:self.currentFolder andNavigateIfIsNecessary:NO];
        } else {
            [self showErrorUserHasChange];
        }
    }
}


#pragma mark - Download methods

- (void) startDownloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView{
    
    if (self.download) {
        self.download = nil;
    }
    
    self.download = [DPDownload new];
    self.download.delegate = self;
  
    [self.download downloadFile:file locatedInFolder:self.currentFolder.localFolder ofUser:self.user withProgressView:progressView];
    
    self.selectedFile = file;
    [self setLockedApperance:YES];
    
}



- (void) cancelCurrentDownloadFile{
    
    if (self.download) {
        [self.download cancelDownload];
    }
    
}

- (void)pickerIsClosing:(NSNotification*)notification {
    
    if (self.download.state != downloadNotStarted ) {
        [self cancelCurrentDownloadFile];
    }
    
    
}

#pragma mark - DPDownload Delegate Methods

- (void)downloadCompleted:(FileDto*)fileDto{
    
    [self setLockedApperance:NO];
    
    if (fileDto) {
        [self.delegate openFile:fileDto];
    }
    
    self.selectedFile = nil;
}

- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    self.selectedFile = nil;
    [self setLockedApperance:NO];
    
    if (![string isEqualToString:@""]) {
        
        [self showError:string];
    }
    
}

- (void)downloadCancelled:(FileDto*)fileDto{
    
    self.selectedFile = nil;
    [self setLockedApperance:NO];
    
}


#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath: indexPath animated:YES];
    
    //Refresh the content with the data of the database
    [self fillTheArraysFromDatabase];
    
    FileDto *file = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    if (file.isDirectory) {
        [self checkBeforeNavigationToFolder:file];
    } else {
        
        if (file.isNecessaryUpdate == NO && file.isDownload == downloaded) {
            [self.delegate openFile:file];
        } else {
            DocumentPickerCell *cell =  (DocumentPickerCell*) [tableView cellForRowAtIndexPath:indexPath];
            
            FFCircularProgressView *progressView = (FFCircularProgressView *) cell.circularPV;
            
            if (self.selectedFile.idFile != file.idFile && (file.isDownload == notDownload || file.isNecessaryUpdate)) {
                [self startDownloadFile:file withProgressView:progressView];
            }else{
                 [self cancelCurrentDownloadFile];
            }

        }
    }
}

#pragma mark - UITableView DataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    if ([self.currentDirectoryArray count] == 0) {
        
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
        
        static NSString *CellIdentifier = @"DocumentPickerCell";
        
        DocumentPickerCell *fileCell = (DocumentPickerCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (fileCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DocumentPickerCell" owner:self options:nil];
            fileCell = (DocumentPickerCell *)[topLevelObjects objectAtIndex:0];
        }
        
        fileCell.indexPath = indexPath;
        
        //Autoresizing width when the iphone is landscape. Not in iPad.
        if (IS_IPHONE) {
            [fileCell.labelTitle setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [fileCell.labelInfoFile setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        }
        
        
        FileDto *file = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
        
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
            
            //Thumbnail
            fileCell.thumbnailSessionTask = [InfoFileUtils updateThumbnail:file andUser:self.user tableView:tableView cellForRowAtIndexPath:indexPath];
            
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
        
        fileCell = (DocumentPickerCell*)[InfoFileUtils getTheStatusIconOntheFile:file onTheCell:fileCell andCurrentFolder:self.currentFolder andIsSonOfFavoriteFolder:NO ofUser:self.user];
        
        //Lock apperance
        if (self.isLockedApperance && file.idFile != self.selectedFile.idFile) {
            fileCell.userInteractionEnabled = NO;
            fileCell.labelTitle.textColor = [UIColor lightGrayColor];
            fileCell.labelInfoFile.textColor = [UIColor lightGrayColor];
            fileCell.fileImageView.alpha = k_Alpha_locked_cell;
            fileCell.imageDownloaded.alpha = k_Alpha_locked_cell;
            fileCell.sharedByLinkImage.alpha = k_Alpha_locked_cell;
            fileCell.sharedWithUsImage.alpha = k_Alpha_locked_cell;
            fileCell.circularPV.alpha = k_Alpha_locked_cell;
        }else{
            fileCell.userInteractionEnabled = YES;
            fileCell.labelTitle.textColor = [UIColor blackColor];
            fileCell.labelInfoFile.textColor = [UIColor blackColor];
            fileCell.fileImageView.alpha = k_Alpha_normal_cell;
            fileCell.imageDownloaded.alpha = k_Alpha_normal_cell;
            fileCell.sharedByLinkImage.alpha = k_Alpha_normal_cell;
            fileCell.sharedWithUsImage.alpha = k_Alpha_normal_cell;
            fileCell.circularPV.alpha = k_Alpha_normal_cell;

        }
        
        if ((file.isDownload == notDownload && !file.isDirectory) || (file.isNecessaryUpdate)) {
            [fileCell.circularPV setHidden:NO];

        }else{
            [fileCell.circularPV setHidden:YES];
        }
        
        
        //Custom cell for SWTableViewCell with right swipe options
        fileCell.containingTableView = tableView;
        [fileCell setCellHeight:fileCell.frame.size.height];
        
        fileCell.rightUtilityButtons = nil;
        
        //Selection style gray
        fileCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell = fileCell;
    }
    return cell;
}


#pragma mark - Check User

- (BOOL) isTheSameUserHereAndOnTheDatabase {
    
    UserDto *userFromDB = [ManageUsersDB getActiveUser];
    
    BOOL isTheSameUser = NO;
    
    if (userFromDB.idUser == self.user.idUser) {
        self.user = userFromDB;
        isTheSameUser = YES;
    }
    
    return isTheSameUser;
    
}

- (void) showErrorUserHasChange {
    //The user has change
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *mesagge = [NSLocalizedString(@"error_user_change_in_core_app", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName];
    
    UIAlertController *alert =   [UIAlertController
                                  alertControllerWithTitle:mesagge
                                  message:@""
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"ok", nil)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [super dismissViewControllerAnimated:YES completion:^{
                                 [[NSNotificationCenter defaultCenter] postNotificationName: userHasChangeNotification object: nil];
                             }];
                         }];
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void) showErrorMessage:(NSString *)string{
    
    [self showError:string];
}

#pragma mark - Navigation
- (void) navigateToFile:(FileDto *) file {
    //Method to be overwritten
    
    NSString *xibName = @"FileListDocumentProviderViewController";
    
    if (self.mode == UIDocumentPickerModeMoveToService || self.mode == UIDocumentPickerModeExportToService) {
        xibName = @"FileListDocumentProviderMoveViewController";
    }
    
    _filesViewController = [[FileListDocumentProviderViewController alloc] initWithNibName:xibName onFolder:file];
    
    _filesViewController.delegate = self.delegate;
    _filesViewController.mode = self.mode;
    
    [[self navigationController] pushViewController:_filesViewController animated:NO];
}

#pragma mark - Rotation

- (void)orientationChange:(NSNotification*)notification {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[notification.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey] intValue];
    
    if(UIInterfaceOrientationIsPortrait(orientation)){
        [self performSelector:@selector(refreshTheInterfaceInPortrait) withObject:nil afterDelay:0.0];
    }
}

//We have to remove the status bar height in navBar and view after rotate
- (void) refreshTheInterfaceInPortrait {
    
    CGRect frameNavigationBar = self.navigationController.navigationBar.frame;
    CGRect frameView = self.view.frame;
    frameNavigationBar.origin.y -= 20;
    frameView.origin.y -= 20;
    frameView.size.height += 20;
    
    self.navigationController.navigationBar.frame = frameNavigationBar;
    self.view.frame = frameView;
    
}

- (void) openFile:(FileDto *) file {
    
    [self.delegate openFile:file];
}

#pragma mark - Move and Export support


- (IBAction)moveToThisLocationButtonTapped:(id)sender{
    
    [self.delegate selectFolder:self.currentFolder];
    
}

@end
