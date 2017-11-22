//
//  ManageDB.h
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

#import <Foundation/Foundation.h>

@interface ManageDB : NSObject

/*
 * Method that create a empty data base.
 */
+(void) createDataBase;

/*
 * Delete table of database version
 */
+ (void) insertVersionToDataBase:(int) version;

/*
 * Update show_help_guide
 */
+ (void) updateShowHelpGuide:(BOOL) newValue;

/*
 * Method that remove a specific table
 * @table -> table to remove
 */
+(void) removeTable:(NSString *) table;

/*
 * This method return if local_folder column exist or not
 */
+(BOOL) isLocalFolderExistOnFiles;

/*
 * This method return the dataBase version
 */

+(int) getDatabaseVersion;

/*
 * This method return if the show help guide should be show
 */

+(BOOL) getShowHelpGuide;

/*
 * Method that make the update the version of the dataBase
 * If the app detect dataBase version 1 launch this method
 * The change is adding the etag column in table files.
 */
+(void) updateDBVersion1To2;


/*
 * This method update the version of the dataBase with version 2 to version 3
 * New changes:
 *  - In users table new field is_server_chunk (BOOL NOT NULL DEFAULT 0)
 */
+(void)updateDBVersion2To3;

/*
 * This method update the version of the dataBase with version 3 to version 4
 * New changes:
 *  - In is_ (BOOL NOT NULL DEFAULT 0)
 */
+(void)updateDBVersion3To4;

/*
 * This method update the version of the dataBase with version 4 to version 5
 * New changes:
 * Shared API Support:
 * files table: shared_by_link (Boolean) & shared_by_user (Boolean) & shared_by_group (Boolean) & public_link (String) fields
 * files_backup table: shared_by_link (Boolean) & shared_by_user (Boolean) & shared_by_group (Boolean) & public_link (String) fields
 */
+(void)updateDBVersion4To5;

///-----------------------------------
/// @name Update Database version with 5 verstion to 6 version
///-----------------------------------

/**
 * Changes:
 *
 * 1.- Fix the problems in previous versions with Path without fathers
 *
 */
+ (void) updateDBVersion5To6;

///-----------------------------------
/// @name Update Database version with 6 verstion to 7 version
///-----------------------------------

/**
 * Changes:
 *
 * Has been included a new field on the uploads_offline file for to store the task identifier: task_identifier field
 *
 */
+ (void) updateDBVersion6To7;


///-----------------------------------
/// @name Update Database version with 7 version to 8 version
///-----------------------------------

/**
 * Changes:
 *
 * Has been included a new field for store the permissions of the file
 *
 */
+ (void) updateDBVersion7To8;

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

+ (void) updateDBVersion8To9;

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
+ (void) updateDBVersion9To10;

///-----------------------------------
/// @name Update Database version with 10 version to 11
///-----------------------------------

/**
 * Changes:
 *
 * Use the ETAG as a string.To do that we have to remove the current etag and convert all the etags to HEX from long (decimal).
 *
 */
+ (void) updateDBVersion10To11;

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
+ (void) updateDBVersion11To12;

///-----------------------------------
/// @name Update Database version with 12 version to 13
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new field to forbidden characters support, and to redirected url
 *
 */
+ (void) updateDBVersion12To13;

///-----------------------------------
/// @name Update Database version with 13 version to 14
///-----------------------------------

/**
 * Changes:
 *
 * Alter db_version table, added new field to show help guide
 *
 */
+ (void) updateDBVersion13To14;

///-----------------------------------
/// @name Update Database version with 14 version to 15
///-----------------------------------

/**
 * Changes:
 *
 * Alter users table, added new field to store that the server has sharee API support.
 *
 */
+ (void) updateDBVersion14To15;

///-----------------------------------
/// @name Update Database version with 15 version to 16
///-----------------------------------

/**
 * Changes:
 *
 * Alter passcode table, added new field to store if Touch ID is active or not.
 *
 */
+ (void) updateDBVersion15To16;

///-----------------------------------
/// @name Update Database version with 16 version to 17
///-----------------------------------

/**
 * Changes:
 *
 * Alter files and files_backup table, added new field to store oc:id
 * Alter users table, added new field to store the sorting choice for showing folders/files in file list.
 */
+ (void) updateDBVersion16To17;

/**
 * Changes:
 *
 * Alter users table, adds new field to track user background Instant Upload preference
 */
+ (void) updateDBVersion17To18;

/**
 * Changes:
 *
 * Alter users table, adds new field to track user video and image Instant Upload preferences, copies user instant upload preference to new image and video instant upload preference fields, deletes old instant upload preference field, adds new image and video last instant upload timestamp fields, migrates old instant upload timestamp field to new timestamp fields, deletes old instant upload timestamp field.
 */
+ (void) updateDBVersion18To19;


/**
 * Changes:
 *
 * Alter users table, adds new field expire to reset the user password. Designed for the update of URL between version
 */
+ (void) updateDBVersion19To20;

/**
 * Changes:
 *
 * Alter capabilities table, adds new column for capability multiple_public_links and supports_upload_only.
 */
+ (void) updateDBVersion20To21;

/**
 * Changes:
 *
 * Support version 3.7.0
 * Alter Keychain items to use credentialsDto as value instead password
 * Alter users table, added new field to store that the server has fed shares, share link option name and share link option upload only API support.
 */
+ (void) updateDBVersion21To22;



@end
