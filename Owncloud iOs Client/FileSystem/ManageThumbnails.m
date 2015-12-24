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
    
    return [NSString stringWithFormat:@"%@%ld", [self getThumbnailLocalSystemPath], (long)hash];
    
}


- (NSString *) getThumbnailLocalSystemPath {
    
    return [NSString stringWithFormat:@"%@%@/", [UtilsUrls getOwnCloudFilePath], thumbnailsCacheFolderName];
    
}


#pragma mark - File System


- (void) createThumbnailCacheFolderIfNotExist {

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPath]]) {
         NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[self getThumbnailLocalSystemPath] withIntermediateDirectories:NO attributes:nil error:&error];
    }
}


- (void) deleteThumbnailCacheFolder {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getThumbnailLocalSystemPath]]) {
         NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[self getThumbnailLocalSystemPath] error:&error];
    }
    
}

@end
