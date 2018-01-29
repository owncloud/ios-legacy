//
//  UtilsCookies.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/07/14.
//

/*
 Copyright (C) 2018, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsCookies.h"
#import "UserDto.h"
#import "ManageCookiesStorageDB.h"
#import "CookiesStorageDto.h"
#import "UtilsUrls.h"
#import "UtilsFramework.h"

@implementation UtilsCookies

//-----------------------------------
/// @name setOnDBStorageCookiesByUser
///-----------------------------------

/**
 * Method set on the Database the current cookies that are on the system Cookies Storage
 *
 * @param UserDto -> user
 *
 */
+ (void) setOnDBStorageCookiesByUser:(UserDto *) user {
    //We add the cookies of that URL
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:user.url]];
    
    DLog(@"cookieStorage: %@", cookies);
    
    for (NSHTTPCookie *current in cookies) {
        
        CookiesStorageDto *newCookieStorage = [CookiesStorageDto new];
        newCookieStorage.cookie = current;
        newCookieStorage.userId = user.userId;
        
        [ManageCookiesStorageDB insertCookie:newCookieStorage];
    }
}


+ (void) setOnSystemCookieStorageDBCookiesOfUser:(UserDto *) user {
    
    NSArray *listOfCookiesStorageDto = [ManageCookiesStorageDB getCookiesByUser:user];
    
    for (CookiesStorageDto *current in listOfCookiesStorageDto) {
        DLog(@"Current cookie: %@", current.cookie);
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:current.cookie];
    }
}

#pragma mark - Delete cache HTTP
+ (void) eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}

+ (void) updateCookiesOfActiveUserInDB {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    if (app.activeUser != nil) {
        
        [self updateCookiesInDBOfUser:app.activeUser];
    }
}

+ (void) updateCookiesInDBOfUser:(UserDto *)user {
    
    DLog(@"_updateCookiesInDBofUser_: %ld",(long)user.userId );
    
    //1- Try to Delete the cookies of the active user
    [ManageCookiesStorageDB deleteCookiesByUser:user];
    
    //2- Store the current cookies on the Database
    [UtilsCookies setOnDBStorageCookiesByUser:user];
}


+ (void) saveCurrentOfActiveUserAndClean {
    DLog(@"_saveAndCleanCookies_");
    
    //Clear the cookies before to try to do login
    
    [self updateCookiesOfActiveUserInDB];
    
    //Clean the cookies storage
    [UtilsFramework deleteAllCookies];
}

+ (void) restoreCookiesOfUser:(UserDto *)user {
    DLog(@"_restoreCookiesOfUser_ %ld", (long)user.userId);
    
    //1-Restore the previous cookies of user on the System Cookie Storage
    [UtilsCookies setOnSystemCookieStorageDBCookiesOfUser:user];
}

+ (void) deleteCurrentSystemCookieStorageAndRestoreTheCookiesOfActiveUser {
    DLog(@"_deleteCurrentSystemCookieStorageAndRestoreTheCookiesOfActiveUser_");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
    
    //2- Restore cookies of active user
    [self restoreCookiesOfUser:app.activeUser];
}

+ (void) saveActiveUserCookiesAndRestoreCookiesOfUser:(UserDto *)user {
    DLog(@"_saveActiveUserCookiesAndRestoreCookiesOfUser_ %ld", (long)user.userId);
    
    [self saveCurrentOfActiveUserAndClean];

    [self restoreCookiesOfUser:user];
}

+ (void) deleteAllCookiesOfActiveUser {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    //1- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
    
    //2- Try to Delete the cookies of the active user
    [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
}

@end
