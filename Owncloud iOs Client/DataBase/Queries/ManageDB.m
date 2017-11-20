//
//  ManageDB.m
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

#import "ManageDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "ManageFilesDB.h"
#import "ManageUsersDB.h"
#import "OCKeychain.h"
#import "UserDto.h"
#import "ManageAppSettingsDB.h"

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

#define notDownload 0

@implementation ManageDB

/*
 * Method that create a empty data base.
 */
+(void) createDataBase {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_sharee_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'has_capabilities_support' INTEGER NOT NULL DEFAULT 0, 'image_instant_upload' BOOL NOT NULL DEFAULT 0, 'video_instant_upload' BOOL NOT NULL DEFAULT 0, 'background_instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'timestamp_last_instant_upload_image' DOUBLE, 'timestamp_last_instant_upload_video' DOUBLE, 'url_redirected' VARCHAR, 'sorting_type' INTEGER NOT NULL DEFAULT 0, 'predefined_url' VARCHAR, has_fed_shares_option_share_support INTEGER NOT NULL DEFAULT 0, has_public_share_link_option_name_support INTEGER NOT NULL DEFAULT 0, has_public_share_link_option_upload_only_support INTEGER NOT NULL DEFAULT 0)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL NOT NULL DEFAULT 0, 'is_necessary_update' BOOL NOT NULL DEFAULT 0, 'shared_file_source' INTEGER NOT NULL DEFAULT 0, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER NOT NULL DEFAULT -1, 'providing_file_id' INTEGER NOT NULL DEFAULT 0, 'oc_id' VARCHAR NOT NULL DEFAULT '')"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files_backup' ('id' INTEGER, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL, 'is_necessary_update' BOOL, 'shared_file_source' INTEGER, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER, 'providing_file_id' INTEGER NOT NULL DEFAULT 0, 'oc_id' VARCHAR NOT NULL DEFAULT '')"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files_backup");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'passcode' ('id' INTEGER PRIMARY KEY, 'passcode' VARCHAR, 'is_touch_id' BOOL)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table passcode");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'certificates' ('id' INTEGER PRIMARY KEY, 'certificate_location' VARCHAR)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table certificates");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'db_version' ('id' INTEGER PRIMARY KEY, 'version' INTEGER, 'show_help_guide' BOOL NOT NULL DEFAULT 1)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table db_version");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'uploads_offline' ('id' INTEGER PRIMARY KEY, 'origin_path' VARCHAR, 'destiny_folder' VARCHAR, 'upload_filename' VARCHAR, 'estimate_length' LONG, 'user_id' INTEGER, 'is_last_upload_file_of_this_Array' BOOL, 'chunk_position' INTEGER, 'chunk_unique_number' INTEGER, 'chunks_length' LONG, 'status' INTEGER, 'uploaded_date' LONG, 'kind_of_error' INTEGER, 'is_internal_upload' BOOL, 'is_not_necessary_check_if_exist' BOOL, 'task_identifier' INTEGER)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table uploads_offline");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'shared' ('id' INTEGER PRIMARY KEY, 'file_source' INTEGER, 'item_source' INTEGER, 'share_type' INTEGER, 'share_with' VARCHAR, 'path' VARCHAR, 'permissions' INTEGER, 'shared_date' LONG, 'expiration_date' LONG, 'token' VARCHAR, 'share_with_display_name' VARCHAR, 'is_directory' BOOL, 'user_id' INTEGER, 'id_remote_shared' INTEGER, 'name' VARCHAR, 'url' VARCHAR)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table shared");
        }

        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'cookies_storage' ('id' INTEGER PRIMARY KEY, 'cookie' BLOB, 'user_id' INTEGER)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table cookies_storage");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'providing_files' ('id' INTEGER PRIMARY KEY, 'file_path' VARCHAR, 'user_id' INTEGER)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table cookies_storage");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'capabilities' ('id' INTEGER PRIMARY KEY, 'id_user' INTEGER, 'version_major' INTEGER, 'version_minor' INTEGER, 'version_micro' INTEGER, 'version_string' VARCHAR, 'version_edition' VARCHAR, 'core_poll_intervall' INTEGER, 'is_files_sharing_api_enabled' BOOL, 'is_files_sharing_share_link_enabled' BOOL, 'is_files_sharing_password_enforced_enabled' BOOL, 'is_files_sharing_expire_date_by_default_enabled' BOOL, 'is_files_sharing_expire_date_enforce_enabled' BOOL, 'files_sharing_expire_date_days_number' INTEGER, 'is_files_sharing_allow_user_send_mail_notification_about_share_link_enabled' BOOL, 'is_files_sharing_allow_public_uploads_enabled' BOOL, 'is_files_sharing_allow_user_send_mail_notification_about_other_users_enabled' BOOL, 'is_files_sharing_re_sharing_enabled' BOOL, 'is_files_sharing_allow_user_send_shares_to_other_servers_enabled' BOOL, 'is_files_sharing_allow_user_receive_shares_to_other_servers_enabled' BOOL, 'is_file_big_file_chunking_enabled' BOOL, 'is_file_undelete_enabled' BOOL, 'is_file_versioning_enabled' BOOL,  'is_files_sharing_allow_user_create_multiple_public_links_enabled' BOOL, 'is_files_sharing_supports_upload_only_enabled' BOOL)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table capabilities");
        }
        
    }];    
}


