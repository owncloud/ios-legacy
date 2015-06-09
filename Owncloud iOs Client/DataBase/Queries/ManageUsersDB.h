//
//  ManageUsersDB.h
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

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"


@class UserDto;


@interface ManageUsersDB : NSObject

/*
 * Method that add user into database
 * @userDto -> userDto (Object of a user info)
 */
+(void) insertUser:(UserDto *)userDto;

/*
 * This method return the active user of the app
 */
+ (UserDto *) getActiveUser;

/*
 * This method change the password of the an user
 * @user -> user object
 */
+(void) updatePassword: (UserDto *) user;

/*
 * Method that return the user object of the idUser
 * @idUser -> id User.
 */
+ (UserDto *) getUserByIdUser:(NSInteger) idUser;

/*
 * Method that return if the user exist or not
 * @userDto -> user object
 */
+ (BOOL) isExistUser: (UserDto *) userDto;

/*
 * Method that return an array with all users
 */
+ (NSMutableArray *) getAllUsers;

/*
 * Method that return an array with all users without credentials info
 */
+ (NSMutableArray *) getAllUsersWithOutCredentialInfo;

/*
 * Method that return an array with all users.
 * This method is only used with the old structure of the table used until version 9
 * And is only used in the update database method
 */
+ (NSMutableArray *) getAllOldUsersUntilVersion10;

/*
 * Method that set a user like a active account
 * @idUser -> id user
 */
+(void) setActiveAccountByIdUser: (NSInteger) idUser;

/*
 * Method that set all acount as a no active.
 * This method is used before that set active account.
 */
+(void) setAllUsersNoActive;

/*
 * Method that select one account active automatically
 */
+(void) setActiveAccountAutomatically;

/*
 * Method that remove user data in all tables
 * @idUser -> id user
 */
+(void) removeUserAndDataByIdUser:(NSInteger)idUser;

/*
 * Method that set the user storage of a user
 */
+(void) updateStorageByUserDto:(UserDto *) user;

/*
 * Method that return last user inserted on the Database
 */
+ (UserDto *) getLastUserInserted;

//-----------------------------------
/// @name Update user by user
///-----------------------------------

/**
 * Method to update a user setting anything just sending the user
 *
 * @param UserDto -> user
 */
+ (void) updateUserByUserDto:(UserDto *) user;

//-----------------------------------
/// @name Has the Server Of the Active User Forbidden Character Support
///-----------------------------------

/**
 * Method to get YES/NO depend if the server of the active user has forbidden character support.
 *
 * @return BOOL
 */
+ (BOOL) hasTheServerOfTheActiveUserForbiddenCharactersSupport;



+ (void)updateUrlRedirected:(NSString *)newValue byUserDto:(UserDto *)user;

+ (NSString *) getUrlRedirectedByUserDto:(UserDto *)user;

@end
