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

@implementation SyncFolderManager

- (id) init{
    
    self = [super init];
    if (self) {
        self.dictOfFilesAndFoldersToBeDownloaded = [NSMutableDictionary new];
    }
    return self;
}

- (void) addFolderToBeDownloaded: (FileDto *) folder {

    [self.dictOfFilesAndFoldersToBeDownloaded setObject:folder forKey:folder.localFolder];
    
    if (self.dictOfFilesAndFoldersToBeDownloaded.count == 1) {
        //id currentKey = [[self.dictOfFilesAndFoldersToBeDownloaded allKeys] objectAtIndex:0];
        [self checkFolderByIdKey:folder.localFolder];
    }
}

- (void) continueWithNextFolder {
    
    id currentKey = [[self.dictOfFilesAndFoldersToBeDownloaded allKeys] objectAtIndex:0];
    [self checkFolderByIdKey:currentKey];
}

- (void) checkFolderByIdKey:(id) idKey {
    
    __block AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    FileDto *currentFolder = [self.dictOfFilesAndFoldersToBeDownloaded objectForKey:idKey];
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
            if (isSamlCredentialsError) {
                //TODO: cancel all download if we can not continue
            }
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
            
            /*if (isNecessaryNavigate) {
                
                [self endLoading];
                
                [self navigateToFile:file];
            } else {
                
                [self fillTheArraysFromDatabase];
                [self.tableView reloadData];
                
                [self stopPullRefresh];
                [self endLoading];
            }
            
            self.isRefreshInProgress = NO;*/
        } else {
            //[self endLoading];
            //[self stopPullRefresh];
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


@end
