//
//  UtilsFileSystem.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 09/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsFileSystem.h"
#import "UtilsUrls.h"

@implementation UtilsFileSystem

+ (NSString *) temporalFileNameByName:(NSString *)fileName {
    //Use a temporal name with a date identification
    NSString *temporalFileName = [NSString stringWithFormat:@"%@-%@", [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *tempPath = [[UtilsUrls getTempFolderForUploadFiles] stringByAppendingPathComponent:temporalFileName];
    
    return tempPath;
}


+ (BOOL) createFileOnTheFileSystemByPath:(NSString *)tempPath andData:(NSData *)fileData {
    
    BOOL created = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]){
       created = [[NSFileManager defaultManager] createFileAtPath:tempPath
                                                contents:fileData
                                              attributes:nil];
    }
    
    return created;
}

+ (BOOL) moveFileOnTheFileSystemFrom:(NSString *)origin toDestiny:(NSString *)destiny {
    
    DLog(@"origin: %@",origin);
    DLog(@"destiny: %@", destiny);
    
    NSFileManager *filemgr;
    
    filemgr = [NSFileManager defaultManager];
    
    [filemgr removeItemAtPath:destiny error:nil];
    
    NSError *error;
    
    // Attempt the move
    if ([filemgr moveItemAtPath:origin toPath:destiny error:&error] != YES) {
        DLog(@"Unable to move file: %@", [error localizedDescription]);
        return NO;
    }
    
    return YES;
}

+ (BOOL) existFileOnFileSystemByPath:(NSString *)filePath {
    
   return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (void) storeVersionUsed {
    
    NSString* currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* currentShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:@"BundleVersionOfLastRun"];
    [[NSUserDefaults standardUserDefaults] setObject:currentShortVersion forKey:@"BundleShortVersionOfLastRun"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
