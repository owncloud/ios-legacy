//
//  DeleteFile.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/17/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "DeleteFile.h"
#import "FileDto.h"
#import "UserDto.h"
#import "AppDelegate.h"
#import "UtilsDtos.h"
#import "Customization.h"
#import "ManageFilesDB.h"
#import "FileListDBOperations.h"
#import "FileNameUtils.h"
#import "DetailViewController.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "UtilsUrls.h"
#import "ManageThumbnails.h"
#import "ManageUsersDB.h"


@implementation DeleteFile

- (void)initialize
{
    _deleteFromFilePreview=NO;
}

- (void)askToDeleteFileByFileDto: (FileDto *) file {
    
    _file = file;
    _isFilesDownloadedInFolder = NO;
    
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
    
    //If the device is an iPhone and its orientation is landscape
    if ((IS_IPHONE) &&
        (!IS_PORTRAIT)) {
        DLog(@"iPhone in landscape");
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:NSLocalizedString(@"not_show_potrait", nil)
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alertView show];
    } else {
        //If the file is a directory, checks if contains downloaded files
        if (_file.isDirectory) {
            DLog(@"Delete a folder");
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            //Remove: /owncloud/remote.php/webdav/ to the pathFolder
            NSString *pathFolder = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser];
            //Obtains the number of the downloaded files in DB which filepath contains the folder that the user want delete
            _isFilesDownloadedInFolder=[ManageFilesDB isGetFilesByDownloadState:downloaded andByUser:app.activeUser andFolder:pathFolder];
        }
        if((_file.isDownload || _isFilesDownloadedInFolder == YES) && (!_file.isFavorite && ![[AppDelegate sharedManageFavorites] isInsideAFavoriteFolderThisFile:self.file])) {
            DLog(@"Delete downloaded files or folder with downloaded files");
            
            if (self.popupQuery) {
                self.popupQuery = nil;
            }
            
            self.popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:NSLocalizedString(@"delete_local_server", nil) otherButtonTitles:NSLocalizedString(@"delete_local", nil), nil];
        } else {
            
            if (self.popupQuery) {
                self.popupQuery = nil;
            }
            DLog(@"Delete files or folder from server");
            self.popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:NSLocalizedString(@"delete_server", nil) otherButtonTitles:nil];
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            [self.popupQuery showInView:_viewToShow];
        } else {
            [self.popupQuery showInView:[_viewToShow window]];
        }
    }
}


/*
 * This method close the loading view in main screen by local notification
 */
- (void)endLoadingInOtherThread {
    
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    //Send notification to indicate to close the loading view
    [[NSNotificationCenter defaultCenter] postNotificationName:EndLoadingFileListNotification object: nil];
    
}

/*
 * Show the standar message of the error connection.
 *
 */
- (void)showError:(NSString *) message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self endLoading];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    });
}


#pragma mark - Delete Folder

/*
 * Recursive method that delete a directory and its file of DB
 */
- (void)deleteFolderChildsWithIdFile:(NSInteger)idFile{
    
    //Rename local url and server url of files
    NSArray *files = [ManageFilesDB getFilesByFileIdForActiveUser:idFile];
    
    if ([files count]>0) {
        FileDto *oneFile;
        
        for (int i=0;i<[files count]; i++) {
            oneFile=[files objectAtIndex:i];
            if (oneFile.isDirectory==NO) {
                //Delete file of DB
                [ManageFilesDB deleteFileByIdFileOfActiveUser:oneFile.idFile];
            } else {
                //If is a folder delete items inside
                [self deleteFolderChildsWithIdFile:oneFile.idFile];
            }
        }
    }
    //Finally we delete this folder of DB
    [ManageFilesDB deleteFileByIdFileOfActiveUser:idFile];
}

/*
 *Deletes items in the server
 */
- (void)executeDeleteItemInServer{
    [self deleteItemFromDeviceByFileDto:self.file];
    [self deleteItemFromServerAndDeviceByFileDto:self.file];
}

/*
 *Deletes items in the device
 */
