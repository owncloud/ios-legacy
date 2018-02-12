//
//  OCKeychain.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 22/10/14.
//

/*
 Copyright (C) 2018, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCKeychain.h"
#import <Security/Security.h>


@implementation OCKeychain

#pragma mark - OCCredentialsStorageDelegate
- (void) saveCredentials:(OCCredentialsDto *)credDto {

    if (credDto.accessToken != nil) {
        [OCKeychain updateCredentials:credDto];
    }
    
#ifdef CONTAINER_APP
    
    if ([credDto.userId integerValue] ==  [ManageUsersDB getActiveUser].userId) {
        APP_DELEGATE.activeUser = [ManageUsersDB getActiveUser];
    }
#endif
}

#pragma mark - set credentials

+(BOOL)storeCredentials:(OCCredentialsDto *)credDto {
    return [OCKeychain storeCredentials:credDto migratingFromDB9to10:NO migratingFromDBAfter23:YES];
}

// private implementation, common to both setCredentialsOfUser and setCredentialsOfUserToFromDbVersion9To10
+(BOOL)storeCredentials:(OCCredentialsDto *)credDto migratingFromDB9to10:(BOOL)migratingFromDB9to10 migratingFromDBAfter23:(BOOL)migratingFromDBAfter23 {
    
    BOOL output = NO;
    
    if (credDto.userDisplayName == nil) {
        credDto.userDisplayName = @"";
    }
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    if (!migratingFromDBAfter23) {
        [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    } else {
        [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAlways) forKey:(__bridge id)kSecAttrAccessible];
    }
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:credDto.userId forKey:(__bridge id)kSecAttrAccount];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist == errSecSuccess) {
        NSLog(@"Error, unable to add keychain item with username =%@",credDto.userName);
        
    } else {
        
        if (!migratingFromDB9to10) {
            NSData *encodedCredDto = [NSKeyedArchiver archivedDataWithRootObject:credDto];
            [keychainItem setObject:encodedCredDto forKey:(__bridge id)kSecValueData];
        } else {
            //to support upgrades from 9to10 db version, in 21to22 is going to be updated to use credDto as kSecValueData
            [keychainItem setObject:[credDto.accessToken dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
            [keychainItem setObject:credDto.userName forKey:(__bridge id)kSecAttrDescription];
        }
        
        OSStatus stsAdd = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        
        NSLog(@"(setCredentials)Error Code: %d (0 = success)", (int)stsAdd);
        if (stsAdd == errSecSuccess) {
            output = YES;
        }
    }
    
    return output;
}


#pragma mark - get credentials

+(NSDictionary *)getKeychainDictionaryOfUserId:(NSString *)userId {
    
    NSDictionary *resultDict = nil;

    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    CFDictionaryRef result = nil;
        
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    DLog(@"(getCredentials of userId %@)Error Code %d (0 = success)", userId, (int)stsExist);
    
    if (stsExist != errSecSuccess) {
        NSLog(@"Unable to get the item with userId=%@ ",userId);
        
    } else {
        
        resultDict = (__bridge_transfer NSDictionary *)result;
    }
    
    return resultDict;
}

+(OCCredentialsDto *)getCredentialsOfUser:(UserDto *)user {
    return [self getCredentialsOfUser:user migratingFromDB21or22to23:NO];
}

+(OCCredentialsDto *)getCredentialsOfUser:(UserDto *)user migratingFromDB21or22to23:(BOOL)previousDB23{
    
    OCCredentialsDto *credentialsDto = nil;
    
    if (user != nil && user.userId != 0) {
        
        NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.userId];
        NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUserId:userId];
        
        if (resultKeychainDict) {
            
            NSData *resultData = resultKeychainDict[(__bridge id)kSecValueData];
            
            if (resultData) {
                
                if (!previousDB23) {
                    credentialsDto = [NSKeyedUnarchiver unarchiveObjectWithData: resultData];
                } else {
                    credentialsDto = [OCCredentialsDto new];
                    credentialsDto.userId = resultKeychainDict[(__bridge id)kSecAttrAccount];
                    credentialsDto.userName = resultKeychainDict[(__bridge id)kSecAttrDescription];
                    credentialsDto.accessToken = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
                    credentialsDto.baseURL = [UtilsUrls getFullRemoteServerPath:user];
                    credentialsDto.userDisplayName = @"";
                }
            }
        }
    }
    return credentialsDto;
}


#pragma mark - remove credentials

+(BOOL)removeCredentialsOfUser:(UserDto *)user {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.userId];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];

    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    NSLog(@"(removeCredentials)Error Code: %d", (int)stsExist);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to delete the item with username=%@ ",user.credDto.userName);
    } else {
        OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
        NSLog(@"Error Code: %d (0 = success)", (int)sts);
        if (sts == errSecSuccess) {
            output = YES;
        }
    }
   
    return output;
}


#pragma mark - update credentials

+(BOOL)updateCredentials:(OCCredentialsDto *)credDto {
    
    BOOL output = NO;
    
    if (credDto.userDisplayName == nil) {
        credDto.userDisplayName = @"";
    }
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:credDto.userId forKey:(__bridge id)kSecAttrAccount];

    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to update keychain item with userId=%@",credDto.userId);
    }else {
        
        NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
        
        NSData *encodedCredDto = [NSKeyedArchiver archivedDataWithRootObject:credDto];
        [attrToUpdate setObject:encodedCredDto forKey:(__bridge id)kSecValueData];
        
        OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainItem), (__bridge CFDictionaryRef)(attrToUpdate));
        
        NSLog(@"(updateKeychainCredentials)Error Code: %d (0 = success)", (int)stsUpd);
        
        if (stsUpd == errSecSuccess) {
            output = YES;
        }
        
    }
    return output;
}


#pragma mark - Reset all OC keychain items

+(BOOL)resetKeychain{
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    
    [keychainQuery setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainQuery setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    NSLog(@"Reset keychain Error Code: %d (0 = success)", (int)sts);
    if (sts == errSecSuccess) {
        output = YES;
    }
    
    return output;
}


#pragma mark - Update all OC keychain items

+ (BOOL) updateAllKeychainItemsToUseTheLockProperty {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    
    [keychainQuery setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainQuery setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
    [attrToUpdate setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    
    OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainQuery), (__bridge CFDictionaryRef)(attrToUpdate));
    DLog(@"(updateLockProperty)Error Code: %d (0 = success)", (int)stsUpd);
    if (stsUpd == errSecSuccess) {
        output = YES;
    }
    
    return output;
}

+ (BOOL) updateAllKeychainItemsToUseAccessibleAlwaysProperty {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    
    [keychainQuery setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainQuery setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
    [attrToUpdate setObject:(__bridge id)(kSecAttrAccessibleAlways) forKey:(__bridge id)kSecAttrAccessible];
    
    OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainQuery), (__bridge CFDictionaryRef)(attrToUpdate));
    DLog(@"(updateLockPropertyToAccessibleAlways)Error Code: %d (0 = success)", (int)stsUpd);
    if (stsUpd == errSecSuccess) {
        output = YES;
    }
    
    return output;
}

#pragma mark - keychain updates after some db updates

#pragma mark - used to update from db version 9to10, from db to keychain
+(BOOL) storeCredentialsOfUserFromDBVersion9To10:(UserDto *)user {
    
    return [OCKeychain storeCredentials:user.credDto migratingFromDB9to10:YES migratingFromDBAfter23:NO];
}

#pragma mark - used to update from db version 22to23

+ (void) updateAllKeychainItemsFromDBVersion22To23ToStoreCredentialsDtoAsValueAndAuthenticationTypeWithCompletion:(void(^)(BOOL isUpdated))completion {
    
    BOOL isUpdated = YES;
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        user.credDto = [OCKeychain getCredentialsOfUser:user migratingFromDB21or22to23:YES];
        
        if (user.credDto && user.credDto.userName != nil && user.credDto.accessToken != nil && user.credDto.userId != nil) {
            
            user.credDto.authenticationMethod = k_is_sso_active ? AuthenticationMethodSAML_WEB_SSO : AuthenticationMethodBASIC_HTTP_AUTH;

            isUpdated &= [OCKeychain updateCredentials:user.credDto];
        } else {
            isUpdated &= NO;
            DLog(@"Not possible to update keychain with userId: %ld", (long)user.userId);
        }
    }
    completion(isUpdated);
}


+ (void) waitUntilKindOfCredentialsInAllKeychainItemsAreUpdatedFromDB22to23 {
    NSLog(@"Migrating kind of credentials of all keychain items");
    
    //We create a semaphore to wait until we have access to the keychain
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_time_t timeout =  timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));

    [OCKeychain updateAllKeychainItemsFromDBVersion22To23ToStoreCredentialsDtoAsValueAndAuthenticationTypeWithCompletion:^(BOOL isUpdated) {
        if (isUpdated){
            NSLog(@"Migrated credentials at init");
        }  else {
            NSLog(@"No Migrated credentials at init");
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    if (dispatch_semaphore_wait(semaphore, timeout)) {
        NSLog(@"Waiting for access to the keychain timeout. No Migrated credentials at init");
    }
}

#pragma mark - check access

+ (void) checkAccessKeychainFromDBVersion:(int)dbVersion withCompletion:(void(^)(BOOL hasAccess))completion {
    
    UserDto *user = [ManageUsersDB getActiveUser];
    OCCredentialsDto *userCred = nil;

    while (userCred == nil) {
        
        if (dbVersion < 23) {
            userCred = [OCKeychain getCredentialsOfUser:user migratingFromDB21or22to23:YES];
        } else {
            userCred = [OCKeychain getCredentialsOfUser:user];
        }
    }

    completion(YES);
}

+ (void) waitUntilAccessToKeychainFromDBVersion:(int)dbVersion {
    
    //We create a semaphore to wait until we have access to the keychain
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_time_t timeout =  timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC));
    
    [OCKeychain  checkAccessKeychainFromDBVersion:dbVersion withCompletion:^(BOOL hasAccess) {
        if (hasAccess){
            dispatch_semaphore_signal(semaphore);
        }
    }];
    
    if (dispatch_semaphore_wait(semaphore, timeout)) {
        NSLog(@"Waiting for access to the keychain timeout. No access to the keychain");
    } else {
        NSLog(@"We get access to the keychain");
    }
}


@end