/*
 * Insert version of the database
 * @version -> database version
 */

+ (void) insertVersionToDataBase:(int) version {
    
    __block BOOL hasRow = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;

    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as NUM from db_version"];
        while ([rs next]) {
            int num = [rs intForColumn:@"NUM"];
            if (num>0) {
                 hasRow = YES;
            }
        }
    }];
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        if (hasRow) {
            correctQuery = [db executeUpdate:@"UPDATE db_version SET version=?", [NSNumber numberWithInt:version]];
        } else {
            correctQuery = [db executeUpdate:@"INSERT INTO db_version(version) Values(?)", [NSNumber numberWithInt:version]];
        }
        
        if (!correctQuery) {
            DLog(@"Error in insertVersionToDataBase");
        }
        
    }];
}

/*
 * Update show help guide
 * @showHelp -> value YES,NO
 */

+ (void) updateShowHelpGuide:(BOOL) newValue {
   
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE db_version SET show_help_guide=? ",[NSNumber numberWithBool:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error update show help guide");
        }
        
    }];
     DLog(@"Se ha actualizado helpGuide a:%d",newValue);
}

/*
* Method that remove a specific table
* @table -> table to remove
*/
+(void) removeTable:(NSString *) table {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        NSString *sqlString = [NSString stringWithFormat:@"drop table if exists %@;", table];
        
        correctQuery = [db executeUpdate:sqlString];
        
        if (!correctQuery) {
            DLog(@"Error in remove Table");
        }
        
    }];
}

/*
 * This method return if local_folder column exist or not 
 */
+(BOOL) isLocalFolderExistOnFiles {
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(local_folder) FROM files"];
        while ([rs next]) {
            
            output = YES;
        }
    }];
    
    return output;
}

/*
 * This method return the dataBase version
 */

+(int) getDatabaseVersion {
    
    DLog(@"getDatabaseVersion");
    
    __block int output = -1;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT version FROM db_version LIMIT 1"];
        
        while ([rs next]) {
            output = [rs intForColumn:@"version"];
        }
        
        [rs close];
    }];

    DLog(@"DataBase Version is: %d", output);
    return output;
}

/*
 * This method return the show help guide
 */

+(BOOL) getShowHelpGuide {
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT show_help_guide FROM db_version LIMIT 1"];
        
        while ([rs next]) {
            output = [rs boolForColumn:@"show_help_guide"];
        }
        
       [rs close];
    }];
    
    DLog(@"getShowHelpGuide: %d", output);
    return output;
}


/*
 * Method that make the update the version of the dataBase
 * If the app detect dataBase version 1 launch this method
 * The change is adding the etag column in table files.
 */

+ (void) updateDBVersion1To2 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD etag LONG"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table files1");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD is_root_folder BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table files2");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD etag LONG"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table files_backup1");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD is_root_folder BOOL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table files_backup2");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD storage_occupied LONG NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table users1");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD storage LONG NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version between 1 and 2 table users2");
        }
    }];
}

/*
 * This method update the version of the dataBase with version 2 to version 3
 * New changes:
 *  - In users table new field is_server_chunk (BOOL NOT NULL DEFAULT 0)
 */
+ (void) updateDBVersion2To3 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD is_server_chunk BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 2 to 3");
        }
    }];
}

/*
 * This method update the version of the dataBase with version 2 to version 3
 * New changes:
 *  - In users table new field is_necessary_update (BOOL NOT NULL DEFAULT 0)
 */
