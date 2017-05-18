//
//  ManageSharesDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 08/01/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageSharesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "OCSharedDto.h"
#import "UtilsDtos.h"
#import "NSString+Encoding.h"
#import "ManageUsersDB.h"

#ifdef CONTAINER_APP
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif



@implementation ManageSharesDB


+ (OCSharedDto *) shareDtoFromDBResults:(FMResultSet *)rs {
    
    
    OCSharedDto *shareDto = [OCSharedDto new];
    
    shareDto.fileSource = [rs intForColumn:@"file_source"];
    shareDto.itemSource = [rs intForColumn:@"item_source"];
    shareDto.shareType = [rs intForColumn:@"share_type"];
    shareDto.shareWith = [rs stringForColumn:@"share_with"];
    shareDto.path = [rs stringForColumn:@"path"];
    shareDto.permissions = [rs intForColumn:@"permissions"];
    shareDto.sharedDate = [rs longForColumn:@"shared_date"];
    shareDto.expirationDate = [rs longForColumn:@"expiration_date"];
    shareDto.token = [rs stringForColumn:@"token"];
    shareDto.shareWithDisplayName = [rs stringForColumn:@"share_with_display_name"];
    shareDto.isDirectory = [rs boolForColumn:@"is_directory"];
    shareDto.idRemoteShared = [rs intForColumn:@"id_remote_shared"];
    shareDto.name = [rs stringForColumn:@"name"];
    shareDto.url = [rs stringForColumn:@"url"];
    
    return shareDto;
}


+ (void) insertSharedList:(NSArray *)elements{
    
    UserDto *mUser =  [ManageUsersDB getActiveUser];

    FMDatabaseQueue *queue = Managers.sharedDatabase;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL correctQuery = NO;
        
       // DLog(@"shared items: %@", elements);
        
        for (OCSharedDto *shareDto in elements) {
            
            //Adding UTF8 encoding
            shareDto.path = [shareDto.path encodeString:NSUTF8StringEncoding];
       
            NSString *sqlQuery = [NSString stringWithFormat:@"INSERT INTO shared SELECT null as id, %ld as 'file_source', %ld as 'item_source', %ld as 'share_type', '%@' as 'share_with', '%@' as 'path', %ld as 'permissions', %ld as 'shared_date', %ld as 'expiration_date', '%@' as 'token', '%@' as 'share_with_display_name', %d as 'is_directory', %ld as 'user_id', %ld as 'id_remote_shared', '%@' as 'name', '%@' as 'url'",
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
                             (long)shareDto.idRemoteShared,
                             shareDto.name,
                             shareDto.url];
            
            correctQuery = [db executeUpdate:sqlQuery];
        }
        
        if (!correctQuery) {
            
            DLog(@"Error in insert Share List");
        }
        
    }];
}


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


+ (NSMutableArray*) getSharesByFolder:(FileDto *) folder {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE file_source IN (SELECT shared_file_source FROM files WHERE file_id = ? AND shared_file_source > 0)", [NSNumber numberWithInteger:folder.idFile]];
        while ([rs next]) {
            
            [output addObject:[self shareDtoFromDBResults:rs]];
        }
        [rs close];
    }];
    
    return output;
}


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
                
                [output addObject:[self shareDtoFromDBResults:rs]];
            }
            
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray*) getSharesByUser:(NSInteger)idUser andPath:(NSString *) path {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE path = ? AND user_id = ? ", path, [NSNumber numberWithInteger:idUser]];
        
        while ([rs next]) {
            
            [output addObject:[self shareDtoFromDBResults:rs]];
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray*) getSharesBySharedFileSource:(NSInteger) sharedFileSource forUser:(NSInteger)idUser {
    
    __block NSMutableArray *output = [NSMutableArray new];

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ? AND file_source = ?", [NSNumber numberWithInteger:idUser], [NSNumber numberWithInteger:sharedFileSource]];
        while ([rs next]) {
            
            [output addObject:[self shareDtoFromDBResults:rs]];
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        while ([rs next]) {
            
            [output addObject:[self shareDtoFromDBResults:rs]];
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser anTypeOfShare: (NSInteger) shareType {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ? AND share_type = ?", [NSNumber numberWithInteger:idUser], [NSNumber numberWithInteger:shareType]];
        while ([rs next]) {
            
            [output addObject:[self shareDtoFromDBResults:rs]];
        }
        [rs close];
    }];
    
    return output;
}


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


+ (OCSharedDto *) getSharedEqualWithFileDtoPath:(NSString*)path{
    
    UserDto *mUser = [ManageUsersDB getActiveUser];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block OCSharedDto *sharedDto = nil;
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:mUser.idUser]];
        while ([rs next]) {
            
            comparePath = [rs stringForColumn:@"path"];
            
            DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                sharedDto = [self shareDtoFromDBResults:rs];
            }
        }
        [rs close];
    }];
    
    return sharedDto;
    
}


+ (OCSharedDto *) getTheOCShareByFileDto:(FileDto*)file andShareType:(NSInteger) shareType andUser:(UserDto *) user {
    
    __block OCSharedDto *sharedDto;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM shared WHERE user_id = ? AND file_source = ? AND share_type = ?", [NSNumber numberWithInteger:user.idUser], [NSNumber numberWithInteger:file.sharedFileSource], [NSNumber numberWithInteger:shareType]];
        while ([rs next]) {
            
            sharedDto = [self shareDtoFromDBResults:rs];
        }
        [rs close];
    }];
    
    return sharedDto;
}


+ (void) updateTheRemoteShared: (NSInteger)idRemoteShared forUser: (NSInteger)userId withPermissions: (NSInteger)permissions{
    DLog(@"updateTheFileIDwithPermissions");
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE shared SET permissions = ? WHERE id_remote_shared = ? AND user_id = ?", [NSNumber numberWithInteger:permissions],[NSNumber numberWithInteger:idRemoteShared], [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error in update file with permissions");
        }
    }];
}

@end
