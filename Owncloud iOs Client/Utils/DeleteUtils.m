//
//  DeleteUtils.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 09/05/16.
//
//

#import "DeleteUtils.h"
#import "UserDto.h"
#import "ManageFilesDB.h"
#import "FileDto.h"
#import "DownloadUtils.h"

NSString *DeleteAllDownloadedFilesFinish = @"DeleteAllDownloadedFilesFinish";

@implementation DeleteUtils

/*
 *  Method to delete all the files that can be deleted by user
 */
+ (void) deleteAllDownloadedFilesByUser:(UserDto *) user {
    
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSMutableArray *filesToBeDeleted = [ManageFilesDB getFilesByDownloadStatus:downloaded andUser:user];
    
    for (FileDto *current in filesToBeDeleted) {
        if (!current.isFavorite && ![DownloadUtils isSonOfFavoriteFolder:current]) {
            
            NSError *error;
            [fileMgr removeItemAtPath:current.localFolder error:&error];
            
            if (error) {
                DLog(@"Error: %@", error);
            } else {
                [ManageFilesDB setFileIsDownloadState:current.idFile andState:notDownload];
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DeleteAllDownloadedFilesFinish object:nil];
}

@end
