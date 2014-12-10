//
//  FileListDocumentProviderViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 24/11/14.
//
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
#import "DocumentPickerViewController.h"
#import "Customization.h"

NSString *userHasChangeNotification = @"userHasChangeNotification";

@interface FileListDocumentProviderViewController ()

@end

@implementation FileListDocumentProviderViewController

#pragma mark Load View Life

- (void) viewWillAppear:(BOOL)animated {
    
    //We need to catch the rotation notifications only in iPhone.
    if (IS_IPHONE) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidAppear:(BOOL)animated {
    
    //When we rotate while make the push of the view does not get resized
    [self.view setFrame: CGRectMake(0, 0, self.view.window.frame.size.width, self.view.window.frame.size.height)];
}


- (void) setLockedApperance:(BOOL) isLocked{
    
    self.isLockedApperance = isLocked;
    [self.navigationController.navigationBar setUserInteractionEnabled:!isLocked];
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
    //Check if the user is the same and does not change
    if ([self isTheSameUserHereAndOnTheDatabase]) {
        [self loadRemote:self.currentFolder andNavigateIfIsNecessary:NO];
    } else {
        [self showErrorUserHasChange];
    }
}


#pragma mark - Download methods

- (void) startDownloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView{
    
    self.selectedFile = file;
    [self setLockedApperance:YES];
    
    OCCommunication *sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
    
    NSArray *splitedUrl = [self.user.url componentsSeparatedByString:@"/"];
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@%@",[NSString stringWithFormat:@"%@/%@/%@",[splitedUrl objectAtIndex:0],[splitedUrl objectAtIndex:1],[splitedUrl objectAtIndex:2]], file.filePath, file.fileName];
    
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //get local path of server
    __block NSString *localPath;
    
    NSString *temporalFileName;
    NSString *deviceLocalPath;
    
    
    if (file.isNecessaryUpdate) {
        //Change the local name for a temporal one
        temporalFileName = [NSString stringWithFormat:@"%@-%@", [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        localPath = [NSString stringWithFormat:@"%@%@", self.currentFolder.localFolder, temporalFileName];
    } else {
        localPath = [NSString stringWithFormat:@"%@%@", self.currentFolder.localFolder, [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    deviceLocalPath = localPath;
    
    if (!file.isNecessaryUpdate && (file.isDownload != overwriting)) {
        //Change file status in Data Base to downloading
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloading];
    } else if (file.isNecessaryUpdate) {
        //Change file status in Data Base to updating
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:updating];
    }

    //Set the right credentials
    if (k_is_sso_active) {
        [sharedCommunication setCredentialsWithCookie:self.user.password];
    } else if (k_is_oauth_active) {
        [sharedCommunication setCredentialsOauthWithToken:self.user.password];
    } else {
        [sharedCommunication setCredentialsWithUser:self.user.username andPassword:self.user.password];
    }
    
    
    [progressView startSpinProgressBackgroundLayer];
    
    self.downloadOperation = [sharedCommunication downloadFile:serverUrl toDestiny:localPath withLIFOSystem:YES onCommunication:sharedCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [progressView stopSpinProgressBackgroundLayer];
        float percent = (float)totalBytesRead / totalBytesExpectedToRead;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:percent];
        });

        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        self.selectedFile.isDownload = downloaded;
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloaded];
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
           
            [progressView setHidden:YES];
            self.selectedFile = nil;
            
            [self setLockedApperance:NO];
        });
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        file.isDownload = notDownload;
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
        self.selectedFile = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:0.0];
        });
        
        
        [self setLockedApperance:NO];

        
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        [self cancelCurrentDownloadFile:file withProgressView:progressView];
    }];
    

}

- (void) cancelCurrentDownloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView{
    
    [self.downloadOperation cancel];
}


#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath: indexPath animated:YES];
    
    FileDto *file = (FileDto *)[[self.sortedArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    
    if (file.isDirectory) {
        [self checkBeforeNavigationToFolder:file];
    } else {
        
        DocumentPickerCell *cell =  (DocumentPickerCell*) [tableView cellForRowAtIndexPath:indexPath];
        
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.circularPV;
        
        if (self.selectedFile.idFile != file.idFile) {
            [self startDownloadFile:file withProgressView:progressView];
        }else{
            [self cancelCurrentDownloadFile:file withProgressView:progressView];
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
        
        
        fileCell = (DocumentPickerCell*)[InfoFileUtils getTheStatusIconOntheFile:file onTheCell:fileCell andCurrentFolder:self.currentFolder];
        
        //Lock apperance
        if (self.isLockedApperance && file.idFile != self.selectedFile.idFile) {
            fileCell.userInteractionEnabled = NO;
            fileCell.labelTitle.textColor = [UIColor lightGrayColor];
            fileCell.labelInfoFile.textColor = [UIColor lightGrayColor];
            fileCell.fileImageView.alpha = 0.5;
            fileCell.imageDownloaded.alpha = 0.5;
            fileCell.sharedByLinkImage.alpha = 0.5;
            fileCell.sharedWithUsImage.alpha = 0.5;
            fileCell.circularPV.alpha = 0.5;
        }else{
            fileCell.userInteractionEnabled = YES;
            fileCell.labelTitle.textColor = [UIColor blackColor];
            fileCell.labelInfoFile.textColor = [UIColor blackColor];
            fileCell.fileImageView.alpha = 1.0;
            fileCell.imageDownloaded.alpha = 1.0;
            fileCell.sharedByLinkImage.alpha = 1.0;
            fileCell.sharedWithUsImage.alpha = 1.0;
            fileCell.circularPV.alpha = 1.0;

        }
        
        if (file.isDownload != downloaded && !file.isDirectory) {
            [fileCell.circularPV setHidden:NO];

        }else{
            [fileCell.circularPV setHidden:YES];
        }
        
        
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
    
    UIAlertController *alert =   [UIAlertController
                                  alertControllerWithTitle:@""
                                  message:@"The user has change on the ownCloud App" //TODO: add a string error internationzalized
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

#pragma mark - Navigation
- (void) navigateToFile:(FileDto *) file {
    //Method to be overwritten
    FileListDocumentProviderViewController *filesViewController = [[FileListDocumentProviderViewController alloc] initWithNibName:@"FileListDocumentProviderViewController" onFolder:file];
    
    [[self navigationController] pushViewController:filesViewController animated:YES];
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


@end
