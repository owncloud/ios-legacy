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

@implementation UtilsUrls

+ (NSString *) getOwnCloudFilePath {
    NSString *output = @"";
    
    [self getBundleOfSecurityGroup];
    
    //We get the current folder to create the local tree
    //TODO: uncomment this to use the shared folder
    output = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self getBundleOfSecurityGroup]] path];
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
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
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
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
        
        return success;
        
    }else{
        return success;
    }
    
}

@end