+ (void) updateDBVersion3To4 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD is_necessary_update BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 3 to 4 table files");
        }

        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD is_necessary_update BOOL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 3 to 4 table files_backup");
        }
    }];
}

/*
 * This method update the version of the dataBase with version 4 to version 5
 * New changes:
 * Shared API Support:
 * files table: shared_by_link (Boolean) & shared_by_user (Boolean) & shared_by_group (Boolean) & public_link (String) fields
 * files_backup table: shared_by_link (Boolean) & shared_by_user (Boolean) & shared_by_group (Boolean) & public_link (String) fields
 *
 * Remove is_server_chunk in Users table
 */
+ (void) updateDBVersion4To5 {

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //Add shared_file_source in files table
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD shared_file_source INTEGER NOT NULL DEFAULT 0"];
        
        if (!correctQuery) {
            DLog(@"Error update version 4 to 5 table files");
        }
        
        //Add shared_file_source in files_backup table
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD shared_file_source INTEGER"];
        if (!correctQuery) {
            DLog(@"Error update version 4 to 5 table files_backup");
        }
        
        //Remove is_server_chunk in users table
        
        //1.- Create a temporal table
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users_backup' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'username' VARCHAR, 'password' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users_backup");
        }
     
        //2.- Copy the information from old table to temporal table
        correctQuery = [db executeUpdate:@"INSERT INTO users_backup SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage FROM users"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in users_backup");
        }
        
        //3.- Delete the old table
        correctQuery = [db executeUpdate:@"DROP TABLE users"];
        if (!correctQuery) {
            DLog(@"Error in delete users table");
        }
        
        //4. Create new table users
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'username' VARCHAR, 'password' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users");
        }
        
        //5.- Copy the information from backup users table to new users table
        correctQuery = [db executeUpdate:@"INSERT INTO users SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage FROM users_backup"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in new users table");
        }
        
        //6.- Drop backup users table
        correctQuery = [db executeUpdate:@"DROP TABLE users_backup"];
        if (!correctQuery) {
            DLog(@"Error in delete users_backup table");
        }
        
        //7.- Add column has_share_api_support
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD has_share_api_support INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error in alter users table adding column has_share_api_support");
        }

        //Remove is_chunks_upload in uploads_offline table
        
        //1.- Create a temporal table of uploads_offline table
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'uploads_offline_backup' ('id' INTEGER PRIMARY KEY, 'origin_path' VARCHAR, 'destiny_folder' VARCHAR, 'upload_filename' VARCHAR, 'estimate_length' LONG, 'user_id' INTEGER, 'is_last_upload_file_of_this_Array' BOOL, 'chunk_position' INTEGER, 'chunk_unique_number' INTEGER, 'chunks_length' LONG, 'status' INTEGER, 'uploaded_date' LONG, 'kind_of_error' INTEGER, 'is_internal_upload' BOOL, 'is_not_necessary_check_if_exist' BOOL)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table uploads_offline_backup");
        }
        
        //2.- Copy the information from old table to temporal table
        correctQuery = [db executeUpdate:@"INSERT INTO uploads_offline_backup SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist FROM uploads_offline"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in uploads_offline_backup");
        }
        
        //3.- Delete the old table
        correctQuery = [db executeUpdate:@"DROP TABLE uploads_offline"];
        if (!correctQuery) {
            DLog(@"Error in delete users uploads_offline");
        }

        //4. Create new table users
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'uploads_offline' ('id' INTEGER PRIMARY KEY, 'origin_path' VARCHAR, 'destiny_folder' VARCHAR, 'upload_filename' VARCHAR, 'estimate_length' LONG, 'user_id' INTEGER, 'is_last_upload_file_of_this_Array' BOOL, 'chunk_position' INTEGER, 'chunk_unique_number' INTEGER, 'chunks_length' LONG, 'status' INTEGER, 'uploaded_date' LONG, 'kind_of_error' INTEGER, 'is_internal_upload' BOOL, 'is_not_necessary_check_if_exist' BOOL)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase new table uploads_offline");
        }
        
        //5.- Copy the information from backup uploads_offline table to new uploads_offline table
        correctQuery = [db executeUpdate:@"INSERT INTO uploads_offline SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist FROM uploads_offline_backup"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in uploads_offline");
        }
        
        //6.- Drop backup uploads_offline_backup table
        correctQuery = [db executeUpdate:@"DROP TABLE uploads_offline_backup"];
        if (!correctQuery) {
            DLog(@"Error in delete uploads_offline_backup table");
        }
    }];
}


