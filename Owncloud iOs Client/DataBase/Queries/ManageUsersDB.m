//
//  ManageUsersDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/06/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageUsersDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "OCKeychain.h"
#import "OCCredentialsDto.h"
#import "constants.h"
#import "ManageCapabilitiesDB.h"
#import "Customization.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif

@implementation ManageUsersDB


+(UserDto *) insertUser:(UserDto *)userDto {
    
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block BOOL correctQuery=NO;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        correctQuery = [db executeUpdate:@"INSERT INTO users(url, ssl, activeaccount, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, url_redirected, predefined_url, has_fed_shares_option_share_support, has_public_share_link_option_name_support, has_public_share_link_option_upload_only_support) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", userDto.url, [NSNumber numberWithBool:userDto.ssl],  [NSNumber numberWithBool:userDto.activeaccount] , [NSNumber numberWithInteger:userDto.hasShareApiSupport], [NSNumber numberWithInteger:userDto.hasShareeApiSupport], [NSNumber numberWithBool:userDto.hasCookiesSupport], [NSNumber numberWithInteger:userDto.hasForbiddenCharactersSupport], [NSNumber numberWithInteger:userDto.hasCapabilitiesSupport], userDto.urlRedirected, userDto.predefinedUrl, [NSNumber numberWithInteger:userDto.hasFedSharesOptionShareSupport], [NSNumber numberWithInteger:userDto.hasPublicShareLinkOptionNameSupport], [NSNumber numberWithInteger:userDto.hasPublicShareLinkOptionUploadOnlySupport] ];
    }];
    
    if (!correctQuery) {
        DLog(@"Error in insertUser");
        return nil;
    }
    
    UserDto *lastUser = [self getLastUserInsertedWithoutCredentials];
    
    if (lastUser) {
        lastUser.username = userDto.username;
        DLog(@"User %@ inserted in DB", userDto.username);
    } else {
        DLog(@"Error, not possible to insert user %@ in DB", userDto.username);
    }
    
    return lastUser;
    
}


+ (UserDto *) getActiveUser {
    
    DLog(@"getActiveUser");
    
    __block UserDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1"];
        
        DLog(@"RSColumnt count: %d", rs.columnCount);
        
        
        while ([rs next]) {
            
            output=[UserDto new];
            
            output.userId = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            output.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            output.backgroundInstantUpload  = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            output.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            output.sortingType = [rs intForColumn:@"sorting_type"];
            output.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            output.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            output.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            output.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
        }
        
        [rs close];
        
    }];
    
    if (output != nil) {
        OCCredentialsDto *credDto = [OCKeychain getCredentialsOfUser:output];
        output.username = credDto.userName;
        output.credDto = credDto;
        
        OCCapabilities *capDB = [ManageCapabilitiesDB getCapabilitiesOfUserId: output.userId];
        output.capabilitiesDto = capDB;
    }
    
    return output;
}


+ (UserDto *) getActiveUserWithoutCredentials {
    
    DLog(@"getActiveUserWithoutCredentials");
    
    __block UserDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1"];
        
        DLog(@"RSColumnt count: %d", rs.columnCount);
        
        
        while ([rs next]) {
            
            output=[UserDto new];
            
            output.userId = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            output.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            output.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            output.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            output.sortingType = [rs intForColumn:@"sorting_type"];
            output.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            output.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            output.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            output.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
            
            output.username = nil;
            output.credDto = nil;
        }
        
        [rs close];
        
    }];
    
    
    return output;
}


+ (UserDto *) getUserByUserId:(NSInteger) userId {
    
    DLog(@"getUserByUserId:(int) userId");
    
    __block UserDto *user = nil;
    
    user = [UserDto new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users WHERE id = ?", [NSNumber numberWithInteger:userId]];
        
        while ([rs next]) {
            
            user.userId = [rs intForColumn:@"id"];
            user.url = [rs stringForColumn:@"url"];
            user.ssl = [rs intForColumn:@"ssl"];
            user.activeaccount = [rs intForColumn:@"activeaccount"];
            user.storageOccupied = [rs longForColumn:@"storage_occupied"];
            user.storage = [rs longForColumn:@"storage"];
            
            user.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            user.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            user.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            user.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            user.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            user.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            user.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            user.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            user.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            user.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            user.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            user.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            user.urlRedirected = [rs stringForColumn:@"url_redirected"];
            user.sortingType = [rs intForColumn:@"sorting_type"];
            user.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            user.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            user.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            user.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
        }
        
        [rs close];
        
    }];
    
    if (user != nil) {
        user.credDto = [OCKeychain getCredentialsOfUser:user];
        user.username = user.credDto.userName;
    }
    
    return user;
}


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


+ (NSMutableArray *) getAllUsers {
    
    DLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.userId= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            current.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            current.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            current.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            current.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            current.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            current.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            current.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            current.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            current.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            current.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            current.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            current.urlRedirected = [rs stringForColumn:@"url_redirected"];
            current.sortingType = [rs intForColumn:@"sorting_type"];
            current.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            current.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            current.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            current.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
            
            OCCredentialsDto *credDto = [OCKeychain getCredentialsOfUser:current];
            current.username = credDto.userName;
            current.credDto = credDto;
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    
    
    return output;
}

