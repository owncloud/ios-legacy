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

    [self setCredentials:sharedOCCommunication.credDto withServer:sharedOCCommunication.oauth2Configuration.url];

}

#pragma mark - set credentials
+(BOOL)setCredentials:(OCCredentialsDto *)credentials withServer:(NSString *)serverPath {
    return [OCKeychain setCredentials:credentials withServer:serverPath migrating:NO];
}

// private implementation, common to both setCredentialsOfUser and setCredentialsOfUserToFromDbVersion9To10
+(BOOL)setCredentials:(OCCredentialsDto *)credDto withServer:(NSString *)serverPath migrating:(BOOL)fromDbVersion9To10 {
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:(__bridge id)(kSecClassInternetPassword) forKey:(__bridge id)kSecClass];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:credDto.userName forKey:(__bridge id)kSecAttrAccount];
    if (fromDbVersion9To10) {
        [keychainItem setObject:credDto.userName forKey:(__bridge id)kSecAttrDescription];
    }
    [keychainItem setObject:serverPath forKey:(__bridge id)kSecAttrServer];
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist == errSecSuccess) {
        NSLog(@"Error, unable to add keychain item with username =%@",credDto.userName);
        DLog(@"and server =%@ ", serverPath);
        
    } else {
        
        if (fromDbVersion9To10) {
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


+(NSDictionary *)getKeychainDictionaryOfUser:(UserDto *)user {
    
    NSDictionary *resultDict = nil;
    NSString *serverPath = [UtilsUrls getFullRemoteServerPath:user];

    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:user.credDto.userName forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:serverPath forKey:(__bridge id)kSecAttrServer];

    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainItem setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    CFDictionaryRef result = nil;
    
    DLog(@"keychainItem: %@", keychainItem);
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    DLog(@"(getCredentials)Error Code %d (0 = success)", (int)stsExist);
    
    if (stsExist != errSecSuccess) {
        NSLog(@"Unable to get the item with username=%@ and serverPath=%@ ",user.credDto.userName, serverPath);
        
    } else {
        
        resultDict = (__bridge_transfer NSDictionary *)result;
    }
    
    return resultDict;
}

+(OCCredentialsDto *)getCredentialsByUser:(UserDto *)user {
    
    OCCredentialsDto *credentialsDto = nil;
    
    NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUser:user];
    
    if (resultKeychainDict) {
        NSData *resultData = resultKeychainDict[(__bridge id)kSecValueData];
        
        if (resultData) {
            credentialsDto = [NSKeyedUnarchiver unarchiveObjectWithData: resultData];
        }
    }
    
    return credentialsDto;
}


+(BOOL)removeCredentialsByUser:(UserDto *)user {
    
    BOOL output = NO;
    NSString *serverPath = [UtilsUrls getFullRemoteServerPath:user];

    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    [keychainItem setObject:user.credDto.userName forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:serverPath forKey:(__bridge id)kSecAttrServer];


    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    NSLog(@"(removeCredentials)Error Code: %d", (int)stsExist);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to delete the item with username=%@ and server=%@ ",user.credDto.userName, serverPath);
    } else {
        OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
        NSLog(@"Error Code: %d (0 = success)", (int)sts);
        if (sts == errSecSuccess) {
            output = YES;
        }
    }
   
    return output;
}

+(BOOL)updateCredentialsOfUser:(UserDto *)user{
    return [OCKeychain updateCredentialsOfUser:user fromDB21:NO];
}

+(BOOL)updateCredentialsOfUser:(UserDto *)user fromDB21:(BOOL)fromDB21 {
    
    BOOL output = NO;
    NSString *serverPath = [UtilsUrls getFullRemoteServerPath:user];
    
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    [keychainItem setObject:[UtilsUrls getFullBundleSecurityGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    
    if (fromDB21) {
        NSString *userId = [NSString stringWithFormat:@"%ld",(long)user.idUser];
        [keychainItem setObject:userId forKey:(__bridge id)kSecAttrAccount];

    } else {
        [keychainItem setObject:user.credDto.userName forKey:(__bridge id)kSecAttrAccount];
        [keychainItem setObject:serverPath forKey:(__bridge id)kSecAttrServer];
    }
    
    
    OSStatus stsExist = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL);
    
    if(stsExist != errSecSuccess) {
        NSLog(@"Unable to update keychain item with username=%@ and server=%@ ",user.credDto.userName,serverPath);
        
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


#pragma mark - Reset all OC keychain items

+(BOOL)resetKeychain{
    
    BOOL output = NO;
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    
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
    return [OCKeychain setCredentials:user.credDto withServer:[UtilsUrls getFullRemoteServerPath:user] migrating:YES];
}

#pragma mark - used to update from db version 21to22

+(OCCredentialsDto *)getOldCredentialsByUser:(UserDto *)user {
    
    OCCredentialsDto *credentialsDto = nil;
    
    NSDictionary *resultKeychainDict = [self getKeychainDictionaryOfUser:user];
    
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

+ (void)updateAllKeychainItemsFromDBVersion21To22ToStoreCredentialsDtoAsValueAndAuthenticationType {
    
    for (UserDto *user in [ManageUsersDB getAllUsersWithOutCredentialInfo]) {
        
        user.credDto = [OCKeychain getOldCredentialsByUser:user];
        
        if (user.credDto) {
            user.credDto.authenticationMethod = k_is_sso_active ? AuthenticationMethodSAML_WEB_SSO : AuthenticationMethodBASIC_HTTP_AUTH;
            
            [OCKeychain updateCredentialsOfUser:user fromDB21:YES];
            
        } else {
            DLog(@"Not possible to update keychain with userId: %ld", (long)user.idUser);
        }
    }
}



@end
