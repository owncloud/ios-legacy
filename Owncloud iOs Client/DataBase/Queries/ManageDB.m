//
//  ManageDB.m
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

#import "ManageDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "ManageFilesDB.h"
#import "ManageUsersDB.h"
#import "OCKeychain.h"
#import "UserDto.h"

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
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0, 'has_share_api_support' INTEGER NOT NULL DEFAULT 0, 'has_cookies_support' INTEGER NOT NULL DEFAULT 0, 'has_forbidden_characters_support' INTEGER NOT NULL DEFAULT 0, 'instant_upload' BOOL NOT NULL DEFAULT 0, 'path_instant_upload' VARCHAR, 'only_wifi_instant_upload' BOOL NOT NULL DEFAULT 0, 'date_instant_upload' LONG, 'url_redirected' VARCHAR )"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table users");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL NOT NULL DEFAULT 0, 'is_necessary_update' BOOL NOT NULL DEFAULT 0, 'shared_file_source' INTEGER NOT NULL DEFAULT 0, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER NOT NULL DEFAULT -1, 'providing_file_id' INTEGER NOT NULL DEFAULT 0)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'files_backup' ('id' INTEGER, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' VARCHAR NOT NULL DEFAULT '', 'is_root_folder' BOOL, 'is_necessary_update' BOOL, 'shared_file_source' INTEGER, 'permissions' VARCHAR NOT NULL DEFAULT '', 'task_identifier' INTEGER, 'providing_file_id' INTEGER NOT NULL DEFAULT 0)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table files_backup");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'passcode' ('id' INTEGER PRIMARY KEY, 'passcode' VARCHAR)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table passcode");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'certificates' ('id' INTEGER PRIMARY KEY, 'certificate_location' VARCHAR)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table certificates");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'db_version' ('id' INTEGER PRIMARY KEY, 'version' INTEGER)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table db_version");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'uploads_offline' ('id' INTEGER PRIMARY KEY, 'origin_path' VARCHAR, 'destiny_folder' VARCHAR, 'upload_filename' VARCHAR, 'estimate_length' LONG, 'user_id' INTEGER, 'is_last_upload_file_of_this_Array' BOOL, 'chunk_position' INTEGER, 'chunk_unique_number' INTEGER, 'chunks_length' LONG, 'status' INTEGER, 'uploaded_date' LONG, 'kind_of_error' INTEGER, 'is_internal_upload' BOOL, 'is_not_necessary_check_if_exist' BOOL, 'task_identifier' INTEGER)"];
        
        if (!correctQuery) {
            DLog(@"Error in createDataBase table uploads_offline");
        }
        
        correctQuery = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS 'shared' ('id' INTEGER PRIMARY KEY, 'file_source' INTEGER, 'item_source' INTEGER, 'share_type' INTEGER, 'share_with' VARCHAR, 'path' VARCHAR, 'permissions' INTEGER, 'shared_date' LONG, 'expiration_date' LONG, 'token' VARCHAR, 'share_with_display_name' VARCHAR, 'is_directory' BOOL, 'user_id' INTEGER, 'id_remote_shared' INTEGER)"];
        
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
        
    }];    
}

/*
 * Delete table of database version
 */
+ (void)clearTableDbVersion {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
       correctQuery = [db executeUpdate:@"DELETE FROM db_version"];
        
        if (!correctQuery) {
            DLog(@"Error in clearTableDbVersion");
        }
    }];
    
}

/*
 * Insert version of the database
 * @version -> database version
 */

+ (void) insertVersionToDataBase:(int) version {
    
    [self clearTableDbVersion];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO db_version(version) Values(?)", [NSNumber numberWithInt:version]];
        
        if (!correctQuery) {
            DLog(@"Error in insertVersionToDataBase");
        }
        
    }];
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
 * Migrate the current usersname and password stored in users table to the new keychain
 * Do a backup of the users table in users_backup table
 * Remove users table
 * Create a new users table without username and password
 * Migrate from users_backup table to new users table
 */
+ (void) updateDBVersion9To10{
    
    //1.- Migrate the current username and passworkd stored in user table to the new keychain
    
    NSArray *currentUsers = [NSArray arrayWithArray:[ManageUsersDB getAllOldUsersUntilVersion10]];
    
    for (UserDto *user in currentUsers) {
         NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];
        if (![OCKeychain setCredentialsById:idString withUsername:user.username andPassword:user.password]){
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

@end