///-----------------------------------
/// @name Update Database version with 5 version to 6 version
///-----------------------------------

/**
 * Changes: 
 *
 * 1.- Fix the problems in previous versions with orphan files and folders
 *
 */
+ (void) updateDBVersion5To6 {

    __block NSMutableArray *zombieFolders = [NSMutableArray new];
    __block NSMutableArray *zombieFiles = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_id NOT IN (SELECT id FROM files) AND file_id >0"];
        while ([rs next]) {
            
            FileDto *file = [FileDto new];
            
            file.idFile = [rs intForColumn:@"id"];
            file.isDirectory = [rs intForColumn:@"is_directory"];
            
            if (file.isDirectory) {
                [zombieFolders addObject:file];
            } else {
                [zombieFiles addObject:file];
            }
            
        }
        [rs close];
    }];
    
    //Check each folder and delete its offspring
    for (FileDto *file in zombieFolders) {
        [ManageFilesDB deleteOffspringOfThisFolder:file];
    }
    
    //Delete the zombie files
    for (FileDto *file in zombieFiles) {
        [ManageFilesDB deleteFileByIdFile:file.idFile];
    }
}




///-----------------------------------
/// @name Update Database version with 6 version to 7 version
///-----------------------------------

/**
 * Changes:
 *
 * Has been included a new field on the uploads_offline file for to store the task identifier: task_identifier field
 *
 */
+ (void) updateDBVersion6To7 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE uploads_offline ADD task_identifier INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 6 to 7 table uploads_offline");
        }
    }];    
}


///-----------------------------------
/// @name Update Database version with 7 version to 8 version
///-----------------------------------

/**
 * Changes:
 *
 * Has been included a new field for store the permissions of the file
 *
 */
+ (void) updateDBVersion7To8 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD permissions VARCHAR NOT NULL DEFAULT ''"];
        if (!correctQuery) {
            DLog(@"Error update version 7 to 8 table files");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD permissions VARCHAR NOT NULL DEFAULT ''"];
        if (!correctQuery) {
            DLog(@"Error update version 7 to 8 table files");
        }
    }];
}

///-----------------------------------
/// @name Update Database version with 8 version to 9 version
///-----------------------------------

/**
 * Changes:
 *
 * Has been included a new field has_cookies_support for store if the server of the user support cookies
 * Has been included a new filed for store task identifier for Downloads in background
 *
 */
+ (void) updateDBVersion8To9 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD task_identifier INTEGER NOT NULL DEFAULT -1"];
        if (!correctQuery) {
            DLog(@"Error update version 8 to 9 table files");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD task_identifier INTEGER"];
        if (!correctQuery) {
            DLog(@"Error update version 8 to 9 table files");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD has_cookies_support INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error in alter users table adding column has_cookies_support");
        }
    }];

}

///-----------------------------------
/// @name Update Database version with 9 version to 10
///-----------------------------------

/**
 * Changes:
 *
 * Migrate the current username and password stored in users table to the new keychain
 * Do a backup of the users table in users_backup table
 * Remove users table
 * Create a new users table without username and password
 * Migrate from users_backup table to new users table
 */
+ (void) updateDBVersion9To10{
    
    //1.- Migrate the current username and passworkd stored in user table to the new keychain
    
    NSArray *currentUsers = [NSArray arrayWithArray:[ManageUsersDB getAllOldUsersUntilVersion10]];
    
    for (UserDto *user in currentUsers) {
        if (![OCKeychain storeCredentialsOfUserFromDBVersion9To10:user]){
            DLog(@"Failed setting credentials");
        }
        
    }
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    //2.- Remove username and password fields in table users
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        
        //2.1.- Create a backup users table
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users_backup' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'username' VARCHAR, 'password' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users_backup");
        }
        
        //2.2.- Copy the information from old table to temporal table
        correctQuery = [db executeUpdate:@"INSERT INTO users_backup SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support FROM users"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in users_backup");
        }
        
        //2.3.- Delete the old table
        correctQuery = [db executeUpdate:@"DROP TABLE users"];
        if (!correctQuery) {
            DLog(@"Error in delete users table");
        }
        
        //2.4. Create new table users
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users");
        }
        
        //2.5.- Copy the information from backup users table to new users table
        correctQuery = [db executeUpdate:@"INSERT INTO users SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_cookies_support FROM users_backup"];
        if (!correctQuery) {
            DLog(@"Error in insertUsers in new users table");
        }
        
        //2.6.- Drop backup users table
        correctQuery = [db executeUpdate:@"DROP TABLE users_backup"];
        if (!correctQuery) {
            DLog(@"Error in delete users_backup table");
        }
        
        
    }];
    
}

