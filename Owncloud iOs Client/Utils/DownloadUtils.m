//
//  DownloadUtils.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 29/05/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DownloadUtils.h"

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

@end