+ (NSMutableArray *) getAllUsersWithOutCredentialInfo{
    
    DLog(@"getAllUsersWithOutCredentialInfo");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.userId= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            current.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            current.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            current.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            current.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            current.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            current.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            current.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            current.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            current.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            current.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            current.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            current.urlRedirected = [rs stringForColumn:@"url_redirected"];
            current.sortingType = [rs intForColumn:@"sorting_type"];
            current.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            current.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            current.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            current.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
            
            current.username = nil;
            current.credDto = nil;
            
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    
    return output;
    
}


+ (NSMutableArray *) getAllOldUsersUntilVersion10 {
    
    DLog(@"getAllUsers");
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage, has_share_api_support FROM users ORDER BY id ASC"];
        
        UserDto *current = nil;
        
        while ([rs next]) {
            
            current = [UserDto new];
            
            current.userId= [rs intForColumn:@"id"];
            current.url = [rs stringForColumn:@"url"];
            current.username = [rs stringForColumn:@"username"];
            current.credDto = [OCCredentialsDto new];
            current.credDto.userName = current.username;
            current.credDto.accessToken = [rs stringForColumn:@"password"];
            current.credDto.authenticationMethod = k_is_sso_active ? AuthenticationMethodSAML_WEB_SSO : AuthenticationMethodBASIC_HTTP_AUTH;
            current.ssl = [rs intForColumn:@"ssl"];
            current.activeaccount = [rs intForColumn:@"activeaccount"];
            current.storageOccupied = [rs longForColumn:@"storage_occupied"];
            current.storage = [rs longForColumn:@"storage"];
            current.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            
            DLog(@"id user: %ld", (long)current.userId);
            
            DLog(@"url user: %@", current.url);
            DLog(@"username user: %@", current.username);
            DLog(@"password user: %@", current.credDto.accessToken);
            
            
            [output addObject:current];
            
        }
        
        [rs close];
        
    }];
    
    return output;
    
}


+(void) setActiveAccountByUserId: (NSInteger) userId {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = ?", [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error setting the active account");
        }
        
    }];
    
}


+(void) setAllUsersNoActive {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=0"];
        
        if (!correctQuery) {
            DLog(@"Error setting no active all acounts");
        }
        
    }];
    
}


+(void) setActiveAccountAutomatically {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET activeaccount=1 WHERE id = (SELECT id FROM users ORDER BY id limit 1)"];
        
        if (!correctQuery) {
            DLog(@"Error setting on account active automatically");
        }
        
    }];
    
}


+(void) removeUserAndDataByUser:(UserDto *)user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM users WHERE id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files users table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files files table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM files_backup WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from files_backup backup table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete files from uploads uploads_offline table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM shared WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete info of shared table");
            
        }
        
        correctQuery = [db executeUpdate:@"DELETE FROM cookies_storage WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error delete info of cookies_storage table");
            
        }
        
    }];
    
    if (![OCKeychain removeCredentialsOfUser:user]) {
        DLog(@"Error delete keychain credentials");
        
    }
}


+(void) updateStorageByUserDto:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET storage_occupied=?, storage=? WHERE id = ?", [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error updating storage of user");
        }
        
    }];
    
}


+ (UserDto *) getLastUserInsertedWithoutCredentials {
    
    __block UserDto *output = nil;
    
    output=[UserDto new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM users ORDER BY id DESC LIMIT 1"];
        
        while ([rs next]) {
            
            output.userId = [rs intForColumn:@"id"];
            output.url = [rs stringForColumn:@"url"];
            output.ssl = [rs intForColumn:@"ssl"];
            output.activeaccount = [rs intForColumn:@"activeaccount"];
            output.storageOccupied = [rs longForColumn:@"storage_occupied"];
            output.storage = [rs longForColumn:@"storage"];
            
            output.hasShareApiSupport = [rs intForColumn:@"has_share_api_support"];
            output.hasShareeApiSupport = [rs intForColumn:@"has_sharee_api_support"];
            output.hasCookiesSupport = [rs intForColumn:@"has_cookies_support"];
            output.hasForbiddenCharactersSupport = [rs intForColumn:@"has_forbidden_characters_support"];
            output.hasCapabilitiesSupport = [rs intForColumn:@"has_capabilities_support"];
            
            output.imageInstantUpload = [rs intForColumn:@"image_instant_upload"];
            output.videoInstantUpload = [rs intForColumn:@"video_instant_upload"];
            output.backgroundInstantUpload = [rs intForColumn:@"background_instant_upload"];
            output.pathInstantUpload = [rs stringForColumn:@"path_instant_upload"];
            output.onlyWifiInstantUpload = [rs intForColumn:@"only_wifi_instant_upload"];
            output.timestampInstantUploadImage = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
            output.timestampInstantUploadVideo = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
            
            output.urlRedirected = [rs stringForColumn:@"url_redirected"];
            output.sortingType = [rs intForColumn:@"sorting_type"];
            output.predefinedUrl = [rs stringForColumn:@"predefined_url"];
            
            output.hasFedSharesOptionShareSupport = [rs intForColumn:@"has_fed_shares_option_share_support"];
            output.hasPublicShareLinkOptionNameSupport = [rs intForColumn:@"has_public_share_link_option_name_support"];
            output.hasPublicShareLinkOptionUploadOnlySupport = [rs intForColumn:@"has_public_share_link_option_upload_only_support"];
        }
        
        [rs close];
        
    }];
    
    return output;
}


