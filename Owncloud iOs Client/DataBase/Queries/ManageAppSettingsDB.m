//
//  ManageAppSettingsDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 24/06/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageAppSettingsDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UtilsUrls.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif


@implementation ManageAppSettingsDB


/*
 * Method that return if exist pass code or not
 */
+(BOOL)isPasscode {
    
    __block BOOL output = NO;
    __block int size = 0;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(*) FROM passcode"];
        
        while ([rs next]) {
            
            size = [rs intForColumnIndex:0];
        }
        
        if(size > 0) {
            output = YES;
        }
        
    }];
    
    return output;
    
}

/*
* Method that insert pin code
* @passcode -> pin code
*/
+(void) insertPasscode: (NSString *) passcode {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO passcode(passcode) Values(?)", passcode];
        
        if (!correctQuery) {
            DLog(@"Error insert pin code");
        }
    }];
    
}

/*
 * Method that return the pin code
 */
+(NSString *) getPassCode {
    
    DLog(@"getPassCode");
    
    __block NSString *output = [NSString new];
 
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT passcode FROM passcode  ORDER BY id DESC LIMIT 1"];
        
        while ([rs next]) {
            
            output = [rs stringForColumn:@"passcode"];
        }
        
    }];
    
    return output;

}


/*
 * Method that remove the pin code
 */
+(void) removePasscode {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM passcode"];
        
        if (!correctQuery) {
            DLog(@"Error delete the pin code");
        }
    }];
    
}

/*
 * Method that insert certificate
 * @certificateLocation -> path of certificate
 */
+(void) insertCertificate: (NSString *) certificateLocation {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO certificates(certificate_location) Values(?)", certificateLocation];
        
        if (!correctQuery) {
            DLog(@"Error insert certificate");
        }
    }];
    
}

/*
 * Method that return an array with all of certifications
 */
+(NSMutableArray*) getAllCertificatesLocation {
    
    DLog(@"getAllCertificatesLocation");
    
    NSString *documentsDirectory = [UtilsUrls getOwnCloudFilePath];
    
    NSString *localCertificatesFolder = [NSString stringWithFormat:@"%@/Certificates/",documentsDirectory];
    
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT certificate_location FROM certificates"];
        
        while ([rs next]) {
            
            NSString *certificatePath = [NSString stringWithFormat:@"%@%@", localCertificatesFolder, [rs stringForColumn:@"certificate_location"]];
            [output addObject:certificatePath];
        }
        
    }];
    
    DLog(@"Number of certificates: %lu", (unsigned long)[output count]);
    
    return output;
}


#pragma mark - Instant Upload

+(BOOL)isInstantUpload {
    
    __block BOOL output = NO;
 
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT instant_upload FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            
            output =[rs intForColumn:@"instant_upload"];
            
        }
        
    }];
    
    return output;
    
}

+(void)updateInstantUploadTo:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET instant_upload=? ", [NSNumber numberWithBool:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error updating instant_upload");
        }
    }];
    
}

+(void)updateDateInstantUpload:(long)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET date_instant_upload=?", [NSNumber numberWithLong:newValue]];

        if (!correctQuery) {
            DLog(@"Error updating path_instant_upload");
        }
    }];
    
}

+(long)getDateInstantUpload{
    DLog(@"getDateInstantUpload");
    
    __block long output;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT date_instant_upload FROM users  WHERE activeaccount=1"];
        
        while ([rs next]) {
            
            output = [rs longForColumn:@"date_instant_upload"];
        }
        
    }];
    
    return output;
    
}

+(void)updateInstantUploadAllUser {
    if ([self isInstantUpload]) {
        [self updateInstantUploadTo:YES];
        [self updateDateInstantUpload:[self getDateInstantUpload]];
    } else {
        [self updateInstantUploadTo:NO];
    }
}

+(void)updatePathInstantUpload:(NSString *)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET path_instant_upload=?", newValue];

        if (!correctQuery) {
            DLog(@"Error updating path_instant_upload");
        }
    }];
    
}


+(void)updateOnlyWifiInstantUpload:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET only_wifi_instant_upload=?",[NSNumber numberWithBool:newValue] ];

        if (!correctQuery) {
            DLog(@"Error updating only_wifi_instant_upload");
        }
    }];
    
}




@end