///-----------------------------------
/// @name Update Database version with 10 version to 11
///-----------------------------------

/**
 * Changes:
 *
 * Use the ETAG as a string.To do that we have to remove the current etag and convert all the etags to HEX from long (decimal).
 *
 */
+ (void) updateDBVersion10To11 {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    NSMutableArray *listOfIds = [NSMutableArray new];
    NSMutableArray *listOfEtags = [NSMutableArray new];
    
    
    //1. Obtain the list of etags to be updated
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_download = 1 OR is_download = 2 OR is_download = 3 OR is_favorite = 1"];
        while ([rs next]) {

            [listOfIds addObject:[NSNumber numberWithInt:[rs intForColumn:@"id"]]];
            [listOfEtags addObject:[NSNumber numberWithLongLong:[rs longLongIntForColumn:@"etag"]]];
    
        }
        [rs close];
    }];
    
    //2. Create change the etag from long to varchar
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //2.1.- Create a backup files table
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files_backup_etag' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL NOT NULL DEFAULT 0, 'is_necessary_update' BOOL NOT NULL DEFAULT 0, 'shared_file_source' INTEGER NOT NULL DEFAULT 0, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER NOT NULL DEFAULT -1)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files_backup_etag");
        }
        
        //2.2.- Copy the information from old table to temporal table
        correctQuery = [db executeUpdate:@"INSERT INTO files_backup_etag SELECT id, file_path, file_name, user_id, is_directory, is_download, file_id, size, date, is_favorite, '', is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier FROM files"];
        if (!correctQuery) {
            DLog(@"Error in insertfiles in files_backup_etag");
        }
        
        //2.3.- Delete the old table
        correctQuery = [db executeUpdate:@"DROP TABLE files"];
        if (!correctQuery) {
            DLog(@"Error in delete files table");
        }
        
        //2.4. Create new table files
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL NOT NULL DEFAULT 0, 'is_necessary_update' BOOL NOT NULL DEFAULT 0, 'shared_file_source' INTEGER NOT NULL DEFAULT 0, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER NOT NULL DEFAULT -1)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files");
        }
        
        //2.5.- Copy the information from backup files table to new files table
        correctQuery = [db executeUpdate:@"INSERT INTO files SELECT id, file_path, file_name, user_id, is_directory, is_download, file_id, size, date, is_favorite, '', is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier FROM files_backup_etag"];
        if (!correctQuery) {
            DLog(@"Error in insert files in new files table");
        }
        
        //2.6.- Drop backup users table
        correctQuery = [db executeUpdate:@"DROP TABLE files_backup_etag"];
        if (!correctQuery) {
            DLog(@"Error in delete files_backup_etag table");
        }
    }];
    
    //3. Drop the files backup table and create the new one. The data on that table it is not important
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //2.3.- Delete the old table
        correctQuery = [db executeUpdate:@"DROP TABLE files_backup"];
        if (!correctQuery) {
            DLog(@"Error in delete files_backup table");
        }
        
        //2.4. Create new table files
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files_backup' ('id' INTEGER, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL, 'is_necessary_update' BOOL, 'shared_file_source' INTEGER, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER)"];
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files_backup");
        }
        
    }];
    
    //4. Put again the etag in Hex format
    for (int i = 0; i < [listOfEtags count]; i++) {
        
        NSNumber *currentEtag = [listOfEtags objectAtIndex:i];
        NSNumber *currentId = [listOfIds objectAtIndex:i];
        
        NSString *currentHexEtag = [NSString stringWithFormat:@"%llX", [currentEtag longLongValue]];
        currentHexEtag = [currentHexEtag lowercaseString];
        [ManageFilesDB updateEtagOfFileDtoByid:[currentId intValue] andNewEtag:currentHexEtag];
    }

}


///-----------------------------------
/// @name Update Database version with 11 version to 12
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new fields to instant uploads options
 * Alter files and files_backup tables, added new field for store the providing_file_id of the file
 *
 */