+ (void) updateUserByUserDto:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET url=?, ssl=?, activeaccount=?, storage_occupied=?, storage=?, has_share_api_support=?, has_sharee_api_support=?, has_cookies_support=?, has_forbidden_characters_support=?, has_capabilities_support=?, image_instant_upload=?, video_instant_upload=?, background_instant_upload=?, path_instant_upload=?, only_wifi_instant_upload=?, timestamp_last_instant_upload_image=?, timestamp_last_instant_upload_video=?, url_redirected=?, sorting_type=?, predefined_url=?, has_fed_shares_option_share_support=?, has_public_share_link_option_name_support=?, has_public_share_link_option_upload_only_support=? WHERE id = ?", user.url, [NSNumber numberWithBool:user.ssl], [NSNumber numberWithBool:user.activeaccount], [NSNumber numberWithLong:user.storageOccupied], [NSNumber numberWithLong:user.storage], [NSNumber numberWithInteger:user.hasShareApiSupport], [NSNumber numberWithInteger:user.hasShareeApiSupport], [NSNumber numberWithInteger:user.hasCookiesSupport], [NSNumber numberWithInteger:user.hasForbiddenCharactersSupport], [NSNumber numberWithInteger:user.hasCapabilitiesSupport], [NSNumber numberWithBool:user.imageInstantUpload], [NSNumber numberWithBool:user.videoInstantUpload], [NSNumber numberWithBool:user.backgroundInstantUpload], user.pathInstantUpload, [NSNumber numberWithBool:user.onlyWifiInstantUpload], [NSNumber numberWithLong:user.timestampInstantUploadImage], [NSNumber numberWithLong:user.timestampInstantUploadVideo], user.urlRedirected, [NSNumber numberWithInteger:user.sortingType],user.predefinedUrl, [NSNumber numberWithInteger:user.hasFedSharesOptionShareSupport], [NSNumber numberWithInteger:user.hasPublicShareLinkOptionNameSupport], [NSNumber numberWithInteger:user.hasPublicShareLinkOptionUploadOnlySupport], [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error updating a user");
        }
        
    }];
    
}


+ (BOOL) hasTheServerOfTheActiveUserForbiddenCharactersSupport{
    
    BOOL isForbiddenCharacterSupport = NO;
    
    UserDto *activeUser = [ManageUsersDB getActiveUser];
    
    if (activeUser.hasForbiddenCharactersSupport == serverFunctionalitySupported) {
        isForbiddenCharacterSupport = YES;
    }
    
    return isForbiddenCharacterSupport;
}


+ (void) updateSortingWayForUserDto:(UserDto *)user {
    
    DLog(@"updateSortingTypeTo");
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET sorting_type=? WHERE id = ?", [NSNumber numberWithInteger:user.sortingType], [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error updating sorting type");
        }
    }];
}

#pragma mark - urlRedirected

+(void)updateUrlRedirected:(NSString *)newValue byUserDto:(UserDto *)user {
    DLog(@"Updated url redirected");
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET url_redirected=? WHERE id = ?", newValue, [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error updating url_redirected");
        }
    }];
}

+(NSString *)getUrlRedirectedByUserDto:(UserDto *)user {
    DLog(@"getUrlRedirected");
    
    __block NSString *output;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT url_redirected FROM users  WHERE id = ?", [NSNumber numberWithInteger:user.userId]];
        
        while ([rs next]) {
            
            output = [rs stringForColumn:@"url_redirected"];
        }
        
    }];
    
    return output;
}


+(BOOL)existAnyUser {
    
    __block BOOL output = NO;
    __block int size = 0;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(*) FROM users"];
        
        while ([rs next]) {
            
            size = [rs intForColumnIndex:0];
        }
        
        if(size > 0) {
            output = YES;
        }
        
    }];
    
    return output;
    
}

#pragma mark - Force update predefined URL

+(void)updatePredefinedUrlTo:(NSString *)newValue byUserId:(NSInteger)userId {
    DLog(@"Update predefined URL of userId %ld", (long)userId);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET predefined_url=? WHERE id=? ", newValue, [NSNumber numberWithInteger:userId] ];
        
        if (!correctQuery) {
            DLog(@"Error setting predefined URL of userId %ld", (long)userId);
        }
    }];
}


@end
