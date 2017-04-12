//
//  SyncFolderManager.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 25/09/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "SyncFolderManager.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "Customization.h"
#import "UtilsUrls.h"
#import "UtilsFramework.h"
#import "UtilsDtos.h"
#import "FileNameUtils.h"
#import "OCErrorMsg.h"
#import "ManageFilesDB.h"
#import "FileListDBOperations.h"
#import "FolderSyncDto.h"
#import "FileDto.h"
#import "CWLOrderedDictionary.h"
#import "IndexedForest.h"
#import "DownloadFileSyncFolder.h"
#import "ManageUsersDB.h"
#import "InfoFileUtils.h"
#import "DownloadUtils.h"
#import "constants.h"
#import "InfoFileUtils.h"

static float const kDelayAfterCancelAll = 3.0;

@implementation SyncFolderManager

- (id) init{
    
    self = [super init];
    if (self) {
        self.dictOfFoldersToBeCheck = [CWLOrderedDictionary new];
        self.forestOfFilesAndFoldersToBeDownloaded = [IndexedForest new];
        self.listOfFilesToBeDownloaded = [[NSMutableArray alloc] init];
    }
    return self;
}

/*
 *  Method to keep the downloads while the app is in background and the user have the System PassCode
 */
- (void) setThePermissionsOnDownloadCacheFolder {
    
    //1. Create the full path structure
    NSString *cacheDirPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    cacheDirPath = [cacheDirPath stringByAppendingString:@"/com.apple.nsurlsessiond/Downloads/"];
    
    NSString *appInfoPlist = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc]initWithContentsOfFile:appInfoPlist];
    
    cacheDirPath = [cacheDirPath stringByAppendingPathComponent:dictionary[@"CFBundleIdentifier"]];
    
    DLog(@"Perssions cache: %@", cacheDirPath);
    
    //2. Check if the folder exist
    NSError *errorCreate = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/com.apple.nsurlsessiond"] withIntermediateDirectories:NO attributes:nil error:&errorCreate];
        [[NSFileManager defaultManager] createDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/com.apple.nsurlsessiond/Downloads"] withIntermediateDirectories:NO attributes:nil error:&errorCreate];
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirPath withIntermediateDirectories:NO attributes:nil error:&errorCreate];
    }
    
    if (errorCreate) {
        DLog(@"Error creating folder: %@", errorCreate);
    }
    
    //3. Give the permissions to the folder
    [DownloadUtils setThePermissionsForFolderPath:cacheDirPath];
    
    
}

- (void) addFolderToBeDownloaded: (FileDto *) folder {
    
    FolderSyncDto *folderSync = [FolderSyncDto new];
    folderSync.file = folder;
    folderSync.isReadFromDatabase = NO;

    NSString *key = [UtilsUrls getKeyByLocalFolder:folder.localFolder];
    [self.dictOfFoldersToBeCheck setObject:folderSync forKey:key];
    
    if (self.dictOfFoldersToBeCheck.count == 1) {
        //id currentKey = [[self.dictOfFoldersToBeCheck allKeys] objectAtIndex:0];
        [self continueWithNextFolder];
    }
}

#pragma mark - Search folders Process

- (void) continueWithNextFolder {
    
    if (self.dictOfFoldersToBeCheck.count > 0) {
        id currentKey = [[self.dictOfFoldersToBeCheck allKeys] objectAtIndex:0];
        [self performSelectorInBackground:@selector(checkFolderByIdKey:) withObject:currentKey];
    }

}

