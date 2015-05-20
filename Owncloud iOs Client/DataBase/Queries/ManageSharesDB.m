//
//  ManageSharesDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 08/01/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageSharesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "AppDelegate.h"
#import "OCSharedDto.h"
#import "UtilsDtos.h"
#import "NSString+Encoding.h"
#import "Owncloud_iOs_Client-Swift.h"

@implementation ManageSharesDB

///-----------------------------------
/// @name Insert Share List in Shares Table
///-----------------------------------

/**
 * Method that insert a list of Share objects into DabaBase
 *
 * @param elements -> NSMutableArray (Array of share objects)
 */
+ (void) insertSharedList:(NSArray *)elements{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;

    FMDatabaseQueue *queue = Managers.sharedDatabase;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL correctQuery = NO;
        
       // DLog(@"shared items: %@", elements);
        
        for (OCSharedDto *shareDto in elements) {
            
            //Adding UTF8 encoding
            shareDto.path = [shareDto.path encodeString:NSUTF8StringEncoding];
       
            NSString *sqlQuery = [NSString stringWithFormat:@"INSERT INTO shared SELECT null as id, %ld as 'file_source', %ld as 'item_source', %ld as 'share_type', '%@' as 'share_with', '%@' as 'path', %ld as 'permissions', %ld as 'shared_date', %ld as 'expiration_date', '%@' as 'token', '%@' as 'share_with_display_name', %d as 'is_directory', %ld as 'user_id', %ld as 'id_remote_shared'",
                             (long)shareDto.fileSource,
                             (long)shareDto.itemSource,
                             (long)shareDto.shareType,
                             shareDto.shareWith,
                             shareDto.path,
                             (long)shareDto.permissions,
                             shareDto.sharedDate,
                             shareDto.expirationDate,
                             shareDto.token,
                             shareDto.shareWithDisplayName,
                             shareDto.isDirectory,
                             (long)mUser.idUser,
                             (long)shareDto.idRemoteShared];
            
            correctQuery = [db executeUpdate:sqlQuery];
           
        }

            
        
        if (!correctQuery) {
            
            DLog(@"Error in insert Share List");
        }
        
    }];
}

///-----------------------------------
/// @name Delete All Shares of User
///-----------------------------------

/**
 * Method that delete all shares element of a specific user
 *
 * @param idUser -> NSInteger
 */

+ (void) deleteAllSharesOfUser:(NSInteger)idUser{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in delete shares of user");
        }
        
    }];

}


///-----------------------------------
/// @name Get Shares by FileDto
///-----------------------------------

/**
 * Get the shared items of parent folder
 *
 * @param fileDto -> FileDto
 * @param idUser -> NSInteger
 *
 * @return NSMutableArray
 *
 */
+ (NSMutableArray*) getSharesByFolder:(FileDto *) folder {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE file_source IN (SELECT shared_file_source FROM files WHERE file_id = ? AND shared_file_source > 0)", [NSNumber numberWithInteger:folder.idFile]];
        while ([rs next]) {
            
            //Get the path
            NSString *itemPath = [rs stringForColumn:@"path"];
            
            itemPath = [UtilsDtos getTheParentPathOfThePath:itemPath];
            
            DLog(@"item path: %@", itemPath);
            //Only if is the same parent folder && only stored share type 3 (Shared with link)
            
            OCSharedDto *sharedDto = [OCSharedDto new];
            
            sharedDto.fileSource = [rs intForColumn:@"file_source"];
            sharedDto.itemSource = [rs intForColumn:@"item_source"];
            sharedDto.shareType = [rs intForColumn:@"share_type"];
            sharedDto.shareWith = [rs stringForColumn:@"share_with"];
            sharedDto.path = [rs stringForColumn:@"path"];
            sharedDto.permissions = [rs intForColumn:@"permissions"];
            sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
            sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
            sharedDto.token = [rs stringForColumn:@"token"];
            sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
            sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
            sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
            
            [output addObject:sharedDto];
        }
        [rs close];
    }];
    
    return output;
}


///-----------------------------------
/// @name Get Shares by Folder Path
///-----------------------------------

/**
 * Get the shared items of a specific folder
 *
 * @param path -> NSString
 * @param idUser -> NSInteger
 *
 * @return NSMutableArray
 *
 */