- (void)executeDeleteItemInDevice{
    [self deleteItemFromDeviceByFileDto:_file];
    
    if (_isFilesDownloadedInFolder == YES) {
        //If the item deleted is a directory update the is_download state to notDownload in the files contains in the folder for deleted
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        NSString *pathFolder = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser];
        pathFolder = [pathFolder stringByAppendingString:_file.fileName];
        
        [ManageFilesDB updateFilesByUser:app.activeUser andFolder:pathFolder toDownloadState:notDownload andIsNecessaryUpdate:NO];
        
        //Create the folder again for a correct navigation
        //We obtain the name of the folder in folderName
        pathFolder = [NSString stringWithFormat:@"%@%@",_file.filePath,_file.fileName];
        DLog(@"path: %@",pathFolder);
        
        NSString *folderName = [UtilsDtos getDbFolderNameFromFilePath:pathFolder];
        DLog(@"folder name: %@ in this location: %@",folderName,_currentLocalFolder);
        [FileListDBOperations createAFolder:folderName inLocalFolder:_currentLocalFolder];
        
    }
}


///-----------------------------------
/// @name Delete item from device
///-----------------------------------

/**
 * This method delete a file from the device
 *
 * @param file -> FileDto with the file that the user want to delete
 *
 */
- (void) deleteItemFromDeviceByFileDto:(FileDto *) file {
    DLog(@"File from server and device");
    NSError *error;
    
    // Create file manager
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    DLog(@"FileName: %@", file.fileName);
    DLog(@"Delete: %@", file.localFolder);
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    DLog(@"FilePath: %@", file.filePath);
    
    // Attempt to delete the file at filePath2
    if ([fileMgr removeItemAtPath:file.localFolder error:&error] != YES) {
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
        [ManageFilesDB setFile:file.idFile isNecessaryUpdate:NO];
        if (_deleteFromFilePreview == YES && _deleteFromFlag == deleteFromServerAndLocal) {
            
        } else {
            [_delegate removeSelectedIndexPath];
            [_delegate reloadTableFromDataBase];
        }
        
    } else {
        
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:notDownload];
        [ManageFilesDB setFile:file.idFile isNecessaryUpdate:NO];
        if (_deleteFromFilePreview == YES && _deleteFromFlag == deleteFromServerAndLocal) {
            
        } else {
            [_delegate removeSelectedIndexPath];
            [_delegate reloadTableFromDataBase];
        }
    }
    
    //Quit movie player if the delete file is running.
    [self quitMoviePlayerIsDeleteFileIsRunning];
    
    //Remove iPad preview if is the same file
    [self removePreviewOniPadIfIsTheSameFile];
}



///-----------------------------------
/// @name Delete a file or a folder from the device and server
///-----------------------------------

/**
 * This method delete a file or a folder in the server and in the device.
 * Remote delete using webdav
 * Local delete in the file system
 * Local delete references in dataBase
 *
 * @param file -> FileDto to delete
 *
 */
- (void) deleteItemFromServerAndDeviceByFileDto:(FileDto *) file {
    
    DLog(@"Delete item from devices and server");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    NSString *pathToDelete = [UtilsUrls getFullRemoteServerFilePathByFile:file andUser:app.activeUser];
    pathToDelete = [pathToDelete stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    DLog(@"Path for delete: %@", pathToDelete);
    
    //Init loading
    if ([(NSObject*)_delegate respondsToSelector:@selector(initLoading)]) {
        [_delegate initLoading];
    }
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] deleteFileOrFolder:pathToDelete onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer){
        
        DLog(@"Great, the item is deleted");
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        //If it is not SAML
        if (!isSamlCredentialsError) {
            
            if([_file isDirectory]) {
                DLog(@"Is directory");
                
                [[ManageThumbnails sharedManager] deleteThumbnailsInFolder:_file.idFile];
                
                //Then delete folder of BD.
                [self deleteFolderChildsWithIdFile:_file.idFile];
                
            } else {
                //if a file
                
                [[ManageThumbnails sharedManager] removeStoredThumbnailForFile:_file];

                [ManageFilesDB deleteFileByIdFileOfActiveUser:_file.idFile];
            }
            //The end of delete
            [self endLoading];
            
            if ([(NSObject*)_delegate respondsToSelector:@selector(reloadTableFromDataBase)]) {
                [_delegate reloadTableFromDataBase];
            }
            //Quit movie player if the delete file is running.
            [self quitMoviePlayerIsDeleteFileIsRunning];
        }
        
    } failureRquest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        DLog(@"error: %@ with code: %ld", error, (long)error.code);
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        //If it is not SAML
        if (!isSamlCredentialsError) {

            [self endLoading];
            
            [_manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
            
        }
        
    }];
}

