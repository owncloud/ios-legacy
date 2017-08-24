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
        newCookieStorage.userId = user.idUser;
        
        [ManageCookiesStorageDB insertCookie:newCookieStorage];
    }
}

//-----------------------------------
/// @name setOnDBStorageCookiesByUser
///-----------------------------------

/**
 * Method set on the System storage the cookies that are on Database of a user
 *
 * @param UserDto -> user
 *
 */
+ (void) setOnSystemStorageCookiesByUser:(UserDto *) user {
    
    NSArray *listOfCookiesStorageDto = [ManageCookiesStorageDB getCookiesByUser:user];
    
    for (CookiesStorageDto *current in listOfCookiesStorageDto) {
        NSLog(@"Current: %@", current.cookie);
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


+ (void) clearCookies {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Clear the cookies before to try to do login
    //1- Storage the new cookies on the Database
    if (app.activeUser != nil) {
        [UtilsCookies setOnDBStorageCookiesByUser:app.activeUser];
    }
    //2- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
}

//-----------------------------------
/// @name restoreTheCookiesOfActiveUserByNewUser
///-----------------------------------

/**
 * Method to restore the cookies of the active after add a new user
 *
 * @param UserDto -> user
 *
 */
+ (void) restoreTheCookiesOfActiveUser {
    DLog(@"_restoreTheCookiesOfActiveUser_");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
    //2- We restore the previous cookies of the active user on the System cookies storage
    [UtilsCookies setOnSystemStorageCookiesByUser:app.activeUser];
    //3- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
    [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
}

@end