+ (NSMutableArray*) getSharesByFolderPath:(NSString *) path {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    if (([path length] > 0) && (![path isEqualToString:@"/"])) {
        path = [path substringToIndex:[path length]-1];
    }
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared"];
        
        while ([rs next]) {
            
            //Get the path
            NSString *itemPath = [rs stringForColumn:@"path"];
            
            itemPath = [UtilsDtos getTheParentPathOfThePath:itemPath];
            
            DLog(@"path: %@", path);
            DLog(@"item path: %@", itemPath);
            
            
            //Only if is the same parent folder && only stored share type 3 (Shared with link)
            
            if ([itemPath isEqualToString:path]) {
                
                OCSharedDto *sharedDto = [OCSharedDto new];
                
                sharedDto.fileSource = [rs intForColumn:@"file_source"];
                sharedDto.itemSource = [rs intForColumn:@"item_source"];
                sharedDto.shareType = [rs intForColumn:@"share_type"];
                sharedDto.shareWith = [rs stringForColumn:@"share_with"];
                sharedDto.path = [rs stringForColumn:@"path"];
                sharedDto.permissions = [rs intForColumn:@"permissions"];
                sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
                sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
                sharedDto.token = [rs stringForColumn:@"token"];
                sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
                sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
                sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
                
                [output addObject:sharedDto];

            }
            
            
        }
        [rs close];
    }];
    
    return output;
}

///-----------------------------------
/// @name Get All Shares for user
///-----------------------------------

/**
 * Get the shared items of a specific user
 *
 * @param idUser -> NSInteger
 *
 * @return NSArray
 *
 */

+ (NSArray*) getAllSharesforUser:(NSInteger)idUser{
    
    __block NSMutableArray *items = [NSMutableArray new];
    NSArray *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        while ([rs next]) {
            
            //only stored share type 3 (Shared with link)
            if ([rs intForColumn:@"share_type"] == 3) {
                
                OCSharedDto *sharedDto = [OCSharedDto new];
                
                sharedDto.fileSource = [rs intForColumn:@"file_source"];
                sharedDto.itemSource = [rs intForColumn:@"item_source"];
                sharedDto.shareType = [rs intForColumn:@"share_type"];
                sharedDto.shareWith = [rs stringForColumn:@"share_with"];
                sharedDto.path = [rs stringForColumn:@"path"];
                sharedDto.permissions = [rs intForColumn:@"permissions"];
                sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
                sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
                sharedDto.token = [rs stringForColumn:@"token"];
                sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
                sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
                sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
                
                [items addObject:sharedDto];
            }
        }
        [rs close];
    }];
    
    
    output = [NSArray arrayWithArray:items];
    items = nil;
    
    
    return output;
    
}


///-----------------------------------
/// @name Get Shares of sharedFileSource
///-----------------------------------

/**
 * Get the shared items of a specific path of a specific user
 *
 * @param sharedFileSource -> NSInteger
 * @param idUser -> NSInteger
 *
 * @return NSMutableArray
 *
 */
+ (NSMutableArray*) getSharesBySharedFileSource:(NSInteger) sharedFileSource forUser:(NSInteger)idUser {
    
    __block NSMutableArray *output = [NSMutableArray new];

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ? AND file_source = ?", [NSNumber numberWithInteger:idUser], [NSNumber numberWithInteger:sharedFileSource]];
        while ([rs next]) {
            
            OCSharedDto *sharedDto = [OCSharedDto new];
            
            sharedDto.fileSource = [rs intForColumn:@"file_source"];
            sharedDto.itemSource = [rs intForColumn:@"item_source"];
            sharedDto.shareType = [rs intForColumn:@"share_type"];
            sharedDto.shareWith = [rs stringForColumn:@"share_with"];
            sharedDto.path = [rs stringForColumn:@"path"];
            sharedDto.permissions = [rs intForColumn:@"permissions"];
            sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
            sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
            sharedDto.token = [rs stringForColumn:@"token"];
            sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
            sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
            sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
            
            [output addObject:sharedDto];
        }
        [rs close];
    }];
    
    return output;
}

///-----------------------------------
/// @name getAllSharesByUser
///-----------------------------------

/**
 * Method to return all shares that have a user
 *
 * @param idUser -> NSInteger
 *
 */
