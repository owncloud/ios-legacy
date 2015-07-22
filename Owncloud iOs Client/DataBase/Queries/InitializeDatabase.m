//
//  InitializeDatabase.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 28/4/15.
//
//

#import "InitializeDatabase.h"
#import "CredentialsDto.h"
#import "OCKeychain.h"
#import "ManageDB.h"
#import "ManageFilesDB.h"
#import "ManageUsersDB.h"
#import "UtilsUrls.h"

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
    static int dbVersion = k_DB_version_14;
    
    //This method make a new database
    [ManageDB createDataBase];
    
    //For future changes on the DB we should check here the version not if a coolum exist
    if([ManageDB isLocalFolderExistOnFiles]) {
        //Now we have to make the big change!
        [ManageDB removeTable:@"files"];
        [ManageDB removeTable:@"files_backup"];
        [ManageDB createDataBase];
    } else {
        switch ([ManageDB getDatabaseVersion]) {
            case k_DB_version_1:
                [ManageDB updateDBVersion1To2];
                [ManageDB updateDBVersion2To3];
                [ManageDB updateDBVersion3To4];
                [ManageDB updateDBVersion4To5];
                [ManageDB updateDBVersion5To6];
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_2:
                [ManageDB updateDBVersion2To3];
                [self removeURLEncodingFromAllFilesAndFoldersInTheFileSystem];
                [ManageDB updateDBVersion3To4];
                [ManageDB updateDBVersion4To5];
                [ManageDB updateDBVersion5To6];
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_3:
                [ManageDB updateDBVersion3To4];
                [ManageDB updateDBVersion4To5];
                [ManageDB updateDBVersion5To6];
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_4:
                [ManageDB updateDBVersion4To5];
                [ManageDB updateDBVersion5To6];
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_5:
                [ManageDB updateDBVersion5To6];
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_6:
                [ManageDB updateDBVersion6To7];
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_7:
                [self updateDBVersion7To8];
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_8:
                [ManageDB updateDBVersion8To9];
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_9:
                [ManageDB updateDBVersion9To10];
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_10:
                [ManageDB updateDBVersion10To11];
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_11:
                [ManageDB updateDBVersion11To12];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_12:
                [ManageDB updateDBVersion12To13];
                //Update keychain of all the users
                [OCKeychain updateAllKeychainsToUseTheLockProperty];
                [ManageDB updateDBVersion12To13];
                [ManageDB updateDBVersion13To14];
                break;
            case k_DB_version_13:
                [ManageDB updateDBVersion13To14];
                break;
        }
    }
    
    //Insert DB version
    [ManageDB insertVersionToDataBase:dbVersion];
    
    /*Reset keychain items when db need to be updated or when db first init after app has been removed and reinstalled */
    NSMutableArray * users = [ManageUsersDB getAllUsers];
    if (![users count]) {
        //delete all keychain items
        [OCKeychain resetKeychain];
    }
    
    CredentialsDto *credDto = [OCKeychain getCredentialsById:@"1"];
    DLog(@"User: %@", credDto.userName);
    DLog(@"Password: %@", credDto.password);
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
            NSString *destinyName = [[splitedUrl objectAtIndex:[splitedUrl count]-1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
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

@end
