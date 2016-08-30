//
//  DeleteUtils.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 09/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DeleteUtils.h"
#import "UserDto.h"
#import "ManageFilesDB.h"
#import "FileDto.h"
#import "DownloadUtils.h"


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
                DLog(@"Error deleting downloaded files: %@", error);
            } else {
                [ManageFilesDB setFileIsDownloadState:current.idFile andState:notDownload];
            }
        }
    }
}

@end
