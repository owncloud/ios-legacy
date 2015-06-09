//
//  ManageFavorites.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/04/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ManageFavorites.h"
#import "ManageFilesDB.h"
#import "OCCommunication.h"
#import "AppDelegate.h"
#import "FileDto.h"
#import "UserDto.h"
#import "ManageUsersDB.h"
#import "UtilsDtos.h"
#import "constants.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "OCErrorMsg.h"
#import "UtilsUrls.h"

NSString *FavoriteFileIsSync = @"FavoriteFileIsSync";

@implementation ManageFavorites


//Overwrite the init method
-(id) init {
    
    self = [super init];
    
    if (self) {
        
        //Init Favorites Array
        _favoritesSyncing = [NSMutableArray new];
    }
    
    return self;
}


///-----------------------------------
/// @name isOnAnUpdatingProcessThisFavoriteFile
///-----------------------------------

/**
 * This method checks if the file is currently on an updating process. It is check by fileName, filePath and userId
 *
 * @param favoriteFile > FileDto. The file which is going to be checked
 */
- (BOOL) isOnAnUpdatingProcessThisFavoriteFile:(FileDto *)favoriteFile {

    //Create a copy of the favorite array
    __block NSArray *favoriteArray = [NSArray arrayWithArray:_favoritesSyncing];
    
    //Variable to use the current favoriteUpdatingFile on the favoriteArray
    __block FileDto *favoriteUpdatingFile = nil;
    
    __block BOOL isInside = NO;
    
    //Make a loop for all the objects in favoriteArray
    [favoriteArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        favoriteUpdatingFile = (FileDto*) obj;
        
        if ([favoriteFile.fileName isEqualToString:favoriteUpdatingFile.fileName] && [favoriteFile.filePath isEqualToString:favoriteUpdatingFile.filePath] && (favoriteFile.userId == favoriteUpdatingFile.userId)) {
            *stop = YES;
            isInside = YES;;
        }
    }];
    
    favoriteArray = nil;
    return isInside;
}


///-----------------------------------
/// @name Sync All Favorites of User
///-----------------------------------

/**
 * Method that begin a process to update all favorites files of a specific user
 *
 * 1.- Get all favorites of a specific user
 *
 * 2.- Send the list to a specific method to update the favorites
 *
 * @param NSInteger -> userId
 *
 */

- (void) syncAllFavoritesOfUser:(NSInteger)userId{
   
    NSArray *dataBaseFavorites = [ManageFilesDB getAllFavoritesOfUserId:userId];
    
    [self syncFavoritesOfList:dataBaseFavorites ofThisUser:userId];
    
}


///-----------------------------------
/// @name Sync Favorites of Folder with User
///-----------------------------------

/**
 * Method that begin a process to sync favorites of a specific path and user
 *
 * @param idFolder -> NSInteger
 * @param userId -> NSInteger
 *
 */
- (void) syncFavoritesOfFolder:(NSInteger)idFolder withUser:(NSInteger)userId{
    
    NSArray *dataBaseFavorites = [ManageFilesDB getAllFavoritesOfUserId:userId];
    NSMutableArray *tempArray = [NSMutableArray new];
    
    for (FileDto *file in dataBaseFavorites) {
        
        if (file.fileId == idFolder) {
            [tempArray addObject:file];
        }
    }
    
    //If there are favorites the path, sync
    if (tempArray.count >= 1) {
        NSArray *favorites = [NSArray arrayWithArray:tempArray];
        [self syncFavoritesOfList:favorites ofThisUser:userId];
    }
    
    //Free memory
    tempArray = nil;
    
}

///-----------------------------------
/// @name Sync Favorites Of This List
///-----------------------------------

/**
 * This method manage a list of favorites in order to
 * check each file and download if is necessary.
 *
 */
