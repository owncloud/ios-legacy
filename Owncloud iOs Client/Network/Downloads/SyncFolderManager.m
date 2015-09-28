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
    
    FileDto *folder = [self.dictOfFilesAndFoldersToBeDownloaded objectForKey:idKey];
    
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *path = [UtilsUrls getFullRemoteServerFilePathByFile:folder andUser:app.activeUser];
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (!app.userSessionCurrentToken) {
        app.userSessionCurrentToken = [UtilsFramework getUserSessionToken];
    }
    
    [[AppDelegate sharedOCCommunication] readFolder:path withUserSessionToken:app.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            //TODO: cancel the complete list because we have a credential error in SAML
        }
        if (!isSamlCredentialsError && [app.userSessionCurrentToken isEqualToString:token]) {

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
            
            //[ManageFilesDB insertManyFiles:directoryList andFileId:_selectedFileDto.idFile];
            
            
            
            for (FileDto *current in directoryList) {
                
                if (current.isDirectory) {
                    //TODO:
                    //[self addFolderToBeDownloaded:current];
                } else {
                    //TODO: add the file to be downloaded
                }
            }
            [self.dictOfFilesAndFoldersToBeDownloaded removeObjectForKey:idKey];
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token) {
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        //TODO: continue with next one or cancel all if is a general error
    }];
    
}

@end
