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
#import "OCCredentialsDto.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "UserDto.h"
#import "Customization.h"

@implementation OCKeychain


+(BOOL)setCredentialsOfUser:(UserDto *)user {

    BOOL output = NO;
    NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.idUser];
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    if (user.credDto) {
        [keychainItem setObject:user.credDto.userName forKey:(__bridge id)kSecAttrDescription];
    } else if (user.username){
        [keychainItem setObject:user.username forKey:(__bridge id)kSecAttrDescription];
    }

    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist == errSecSuccess) {
        NSLog(@"Unable add item with id =%@ error",userId);
    }else {
        
        if (user.credDto) {
            
            NSData *encodedCredDto = [NSKeyedArchiver archivedDataWithRootObject:user.credDto];
            [keychainItem setObject:encodedCredDto forKey:(__bridge id)kSecValueData];
            
        } else if (user.password){
            //to support upgrades from 9to10 db version, in 21to22 is going to be updated to use credDto as kSecValueData
            [keychainItem setObject:[user.password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        }
        
        OSStatus stsAdd = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        
        NSLog(@"(setCredentials)Error Code: %d (0 = success)", (int)stsAdd);
        if (stsAdd == errSecSuccess) {
            output = YES;
        }
    }
    
    return output;
}


+(NSDictionary *)getKeychainDictionaryOfUserId:(NSString *)userId {
    
    NSDictionary *resultDict = nil;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    CFDictionaryRef result = nil;
    
    DLog(@"keychainItem: %@", keychainItem);
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    DLog(@"(getCredentials)Error Code %d", (int)stsExist);
    
    if (stsExist != errSecSuccess) {
        NSLog(@"Unable to get the item with id =%@ ",userId);
        
    } else {
        
        resultDict = (__bridge_transfer NSDictionary *)result;
    }
    
    return resultDict;

}

+(OCCredentialsDto *)getCredentialsByUserId:(NSString *)userId{
    
    OCCredentialsDto *credentialsDto = nil;
    
    NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUserId:userId];
    
    if (resultKeychainDict) {
        NSData *resultData = resultKeychainDict[(__bridge id)kSecValueData];
        
        if (resultData) {
            credentialsDto = [NSKeyedUnarchiver unarchiveObjectWithData: resultData];
        }
    }
    
    return credentialsDto;
}


+(BOOL)removeCredentialsByUserId:(NSString *)userId{
    
    BOOL output = NO;

    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    

    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    NSLog(@"(removeCredentials)Error Code: %d", (int)stsExist);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to delete the item with id =%@ ",userId);
    } else {
        OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
        NSLog(@"Error Code: %d (0 = success)", (int)sts);
        if (sts == errSecSuccess) {
            output = YES;
        }
    }
   
    return output;
}

+(BOOL)updateCredentialsOfUser:(UserDto *)user {
    
    BOOL output = NO;
    NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.idUser];
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to update keychain item with id =%@ ",userId);
        
    }else {
        
        NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
        
        if (user.credDto && user.credDto.userName && user.credDto.accessToken){
            
            NSData *encodedCredDto = [NSKeyedArchiver archivedDataWithRootObject:user.credDto];
            
            [attrToUpdate setObject:encodedCredDto forKey:(__bridge id)kSecValueData];
            [attrToUpdate setObject:user.credDto.userName forKey:(__bridge id)kSecAttrDescription];
            
            OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainItem), (__bridge CFDictionaryRef)(attrToUpdate));
            
            NSLog(@"(updateKeychainCredentials)Error Code: %d (0 = success)", (int)stsUpd);
            
            if (stsUpd == errSecSuccess) {
                output = YES;
            }
        }
    }
    
    return output;
}

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


#pragma mark - Update old keychain items

+ (void) updateAllKeychainsToUseTheLockProperty{
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];
        
        [OCKeychain updateKeychainForUseLockPropertyForUser:idString];
    }
}

+ (BOOL)updateKeychainForUseLockPropertyForUser:(NSString *)userId{
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        DLog(@"Unable to update item with id =%@ ",userId);
        
    }else {
        
        NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
        
        [attrToUpdate setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
        
        OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainItem), (__bridge CFDictionaryRef)(attrToUpdate));
        
        DLog(@"(updateLockProperty)Error Code: %d (0 = success)", (int)stsUpd);
        
        if (stsUpd == errSecSuccess) {
            output = YES;
        }
    }
    
    return output;
}

#pragma mark - used to update from db version 21to22

+(OCCredentialsDto *)getOldCredentialsByUserId:(NSString *)userId {
    
    OCCredentialsDto *credentialsDto = nil;
    
    NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUserId:userId];
    
    if (resultKeychainDict) {
        NSData *resultData = resultKeychainDict[(__bridge id)kSecValueData];
    
        if (resultData) {
            credentialsDto = [OCCredentialsDto new];
            credentialsDto.userName = resultKeychainDict[(__bridge id)kSecAttrDescription];
            credentialsDto.accessToken = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        }
    }
    
    return credentialsDto;
}

+ (void)updateAllKeychainItemsUntilVersion21ToStoreCredentialsDtoWithBasicAuthenticationAsValue {
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];
        
        user.credDto = [OCKeychain getOldCredentialsByUserId:idString];
        
        if (user.credDto) {
            user.username = user.credDto.userName;
            user.password = user.credDto.accessToken;
            
            user.credDto.authenticationMethod = k_is_sso_active ? @"SAML_WEB_SSO" : @"BASIC_HTTP_AUTH";
            
            [OCKeychain updateCredentialsOfUser:user];
            
        } else {
            DLog(@"Not possible to update keychain with userId: %ld", (long)user.idUser);
        }
    }
}



@end