- (void) syncFavoritesOfList:(NSArray*)favoritesFiles ofThisUser:(NSInteger)userId{
    
    UserDto *user = [ManageUsersDB getUserByIdUser:userId];
    
    //Loop for favorites
    for (FileDto *file in favoritesFiles) {
        
        //FileName full path
        NSString *serverPath = [UtilsUrls getFullRemoteServerPathWithWebDav:user];
        NSString *path = [NSString stringWithFormat:@"%@%@%@",serverPath, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:user], file.fileName];
        
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //Check if the file is including in the sync files
        if (![self isOnAnUpdatingProcessThisFavoriteFile:file]) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            //Check if is necessary update each favorite
            [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
                
                DLog(@"Operation response: %ld", (long)response.statusCode);
                
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active && redirectedServer) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                    if (isSamlCredentialsError) {
                        //SamlCredentialsError
                    }
                }
                
                if(response.statusCode < kOCErrorServerUnauthorized && !isSamlCredentialsError) {
                    //Pass the items with OCFileDto to FileDto Array
                    NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                    
                    if (directoryList.count > 0) {
                        
                        FileDto *item = [directoryList objectAtIndex:0];
                        
                        //Update the file data
                        FileDto *updatedFile = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:user] andUser:user];
                        
                        //Check if the etag has changed
                        if (((![item.etag isEqual: updatedFile.etag] && updatedFile.isDownload != downloading && updatedFile.isDownload != updating) || (updatedFile.isDownload == notDownload)) && updatedFile) {
                            
                            //Update the info of the file
                            if (updatedFile.isDownload == downloaded) {
                                updatedFile.isNecessaryUpdate = YES;
                                [ManageFilesDB setFile:updatedFile.idFile isNecessaryUpdate:YES];
                            }
                            
                            //Send notification in order to update the file list
                            [[NSNotificationCenter defaultCenter] postNotificationName:FavoriteFileIsSync object:updatedFile];
                            
                            //Control this files in array
                            [_favoritesSyncing addObject:updatedFile];
                            
                            
                            //Data to download
                            //Get the current local folder
                            AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                            NSString *currentLocalFolder = [NSString stringWithFormat:@"%@%ld/%@", [UtilsUrls getOwnCloudFilePath],(long)user.idUser, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:updatedFile.filePath andUser:user]];
                            currentLocalFolder = [currentLocalFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                            
                            Download *download = [Download new];
                            download.delegate =self;
                            download.currentLocalFolder = currentLocalFolder;
                            //Set FIFO queue for favorites
                            download.isLIFO = NO;
                            [download fileToDownload:updatedFile];
                            
                            //Update iPad Detail View
                            if (!IS_IPHONE && [app.detailViewController.file.localFolder isEqualToString:updatedFile.localFolder]) {
                                [app.detailViewController handleFile:updatedFile fromController:app.detailViewController.controllerManager];
                            }
                            
                        }
                    }
                    
                }
                
                
                dispatch_semaphore_signal(semaphore);
                
                
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                
                //Finish with this file
                DLog(@"error: %@", error);
                DLog(@"Operation error: %ld", (long)response.statusCode);
                
                dispatch_semaphore_signal(semaphore);
                
                
            }];
            
            // Run loop
            while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate distantFuture]];
        }
    }
        
}


///-----------------------------------
/// @name Remove of sync process file
///-----------------------------------

/**
 * Method that find the equal file stored in _favoritesSyncing and remove it
 *
 * @param file -> FileDto
 */
- (void) removeOfSyncProcessFile:(FileDto*)file{
    
    FileDto *fileDto = [self getFileEqualTo:file];
    
    [_favoritesSyncing removeObjectIdenticalTo:fileDto];
    
    
}

#pragma mark - Utils

///-----------------------------------
/// @name Get File Equal to File
///-----------------------------------

/**
 * This method seek the file in favorites
 *
 * @param FileDto -> file
 *
 *
 * @return FileDto
 *
 */
- (FileDto *)getFileEqualTo:(FileDto*)file{
    
    __block FileDto *temp = nil;
    
    [_favoritesSyncing enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        temp = (FileDto*)obj;
        
        if ([file.localFolder isEqualToString:temp.localFolder]) {
            *stop = YES;
        }
    }];
    
    return temp;
}


///-----------------------------------
/// @name thereIsANewVersionAvailableOfThisFile
///-----------------------------------

/**
 * This method check if there is a new version on the server for a concret file
 *
 * @param favoriteFile -> FileDto
 */
- (void) thereIsANewVersionAvailableOfThisFile: (FileDto *)favoriteFile {
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
    
    //FileName full path
    NSString *serverPath = [UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser];
    NSString *path = [NSString stringWithFormat:@"%@%@%@",serverPath, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:favoriteFile.filePath andUser:app.activeUser], favoriteFile.fileName];
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                DLog(@"error login updating the etag");
            }
        }
        if(response.statusCode < kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            
            //Change the filePath from the library to our format
            for (FileDto *currentFile in items) {
                //Remove part of the item file path
                NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:app.activeUser];
                if([currentFile.filePath length] >= [partToRemove length]){
                    currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
                }
            }
            
            DLog(@"The directory List have: %ld elements", (long)items.count);
            
            //Check if there are almost one item in the array
            if (items.count >= 1) {
                DLog(@"Directoy list: %@", items);
                FileDto *currentFileDto = [items objectAtIndex:0];
                DLog(@"currentFileDto: %@", currentFileDto.etag);
                if (![currentFileDto.etag isEqual: favoriteFile.etag]) {
                    [self.delegate fileHaveNewVersion:YES];
                } else {
                    [self.delegate fileHaveNewVersion:NO];
                }
            }
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        [self.delegate fileHaveNewVersion:NO];
    }];
}

#pragma mark - Download Delegate Methods


//Send the downloading percent of a specific file
- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    
    
}
//Send the downloading string of a specific file
- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
    
    
}
//Send the download is complete for a specific file
- (void)downloadCompleted:(FileDto*)fileDto{
    
    //Remove the file of the sync process
    [self removeOfSyncProcessFile:fileDto];
    
    //Send notification in order to update the file list
    [[NSNotificationCenter defaultCenter] postNotificationName:FavoriteFileIsSync object:fileDto];
    
    
}
//Send the download is failed for a specific file with a custom message
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    //Remove the file of the sync process
    [self removeOfSyncProcessFile:fileDto];

    
}
//Send the download is failed for a credentials error
- (void)errorLogin{
    
    
}
//Send question about the updated file after 0 bytes error
- (void)updateOrCancelTheDownload:(id)download{
    
    
}


@end