///-----------------------------------
/// @name Remove iPad Preview
///-----------------------------------

/**
 * Method that compare the iPad preview with the delete file
 * and remove the iPad preview in case that the file is the same
 *
 */
- (void)removePreviewOniPadIfIsTheSameFile{
    
    if (!IS_IPHONE) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        if (_isFilesDownloadedInFolder) {
            
            //Obtains the complete path of the folder
            NSString *pathFolder = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser];
            //Check if the id file is in the files into this folder
            DLog(@"path folder: %@", pathFolder);
            
            if ([ManageFilesDB isThisFile:app.detailViewController.file.idFile ofThisUserId:app.activeUser.idUser intoThisFolder:pathFolder]) {
                [app.detailViewController unselectCurrentFile];
            }
        }
        if ([app.detailViewController.file.localFolder isEqualToString: _file.localFolder]) {
            //its the same
            [app.detailViewController unselectCurrentFile];
        }
    }
}


- (NSString *)filePath {
    NSString *localUrl = [NSString stringWithFormat:@"%@%@", _currentLocalFolder, _file.fileName];
    DLog(@"Current Local Folder: %@", _currentLocalFolder);
    DLog(@"File Name: %@", _file.fileName);
    DLog(@"Local URL: %@", localUrl);
    return localUrl;
}

#pragma mark - View lifecycle
- (BOOL)testErrorAction:(id)sender {
    return YES;
}

#pragma mark CheckAcessToServer
- (void) isConnectedToServer:(BOOL)isConnected{
    if (isConnected == YES) {
        [self performSelector:@selector(executeDeleteItemInServer) withObject:nil afterDelay:0.1];
    } else {
        
    }
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ((_file.isDownload || _isFilesDownloadedInFolder == YES) && (!_file.isFavorite && ![[AppDelegate sharedManageFavorites] isInsideAFavoriteFolderThisFile:self.file])) {
        switch (buttonIndex) {
            case 0:
                DLog(@"Delete from server");
                _deleteFromFlag = deleteFromServerAndLocal;
                [self executeDeleteItemInServer];
                break;
            case 1:
                DLog(@"Delete from local");
                _deleteFromFlag = deleteFromLocal;
                [self executeDeleteItemInDevice];
                break;
            case 2:
                DLog(@"Cancel");
                break;
        }
    } else {
        switch (buttonIndex) {
            case 0:
                DLog(@"Delete from server");
                _deleteFromFlag = deleteFromServerAndLocal;
                [self executeDeleteItemInServer];
                break;
            case 1:
                DLog(@"Cancel");
                break;
        }
    }
}

#pragma mark - Movie Player delete
/*
 * Check if the delete file is running at the movie player
 * and quit movie player in that case
 */
- (void)quitMoviePlayerIsDeleteFileIsRunning{    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    if ([app isMediaPlayerRunningWithThisFilePath:_file.localFolder]) {
        [app quitMediaPlayer];
    }
}

#pragma mark - Error login
///-----------------------------------
/// @name Error Login
///-----------------------------------

/**
 * Method called when a request gets a Credential error.
 * In this method close the loading screen
 * and call the error login method of the delegate class
 *
 */
-(void) errorLogin {
    [self endLoading];
    [_delegate errorLogin];
}


#pragma mark - Loading
///-----------------------------------
/// @name End Loading
///-----------------------------------

/**
 * Method that remove the loading icon in parent view
 * in Case on iPhone by delegate
 * and in case of iPad by notification
 */
- (void)endLoading {
    
    if ([(NSObject*)_delegate respondsToSelector:@selector(endLoading)]) {
        [_delegate endLoading];
    }
    [self performSelectorOnMainThread:@selector(endLoadingInOtherThread) withObject:nil waitUntilDone:YES];
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = NO;
    }
}


@end
