//
//  UtilsCookies.m
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

+ (void) eraseCredentialsWithURL:(NSString *)connectURL
{
    NSURLCredentialStorage *credentialsStorage = [NSURLCredentialStorage sharedCredentialStorage];
    NSDictionary *allCredentials = [credentialsStorage allCredentials];
    
    if ([allCredentials count] > 0)
    {
        for (NSURLProtectionSpace *protectionSpace in allCredentials)
        {
            DLog(@"Protetion espace: %@", [protectionSpace host]);
            
            if ([[protectionSpace host] isEqualToString:connectURL])
            {
                DLog(@"Credentials erase");
                NSDictionary *credentials = [credentialsStorage credentialsForProtectionSpace:protectionSpace];
                for (NSString *credentialKey in credentials)
                {
                    [credentialsStorage removeCredential:[credentials objectForKey:credentialKey] forProtectionSpace:protectionSpace];
                }
            }
        }
    }
}

+ (void) eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}

+ (void) eraseCredentialsAndUrlCacheOfActiveUser {
    
    NSString *connectURL = [UtilsUrls getFullRemoteServerPathWithWebDav:APP_DELEGATE.activeUser];
    
    [UtilsCookies eraseCredentialsWithURL:connectURL];
    [UtilsCookies eraseURLCache];
}



+ (void) saveCurrentOfActiveUserAndClean {
    DLog(@"_saveAndCleanCookies_");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Clear the cookies before to try to do login

    //1- Store the current cookies on the Database
    if (app.activeUser != nil) {
        [UtilsCookies setOnDBStorageCookiesByUser:app.activeUser];
    }
    //2- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
}

+ (void) restoreCookiesOfUser:(UserDto *)user {
    DLog(@"_srestoreCookiesOfUser_ %ld", (long)user.userId);
    
    //1-Restore the previous cookies of user on the System Cookie Storage
    [UtilsCookies setOnSystemCookieStorageDBCookiesOfUser:user];
    
    //2-Delete the cookies of the active user on the database because it could change and it is not necessary keep them there
    [ManageCookiesStorageDB deleteCookiesByUser:user];
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

@end
