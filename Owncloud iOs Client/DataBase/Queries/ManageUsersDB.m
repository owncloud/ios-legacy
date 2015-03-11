//
//  ManageUsersDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/06/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageUsersDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "UtilsUrls.h"
#import "OCKeychain.h"
#import "CredentialsDto.h"


#ifdef CONTAINER_APP
#import "AppDelegate.h"
#elif FILE_PICKER
#import "DocumentPickerViewController.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "FileProvider.h"
#endif

@implementation ManageUsersDB


/*
 * Method that add user into database
 * @userDto -> userDto (Object of a user info)
 */
+(void) insertUser:(UserDto *)userDto {
    
     NSLog(@"Insert user: url:%@ / username:%@ / password:%@ / ssl:%d / activeaccount:%d", userDto.url, userDto.username, userDto.password, userDto.ssl, userDto.activeaccount);
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO users(url, ssl, activeaccount, has_share_api_support, has_cookies_support) Values(?, ?, ?, ?, ?)", userDto.url, [NSNumber numberWithBool:userDto.ssl],  [NSNumber numberWithBool:userDto.activeaccount] , [NSNumber numberWithInteger:userDto.hasShareApiSupport], [NSNumber numberWithBool:userDto.hasCookiesSupport]];
        
        if (!correctQuery) {
            NSLog(@"Error in insertUser");
        }
        
    }];
    
    //Insert last user inserted in the keychain
    UserDto *lastUser = [self getLastUserInserted];
    NSString *idString = [NSString stringWithFormat:@"%ld", (long)lastUser.idUser];
    
    if (![OCKeychain setCredentialsById:idString withUsername:userDto.username andPassword:userDto.password]) {
        NSLog(@"Failed setting credentials");
    }
    
   
    
}

/*
 * This method return the active user of the app
 */
+ (UserDto *) getActiveUser {
    
    NSLog(@"getActiveUser");
    
    __block UserDto *output = nil;
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support, instant_upload, path_instant_upload, only_wifi_instant_upload, date_instant_upload FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1"];
        
        NSLog(@"RSColumnt count: %d", rs.columnCount);
        
        
        while ([rs next]) {
            
            output=[UserDto new];
            
            output.idUser = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            
            output.instant_upload = [rs intForColumn:@"instant_upload"];
            output.path_instant_upload = [rs stringForColumn:@"path_instant_upload"];
            output.only_wifi_instant_upload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.date_instant_upload = [rs longForColumn:@"date_instant_upload"];
            
            NSString *idString = [NSString stringWithFormat:@"%ld", (long)output.idUser];

            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            output.username = credDto.userName;
            output.password = credDto.password;
        }
        
        [rs close];
        
    }];
    
    
    return output;
}


/*
 * This method change the password of the an user
 * @user -> user object
 */
+(void) updatePassword: (UserDto *) user {
    
    
    if(user.password != nil) {
        
        NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];

        if (![OCKeychain updatePasswordById:idString withNewPassword:user.password]) {
            NSLog(@"Error update the password keychain");
        }
        
#ifdef CONTAINER_APP
        //Set the user password
        if (user.activeaccount == YES) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            app.activeUser = user;
            
            [app eraseCredentials];
            [app eraseURLCache];
        }
#endif

    }
}


/*
 * Method that return the user object of the idUser
 * @idUser -> id User.
 */
+ (UserDto *) getUserByIdUser:(NSInteger) idUser {
    
    NSLog(@"getUserByIdUser:(int) idUser");
    
    __block UserDto *output = nil;
    
    output=[UserDto new];
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support, instant_upload, path_instant_upload, only_wifi_instant_upload, date_instant_upload FROM users WHERE id = ?", [NSNumber numberWithInteger:idUser]];
    
        while ([rs next]) {
            
            output.idUser = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            
            output.instant_upload = [rs intForColumn:@"instant_upload"];
            output.path_instant_upload = [rs stringForColumn:@"path_instant_upload"];
            output.only_wifi_instant_upload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.date_instant_upload = [rs longForColumn:@"date_instant_upload"];

            NSString *idString = [NSString stringWithFormat:@"%ld", (long)output.idUser];

            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            output.username = credDto.userName;
            output.password = credDto.password;
        }
        
        [rs close];
        
    }];
    
    
    return output;
}

/*
 * Method that return if the user exist or not
 * @userDto -> user object
 */
+ (BOOL) isExistUser: (UserDto *) userDto {
    
    __block BOOL output = NO;
    
    NSArray *allUsers = [self getAllUsers];
    
    for (UserDto *user in allUsers) {
        if ([user.username isEqualToString:userDto.username] ) {
            if ([user.url isEqualToString:userDto.url]) {
                output = YES;
            }
        }
    }
    
    return output;
}

/*
 * Method that return an array with all users
 */