- (void) checkFolderByIdKey:(id) idKey {
    
    __block AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    UserDto *currentUser = [ManageUsersDB getActiveUser];
    
    FolderSyncDto *currentFolderSync = [self.dictOfFoldersToBeCheck objectForKey:idKey];
    
    FileDto *currentFolder = currentFolderSync.file;
    currentFolder = [ManageFilesDB getFileDtoByFileName:currentFolder.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFolder.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    NSMutableArray *filesFromCurrentFolder = [ManageFilesDB getFilesByFileId:currentFolder.idFile];

    
    if (currentFolderSync.isReadFromDatabase && filesFromCurrentFolder.count > 0) {
        
        [InfoFileUtils createAllFoldersInFileSystemByFileDto:currentFolder andUserDto:currentUser];
        
        for (FileDto *currentFile in filesFromCurrentFolder) {
            //Add the folder to the queue of sync and the file to the queue of downloads
            if (currentFile.fileName != nil) {
                
                if (currentFile.isDirectory) {
                    FolderSyncDto *folderSync = [FolderSyncDto new];
                    folderSync.file = currentFile;
                    folderSync.isReadFromDatabase = YES;
                    
                    NSString *key = [UtilsUrls getKeyByLocalFolder:folderSync.file.localFolder];
                    [self.dictOfFoldersToBeCheck setObject:folderSync forKey:key];
                    
                } else {
                    
                    if (currentFile.isDownload == notDownload || currentFile.isNecessaryUpdate) {
                        
                        [DownloadUtils setThePermissionsForFolderPath:currentFolder.localFolder];

                        //Add the file to the indexed forest of files downloading
                        //We check if the user is the same that when we started to check
                        if (currentUser.idUser == app.activeUser.idUser) {
                            [self.forestOfFilesAndFoldersToBeDownloaded addFileToTheForest:currentFile];
                            [self downloadTheFile:currentFile andNewEtag:currentFile .etag];
                        }
                        

                    }
                }
            } else {
                //Parent folder
            }
        }
        
        [self reloadCellAndRemovedFolderToBeCheckByKey:idKey];
        
        //Continue with the next
        
        if (filesFromCurrentFolder.count > 0) {
            [app reloadTableFromDataBaseIfFileIsVisibleOnList:[filesFromCurrentFolder objectAtIndex:0]];
        }
        
        [self continueWithNextFolder];
        
    } else {
        
        //Set the right credentials
        if (k_is_sso_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
        } else if (k_is_oauth_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
        } else {
            [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
        }
        
        [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
        
        NSString *path = [UtilsUrls getFullRemoteServerFilePathByFile:currentFolder andUser:app.activeUser];
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        DLog(@"PathRquest: %@", path);
        
        if (!app.userSessionCurrentToken) {
            app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
        }
        
        [[AppDelegate sharedOCCommunication] readFolder:path withUserSessionToken:app.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
            
            //We check before everything if the user is the same as before because could be any change of user
            if ([app.userSessionCurrentToken isEqualToString:token]) {
                DLog(@"Operation response code: %d", (int)response.statusCode);
                BOOL isSamlCredentialsError=NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                }
                
                if(response.statusCode != kOCErrorServerUnauthorized && !isSamlCredentialsError) {
                    
                    //We execute this in other thread because if not it froze the app
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        //Pass the items with OCFileDto to FileDto Array
                        NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                        
                        //Change the filePath from the library to our format
                        for (FileDto *currentFile in directoryList) {
                            //Remove part of the item file path
                            NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
                            if([currentFile.filePath length] >= [partToRemove length]){
                                currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
                            }
                        }
                        
                        for (int i = 0 ; i < directoryList.count ; i++) {
                            
                            FileDto *currentFile = [directoryList objectAtIndex:i];
                            
                            if (currentFile.fileName == nil) {
                                //This is the fileDto of the current father folder
                                currentFolder.etag = currentFile.etag;
                                
                                //We update the current folder with the new etag
                                [ManageFilesDB updateEtagOfFileDtoByid:currentFolder.idFile andNewEtag: currentFolder.etag];
                                
                                //break;
                            }
                        }
                        
                        [FileListDBOperations makeTheRefreshProcessWith:directoryList inThisFolder:currentFolder.idFile];
                        
                        //Send the data to DB and refresh the table
                        
                        [InfoFileUtils createAllFoldersInFileSystemByFileDto:currentFolder andUserDto:currentUser];
                        
                        NSMutableArray *tmpFilesAndFolderToSync = [ManageFilesDB getFilesByFileIdForActiveUser:currentFolder.idFile];
                        
                        NSInteger indexEtag = 0;
                        for (FileDto *currentFile in tmpFilesAndFolderToSync) {
                            indexEtag++;
                            //Add the folder to the queue of sync and the file to the queue of downloads
                            if (currentFile.fileName != nil) {
                                
                                if (currentFile.isDirectory) {
                                    FolderSyncDto *folderSync = [FolderSyncDto new];
                                    folderSync.file = currentFile;
                                    folderSync.isReadFromDatabase = NO;
                                    
                                    FileDto *fileRemote = [directoryList objectAtIndex:indexEtag];
                                    if ([fileRemote.etag isEqual:currentFile.etag]) {
                                        folderSync.isReadFromDatabase = YES;
                                    }
                                    
                                    NSString *key = [UtilsUrls getKeyByLocalFolder:folderSync.file.localFolder];
                                    [self.dictOfFoldersToBeCheck setObject:folderSync forKey:key];
                                    
                                } else {
                                    
                                    FolderSyncDto *currentFolderSync = [self.dictOfFoldersToBeCheck objectForKey:idKey];
                                    
                                    if ((currentFile.isDownload == notDownload || currentFile.isNecessaryUpdate) && currentFolderSync) {
                                        
                                        [DownloadUtils setThePermissionsForFolderPath:currentFolder.localFolder];
                                        
                                        //Add the file to the indexed forest of files downloading
                                        [self.forestOfFilesAndFoldersToBeDownloaded addFileToTheForest:currentFile];
                                        FileDto *fileRemote = [directoryList objectAtIndex:indexEtag];
                                        [self downloadTheFile:currentFile andNewEtag:fileRemote.etag];
                                    }
                                }
                                
                            } else {
                                //Parent folder
                            }
                        }
                        
                        [self reloadCellAndRemovedFolderToBeCheckByKey:idKey];
                        
                        //Continue with the next
                        if (tmpFilesAndFolderToSync.count > 0) {
                            [app reloadTableFromDataBaseIfFileIsVisibleOnList:[tmpFilesAndFolderToSync objectAtIndex:0]];
                        }
                        
                        [self continueWithNextFolder];
                        
                        
                    });
                } else {
                    //For sons of favorites to force again to be checked and downloaded again
                    if ([DownloadUtils isSonOfFavoriteFolder:currentFolder]) {
                        [DownloadUtils setEtagNegativeToAllTheFoldersThatContainsFile:currentFolder];
                    } else if (currentFolder.isFavorite) {
                        [ManageFilesDB updateEtagOfFileDtoByid:currentFolder.idFile andNewEtag:k_negative_etag];
                    }
                    
                    //Credential error//SAML expiration
                    [self reloadCellAndRemovedFolderToBeCheckByKey:idKey];
                }
            } else {
                DLog(@"User changed while check a folder");
                [UtilsFramework deleteAllCookies];
            }
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
            
            DLog(@"response: %@", response);
            DLog(@"error: %@", error);
            
            //Removed failed folder
            [self reloadCellAndRemovedFolderToBeCheckByKey:idKey];
            
            //For sons of favorites to force again to be checked and downloaded again
            if ([DownloadUtils isSonOfFavoriteFolder:currentFolder]) {
                [DownloadUtils setEtagNegativeToAllTheFoldersThatContainsFile:currentFolder];
            } else if(currentFolder.isFavorite) {
                [ManageFilesDB updateEtagOfFileDtoByid:currentFolder.idFile andNewEtag:k_negative_etag];
            }
        }];
    }
}

