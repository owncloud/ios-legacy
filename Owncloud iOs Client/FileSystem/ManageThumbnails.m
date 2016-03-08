//
//  ManageThumbnails.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 23/12/15.
//

/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageThumbnails.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "UIImage+Thumbnail.h"
#import "constants.h"


@interface ManageThumbnails ()


@end


@implementation ManageThumbnails


+ (id)sharedManager {
    static ManageThumbnails *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


#pragma mark - Store, remove, rename thumbnails

- (BOOL) storeThumbnail:(NSData *)thumbnail forFile:(FileDto *)file {
    
    [self createThumbnailCacheFolderIfNotExistForUser:file.userId];
    
   return [[NSFileManager defaultManager] createFileAtPath:[self getThumbnailPathForFile:file] contents:thumbnail attributes:nil];
    
}

- (BOOL) isStoredThumbnailForFile:(FileDto *)file {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailPathForFile:file]];
    
}


- (BOOL) removeStoredThumbnailForFile:(FileDto *)file {
    
    return [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailPathForFile:file] error:nil];
}


- (BOOL) renameThumbnailOfFile:(FileDto *)oldFile withNewFile:(FileDto *)newFile {
    
    return [[NSFileManager defaultManager] moveItemAtPath:[self getThumbnailPathForFile:oldFile] toPath:[self getThumbnailPathForFile:newFile] error:nil];
    
}


#pragma mark - Paths

- (NSString *) getThumbnailPathForFile:(FileDto *)file {
    
    return [NSString stringWithFormat:@"%@%@", [self getThumbnailLocalSystemPathOfUserId:file.userId], file.ocId];
    
}

- (NSString *) getThumbnailLocalSystemPathOfUserId:(NSInteger)userId {
    
    return [NSString stringWithFormat:@"%@/%ld/", [UtilsUrls getThumbnailFolderPath], userId];
    
}


#pragma mark - File System


- (void) createThumbnailCacheFolderIfNotExistForUser:(NSInteger)userId {

    NSString *path = [self getThumbnailLocalSystemPathOfUserId:userId];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
         NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

- (void) deleteThumbnailCacheFolderOfUserId:(NSInteger) userId {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPathOfUserId: userId]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailLocalSystemPathOfUserId: userId] error:&error];
    }
    
}


/*
 * Recursive method that delete all thumbnails of a directory by idFile
 */
- (void) deleteThumbnailsInFolder:(NSInteger)idFile {
    
    NSArray *files = [ManageFilesDB getFilesByFileIdForActiveUser:idFile];
    
    for (FileDto *file in files) {
        if (file.isDirectory) {
            //If is a folder delete items inside
            [self deleteThumbnailsInFolder:file.idFile];
        } else {
            //delete thumbnail
            [self removeStoredThumbnailForFile:file];
        }
    }
    
}

@end
