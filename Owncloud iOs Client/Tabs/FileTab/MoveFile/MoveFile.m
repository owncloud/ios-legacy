//
//  MoveFile.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/24/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "MoveFile.h"
#import "constants.h"
#import "UtilsDtos.h"
#import "AppDelegate.h"
#import "OverwriteFileOptions.h"
#import "Customization.h"
#import "OCErrorMsg.h"
#import "ManageFilesDB.h"
#import "FileNameUtils.h"
#import "OCCommunication.h"
#import "UtilsNetworkRequest.h"
#import "NSString+Encoding.h"
#import "UploadUtils.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "ManageThumbnails.h"


@implementation MoveFile

#pragma mark - Methods to check the paths

/*
 * 1st method to begin the move item
 * - Get Original Path of file and check if the file exist
 */

-(void) initMoveProcess {

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
    
    NSString *destinyPath = [_destinationFolder stringByAppendingString:_destinyFilename];
    NSString *originPath = [_selectedFileDto.filePath stringByAppendingString:_selectedFileDto.fileName];
    //Remove the first character / to not duplicate it on the stringByAppendingString
    originPath = [originPath substringFromIndex:1];
    originPath = [NSString stringWithFormat:@"%@/%@", [UtilsUrls getRemoteServerPathWithoutFolders:app.activeUser], originPath];
    
    DLog(@"destinyPath: %@", destinyPath);
    DLog(@"originPath: %@", originPath);
    
    
    if ([destinyPath isEqualToString:originPath]) {
        DLog(@"We have to move the folder to the same position so we do not do anything");
    } else {
        if ([(NSObject*)self.delegate respondsToSelector:@selector(initLoading)]) {
            [_delegate initLoading];
        }
    
        [self moveFile];
    }
}

-(void) moveFile {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!_utilsNetworkRequest) {
        _utilsNetworkRequest = [UtilsNetworkRequest new];
        _utilsNetworkRequest.delegate = self;
    }
    
    //Check the original item path
    [_utilsNetworkRequest checkIfTheFileExistsWithThisPath:[NSString stringWithFormat:@"%@%@",_destinationFolder,_destinyFilename] andUser:app.activeUser];
}

#pragma mark - UtilsNetworkRequestDelegate

/*
 * Method that receive of the server the check if the destination item exist or not
 * @isExist -> boolean value that indicate if the destination item exist in the server
 */
-(void) theFileIsInThePathResponse:(NSInteger) response {
    
    if(response == isInThePath) {
        
        [self endLoading];
        
        self.overWritteOption = [[OverwriteFileOptions alloc] init];
        self.overWritteOption.viewToShow = self.viewToShow;
        self.overWritteOption.delegate = self;
        self.overWritteOption.fileDto = self.selectedFileDto;
        [self.overWritteOption showOverWriteOptionActionSheet];
        
    } else {
        
        DLog(@"Before the move the item don't exist, all ok to move the item :)");
        [self moveItem];
    }
}

#pragma mark - OCWebDavMethods

/*
 * OCWebDav method that send the move item request to the server
 */