- (void) reloadCellAndRemovedFolderToBeCheckByKey:(NSString *)idKey {
    
    //Remove folder
    [self.dictOfFoldersToBeCheck removeObjectForKey:idKey];
    
    NSArray *listOfKeysSplited = [idKey componentsSeparatedByString:@"/"];
    NSString *completedKey = @"";
    
    for (NSString *current in listOfKeysSplited) {
        
        completedKey = [NSString stringWithFormat:@"%@%@/", completedKey, current];
        
        //Refresh cell to update the arrow
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [app reloadCellByKey:completedKey];
    }
}

#pragma mark - Download Process

- (void) downloadTheFile:(FileDto *) file andNewEtag:(NSString *) currentFileEtag {
    DownloadFileSyncFolder *download = [DownloadFileSyncFolder new];
    download.currentFileEtag = currentFileEtag;
    [download addFileToDownload:file];
    
    [self.listOfFilesToBeDownloaded addObject:download];
    
    if (k_is_sso_active || !k_is_background_active) {
        if (self.listOfFilesToBeDownloaded.count == 1) {
            [download.downloadTask resume];
        }
    }
}

- (void) simpleDownloadTheFile:(FileDto *) file andTask:(NSURLSessionDownloadTask *) task {
    DownloadFileSyncFolder *download = [DownloadFileSyncFolder new];
    download.currentFileEtag = nil;
    download.file = file;
    download.downloadTask = task;
    
    [self.forestOfFilesAndFoldersToBeDownloaded addFileToTheForest:file];
    [self.listOfFilesToBeDownloaded addObject:download];
}