+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        while ([rs next]) {
            
            OCSharedDto *sharedDto = [OCSharedDto new];
            
            sharedDto.fileSource = [rs intForColumn:@"file_source"];
            sharedDto.itemSource = [rs intForColumn:@"item_source"];
            sharedDto.shareType = [rs intForColumn:@"share_type"];
            sharedDto.shareWith = [rs stringForColumn:@"share_with"];
            sharedDto.path = [rs stringForColumn:@"path"];
            sharedDto.permissions = [rs intForColumn:@"permissions"];
            sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
            sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
            sharedDto.token = [rs stringForColumn:@"token"];
            sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
            sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
            sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
            
            [output addObject:sharedDto];
        }
        [rs close];
    }];
    
    return output;
}




///-----------------------------------
/// @name getAllSharesByUserAndSharedType
///-----------------------------------

/**
 * Method to return all shares that have a user of shared type
 *
 * @param idUser -> NSInteger
 * @param sharedType -> NSInteger
 *
 */
+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser anTypeOfShare: (NSInteger) shareType {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ? AND share_type = ?", [NSNumber numberWithInteger:idUser], [NSNumber numberWithInteger:shareType]];
        while ([rs next]) {
            
            OCSharedDto *sharedDto = [OCSharedDto new];
            
            sharedDto.fileSource = [rs intForColumn:@"file_source"];
            sharedDto.itemSource = [rs intForColumn:@"item_source"];
            sharedDto.shareWith = [rs stringForColumn:@"share_with"];
            sharedDto.path = [rs stringForColumn:@"path"];
            sharedDto.permissions = [rs intForColumn:@"permissions"];
            sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
            sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
            sharedDto.token = [rs stringForColumn:@"token"];
            sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
            sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
            sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
            
            [output addObject:sharedDto];
        }
        [rs close];
    }];
    
    return output;
}


///-----------------------------------
/// @name Delete a list of shared
///-----------------------------------

/**
 * Method that delete all shares element of a specific user
 *
 * @param listOfRemoved -> NSArray of OCSharedDto
 */
+ (void) deleteLSharedByList:(NSArray *) listOfRemoved {
    
    //Shared items
    for (OCSharedDto *current in listOfRemoved) {
        
        FMDatabaseQueue *queue = Managers.sharedDatabase;
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL correctQuery=NO;
            
            correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE id_remote_shared = ?", [NSNumber numberWithInteger:current.idRemoteShared]];
            
            if (!correctQuery) {
                DLog(@"Error in deleteListOfSharedByList");
            }
            
        }];
    }
}

///-----------------------------------
/// @name deleteSharedNotRelatedByUser
///-----------------------------------

/**
 * Method that delete all shares that not appear on the file list (old shared that does not exist)
 *
 * @param user -> UserDto
 */
+ (void) deleteSharedNotRelatedByUser:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE user_id = ? AND file_source NOT IN (SELECT shared_file_source FROM files WHERE user_id = ?)", [NSNumber numberWithInteger:user.idUser], [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteListOfSharedByList");
        }
        
    }];
    
}


/**
 * This method return a OCSharedDto with equal file dto path, if
 * is not catched this method return nil
 *
 * @param path -> NSString
 *
 * @return OCSharedDto
 *
 */
+ (OCSharedDto *) getSharedEqualWithFileDtoPath:(NSString*)path{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block OCSharedDto *sharedDto = nil;
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:mUser.idUser]];
        while ([rs next]) {
            
            comparePath = [rs stringForColumn:@"path"];
            
            DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                //Store the rs file object
                sharedDto = [OCSharedDto new];
                sharedDto.fileSource = [rs intForColumn:@"file_source"];
                sharedDto.itemSource = [rs intForColumn:@"item_source"];
                sharedDto.shareType = [rs intForColumn:@"share_type"];
                sharedDto.shareWith = [rs stringForColumn:@"share_with"];
                sharedDto.path = [rs stringForColumn:@"path"];
                sharedDto.permissions = [rs intForColumn:@"permissions"];
                sharedDto.sharedDate = [rs longForColumn:@"shared_date"];
                sharedDto.expirationDate = [rs longForColumn:@"expiration_date"];
                sharedDto.token = [rs stringForColumn:@"token"];
                sharedDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
                sharedDto.isDirectory = [rs boolForColumn:@"is_directory"];
                sharedDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
                
            }
            
        }
        [rs close];
    }];
    
    return sharedDto;
    
}


@end