+ (void) updateDBVersion11To12{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //Instant uploads
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD instant_upload BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 table users instant_upload");
        }
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD path_instant_upload VARCHAR"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 table users path_instant_upload");
        }
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD only_wifi_instant_upload BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 table users only_wifi_instant_upload");
        }
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD date_instant_upload LONG"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 table users date_instant_upload");
        }
        
        //Document provider
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD providing_file_id INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 adding providing_file_id field to files table");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD providing_file_id INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 11 to 12 adding providing_file_id field to files_backup table");
        }
        
    }];
    
}

///-----------------------------------
/// @name Update Database version with 12 version to 13
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new fields to forbidden characters support and to redirected url.
 *
 */
+ (void) updateDBVersion12To13{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD has_forbidden_characters_support INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 12 to 13 table users instant_upload");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD url_redirected VARCHAR"];
        if (!correctQuery) {
            DLog(@"Error update version 12 to 13 table users url_redirected");
        }
        
    }];
}

///-----------------------------------
/// @name Update Database version with 13 version to 14
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new fields to forbidden characters support and to redirected url.
 *
 */
+ (void) updateDBVersion13To14{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE db_version ADD show_help_guide BOOL NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 13 to 14 table db_version show_help_guide");
        }
        
    }];
}

///-----------------------------------
/// @name Update Database version with 14 version to 15
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new field to store that the server has sharee API support.
 *
 */
+ (void) updateDBVersion14To15{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD has_sharee_api_support INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 14 to 15 table users has_sharee_api_support");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD has_capabilities_support INTEGER NOT NULL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 14 to 15 table users has_capabilities_support");
        }
        
    }];

    
}

///-----------------------------------
/// @name Update Database version with 15 version to 16
///-----------------------------------

/**
 * Changes:
 *
 * Alter passcode table, added new field to store if Touch ID is active or not.
 *
 */
+ (void) updateDBVersion15To16{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE passcode ADD is_touch_id BOOL DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 15 to 16 table passcode is_touch_id");
        }

    }];
    
}

///-----------------------------------
/// @name Update Database version with 16 version to 17
///-----------------------------------

/**
 * Changes:
 *
 * Alter files and files_backup table, added new field to store oc:id
 * Alter users table, added new field to store the sorting choice for showing folders/files in file list.
 *
 */
+ (void) updateDBVersion16To17{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files ADD oc_id VARCHAR NOT NULL DEFAULT ''"];
        if (!correctQuery) {
            DLog(@"Error update version 16 to 17 table files oc_id");
        }
        
        correctQuery = [db executeUpdate:@"ALTER TABLE files_backup ADD oc_id VARCHAR NOT NULL DEFAULT ''"];
        if (!correctQuery) {
            DLog(@"Error update version 16 to 17 table files_backup oc_id");
        }

        correctQuery = [db executeUpdate:@"ALTER TABLE users ADD sorting_type INTEGER DEFAULT 0"];
        if (!correctQuery) {
            DLog(@"Error update version 16 to 17 table users sorting_type");
        }
        
    }];
    
}


///-----------------------------------
/// @name Update Database version with 17 version to 18
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, adds new field to track user background Instant Upload preference
 */
