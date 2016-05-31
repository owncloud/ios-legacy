//
//  PrepareFilesToUpload.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 12/09/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "PrepareFilesToUpload.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "CheckAccessToServer.h"
#import "AppDelegate.h"
#import <Photos/Photos.h>

#import "UserDto.h"
#import "constants.h"
#import "EditAccountViewController.h"
#import "UtilsDtos.h"
#import "ManageUploadsDB.h"
#import "FileNameUtils.h"
#import "UploadUtils.h"
#import "ManageUsersDB.h"
#import "ManageUploadRequest.h"
#import "ManageAppSettingsDB.h"
#import "UtilsNetworkRequest.h"
#import "constants.h"
#import "Customization.h"
#import "UtilsUrls.h"
#import "OCCommunication.h"
#import "FileNameUtils.h"

//Notification to end and init loading screen
NSString *EndLoadingFileListNotification = @"EndLoadingFileListNotification";
NSString *InitLoadingFileListNotification = @"InitLoadingFileListNotification";
NSString *ReloadFileListFromDataBaseNotification = @"ReloadFileListFromDataBaseNotification";


@implementation PrepareFilesToUpload

#pragma  mark - Manage queue
- (void) addFilesToUpload:(NSArray *) info andRemoteFoldersToUpload:(NSMutableArray *) arrayOfRemoteurl {
    
    for (int i = 0 ; i < [info count] ; i++) {
        
        [self.listOfFilesToUpload addObject:[info objectAtIndex:i]];
        [self.arrayOfRemoteurl addObject:[arrayOfRemoteurl objectAtIndex:i]];
    }
    
    [self startWithTheNextFile];
}

- (void) startWithTheNextFile {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL isLastUploadFileOfThisArray = NO;
    
    if ([self.listOfFilesToUpload count] == 1 && [self.arrayOfRemoteurl count]== 1) {
        isLastUploadFileOfThisArray = YES;
    }
    
    [self uploadFileFromGallery:[self.listOfFilesToUpload objectAtIndex:0] andRemoteFolder:[self.arrayOfRemoteurl objectAtIndex:0] andCurrentUser:appDelegate.activeUser andIsLastFile:isLastUploadFileOfThisArray];
    
    [self.listOfFilesToUpload removeObjectAtIndex:0];
    [self.arrayOfRemoteurl removeObjectAtIndex:0];
}

- (void)sendFileToUploadByUploadOfflineDto:(UploadsOfflineDto *) currentUpload {
    
    DLog(@"self.currentUpload: %@", currentUpload.uploadFileName);
    DLog(@"isLast: %d", currentUpload.isLastUploadFileOfThisArray);
    
    ManageUploadRequest *currentManageUploadRequest = [ManageUploadRequest new];
    currentManageUploadRequest.delegate = self;
    currentManageUploadRequest.lenghtOfFile = [UploadUtils makeLengthString:currentUpload.estimateLength];
    
    [currentManageUploadRequest addFileToUpload:currentUpload];
    
}

- (void)uploadFileFromGallery:(PHAsset *)assetToUpload andRemoteFolder:(NSString *) remoteFolder andCurrentUser:(UserDto *) currentUser andIsLastFile:(BOOL) isLastUploadFileOfThisArray {
    
    DLog(@"uploadFileFromGallery");
    
    [[PHImageManager defaultManager] requestImageDataForAsset:assetToUpload options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        NSString *fileName = [FileNameUtils getComposeNameFromPHAsset:assetToUpload];
        NSString *localPath = [[UtilsUrls getTempFolderForUploadFiles] stringByAppendingPathComponent:fileName];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:localPath]) {
            [fileManager removeItemAtPath:localPath error:nil];
        }
        
        [fileManager createFileAtPath:localPath contents:imageData attributes:nil];
        
        UploadsOfflineDto *currentUpload = [[UploadsOfflineDto alloc] init];
        currentUpload.originPath = localPath;
        currentUpload.destinyFolder = remoteFolder;
        currentUpload.uploadFileName = fileName;
        currentUpload.estimateLength = imageData.length;;
        currentUpload.userId = currentUser.idUser;
        currentUpload.isLastUploadFileOfThisArray = isLastUploadFileOfThisArray;
        currentUpload.status = waitingAddToUploadList;
        currentUpload.chunksLength = k_lenght_chunk;
        currentUpload.uploadedDate = 0;
        currentUpload.kindOfError = notAnError;
        currentUpload.isInternalUpload = YES;
        currentUpload.taskIdentifier = 0;
        
        [self.listOfUploadOfflineToGenerateSQL addObject:currentUpload];
        
        long dateAsset = (long)[assetToUpload.creationDate timeIntervalSince1970];
        //update date last asset uploaded
        if (dateAsset > [ManageAppSettingsDB getDateInstantUpload]) {
            //assetDate later than startDate
            [ManageAppSettingsDB updateDateInstantUpload:dateAsset];
        }
        
        if([self.listOfFilesToUpload count] > 0) {
            //We have more files to process
            [self startWithTheNextFile];
        } else {
            
            //We finish all the files of this block
            DLog(@"self.listOfUploadOfflineToGenerateSQL: %lu", (unsigned long)[self.listOfUploadOfflineToGenerateSQL count]);
            
            //In this point we have all the files to upload in the Array
            [ManageUploadsDB insertManyUploadsOffline:self.listOfUploadOfflineToGenerateSQL];
            
            //if is the last one we reset the array
            self.listOfUploadOfflineToGenerateSQL = nil;
            self.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
            
            self.positionOfCurrentUploadInArray = 0;
            
            [self performSelectorOnMainThread:@selector(endLoadingInFileList) withObject:nil waitUntilDone:YES];
            
            UploadsOfflineDto *currentFile = [ManageUploadsDB getNextUploadOfflineFileToUpload];
            
            //We begin with the first file of the array
            if (currentFile) {
                [self sendFileToUploadByUploadOfflineDto:currentFile];
            }
        }
        
    }];

}