- (void) cancelDownload: (FileDto *) file {
    for (DownloadFileSyncFolder *current in self.listOfFilesToBeDownloaded) {
        if ([current.file.localFolder isEqualToString:file.localFolder]) {
            [current cancelDownload];
            break;
        }
    }
}

- (void) cancelAllDownloads {
    
    //Stop the check progress
    self.dictOfFoldersToBeCheck = [CWLOrderedDictionary new];
    self.forestOfFilesAndFoldersToBeDownloaded = [IndexedForest new];
    
    NSArray *listOfFilesToBeDownloadedCopy = [[NSMutableArray alloc] initWithArray: self.listOfFilesToBeDownloaded];
    
    //We set the user before the loop to update the FildDto canceled with the right user
    UserDto *user = nil;
    
    for (DownloadFileSyncFolder *current in listOfFilesToBeDownloadedCopy) {
        
        if (!user) {
            user = [ManageUsersDB getUserByIdUser:current.file.userId];
        }
        
        current.user = user;
        [current cancelDownload];
    }
    
    DLog(@"All downloads have been canceled");
    
    if (self.delegate) {
        if (listOfFilesToBeDownloadedCopy.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(releaseSemaphoreToContinueChangingUser) withObject:nil afterDelay:kDelayAfterCancelAll];
            });
        } else {
            [self releaseSemaphoreToContinueChangingUser];
        }
    }
}

- (void) releaseSemaphoreToContinueChangingUser {
    [self.delegate releaseSemaphoreToContinueChangingUser];
}

#pragma mark - Cancel Download Folder

- (void) cancelDownloadsByFolder:(FileDto *) folder {
    
    //1. Remove the folders to be check
    [self removeFoldersPendingToBeCheck:folder];
    
    //2. Cancel the downloads folder by folder
    CWLOrderedDictionary *rootDictionary = [self.forestOfFilesAndFoldersToBeDownloaded getDictionaryOfTreebyKey:[UtilsUrls getKeyByLocalFolder:folder.localFolder]];
    [self cancelDownloadTaskByForestOfFilesAndFolders:rootDictionary];
    
}

- (void) removeFoldersPendingToBeCheck:(FileDto *) folder {
    
    CWLOrderedDictionary *dictOfFoldersToBeCheckCopy = self.dictOfFoldersToBeCheck.copy;
    NSString *key = [UtilsUrls getKeyByLocalFolder:folder.localFolder];
    
    for (NSString *currentKey in dictOfFoldersToBeCheckCopy) {
        if ([currentKey hasPrefix:key]) {
            [self.dictOfFoldersToBeCheck removeObjectForKey:currentKey];
        }
    }
    
}

- (void) cancelDownloadTaskByForestOfFilesAndFolders:(CWLOrderedDictionary *) forestOfFilesAndFolders {
    
    CWLOrderedDictionary *forestOfFilesAndFoldersCopy = forestOfFilesAndFolders.copy;
    
    for (NSString *currentKey in forestOfFilesAndFoldersCopy) {
        
        id current = [forestOfFilesAndFolders objectForKey:currentKey];
        
        if ([current isKindOfClass:[CWLOrderedDictionary class]]) {
            //It is a dictionary
            CWLOrderedDictionary *currentDict = current;
            [self cancelDownloadTaskByForestOfFilesAndFolders:currentDict];
        } else {
            //It is a file
            FileDto *currentFile = current;
            [self cancelDownload:currentFile];
        }
    }
}

@end