-(void)moveItem {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *originFile = [UtilsUrls getFullRemoteServerFilePathByFile:self.selectedFileDto andUser:app.activeUser];
    NSString *destinyFile = [NSString stringWithFormat:@"%@%@",self.destinationFolder, self.destinyFilename];
    
    //We remove the URL Encoding
    originFile = [originFile stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    destinyFile = [destinyFile stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
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
    
    [[AppDelegate sharedOCCommunication] moveFileOrFolder:originFile toDestiny:destinyFile onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        DLog(@"Great, the item is moved");
        
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
            
            //First at all we clean on the database a possible file or folder where we will put the moved one
            [self deleteDestinyFolderOnDatabaseAndFileSystem];
            
            if(self.selectedFileDto.isDirectory) {
                //Move the folder on the DB
                [self performSelector:@selector(moveTheFolderOnTheDB) withObject:nil afterDelay:0.5];
            } else {
                [self moveTheFileOnTheDB];
            }
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        [self endLoading];
        
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
            [_manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
  
    } errorBeforeRequest:^(NSError *error) {
        
        [self endLoading];
        
        if (error.code == OCErrorMovingTheDestinyAndOriginAreTheSame) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_folder_destiny_is_the_same", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        } else if (error.code == OCErrorMovingFolderInsideItself) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_folder_destiny_is_the_same", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        } else if (error.code == OCErrorMovingDestinyNameHaveForbiddenCharacters) {
            
            NSString *msg = nil;
            msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unknow_response_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

#pragma mark - Error Mesagges
/*
 * Method calle when there are a credential error with the connection server.
 */
-(void) errorLogin {
    [self endLoading];
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(errorLogin)]) {
        [self.delegate errorLogin];
    }
}


#pragma mark - Move the item on device

-(void) moveTheFileOnTheDB {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1. NewFilePath
    DLog(@"Destination path: %@", self.destinationFolder);
    NSString *newFilePath = [UtilsUrls getFilePathOnDBByFullPath:self.destinationFolder andUser:app.activeUser];
    DLog(@"FilePath: %@", newFilePath);
    
    //3.- NewFolderPath
    NSString *newFolderPath = [UtilsDtos getDbFolderPathFromFilePath:newFilePath];
    
    //4.- NewFolderName
    NSString *newFolderName = [UtilsDtos getDbFolderNameFromFilePath:newFilePath];
    
    
    // FileDto *destinationFolderFileDto = [ExecuteManager getFolderByFilePath:newFilePath andFileName:self.selectedFileDto.fileName];
    
    FileDto *destinationFolderFileDto = [ManageFilesDB getFolderByFilePath:newFolderPath andFileName:newFolderName];
    
    DLog(@"self.selectedFileDto.filePath: %@", self.selectedFileDto.filePath);
    
    self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    DLog(@"self.selectedFileDto.id: %ld", (long) self.selectedFileDto.idFile);
    DLog(@"self.selectedFileDto.localFolder: %@", self.selectedFileDto.localFolder);
    
    
    //update file_id (new parent folder) and file_path
    NSString *destinyFolder = [self getDestinyLocalFolder];
    
    //If the origin and the destiny is the same we do not do anything
    if(![destinyFolder isEqualToString:self.selectedFileDto.localFolder]) {
        //delete the old file because if it exist will be override
        [ManageFilesDB deleteFileByFilePath:newFilePath andFileName:self.destinyFilename];
        
        DLog(@"self.selectedFileDto.fileName: %@", self.destinyFilename);
        
        [ManageFilesDB updateFolderOfFileDtoByNewFilePath:newFilePath andDestinationFileDto:destinationFolderFileDto andNewFileName:self.destinyFilename andFileDto:self.selectedFileDto];
        
        //We move the file
        if(!self.selectedFileDto.isDirectory) {
            
            DLog(@"self.selectedFileDto.localFolder: %@", self.selectedFileDto.localFolder);
            [self moveFileOnTheFileSystemByOrigin:self.selectedFileDto.localFolder andDestiny:destinyFolder];
        }
    }
    [_delegate reloadTableFromDataBase];
    [self endLoading];
    [_delegate endMoveBackGroundTask];
    
}

- (void)deleteDestinyFolderOnDatabaseAndFileSystem {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Find the folder object with the same name
    //Need the path and de name
    NSString *newFilePath = [UtilsUrls getFilePathOnDBByFullPath:self.destinationFolder andUser:app.activeUser];
    FileDto *destinationFolderDto = [ManageFilesDB getFolderByFilePath:newFilePath andFileName:_destinyFilename];
    
    //Delete de folder with the same name in DB
    [self deleteFolderChildsWithIdFile:destinationFolderDto.idFile];
    
    //Delete from filesystem
    NSError *error;
    
    NSString *localFilePath = [UtilsUrls getLocalFolderByFilePath:[NSString stringWithFormat:@"%@%@", [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser], newFilePath] andFileName:_destinyFilename andUserDto:app.activeUser];
    
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    [fileMgr removeItemAtPath:localFilePath error:&error];
    
    if (error) {
        DLog(@"Error deleting on file system: %@", error);
    }
}

-(void) moveTheFolderOnTheDB {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1. NewFilePath
    DLog(@"Destination path: %@", self.destinationFolder);
    NSString *newFilePath = [UtilsUrls getFilePathOnDBByFullPath:self.destinationFolder andUser:app.activeUser];
    DLog(@"FolderPath: %@", newFilePath);
    
    
    //Root folder
    NSString *rootFilePath = @"";
    
    if([newFilePath isEqualToString:rootFilePath]) {
        //The destiny is the root folder
        
        DLog(@"MOVING THE FILE TO THE ROOT");
        DLog(@"Old path: %@", self.selectedFileDto.filePath);
        DLog(@"New path: %@", rootFilePath);
        DLog(@"File for where id: %ld", (long)self.selectedFileDto.idFile);
        
        
        [ManageFilesDB updatePath:self.selectedFileDto.filePath withNew:rootFilePath andFileId:[ManageFilesDB getRootFileDtoByUser:app.activeUser].idFile andSelectedFileId:self.selectedFileDto.idFile andChangedFileName:_destinyFilename];
        
        // [ManageFilesDB updatePath:self.selectedFileDto.filePath withNew:rootFilePath andFileId:[ManageFilesDB getRootFileDtoByUser:app.activeUser].idFile andSelectedFileId:self.selectedFileDto.idFile];
        
        
    } else {
        
        //0.- Look for the id of destination path
        // if the newpath is: "dd/cc/ff/"
        // destination folder path is: "dd/cc/"
        // destination folder name is: "ff/"
        
        
        //Divide the newpath by the "/"
        NSArray *selectedFolderPathSplitted = [newFilePath componentsSeparatedByString:@"/"];
        
        
        NSString *destinationFolderPath = @"";
        NSString *destinationFolderName = @"";
        
        for (NSInteger i = ([selectedFolderPathSplitted count] -1) ; i < [selectedFolderPathSplitted count]; i++) {
            
            destinationFolderName = [NSString stringWithFormat:@"%@/",[selectedFolderPathSplitted objectAtIndex:(i-1)]];
        }
        
        DLog(@"newFilePath length: %lu",(unsigned long)[newFilePath length]);
        DLog(@"foldername length: %lu",(unsigned long)[destinationFolderName length]);
        
        if ([newFilePath length]==[destinationFolderName length]) {
            //The path is in the root
            destinationFolderPath = @"";
        }else{
            destinationFolderPath = [NSString stringWithFormat:@"%@/",[newFilePath substringToIndex:[newFilePath length] - ([destinationFolderName length]+1)]];
        }
        
        
        DLog(@"Destination Folder Path: %@", destinationFolderPath);
        DLog(@"Destination Folder Name: %@", destinationFolderName);
        
        
        FileDto *destinationFolderDto = [ManageFilesDB getFolderByFilePath:destinationFolderPath andFileName:destinationFolderName];
        self.selectedFileDto = [ManageFilesDB getFileDtoByFileName:self.selectedFileDto.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        DLog(@"MOVING THE FOLDER TO OTHER FOLDER");
        DLog(@"Old path: %@", self.selectedFileDto.filePath);
        DLog(@"New path: %@", newFilePath);
        DLog(@"New file_id: %ld", (long)destinationFolderDto.idFile);
        DLog(@"File for where id: %ld", (long)self.selectedFileDto.idFile);
        
        [ManageFilesDB updatePath:self.selectedFileDto.filePath withNew:newFilePath andFileId:destinationFolderDto.idFile andSelectedFileId:self.selectedFileDto.idFile andChangedFileName:_destinyFilename];
    }
    
    [self performSelector:@selector(moveSubFilesAndSubFoldersBy:) withObject:newFilePath afterDelay:1.0];
    
}

- (void) moveSubFilesAndSubFoldersBy:(NSString *) newFilePath {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *oldFilePathWithServerPath = [NSString stringWithFormat:@"%@%@",self.selectedFileDto.filePath,self.selectedFileDto.fileName];
    
    //0.- OldFilePath
    DLog(@"OldFilePathWithServerPath: %@", oldFilePathWithServerPath);
    NSString *oldFilePath= [UtilsUrls getFilePathOnDBByFilePathOnFileDto:oldFilePathWithServerPath andUser:app.activeUser];
    DLog(@"OldFilePath: %@", oldFilePath);
    
    //1.- NewFolderPath
    NSString *filePathToSelect = newFilePath;
    DLog(@"FilePathToSelect: %@", filePathToSelect);
    
    //2.- FolderName
    NSString *newFolderName = _destinyFilename;
    DLog(@"NewFolderName: %@", newFolderName);
    
    //3.- NewSubFolderPath
    NSString *subFolderPath = [NSString stringWithFormat:@"%@%@", filePathToSelect,newFolderName];
    DLog(@"SubFolderPath: %@", subFolderPath);
    
    NSArray *listOfFoldersToUpdate = [ManageFilesDB getAllFoldersByBeginFilePath:oldFilePath];
    DLog(@"listOfFoldersToUpdate: %lu", (unsigned long)[listOfFoldersToUpdate count]);
    
    
    FileDto *folder;
    
    for (int i = 0 ; i < [listOfFoldersToUpdate count] ; i++) {
        
        folder=[listOfFoldersToUpdate objectAtIndex:i];
        
        NSString *newCurrentFilePath = [folder.filePath substringFromIndex:[oldFilePath length]];
        DLog(@"newCurrentFilePath: %@", newCurrentFilePath);
        
        NSString *newFolderTotalPath = [NSString stringWithFormat:@"%@%@", subFolderPath, newCurrentFilePath];
        
        DLog(@"Old Folder Path: %@", folder.filePath);
        DLog(@"New Folder Path: %@", newFolderTotalPath);
        
        [ManageFilesDB updatePathwithNewPath:newFolderTotalPath andFileDto:folder];
    }
    
    //update file_id (new parent folder) and file_path
    NSString *destinyFolder = [self getDestinyLocalFolder];
    
    //We move the folder
    [self moveFileOnTheFileSystemByOrigin:self.selectedFileDto.localFolder andDestiny:destinyFolder];
    
    [_delegate reloadTableFromDataBase];
    [self endLoading];
    [_delegate endMoveBackGroundTask];
    
}

- (NSString *)getDestinyLocalFolder {
    
    //Delete files os user in the system
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //NSString *newLocalFolder= [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", currentUser.idUser]];
    NSString *newLocalFolder= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)app.activeUser.idUser]];
    
    NSString *newStr = [UtilsUrls getFilePathOnDBByFullPath:self.destinationFolder andUser:app.activeUser];
    newLocalFolder = [NSString stringWithFormat:@"%@/%@%@", newLocalFolder,[newStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[_destinyFilename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return newLocalFolder;
}

-(void) moveFileOnTheFileSystemByOrigin:(NSString *) origin andDestiny:(NSString *) destiny {
    
    DLog(@"origin: %@",origin);
    DLog(@"destiny: %@", destiny);
        
    NSFileManager *filemgr;
    
    filemgr = [NSFileManager defaultManager];
    
    [filemgr removeItemAtPath:destiny error:nil];
    
    NSError *error;
    
    // Attempt the move
    if ([filemgr moveItemAtPath:origin toPath:destiny error:&error] != YES) {
        DLog(@"Unable to move file: %@", [error localizedDescription]);
    }

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
            }else{
                //Si es un directorio borrar los items que contiene
                [self deleteFolderChildsWithIdFile:oneFile.idFile];
            }
            
        }
        
    }
    //Finally we delete this folder of DB
    [ManageFilesDB deleteFileByIdFileOfActiveUser:idFile];
}

#pragma mark - OverwriteFileOptionsDelegate

- (void) setNewNameToSaveFile:(NSString *)name {
    DLog(@"setNewNameToSaveFile: %@", name);
    
    _destinyFilename = [name encodeString:NSUTF8StringEncoding];
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(initLoading)]) {
        [_delegate initLoading];
    }
    
    [self performSelector:@selector(moveFile) withObject:nil afterDelay:0.5];
}

- (void) overWriteFile {
    
    DLog(@"overWriteFile");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //A overwrite process is in progress
    app.isOverwriteProcess = YES;
    
    //Obtain the file that the user wants overwrite
    FileDto *file = nil;
    
    NSString *newFilePath = [UtilsUrls getFilePathOnDBByFullPath:self.destinationFolder andUser:app.activeUser];
    
    file = [ManageFilesDB getFileDtoByFileName:_destinyFilename andFilePath:newFilePath andUser:app.activeUser];
    
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
        [UploadUtils updateOverwritenFile:file FromPath:file.localFolder];
    }
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(initLoading)]) {
        [_delegate initLoading];
    }
    
    [self performSelector:@selector(moveItem) withObject:nil afterDelay:0.5];
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
- (void) endLoading {
    
    if (IS_IPHONE) {
        if ([(NSObject*)_delegate respondsToSelector:@selector(endLoading)]) {
            [_delegate endLoading];
        }
    } else {
        [self performSelectorOnMainThread:@selector(endLoadingInOtherThread) withObject:nil waitUntilDone:YES];
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

@end