+ (void) updateDBVersion17To18 {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    // Fetch parameters needed for migration
    
    __block long lastDateInstantUpload;
    __block BOOL defaultBackgroundInstantUploadValue;
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT instant_upload, date_instant_upload FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            defaultBackgroundInstantUploadValue = [rs boolForColumn:@"instant_upload"];
            lastDateInstantUpload = [rs longForColumn:@"date_instant_upload"];
        }
    }];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL dbOperationSuccessful;
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD background_instant_upload INTEGER"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 17 to 18 table users add column background_instant_upload");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET background_instant_upload=?", @(defaultBackgroundInstantUploadValue)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 17 to 18 table set background_instant_upload value");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD timestamp_last_instant_upload DOUBLE"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 17 to 18 table users add column timestamp_last_instant_upload");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET timestamp_last_instant_upload=?", @(lastDateInstantUpload)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 17 to 18 table set timestamp_last_instant_upload value");
        }
        
        // Remove date_instant_upload column from users table
        
        //1.- Create a temporary users table users_temp
        
        dbOperationSuccessful = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users_temp' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_sharee_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'has_capabilities_support' INTEGER NOT NULL DEFAULT 0, 'instant_upload' BOOL NOT NULL DEFAULT 0, 'background_instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'timestamp_last_instant_upload' DOUBLE, 'url_redirected' VARCHAR, 'sorting_type' INTEGER NOT NULL DEFAULT 0)"];
        if (!dbOperationSuccessful) {
            DLog(@"Error creating database table users_temp, timestamp migration failed");
        }
        
        //2.- Copy the information from users to users_temp
        dbOperationSuccessful = [db executeUpdate:@"INSERT INTO users_temp SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users"];
        if (!dbOperationSuccessful) {
            DLog(@"Error backing up users table in users_temp");
        }
        
        //3.- Delete the old users table
        dbOperationSuccessful = [db executeUpdate:@"DROP TABLE users"];
        if (!dbOperationSuccessful) {
            DLog(@"Error deleting table users");
        }
        
        //4. Create new table users
        dbOperationSuccessful = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_sharee_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'has_capabilities_support' INTEGER NOT NULL DEFAULT 0, 'instant_upload' BOOL NOT NULL DEFAULT 0, 'background_instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'timestamp_last_instant_upload' DOUBLE, 'url_redirected' VARCHAR, 'sorting_type' INTEGER NOT NULL DEFAULT 0)"];
        if (!dbOperationSuccessful) {
            DLog(@"Error creating table users");
        }
        
        //5.- Copy the information from users_temp to users
        dbOperationSuccessful = [db executeUpdate:@"INSERT INTO users SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload, url_redirected, sorting_type FROM users_temp"];
        if (!dbOperationSuccessful) {
            DLog(@"Error migrating data from users_temp to users");
        }
        
        //6.- Drop user_temp table
        dbOperationSuccessful = [db executeUpdate:@"DROP TABLE users_temp"];
        if (!dbOperationSuccessful) {
            DLog(@"Error dropping table users_temp");
        }
        
    }];
}

///-----------------------------------
/// @name Update Database version with 18 version to 19
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, adds new field to track user video and image Instant Upload preferences, copies user instant upload preference to new image and video instant upload preference fields, deletes old instant upload preference field, adds new image and video last instant upload timestamp fields, migrates old instant upload timestamp field to new timestamp fields, deletes old instant upload timestamp field.
 */
+ (void) updateDBVersion18To19 {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    // Fetch parameters needed for migration
    
    __block BOOL instantUploadDefaultValue;
    __block double lastInstantUploadTimestamp;
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT instant_upload, timestamp_last_instant_upload FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            instantUploadDefaultValue = [rs boolForColumn:@"instant_upload"];
            lastInstantUploadTimestamp = [rs doubleForColumn:@"timestamp_last_instant_upload"];
        }
    }];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL dbOperationSuccessful;
        

        //Instant uploads separate in video and image
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD image_instant_upload INTEGER"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users add column image_instant_upload");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD video_instant_upload INTEGER"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users add column video_instant_upload");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD timestamp_last_instant_upload_image DOUBLE"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users add column timestamp_last_instant_upload_image");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD timestamp_last_instant_upload_video DOUBLE"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users add column timestamp_last_instant_upload_video");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET image_instant_upload=?", @(instantUploadDefaultValue)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users set image_instant_upload value");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET video_instant_upload=?", @(instantUploadDefaultValue)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users set video_instant_upload value");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET timestamp_last_instant_upload_image=?", @(lastInstantUploadTimestamp)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users set timestamp_last_instant_upload_image value");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"UPDATE users SET timestamp_last_instant_upload_video=?", @(lastInstantUploadTimestamp)];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 18 to 19 table users set timestamp_last_instant_upload_video value");
        }
        
        // Remove instant_upload column from users table
        
        //1.- Create a temporary users table users_temp
        
        dbOperationSuccessful = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users_temp' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_sharee_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'has_capabilities_support' INTEGER NOT NULL DEFAULT 0, 'image_instant_upload' BOOL NOT NULL DEFAULT 0, 'video_instant_upload' BOOL NOT NULL DEFAULT 0, 'background_instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'timestamp_last_instant_upload_image' DOUBLE, 'timestamp_last_instant_upload_video' DOUBLE, 'url_redirected' VARCHAR, 'sorting_type' INTEGER NOT NULL DEFAULT 0)"];
        if (!dbOperationSuccessful) {
            DLog(@"Error creating database table users_temp, timestamp migration failed");
        }
        
        //2.- Copy the information from users to users_temp
        dbOperationSuccessful = [db executeUpdate:@"INSERT INTO users_temp SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, image_instant_upload, video_instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload_image, timestamp_last_instant_upload_video, url_redirected, sorting_type FROM users"];
        if (!dbOperationSuccessful) {
            DLog(@"Error backing up users table in users_temp");
        }
        
        //3.- Delete the old users table
        dbOperationSuccessful = [db executeUpdate:@"DROP TABLE users"];
        if (!dbOperationSuccessful) {
            DLog(@"Error deleting table users");
        }
        
        //4. Create new table users
        dbOperationSuccessful = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_sharee_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'has_capabilities_support' INTEGER NOT NULL DEFAULT 0, 'image_instant_upload' BOOL NOT NULL DEFAULT 0, 'video_instant_upload' BOOL NOT NULL DEFAULT 0, 'background_instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'timestamp_last_instant_upload_image' DOUBLE, 'timestamp_last_instant_upload_video' DOUBLE, 'url_redirected' VARCHAR, 'sorting_type' INTEGER NOT NULL DEFAULT 0)"];
        if (!dbOperationSuccessful) {
            DLog(@"Error creating table users");
        }
        
        //5.- Copy the information from users_temp to users
        dbOperationSuccessful = [db executeUpdate:@"INSERT INTO users SELECT id, url, ssl, activeaccount, storage_occupied, storage, has_share_api_support, has_sharee_api_support, has_cookies_support, has_forbidden_characters_support, has_capabilities_support, image_instant_upload, video_instant_upload, background_instant_upload, path_instant_upload, only_wifi_instant_upload, timestamp_last_instant_upload_image, timestamp_last_instant_upload_video, url_redirected, sorting_type FROM users_temp"];
        
        if (!dbOperationSuccessful) {
            DLog(@"Error migrating data from users_temp to users");
        }
        
        //6.- Drop user_temp table
        dbOperationSuccessful = [db executeUpdate:@"DROP TABLE users_temp"];
        if (!dbOperationSuccessful) {
            DLog(@"Error dropping table users_temp");
        }
        
    }];
    
}


