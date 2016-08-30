//
//  FileListDBOperations.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 09/05/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "FileListDBOperations.h"

#import "ManageFilesDB.h"
#import "UserDto.h"

@implementation FileListDBOperations


/*
 *  Method to create the directories in the system
 * with the list of files information
 * @listOfFiles --> List of files and folder of a folder
 */
+ (void) createAllFoldersByArrayOfFilesDto: (NSArray *) listOfFiles andLocalFolder:(NSString *)localFolder{
    
    for (int i = 0 ; i < [listOfFiles count] ; i++) {
        
        FileDto *currentFile = [listOfFiles objectAtIndex:i];
        
        if(currentFile.isDirectory) {
            
            DLog(@"Current folder to create: %@%@",currentFile.filePath, currentFile.fileName);
            
            NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@%@",localFolder,[currentFile.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            DLog(@"currentLocalFileToCreateFolder: %@", currentLocalFileToCreateFolder);
            
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:currentLocalFileToCreateFolder]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] createDirectoryAtPath:currentLocalFileToCreateFolder withIntermediateDirectories:NO attributes:nil error:&error];
                
                if(error) {
                    DLog(@"Error Files: %@", [error localizedDescription]);
                }
            }
        }
    }
    
}


/*
 * Method that create the root folder and return this object
 * @FileDto -> FileDto object of root folder
 */
+ (FileDto*)createRootFolderAndGetFileDtoByUser:(UserDto *) user {
    
    FileDto *initialRootFolder = [[FileDto alloc] init];
    
    initialRootFolder.ocId = @"";
    initialRootFolder.filePath = @"";
    initialRootFolder.fileName = @"";
    initialRootFolder.userId = user.idUser;
    initialRootFolder.isDirectory = YES;
    initialRootFolder.isDownload = notDownload;
    initialRootFolder.fileId = -1;
    initialRootFolder.size = 0;
    initialRootFolder.date = 0;
    initialRootFolder.isFavorite = NO;
    initialRootFolder.etag = @"";
    initialRootFolder.isRootFolder = YES;
    initialRootFolder.isNecessaryUpdate = NO;
    initialRootFolder.sharedFileSource = 0;
    initialRootFolder.permissions = @"";
    initialRootFolder.taskIdentifier = -1;
    initialRootFolder.providingFileId = 0;
    
    [ManageFilesDB insertFile:initialRootFolder];
    
    //We have to update the current files (We have just to login and we have the first files on the DB with the id 0)
    [ManageFilesDB updateFilesWithFileId:0 withNewFileId:[ManageFilesDB getRootFileDtoByUser:user].idFile];
    

    initialRootFolder=[ManageFilesDB getRootFileDtoByUser:user];
    
    return initialRootFolder;
    
}

/*
 * Method that realice the refresh process
 *
 */

+ (void)makeTheRefreshProcessWith:(NSMutableArray*)arrayFromServer inThisFolder:(NSInteger)idFolder{

    DLog(@"self.fileIdToShowFiles before refresh: %ld", (long)idFolder);
    
    [ManageFilesDB deleteFilesBackup];
    [ManageFilesDB backupOfTheProcessingFilesAndFoldersByFileId:idFolder];
    [ManageFilesDB deleteFilesFromDBBeforeRefreshByFileId:idFolder];
    
    DLog(@"self.fileIdToShowFiles: %ld", (long)idFolder);
    
    FileDto *currentFolder = [ManageFilesDB getFileDtoByIdFile:idFolder];
    
    DLog(@"idFile: %ld", (long)currentFolder.idFile);
    DLog(@"name: %@", currentFolder.fileName);
    
  //  NSMutableArray *directoryList = [[req getDirectoryList] mutableCopy];
    [ManageFilesDB insertManyFiles:arrayFromServer andFileId:currentFolder.idFile];
    
    //Read all backups folders and update on the old files related with the new ids
    [ManageFilesDB updateRelatedFilesFromBackup];
    //Delete the files and folders that not exist on the server
    [ManageFilesDB deleteAllFilesAndFoldersThatNotExistOnServerFromBackup];
    [ManageFilesDB deleteAllThumbnailsWithDifferentEtagFromBackup];
    //Read all backups that need be marked as necessary update
    [ManageFilesDB setUpdateIsNecessaryFromBackup:idFolder];
    //Read all backups downloaded files and update the new registers with the downloaded/shared status and isNessesaryUpdate
    [ManageFilesDB updateFilesFromBackup];
    //Read all backups favourites files and update the new registers with the favourite status
    [ManageFilesDB updateFavoriteFilesFromBackup];
}

/*
 *  Method to create a single folder
 */
+ (void) createAFolder: (NSString *)folderName inLocalFolder:(NSString *)localFolder{
    //Folder name: A/
    //Local folder: /Users/RebecaMartindeLeon/Library/Application Support/iPhone Simulator/7.0/Applications/FA43D5D3-2540-4D0B-B1B7-2E5B41B76965/Library/Application Support/cache_folder//7/
    
    DLog(@"Current folder to create: %@", folderName);
    
    NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@%@",localFolder,[folderName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    DLog(@"currentLocalFileToCreateFolder: %@", currentLocalFileToCreateFolder);
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:currentLocalFileToCreateFolder]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:currentLocalFileToCreateFolder withIntermediateDirectories:NO attributes:nil error:&error];
        
        if(error) {
            DLog(@"Error Files: %@", [error localizedDescription]);
        }
    }
}



@end