#pragma mark - Upload camera assets, instant upload

- (void) addAssetsToUpload:(PHFetchResult *) assetsToUpload andRemoteFolder:(NSString *) remoteFolder {
    
    self.nameRemoteInstantUploadFolder = remoteFolder;
    
    for (int i = 0 ; i < [assetsToUpload count] ; i++) {
        
        [self.listOfAssetsToUpload addObject:[assetsToUpload objectAtIndex:i]];
    }
    
    [self startWithTheNextAsset];
}

- (void) startWithTheNextAsset {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.pathRemoteInstantUpload = [[NSString alloc]initWithFormat:@"%@%@/",[UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser],[self nameRemoteInstantUploadFolder]];
    DLog(@"remoteFolderInstantUpload: %@", self.pathRemoteInstantUpload);
    
    BOOL isLastUploadFileOfThisArray = NO;
    
    if ([self.listOfAssetsToUpload count] == 1) {
        isLastUploadFileOfThisArray = YES;
    }
    
    PHAsset *assetToUpload = [self.listOfAssetsToUpload objectAtIndex:0];
    
    [self.listOfAssetsToUpload removeObjectAtIndex:0];
    
    [self uploadAssetFromGallery:assetToUpload andRemoteFolder:self.pathRemoteInstantUpload andCurrentUser:app.activeUser andIsLastFile:isLastUploadFileOfThisArray];
    
}

- (void) uploadAssetFromGallery:(PHAsset *) assetToUpload andRemoteFolder:(NSString *) remoteFolder andCurrentUser:(UserDto *) currentUser andIsLastFile:(BOOL) isLastUploadFileOfThisArray {
    DLog(@"uploadAssetFromGalleryToRemoteFolder");
    
    [[PHImageManager defaultManager] requestImageDataForAsset:assetToUpload options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        static NSDateFormatter *dateFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss.SSS"];
            dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        });
        
        NSURL *url = info[@"PHImageFileURLKey"];
        NSString *fileExtension = url.pathExtension;
        
        //Use a temporary name with a date identification
        NSString *temporaryFileName = [NSString stringWithFormat:@"IMG_%@.%@", [dateFormatter stringFromDate:[NSDate date]], fileExtension];
        NSString *localPath = [[UtilsUrls getTempFolderForUploadFiles] stringByAppendingPathComponent:temporaryFileName];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:localPath]) {
            [fileManager removeItemAtPath:localPath error:nil];
        }
        
        [fileManager createFileAtPath:localPath contents:imageData attributes:nil];
        
        UploadsOfflineDto *currentUpload = [[UploadsOfflineDto alloc] init];
        currentUpload.originPath = localPath;
        currentUpload.destinyFolder = remoteFolder;
        currentUpload.uploadFileName = temporaryFileName;
        currentUpload.estimateLength = imageData.length;;
        currentUpload.userId = currentUser.idUser;
        currentUpload.isLastUploadFileOfThisArray = isLastUploadFileOfThisArray;
        currentUpload.status = waitingAddToUploadList;
        currentUpload.chunksLength = k_lenght_chunk;
        currentUpload.uploadedDate = 0;
        currentUpload.kindOfError = notAnError;
        currentUpload.isInternalUpload = YES;
        currentUpload.taskIdentifier = 0;
        
        [self.listOfUploadOfflineToGenerateSQL addObject:currentUpload];
        
        if([self.listOfAssetsToUpload count] > 0) {
            //We have more files to process
            [self startWithTheNextAsset];
        } else {
            
            //We finish all the files of this block
            DLog(@"self.listOfUploadOfflineToGenerateSQL: %lu", (unsigned long)[self.listOfUploadOfflineToGenerateSQL count]);
            
            //In this point we have all the files to upload in the Array
            [ManageUploadsDB insertManyUploadsOffline:self.listOfUploadOfflineToGenerateSQL];
            
            //if is the last one we reset the array
            self.listOfUploadOfflineToGenerateSQL = nil;
            self.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
            
            self.positionOfCurrentUploadInArray = 0;
            
            [self performSelectorOnMainThread:@selector(endLoadingInFileList) withObject:nil waitUntilDone:YES];
            
            UploadsOfflineDto *currentFile = [ManageUploadsDB getNextUploadOfflineFileToUpload];
            
            //We begin with the first file of the array
            if (currentFile) {
                [self sendFileToUploadByUploadOfflineDto:currentFile];
            }
        }
        
    }];
}