///-----------------------------------
/// @name Update Database version with 19 version to 20
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, adds new field predefined url
 * Alter shared table, added new fields to store name and url
 *
 */
+ (void) updateDBVersion19To20 {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL dbOperationSuccessful;
        
        //new predefined URL variable to set after we force update existing urls
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE users ADD predefined_url VARCHAR"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 19 to 20 table users add column predefined_url");
        }

        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE shared ADD name VARCHAR NOT NULL DEFAULT ''"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 19 to 20 table shared 'name' ");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE shared ADD url VARCHAR NOT NULL DEFAULT ''"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 19 to 20 table shared 'url' ");
        }
        
    }];
    
}

+ (void) updateDBVersion20To21 {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL dbOperationSuccessful;
        
        dbOperationSuccessful =[db executeUpdate:@"ALTER TABLE capabilities ADD is_files_sharing_allow_user_create_multiple_public_links_enabled BOOL NOT NULL DEFAULT 0"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 20 to 21 table capabilities add column is_files_sharing_allow_user_create_multiple_public_links_enabled");
        }
        
        dbOperationSuccessful = [db executeUpdate:@"ALTER TABLE capabilities ADD is_files_sharing_supports_upload_only_enabled BOOL NOT NULL DEFAULT 0"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 20 to 21 table capabilities is_files_sharing_supports_upload_only_enabled ");
        }
        
    }];

}



+ (void) updateDBVersion21To22 {
        
    //1.- Migrate the current password stored in keychain

    [OCKeychain updateAllKeychainItemsFromDBVersion21To22ToStoreCredentialsDtoAsValueAndAuthenticationType];
    

    //2.- Alter users table to add more supported share options
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL dbOperationSuccessful;
        
        dbOperationSuccessful =[db executeUpdate:@"ALTER TABLE users ADD has_fed_shares_option_share_support INTEGER NOT NULL DEFAULT 0"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 21 to 22 table users add column has_fed_shares_option_share_support");
        }
        
        dbOperationSuccessful =[db executeUpdate:@"ALTER TABLE users ADD has_public_share_link_option_name_support INTEGER NOT NULL DEFAULT 0"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 21 to 22 table users add column has_public_share_link_option_name_support");
        }
        
        dbOperationSuccessful =[db executeUpdate:@"ALTER TABLE users ADD has_public_share_link_option_upload_only_support INTEGER NOT NULL DEFAULT 0"];
        if (!dbOperationSuccessful) {
            DLog(@"Error update version 21 to 22 table users add column has_public_share_link_option_upload_only_support");
        }
        
    }];
    
    
    
}


@end
