//
//  SyncFolderManager.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 25/09/15.
//
//

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

@implementation SyncFolderManager

- (id) init{
    
    self = [super init];
    if (self) {
        self.dictOfFoldersToBeCheck = [CWLOrderedDictionary new];
        self.forestOfFilesAndFoldersToBeDownloaded = [IndexedForest new];
    }
    return self;
}

- (void) addFolderToBeDownloaded: (FileDto *) folder {
    
    FolderSyncDto *folderSync = [FolderSyncDto new];
    folderSync.file = folder;
    folderSync.isRead = NO;

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
        [self checkFolderByIdKey:currentKey];
    }

}

- (void) checkFolderByIdKey:(id) idKey {
    
    __block AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    FolderSyncDto *currentFolderSync = [self.dictOfFoldersToBeCheck objectForKey:idKey];
    
    FileDto *currentFolder = currentFolderSync.file;
    currentFolder = [ManageFilesDB getFileDtoByFileName:currentFolder.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFolder.filePath andUser:app.activeUser] andUser:app.activeUser];
    
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
        
        DLog(@"Operation response code: %d", (int)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
        }
        
        if(response.statusCode != kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            
            
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
                    
                }
            }
            
            [FileListDBOperations makeTheRefreshProcessWith:directoryList inThisFolder:currentFolder.idFile];
            
            //Send the data to DB and refresh the table
            [self deleteOldDataFromDBBeforeRefresh:directoryList ofFolder:currentFolder];
      
            NSMutableArray *tmpFilesAndFolderToSync = [ManageFilesDB getFilesByFileIdForActiveUser:currentFolder.idFile];
            
            for (FileDto *currentFile in tmpFilesAndFolderToSync) {
                //Add the folder to the queue of sync and the file to the queue of downloads
                if (currentFile.fileName != nil) {

                    if (currentFile.isDirectory) {
                        FolderSyncDto *folderSync = [FolderSyncDto new];
                        folderSync.file = currentFile;
                        folderSync.isRead = NO;
                        
                        DLog(@"folderSync 1: %@", folderSync.file.fileName);
                        DLog(@"folderSync 2: %@", folderSync.file.localFolder);
                        
                        NSString *key = [UtilsUrls getKeyByLocalFolder:folderSync.file.localFolder];
                        [self.dictOfFoldersToBeCheck setObject:folderSync forKey:key];
                    } else {
                        
                        if (currentFile.isDownload == notDownload || currentFile.isNecessaryUpdate) {
                            //Add the file to the indexed forest of files downloading
                            [self.forestOfFilesAndFoldersToBeDownloaded addFileToTheForest:currentFile];
                            [self downloadTheFile:currentFile];
                        }
                    }
                    
                } else {
                    //Parent folder
                }
            }
            
            //Continue with the next
            [self.dictOfFoldersToBeCheck removeObjectForKey:idKey];
            [self continueWithNextFolder];
            
        } else {
            //TODO: cancel all downloads because we have a credential error
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token) {
        
        DLog(@"response: %@", response);
        DLog(@"error: %@", error);
        
        //TODO: continue with next or remove all from the list if we can not manage the problem
    }];
}


/*
 * This method receive the new array of the server and store the changes
 * in the Database and in the tableview
 * @param requestArray -> NSArray of path items
 */
-(void)deleteOldDataFromDBBeforeRefresh:(NSArray *) requestArray ofFolder:(FileDto *) file {

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSMutableArray *directoryList = [NSMutableArray arrayWithArray:requestArray];
    
    //Change the filePath from the library to our format
    for (FileDto *currentFile in directoryList) {
        //Remove part of the item file path
        NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
        if([currentFile.filePath length] >= [partToRemove length]){
            currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
        }
    }
    
    NSArray *listOfRemoteFilesAndFolders = [ManageFilesDB getFilesByFileIdForActiveUser:(int) file.idFile];
    
    for (FileDto *current in listOfRemoteFilesAndFolders) {
        DLog(@"current: %@", current.fileName);
    }
    
    NSString *path = [UtilsUrls getLocalFolderByFilePath:file.filePath andFileName:file.fileName andUserDto:app.activeUser];
    
    [FileListDBOperations createAllFoldersByArrayOfFilesDto:listOfRemoteFilesAndFolders andLocalFolder:path];
}

#pragma mark - Download Process

- (void) downloadTheFile:(FileDto *) file {
    Download *download = nil;
    download = [[Download alloc]init];
    download.delegate = nil;
    
    NSString *currentLocalFolder = [file.localFolder substringToIndex:[file.localFolder length] - file.fileName.length];
    download.currentLocalFolder = currentLocalFolder;
    
    [download fileToDownload:file];
}

@end
