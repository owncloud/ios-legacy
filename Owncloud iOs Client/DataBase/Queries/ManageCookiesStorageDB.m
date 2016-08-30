//
//  ManageCookiesStorageDB.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/07/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageCookiesStorageDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "CookiesStorageDto.h"
#import "UtilsCookies.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "UserDto.h"

@implementation ManageCookiesStorageDB

//-----------------------------------
/// @name insertCookie
///-----------------------------------

/**
 * Method to insert a cookie on the Database
 *
 * @param CookiesStorageDto -> cookie
 *
 */
+ (void) insertCookie:(CookiesStorageDto *) cookie {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO cookies_storage (cookie, user_id) Values (?,?)", [NSKeyedArchiver archivedDataWithRootObject:cookie.cookie], [NSNumber numberWithInteger:cookie.userId]];
        
        if (!correctQuery) {
            DLog(@"Error insert cookie");
        }
    }];
}

//-----------------------------------
/// @name getCookiesByUser
///-----------------------------------

/**
 * Method to return the list of cookies of a user
 *
 * @param UserDto -> user
 *
 * @return NSMutableArray -> output
 */
+ (NSMutableArray *) getCookiesByUser:(UserDto *) user {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, cookie, user_id FROM cookies_storage WHERE user_id = ?", [NSNumber numberWithInteger:user.idUser]];
        
        while ([rs next]) {
            
            CookiesStorageDto *current = [CookiesStorageDto new];
            
            current.idCookieStorage = [rs intForColumn:@"id"];
            current.cookie = [NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"cookie"]];
            current.userId = [rs intForColumn:@"user_id"];
        
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}

//-----------------------------------
/// @name deleteCookiesByUser
///-----------------------------------

/**
 * Method delete the cookies of a user
 *
 * @param UserDto -> user
 *
 */
+ (void) deleteCookiesByUser:(UserDto *) user {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM cookies_storage WHERE user_id = ?", [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error deleting an upload offline");
        }
    }];
}

@end
