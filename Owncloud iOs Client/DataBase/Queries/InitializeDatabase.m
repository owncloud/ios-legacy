//
//  InitializeDatabase.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 28/4/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "InitializeDatabase.h"
#import "CredentialsDto.h"
#import "OCKeychain.h"
#import "ManageDB.h"
#import "ManageFilesDB.h"
#import "ManageUsersDB.h"
#import "UtilsUrls.h"
#import "ManageThumbnails.h"

#define k_DB_version_1 1
#define k_DB_version_2 2
#define k_DB_version_3 3
#define k_DB_version_4 4
#define k_DB_version_5 5
#define k_DB_version_6 6
#define k_DB_version_7 7
#define k_DB_version_8 8
#define k_DB_version_9 9
#define k_DB_version_10 10
#define k_DB_version_11 11
#define k_DB_version_12 12
#define k_DB_version_13 13
#define k_DB_version_14 14
#define k_DB_version_15 15
#define k_DB_version_16 16
#define k_DB_version_17 17
#define k_DB_version_18 18
#define k_DB_version_19 19
#define k_DB_version_20 20
#define k_DB_version_21 21

@implementation InitializeDatabase

#pragma mark - Database updates
/*
 * This method prepare the dataBase
 * if not exist, make a new database
 * if exist, prepare the database to the new version
 * the current version it's 3
 */
+ (void) initDataBase {
    
    //New version
    static int dbVersion = k_DB_version_21;
    
    //This method make a new database
    [ManageDB createDataBase];
    
    //For future changes on the DB we should check here the version not if a coolum exist
    if([ManageDB isLocalFolderExistOnFiles]) {
        //Now we have to make the big change!
        [ManageDB removeTable:@"files"];
        [ManageDB removeTable:@"files_backup"];
        [ManageDB createDataBase];
    } else {
        //Switch uses fallthrough to handle migrations - don't add "break" to your migration
        switch ([ManageDB getDatabaseVersion]) {
            case k_DB_version_1:
                [ManageDB updateDBVersion1To2];
            case k_DB_version_2:
                [ManageDB updateDBVersion2To3];
                [self removeURLEncodingFromAllFilesAndFoldersInTheFileSystem];
            case k_DB_version_3:
                [ManageDB updateDBVersion3To4];
            case k_DB_version_4:
                [ManageDB updateDBVersion4To5];
            case k_DB_version_5:
                [ManageDB updateDBVersion5To6];
            case k_DB_version_6:
                [ManageDB updateDBVersion6To7];
            case k_DB_version_7:
                [self updateDBVersion7To8];
            case k_DB_version_8:
                [ManageDB updateDBVersion8To9];
            case k_DB_version_9:
                [ManageDB updateDBVersion9To10];
            case k_DB_version_10:
                [ManageDB updateDBVersion10To11];
            case k_DB_version_11:
                [ManageDB updateDBVersion11To12];
            case k_DB_version_12:
                [ManageDB updateDBVersion12To13];
                //Update keychain of all the users
                [OCKeychain updateAllKeychainsToUseTheLockProperty];
            case k_DB_version_13:
                [ManageDB updateDBVersion13To14];
            case k_DB_version_14:
                [ManageDB updateDBVersion14To15];
            case k_DB_version_15:
                [ManageDB updateDBVersion15To16];
            case k_DB_version_16:
                [self updateDBVersion16To17];
            case k_DB_version_17:
                [ManageDB updateDBVersion17To18];
            case k_DB_version_18:
                [ManageDB updateDBVersion18To19];
            case k_DB_version_19:
                [ManageDB updateDBVersion19To20];
            case k_DB_version_20:
                [ManageDB updateDBVersion20To21];
                break; //Insert your migration above this final break.
        }
    }
    
    //Insert DB version
    [ManageDB insertVersionToDataBase:dbVersion];
    
}

#pragma mark - System Updates

+ (void) removeURLEncodingFromAllFilesAndFoldersInTheFileSystem {
    
    NSString *documentsDirectory = [UtilsUrls getOwnCloudFilePath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray * subpaths = [manager subpathsAtPath:documentsDirectory];
    
    subpaths = [[subpaths reverseObjectEnumerator] allObjects];
    
    for (NSString *fileRoute in subpaths){
        NSArray *splitedUrl = [fileRoute componentsSeparatedByString:@"/"];
        
        //We check if the file that we should rename contain percent character
        if([[splitedUrl objectAtIndex:[splitedUrl count]-1] rangeOfString:@"%"].location != NSNotFound) {
            NSString *smallPath = @"";
            for (int i = 0 ; i < [splitedUrl count]-1 ; i++ ){
                smallPath = [NSString stringWithFormat:@"%@%@/", smallPath,[splitedUrl objectAtIndex:i]];
            }
            
            NSString *fullPath = [NSString stringWithFormat:@"%@%@",documentsDirectory, smallPath];
            NSString *originalName = [splitedUrl objectAtIndex:[splitedUrl count]-1];
            NSString *destinyName = [[splitedUrl objectAtIndex:[splitedUrl count]-1] stringByRemovingPercentEncoding];
            
            NSURL *originalPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",fullPath,originalName]];
            NSURL *destinyPath= [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",fullPath,destinyName]];
            
            [manager moveItemAtURL: originalPath toURL: destinyPath error: nil];
        }
    }
}


///-----------------------------------
/// @name updateDBVersion7To8
///-----------------------------------

/**
 * This method updates the DB from 7 to 8 version and delete the etag of the directories for to force the refresh
 */
+ (void) updateDBVersion7To8 {
    [ManageDB updateDBVersion7To8];
    [ManageFilesDB deleteAlleTagOfTheDirectoties];
}

///-----------------------------------
/// @name updateDBVersion16To17
///-----------------------------------

/**
 * This method updates the DB from 16 to 17 version and delete the folder of the thumbnails to force the generation of the thumbnails Offline
 */
+ (void) updateDBVersion16To17 {
    
    NSString *path = [UtilsUrls getThumbnailFolderPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    
    [ManageFilesDB deleteAlleTagOfTheDirectoties];
    
    [ManageDB updateDBVersion16To17];
}

@end
