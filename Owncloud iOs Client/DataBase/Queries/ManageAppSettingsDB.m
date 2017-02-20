//
//  ManageAppSettingsDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 24/06/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
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

+(void) insertPasscode: (NSString *) passcode {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO passcode(passcode) Values(?)", passcode];
        
        if (!correctQuery) {
            DLog(@"Error insert passcode");
        }
    }];
}

+(void) updatePasscode: (NSString *) passcode {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE passcode SET passcode=?", passcode];
        
        if (!correctQuery) {
            DLog(@"Error passcode not updated");
        }
    }];
}

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

+(BOOL) isTouchID {
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT is_touch_id FROM passcode"];
        
        while ([rs next]) {
            
            output =[rs boolForColumn:@"is_touch_id"];
        }
    }];
    
    return output;
}

+(void) updateTouchIDTo:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE passcode SET is_touch_id=? ", [NSNumber numberWithBool:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error updating is_touch_id");
        }
    }];
}

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

+(NSMutableArray*) getAllCertificatesLocation {
    
    DLog(@"getAllCertificatesLocation");
    
    NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
    
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

+(BOOL)isImageInstantUpload {
    
    __block BOOL output = NO;
 
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT image_instant_upload FROM users WHERE activeaccount=1"];
        while ([rs next]) {
            output =[rs boolForColumn:@"image_instant_upload"];
        }
    }];
    
    return output;
}

+(BOOL)isVideoInstantUpload {
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT video_instant_upload FROM users WHERE activeaccount=1"];
        while ([rs next]) {
            output =[rs boolForColumn:@"video_instant_upload"];
        }
    }];
    
    return output;
}

+(void)updateImageInstantUploadTo:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        correctQuery = [db executeUpdate:@"UPDATE users SET image_instant_upload=? ", [NSNumber numberWithBool:newValue]];
        if (!correctQuery) {
            DLog(@"Error updating image_instant_upload");
        }
    }];
    
}

+(void)updateVideoInstantUploadTo:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        correctQuery = [db executeUpdate:@"UPDATE users SET video_instant_upload=? ", [NSNumber numberWithBool:newValue]];
        if (!correctQuery) {
            DLog(@"Error updating video_instant_upload");
        }
    }];
}

+ (BOOL) isBackgroundInstantUpload {
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT background_instant_upload FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            
            output =[rs boolForColumn:@"background_instant_upload"];
        }
    }];
    
    return output;
}

+(void)updateBackgroundInstantUploadTo:(BOOL)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET background_instant_upload=? ", [NSNumber numberWithBool:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error updating background_instant_upload");
        }
    }];
}

+(NSTimeInterval)getTimestampInstantUploadImage {
    DLog(@"getTimestampInstantUploadImage");
    
    __block double output;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT timestamp_last_instant_upload_image FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            
            output = [rs doubleForColumn:@"timestamp_last_instant_upload_image"];
        }
    }];
    
    return output;
}

+ (NSTimeInterval)getTimestampInstantUploadVideo {
    DLog(@"getTimestampInstantUploadVideo");
    
    __block double output;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT timestamp_last_instant_upload_video FROM users WHERE activeaccount=1"];
        
        while ([rs next]) {
            
            output = [rs doubleForColumn:@"timestamp_last_instant_upload_video"];
        }
    }];
    
    return output;
}

+ (void)updateTimestampInstantUploadImage:(NSTimeInterval)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET timestamp_last_instant_upload_image=?", [NSNumber numberWithDouble:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error updating timestamp_last_instant_upload_image");
        }
    }];
}

+ (void)updateTimestampInstantUploadVideo:(NSTimeInterval)newValue {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE users SET timestamp_last_instant_upload_video=?", [NSNumber numberWithDouble:newValue]];
        
        if (!correctQuery) {
            DLog(@"Error updating timestamp_last_instant_upload_video");
        }
    }];
}

+(void)updateInstantUploadAllUser {
    
    [self updateImageInstantUploadTo:[self isImageInstantUpload]];
    [self updateVideoInstantUploadTo:[self isVideoInstantUpload]];
    if ([self isImageInstantUpload] || [self isVideoInstantUpload]) {
        [self updateTimestampInstantUploadImage:[self getTimestampInstantUploadImage]];
        [self updateTimestampInstantUploadVideo:[self getTimestampInstantUploadVideo]];
    }
    [self updateBackgroundInstantUploadTo:[self isBackgroundInstantUpload]];
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
