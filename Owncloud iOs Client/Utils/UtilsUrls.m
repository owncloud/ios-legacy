//
//  UtilsUrls.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 16/10/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsUrls.h"
#import "constants.h"
#import "UserDto.h"

@implementation UtilsUrls

+ (NSString *) getOwnCloudFilePath {
    NSString *output = @"";
    
    //We get the current folder to create the local tree
    //TODO: uncomment this to use the shared folder
    
    NSString *bundleSecurityGroup = [self getBundleOfSecurityGroup];
    
    output = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:bundleSecurityGroup] path];
    output = [NSString stringWithFormat:@"%@/%@",output, k_owncloud_folder];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:output isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:output
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error) {
            DLog(@"Error creating directory path: %@", [error localizedDescription]);
        } else {
            [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:output]];
        }
    }
    
    output = [output stringByAppendingString:@"/"];
    
    return output;
}

+ (NSString *)getBundleOfSecurityGroup {
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource: @"Owncloud iOs Client" ofType: @"entitlements"];
    
    NSPropertyListFormat format;
    NSDictionary *entitlement = [NSPropertyListSerialization propertyListFromData:[[NSFileManager defaultManager] contentsAtPath:path] mutabilityOption:NSPropertyListImmutable format:&format errorDescription:nil];
    NSArray *securityGroups = [entitlement objectForKey:@"com.apple.security.application-groups"];
    
    return [securityGroups objectAtIndex:0];
}

+ (NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

+ (NSString *) getFullBundleSecurityGroup {
    
    NSString *output;
    
    output = [NSString stringWithFormat:@"%@.%@", [self bundleSeedID], [self getBundleOfSecurityGroup]];
    
    return output;
    
}

//Method to skip a file to a iCloud backup
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    
    BOOL success = NO;
    
    NSString *reqSysVer = @"5.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([URL path]!=nil && ![currSysVer isEqualToString:reqSysVer]) {
        assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
        
        NSError *error = nil;
        
        success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                 forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            DLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
        
        return success;
        
    }else{
        return success;
    }
    
}

//We remove the part of the remote file path that is not necesary
+(NSString *) getRemovedPartOfFilePathAnd:(UserDto *)mUserDto {
    
    NSArray *userUrlSplited = [mUserDto.url componentsSeparatedByString:@"/"];
    NSString *partRemoved = @"";
    
    for(int i = 3 ; i < [userUrlSplited count] ; i++) {
        partRemoved = [NSString stringWithFormat:@"%@/%@", partRemoved, [userUrlSplited objectAtIndex:i]];
        //DLog(@"partRemoved: %@", partRemoved);
    }
    
    //We remove the first and the last "/"
    if ( [partRemoved length] > 0) {
        partRemoved = [partRemoved substringFromIndex:1];
    }
    if ( [partRemoved length] > 0)
        partRemoved = [partRemoved substringToIndex:[partRemoved length] - 1];
    
    
    
    if([partRemoved length] <= 0) {
        partRemoved = [NSString stringWithFormat:@"/%@", k_url_webdav_server];
    } else {
        partRemoved = [NSString stringWithFormat:@"/%@/%@", partRemoved, k_url_webdav_server];
    }
    
    return partRemoved;
}

//We generate de local path of the files dinamically
+(NSString *)getLocalFolderByFilePath:(NSString*) filePath andFileName:(NSString*) fileName andUserDto:(UserDto *) mUser {
    
    NSArray *listItems = [mUser.url componentsSeparatedByString:@"/"];;
    NSString *urlWithoutAddress = @"";
    for (int i = 3 ; i < [listItems count] ; i++) {
        urlWithoutAddress = [NSString stringWithFormat:@"%@/%@", urlWithoutAddress, [listItems objectAtIndex:i]];
    }
    
    urlWithoutAddress = [NSString stringWithFormat:@"%@%@",urlWithoutAddress, k_url_webdav_server];
    
    //DLog(@"urlWithoutAddress: %d", [urlWithoutAddress length]);
    
    urlWithoutAddress = [filePath substringFromIndex:[urlWithoutAddress length]];
    
    //NSString *newLocalFolder= [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", mUser.idUser]];
    NSString *newLocalFolder= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", (int)mUser.idUser]];
    
    
    
    newLocalFolder = [NSString stringWithFormat:@"%@/%@%@", newLocalFolder,urlWithoutAddress,fileName];
    
    //We remove the http encoding
    newLocalFolder = [newLocalFolder stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    //DLog(@"newLocalFolder: %@", newLocalFolder);
    return newLocalFolder;
}

@end
