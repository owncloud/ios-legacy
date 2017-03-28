//
//  OCKeychain.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 22/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCKeychain.h"
#import <Security/Security.h>
#import "CredentialsDto.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "UserDto.h"

@implementation OCKeychain


+(BOOL)setCredentialsById:(NSString *)idUser withUsername:(NSString *)userName andPassword:(NSString *)password{
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:idUser forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:userName forKey:(__bridge id)kSecAttrDescription];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];

    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist == errSecSuccess) {
        NSLog(@"Unable add item with id =%@ error",idUser);
    }else {
        [keychainItem setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        OSStatus stsAdd = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        
        NSLog(@"(setCredentials)Error Code: %d", (int)stsAdd);
        if (stsAdd == errSecSuccess) {
            output = YES;
        }
        
    }
    
    return output;
}



+(CredentialsDto *)getCredentialsById:(NSString *)idUser{
    
    CredentialsDto *output = nil;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:idUser forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    CFDictionaryRef result = nil;
    
    DLog(@"keychainItem: %@", keychainItem);
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    DLog(@"(getCredentials)Error Code %d", (int)stsExist);
    
    if (stsExist != errSecSuccess) {
        NSLog(@"Unable to get the item with id =%@ ",idUser);
        
    } else {
        
        NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
        
        NSData *pswd = resultDict[(__bridge id)kSecValueData];
        NSString *password = [[NSString alloc] initWithData:pswd encoding:NSUTF8StringEncoding];
        output = [CredentialsDto new];
        
        output.password = password;
        output.userName = resultDict[(__bridge id)kSecAttrDescription];
    }
    
    return output;

}

+(BOOL)removeCredentialsById:(NSString *)idUser{
    
    BOOL output = NO;

    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:idUser forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    

    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    NSLog(@"(removeCredentials)Error Code: %d", (int)stsExist);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to delete the item with id =%@ ",idUser);
    } else {
        OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
        NSLog(@"Error Code: %d", (int)sts);
        if (sts == errSecSuccess) {
            output = YES;
        }
    }
   
    return output;

}

+(BOOL)updateCredentialsById:(NSString *)idUser withUsername:(NSString *)userName andPassword:(NSString *)password {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:idUser forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to update keychain item with id =%@ ",idUser);
        
    }else {
        
        NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
        if (password != nil){
            [attrToUpdate setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        }
        
        if (userName != nil) {
            [attrToUpdate setObject:userName forKey:(__bridge id)kSecAttrDescription];
        }
        
        OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainItem), (__bridge CFDictionaryRef)(attrToUpdate));
        
        NSLog(@"(updateKeychainCredentials)Error Code: %d", (int)stsUpd);
        
        if (stsUpd == errSecSuccess) {
            output = YES;
        }
    }
    
    return output;
}

+ (BOOL)updateKeychainForUseLockPropertyForUser:(NSString *)idUser{
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:idUser forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        DLog(@"Unable to update item with id =%@ ",idUser);
        
    }else {
        
        NSMutableDictionary *attrToUpdate = [NSMutableDictionary dictionary];
        
        [attrToUpdate setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
        
        OSStatus stsUpd = SecItemUpdate((__bridge CFDictionaryRef)(keychainItem), (__bridge CFDictionaryRef)(attrToUpdate));
        
        DLog(@"(updateLockProperty)Error Code: %d", (int)stsUpd);
        
        if (stsUpd == errSecSuccess) {
            output = YES;
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
    NSLog(@"Reset keychain Error Code: %d", (int)sts);
    if (sts == errSecSuccess) {
        output = YES;
    }

    
    return output;
    
}

///-----------------------------------
/// @name updateAllKeychainsToUseTheLockProperty
///-----------------------------------

/**
 * This method updates all the credentials to use a property to allow to access to them when the passcode system is set.
 */
+ (void) updateAllKeychainsToUseTheLockProperty{
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        NSString *idString = [NSString stringWithFormat:@"%ld", (long)user.idUser];
        
        [OCKeychain updateKeychainForUseLockPropertyForUser:idString];
        
    }
    
}


@end