/*
 * This method close the loading view in main screen by local notification
 */
- (void)endLoadingInFileList {
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    //Send notification to indicate to close the loading view
    [[NSNotificationCenter defaultCenter] postNotificationName:EndLoadingFileListNotification object: nil];
}

/*
 * This method close the loading view in main screen by local notification
 */
- (void)initLoadingInFileList {
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = YES;
    //Send notification to indicate to close the loading view
    [[NSNotificationCenter defaultCenter] postNotificationName:InitLoadingFileListNotification object: nil];
}

/*
 * This method close the loading view in main screen by local notification
 */
- (void)reloadFromDataBaseInFileList {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReloadFileListFromDataBaseNotification object: nil];
}


/*
 * Method to obtain the extension of the file in upper case
 */
- (NSString *)getExtension:(NSString*)string{

    NSArray *arr =[[NSArray alloc] initWithArray: [string componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&ext="]]];
    NSString *ext = [NSString stringWithFormat:@"%@",[arr lastObject]];
    ext = [ext uppercaseString];
    
    return ext;
}



#pragma mark - ManageUploadRequestDelegate

/*
 * Method that is called when the upload is completed, its posible that the file
 * is not upload.
 */

- (void)uploadCompleted:(NSString *) currentRemoteFolder {
    DLog(@"uploadCompleted");
    
    if (_delegate) {
        [_delegate refreshAfterUploadAllFiles:currentRemoteFolder];
    } else {
        DLog(@"_delegate is nil");
    }
    
    //Update the Recent Tab for update the number of error in the badge
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [app updateRecents];
}

- (void)uploadFailed:(NSString*)string{
    
    //Error msg
    //Call showAlertView in main thread
    [self performSelectorOnMainThread:@selector(showAlertView:)
                           withObject:string
                        waitUntilDone:YES];
}

- (void)uploadFailedForLoginError:(NSString*)string {
    
    //Cancel all uploads
    //  [self cancelAllUploads];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate updateRecents];
    if ([(NSObject*)self.delegate respondsToSelector:@selector(errorWhileUpload)]) {
        [_delegate errorWhileUpload];
    }
    
    [self performSelectorOnMainThread:@selector(showAlertView:) withObject:string waitUntilDone:YES];
    
}

- (void)uploadCanceled:(NSObject*)up{
    DLog(@"uploadCanceled");
}

//Control of the number of lost connecition to send only one message for the user
- (void)uploadLostConnectionWithServer:(NSString*)string{
    DLog(@"uploadLostConnectionWithServer:%@", string);
    
    //Error msg
    //Call showAlertView in main thread
  /*  [self performSelectorOnMainThread:@selector(showAlertView:)
                           withObject:string
                        waitUntilDone:YES];*/
}

/*
 * This method is for show alert view in main thread.
 */

- (void) showAlertView:(NSString*)string {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
}


/*
 * Method to continue with the next file of the list (or the first)
 */
- (void)uploadAddedContinueWithNext {
    
    UploadsOfflineDto *currentFile = [ManageUploadsDB getNextUploadOfflineFileToUpload];
    
    if (currentFile) {
        [self sendFileToUploadByUploadOfflineDto:currentFile];
    }

}

/*
* Method to be sure that the loading of the file list is finish
*/
- (void) overwriteCompleted{
    
    [self initLoadingInFileList];
    [self reloadFromDataBaseInFileList];
    [self endLoadingInFileList];
}

@end
