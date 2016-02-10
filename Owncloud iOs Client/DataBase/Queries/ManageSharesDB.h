//
//  ManageSharesDB.h
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

#import <Foundation/Foundation.h>


@class OCSharedDto;
@class UserDto;
@class FileDto;

@interface ManageSharesDB : NSObject

///-----------------------------------
/// @name Insert Share List in Shares Table
///-----------------------------------

/**
 * Method that insert a list of Share objects into DabaBase
 *
 * @param elements -> NSMutableArray (Array of share objects)
 */
+ (void) insertSharedList:(NSArray *)elements;


///-----------------------------------
/// @name Delete All Shares of User
///-----------------------------------

/**
 * Method that delete all shares element of a specific user
 *
 * @param idUser -> NSInteger
 */

+ (void) deleteAllSharesOfUser:(NSInteger)idUser;


///-----------------------------------
/// @name Get Shares of Path
///-----------------------------------

/**
 * Get the shared items of a specific path of a specific user
 *
 * @param path -> NSString
 * @param idUser -> NSInteger
 *
 * @return NSMutableArray
 *
 */
+ (NSMutableArray*) getSharesByFolder:(FileDto *) folder;

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
+ (NSMutableArray*) getSharesByFolderPath:(NSString *) path;

///-----------------------------------
/// @name Get Shares From User And Group By Path
///-----------------------------------

/**
 * Get the shared items of a specific path
 *
 * @param path -> NSString
 *
 * @return NSMutableArray
 *
 */
+ (NSMutableArray*) getSharesFromUserAndGroupByPath:(NSString *) path;

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
+ (NSArray*) getAllSharesforUser:(NSInteger)idUser;


///-----------------------------------
///
/// @name getAllSharesByUserAndSharedType
///-----------------------------------

/**
 * Method to return all shares that have a user of shared type
 *
 * @param idUser -> NSInteger
 * @param sharedType -> NSInteger
 *
 */
+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser anTypeOfShare: (NSInteger) shareType;


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
+ (NSMutableArray*) getSharesBySharedFileSource:(NSInteger) sharedFileSource forUser:(NSInteger)idUser;


///-----------------------------------
/// @name getAllSharesByUser
///-----------------------------------

/**
 * Method to return all shares that have a user
 *
 * @param idUser -> NSInteger
 *
 */
+ (NSMutableArray *) getAllSharesByUser:(NSInteger)idUser;

///-----------------------------------
/// @name Delete a list of shared
///-----------------------------------

/**
 * Method that delete all shares element of a specific user
 *
 * @param listOfRemoved -> NSArray of OCSharedDto
 */
+ (void) deleteLSharedByList:(NSArray *) listOfRemoved;


///-----------------------------------
/// @name deleteSharedNotRelatedByUser
///-----------------------------------

/**
 * Method that delete all shares that not appear on the file list (old shared that does not exist)
 *
 * @param user -> UserDto
 */
+ (void) deleteSharedNotRelatedByUser:(UserDto *) user;

/**
 * This method return a OCSharedDto with equal file dto path, if
 * is not catched this method return nil
 *
 * @param path -> NSString
 *
 * @return OCSharedDto
 *
 */
+ (OCSharedDto *) getSharedEqualWithFileDtoPath:(NSString*)path;

///-----------------------------------
/// @name getTheOCShareByFileDto
///-----------------------------------

/**
 * Method that to get the OCSharedDto by a filedto and the type of share
 *
 * @param file -> FileDto
 * @param shareType -> NSInteger
 * @param user -> UserDto
 *
 * @return OCSharedDto
 */
+ (OCSharedDto *) getTheOCShareByFileDto:(FileDto*)file andShareType:(NSInteger) shareType andUser:(UserDto *) user;

///-----------------------------------
/// @name updateTheRemoteSharedwithPermissions:
///-----------------------------------

/**
 * This method updates the permissions of the file
 *
 * @param idRemoteShared    -> int
 * @param permissions       -> NSInteger
 */
+ (void) updateTheRemoteShared: (NSInteger)idRemoteShared withPermissions: (NSInteger)permissions;

@end
