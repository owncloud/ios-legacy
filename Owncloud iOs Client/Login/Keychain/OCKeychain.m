//
//  OCKeychain.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 22/10/14.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCKeychain.h"
#import <Security/Security.h>


@implementation OCKeychain

#pragma mark - OCCredentialsStorageDelegate
+ (void) storeCurrentCredentialsOfSharedOCCommunication:(OCCommunication *)sharedOCCommunication {

    [self updateCredentials:sharedOCCommunication.credDto];
}

#pragma mark - set credentials

+(BOOL)setCredentials:(OCCredentialsDto *)credentials {
    return [OCKeychain setCredentials:credentials migratingFromDB9to10:NO];
}

// private implementation, common to both setCredentialsOfUser and setCredentialsOfUserToFromDbVersion9To10
+(BOOL)setCredentials:(OCCredentialsDto *)credDto migratingFromDB9to10:(BOOL)migratingFromDB9to10 {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:credDto.userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:credDto.userName forKey:(__bridge id)kSecAttrDescription];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist == errSecSuccess) {
        NSLog(@"Error, unable to add keychain item with username =%@",credDto.userName);
        
    } else {
        
        if (migratingFromDB9to10) {
            //to support upgrades from 9to10 db version, in 21to22 is going to be updated to use credDto as kSecValueData
            [keychainItem setObject:[credDto.accessToken dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        } else {
            NSData *encodedCredDto = [NSKeyedArchiver archivedDataWithRootObject:credDto];
            [keychainItem setObject:encodedCredDto forKey:(__bridge id)kSecValueData];
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
    
    DLog(@"keychainItem: %@", keychainItem);
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    DLog(@"(getCredentials)Error Code %d (0 = success)", (int)stsExist);
    
    if (stsExist != errSecSuccess) {
        NSLog(@"Unable to get the item with userId=%@ ",userId);
        
    } else {
        
        resultDict = (__bridge_transfer NSDictionary *)result;
    }
    
    return resultDict;
}

+(OCCredentialsDto *)getCredentialsOfUser:(UserDto *)user {
    return [self getCredentialsOfUser:user fromPreviousDBVersion22:NO] ;;
}

+(OCCredentialsDto *)getCredentialsOfUser:(UserDto *)user fromPreviousDBVersion22:(BOOL)previousDB22{
    
    OCCredentialsDto *credentialsDto = nil;
    
    NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.idUser];
    NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUserId:userId];
    
    if (resultKeychainDict) {
        
        NSData *resultData = resultKeychainDict[(__bridge id)kSecValueData];
        
        if (resultData) {
            
            if (previousDB22) {
                credentialsDto = [OCCredentialsDto new];
                credentialsDto.userId = resultKeychainDict[(__bridge id)kSecAttrAccount];
                credentialsDto.userName = resultKeychainDict[(__bridge id)kSecAttrDescription];
                credentialsDto.accessToken = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
            } else {
                credentialsDto = [NSKeyedUnarchiver unarchiveObjectWithData: resultData];
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
    
    NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.idUser];
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
        [attrToUpdate setObject:credDto.userName forKey:(__bridge id)kSecAttrDescription];
        
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

+ (BOOL) updateAllOCKeychainItemsToUseTheLockProperty {
    
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

#pragma mark - keychain updates after some db updates

#pragma mark - used to update from db version 9to10, from db to keychain
+(BOOL)setCredentialsOfUserFromDBVersion9To10:(UserDto *)user {
    
    return [OCKeychain setCredentials:user.credDto migratingFromDB9to10:YES];
}

#pragma mark - used to update from db version 21to22

+ (void)updateAllKeychainItemsFromDBVersion21To22ToStoreCredentialsDtoAsValueAndAuthenticationType {
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        user.credDto = [OCKeychain getCredentialsOfUser:user fromPreviousDBVersion22:YES];
        
        if (user.credDto) {
            user.credDto.authenticationMethod = k_is_sso_active ? AuthenticationMethodSAML_WEB_SSO : AuthenticationMethodBASIC_HTTP_AUTH;
            
            [OCKeychain updateCredentials:user.credDto];
            
        } else {
            DLog(@"Not possible to update keychain with userId: %ld", (long)user.idUser);
        }
    }
}



@end
