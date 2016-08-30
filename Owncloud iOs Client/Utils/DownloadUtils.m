//
//  DownloadUtils.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 29/05/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DownloadUtils.h"
#import "UtilsUrls.h"
#import "ManageFilesDB.h"
#import "constants.h"

@implementation DownloadUtils

///-----------------------------------
/// @name thereAreDownloadingFilesOnTheFolder
///-----------------------------------

/**
 * This method checks if there are any files on a download process on the selected folder
 *
 * @return thereAreDownloadingFilesOnTheFolder -> BOOL, return YES if there is a file on a download process inside this folder
 */
+ (BOOL) thereAreDownloadingFilesOnTheFolder: (FileDto *) selectedFolder {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL thereAreDownloadingFilesOnTheFolder = NO;
    Download *downloadFile;
    
    //Create a copy of the downloadArray for avoid manage directly the downloadArray
    NSArray *downloadsArrayCopy = [NSArray arrayWithArray:[app.downloadManager getDownloads]];
    //On the downloadArrayCopy check if there are download files on the selected folder
    for (downloadFile in downloadsArrayCopy) {
        NSString *folderCompletePath = [NSString stringWithFormat:@"%@%@", selectedFolder.filePath,selectedFolder.fileName];
        if([downloadFile.fileDto.filePath rangeOfString:folderCompletePath].location != NSNotFound) {
            DLog(@"There is a file on a downloading process on this folder");
            thereAreDownloadingFilesOnTheFolder = YES;
        }
    }
    return thereAreDownloadingFilesOnTheFolder;
}



+ (void) removeDownloadFileWithPath:(NSString *)path{

    if (path) {
         NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        DLog(@"Error deleted downloaded file: %@", error);
    }
  
}

///-----------------------------------
/// @name Update a file with the temporal one
///-----------------------------------

/**
 * This method updates a file because there is a new version in the server
 *
 * @param file > (FileDto) the file to be updated
 * @param temporalFile > (NSString) the path of the temporal file
 */
+ (void) updateFile:(FileDto *)file withTemporalFile:(NSString *)temporalFile {
    
    //If the file has been updated
    DLog(@"Temporal local path: %@", temporalFile);
    DLog(@"Old local path: %@", file.localFolder);
    
    //Delete the old file
    DeleteFile *mDeleteFile = [[DeleteFile alloc] init];
    [mDeleteFile deleteItemFromDeviceByFileDto:file];
    
    //Change the name of the new updated file
    NSFileManager *filecopy=nil;
    filecopy =[NSFileManager defaultManager];
    NSError *error;
    if(![filecopy moveItemAtPath:temporalFile toPath:file.localFolder error:&error]){
        DLog(@"Error: %@",[error localizedDescription]);
    }
    else{
        DLog(@"All ok");
    }
}


+ (void) setThePermissionsForFolderPath:(NSString *)folderPath {
    
    NSError *error;
    
    DLog(@"setting permissions to folder: %@", folderPath);
    
    // Give the permissions to the folder
    [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:folderPath error:&error];
    
    if (error) {
        DLog(@"Error setting permissions: %@", error);
    }
}

///-----------------------------------
/// @name Update a file with the temporal one
///-----------------------------------

/**
 * This method check if one of the folders that contains a file is favorite
 *
 * @param file > (FileDto) the file to be checked
 *
 * @return BOOL -> return YES if there is a folder favorite that contains the file
 */
+ (BOOL) isSonOfFavoriteFolder:(FileDto *) file {
    
    BOOL isSonOfFavoriteFolder = NO;
    BOOL isFolderPending = YES;
    
    FileDto *folder = file;
    
    do {
        folder = [ManageFilesDB getFileDtoByIdFile:folder.fileId];
        
        if (folder.isFavorite) {
            isSonOfFavoriteFolder = YES;
            isFolderPending = NO;
        }
        
        if (folder.isRootFolder || folder == nil) {
            isFolderPending = NO;
        }
        
    } while (isFolderPending);
    
    
    return isSonOfFavoriteFolder;
}

+ (void) setEtagNegativeToAllTheFoldersThatContainsFile:(FileDto *) file {
    
    BOOL isFolderPending = YES;
    
    FileDto *folder = file;
    
    do {
        folder = [ManageFilesDB getFileDtoByIdFile:folder.fileId];
        [ManageFilesDB updateEtagOfFileDtoByid:folder.idFile andNewEtag:k_negative_etag];
        
        if (folder.isFavorite) {
            isFolderPending = NO;
            //Also we change the father in order to force the refresh
            folder = [ManageFilesDB getFileDtoByIdFile:folder.fileId];
            [ManageFilesDB updateEtagOfFileDtoByid:folder.idFile andNewEtag:k_negative_etag];
        }
        
    } while (isFolderPending);
    
}

@end
