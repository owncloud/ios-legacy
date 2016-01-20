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


static NSString *thumbnailsCacheFolderName = @"thumbnails_cache";


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


#pragma mark - Store

- (BOOL) storeThumbnail:(NSData *)thumbnail withHash:(NSUInteger) hash {
    
    [self createThumbnailCacheFolderIfNotExist];
    
   return [[NSFileManager defaultManager] createFileAtPath:[self getThumbnailPathForFileHash:hash] contents:thumbnail attributes:nil];
    
}

- (BOOL) isStoredThumbnailWithHash:(NSUInteger) hash {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailPathForFileHash:hash]];
    
}


- (BOOL) removeStoredThumbnailWithHash:(NSUInteger) hash {
    
    return [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailPathForFileHash:hash] error:nil];
}


- (BOOL) renameStoredThumbnailWithOldHash:(NSUInteger) oldHash withNewHash:(NSUInteger) newHash {
    
    return [[NSFileManager defaultManager] moveItemAtPath:[self getThumbnailPathForFileHash:oldHash] toPath:[self getThumbnailPathForFileHash:newHash] error:nil];
    
}


#pragma mark - Paths


- (NSString *) getThumbnailPathForFileHash:(NSUInteger) hash {
    
    return [NSString stringWithFormat:@"%@%ld", [self getThumbnailLocalSystemPathOfActiveUser], (long)hash];
    
}


- (NSString *) getThumbnailLocalSystemPathOfActiveUser {
    
    return [self getThumbnailLocalSystemPathOfUserId:(long)[ManageUsersDB getActiveUser].idUser];
    
}

- (NSString *) getThumbnailLocalSystemPathOfUserId: (NSInteger)userId {
    
    DLog(@"%@", [NSString stringWithFormat:@"%@%@/%ld/", [UtilsUrls getOwnCloudFilePath], thumbnailsCacheFolderName, (long)[ManageUsersDB getActiveUser].idUser]);
    
    return [NSString stringWithFormat:@"%@%@/%ld/", [UtilsUrls getOwnCloudFilePath], thumbnailsCacheFolderName, userId];
    
}


#pragma mark - File System


- (void) createThumbnailCacheFolderIfNotExist {

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPathOfActiveUser]]) {
         NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[self getThumbnailLocalSystemPathOfActiveUser] withIntermediateDirectories:YES attributes:nil error:&error];
    }
}


- (void) deleteThumbnailCacheFolderOfActiveUser {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPathOfActiveUser]]) {
         NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailLocalSystemPathOfActiveUser] error:&error];
    }
    
}

- (void) deleteThumbnailCacheFolderOfUserId:(NSInteger) userId {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPathOfUserId: userId]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailLocalSystemPathOfUserId: userId] error:&error];
    }
    
}

#pragma mark - Manage thumbnails

- (void) renameThumbnailOfFile:(FileDto *)oldFile withNewFile:(FileDto *)newFile {
    
    UserDto *user = [ManageUsersDB getActiveUser];
    
    [self renameStoredThumbnailWithOldHash:[oldFile getHashIdentifierOfUserID:user.idUser] withNewHash:[newFile getHashIdentifierOfUserID:user.idUser] ];
}


- (void) removeThumbnailIfExistWithFile:(FileDto *)theFile {

    UserDto *user = [ManageUsersDB getActiveUser];
    [self removeStoredThumbnailWithHash:[theFile getHashIdentifierOfUserID:user.idUser]];
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
            [self removeThumbnailIfExistWithFile:file];
        }
    }
    
}

@end