+ (NSMutableArray *) getAllUsers {
    
    NSLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support, instant_upload, path_instant_upload, only_wifi_instant_upload, date_instant_upload FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.idUser= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            current.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            
            current.instant_upload = [rs intForColumn:@"instant_upload"];
            current.path_instant_upload = [rs stringForColumn:@"path_instant_upload"];
            current.only_wifi_instant_upload = [rs intForColumn:@"only_wifi_instant_upload"];
            current.date_instant_upload = [rs longForColumn:@"date_instant_upload"];
            
            NSString *idString = [NSString stringWithFormat:@"%ld", (long)current.idUser];

            CredentialsDto *credDto = [OCKeychain getCredentialsById:idString];
            current.username = credDto.userName;
            current.password = credDto.password;
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    

    return output;
}

/*
 * Method that return an array with all users. 
 * This method is only used with the old structure of the table used until version 9
 * And is only used in the update database method
 */
+ (NSMutableArray *) getAllOldUsersUntilVersion10 {
    
    NSLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage, has_share_api_support FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.idUser= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.username = [rs stringForColumn:@"username"];
            current.password = [rs stringForColumn:@"password"];
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            
            NSLog(@"id user: %ld", (long)current.idUser);

            NSLog(@"url user: %@", current.url);
            NSLog(@"username user: %@", current.username);
            NSLog(@"password user: %@", current.password);
            
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    return output;

}

/*
 * Method that set a user like a active account
 * @idUser -> id user
 */
+(void) setActiveAccountByIdUser: (NSInteger) idUser {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error setting the active account");
        }
        
    }];

}


/*
 * Method that set all acount as a no active.
 * This method is used before that set active account.
 */
+(void) setAllUsersNoActive {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=0"];
        
        if (!correctQuery) {
            NSLog(@"Error setting no active all acounts");
        }
        
    }];

}

/*
 * Method that select one account active automatically
 */
+(void) setActiveAccountAutomatically {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = (SELECT id FROM users ORDER BY id limit 1)"];
        
        if (!correctQuery) {
            NSLog(@"Error setting on account active automatically");
        }
        
    }];

}

/*
 * Method that remove user data in all tables 
 * @idUser -> id user
 */
+(void) removeUserAndDataByIdUser:(NSInteger)idUser {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM users WHERE id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete files from files users table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete files from files files table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files_backup WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete files from files_backup backup table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete files from uploads uploads_offline table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete info of shared table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM cookies_storage WHERE user_id = ?", [NSNumber numberWithInteger:idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error delete info of cookies_storage table");
            
        }
        
    }];
    
    NSString *idString = [NSString stringWithFormat:@"%ld", (long)idUser];
    if (![OCKeychain removeCredentialsById:idString]) {
        NSLog(@"Error delete keychain credentials");
        
    }
}

/*
 * Method that set the user storage of a user
 */
+(void) updateStorageByUserDto:(UserDto *) user {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET storage_occupied=?, storage=? WHERE id = ?", [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.idUser]];
        
        if (!correctQuery) {
            NSLog(@"Error updating storage of user");
        }
    
    }];

}

/*
 * Method that return last user inserted on the Database
 */
+ (UserDto *) getLastUserInserted {
    
    __block UserDto *output = nil;
    
    output=[UserDto new];
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support, instant_upload, path_instant_upload, only_wifi_instant_upload, date_instant_upload FROM users ORDER BY id DESC LIMIT 1"];
        
        while ([rs next]) {
            
            output.idUser = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            
            output.instant_upload = [rs intForColumn:@"instant_upload"];
            output.path_instant_upload = [rs stringForColumn:@"path_instant_upload"];
            output.only_wifi_instant_upload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.date_instant_upload = [rs longForColumn:@"date_instant_upload"];
        }
        
        [rs close];
        
    }];
    
    return output;
}

//-----------------------------------
/// @name Update user by user
///-----------------------------------

/**
 * Method to update a user setting anything just sending the user
 *
 * @param UserDto -> user
 */
+ (void) updateUserByUserDto:(UserDto *) user {
    
        FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#elif SHARE_IN
    queue = [Managers sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET url=?, ssl=?, activeaccount=?, storage_occupied=?, storage=?, has_share_api_support=?, has_cookies_support=?, instant_upload=?, path_instant_upload=?, only_wifi_instant_upload=?, date_instant_upload=? WHERE id = ?", user.url, [NSNumber numberWithBool:user.ssl], [NSNumber numberWithBool:user.activeaccount], [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.hasShareApiSupport],[NSNumber numberWithInteger:user.hasCookiesSupport], [NSNumber numberWithBool:user.instant_upload], user.path_instant_upload, [NSNumber numberWithBool:user.only_wifi_instant_upload], [NSNumber numberWithLong:user.date_instant_upload], [NSNumber numberWithInteger:user.idUser]];

        
        if (!correctQuery) {
            NSLog(@"Error updating a user");
        }
        
    }];
    
}



@end
