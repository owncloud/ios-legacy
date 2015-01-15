//
//  ManageProvidingFilesDB.m
//  Owncloud iOs Client
//
// This class represents the files that are using in other apps by Document Provider and
// it's can be edited by these other apps.
//
//  Created by Gonzalo Gonzalez on 2/1/15.
//


/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageProvidingFilesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "ProvidingFileDto.h"


#ifdef CONTAINER_APP
#import "AppDelegate.h"
#elif FILE_PICKER
#import "DocumentPickerViewController.h"
#else
#import "FileProvider.h"
#endif


@implementation ManageProvidingFilesDB

/*
 * Method that return last user inserted on the Database
 */
+ (ProvidingFileDto *) getTheLastProvidingFileInserted {
    
    __block ProvidingFileDto *output = nil;
    
    output=[ProvidingFileDto new];
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, user_id FROM providing_files ORDER BY id DESC LIMIT 1"];
        
        while ([rs next]) {
            
            output.idProvidingFile = [rs intForColumn:@"id"];
            output.filePath = [rs stringForColumn:@"file_path"];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.userId = [rs intForColumn:@"user_id"];
            
        }
        
        [rs close];
        
    }];
    
    return output;
}


+ (ProvidingFileDto *) insertProvidingFileDtoNamed:(NSString *)fileName withPath:(NSString*)filePath byUserId:(NSInteger)userId{
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    __block BOOL correctQuery = NO;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        correctQuery = [db executeUpdate:@"INSERT INTO providing_files(file_path, file_name, user_id) Values(?, ?, ?)", filePath, fileName, [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error added ProvidingFile");
        }
        
    }];
    
    ProvidingFileDto *providingFileDto = nil;
    
    if (correctQuery) {
        providingFileDto = [self getTheLastProvidingFileInserted];
    }
    
    return providingFileDto;
    
}

+ (BOOL) removeProvidingFileDtoById:(NSInteger)idProvidingFile{
    
    __block BOOL correctQuery = NO;
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM providing_files WHERE id = ?", [NSNumber numberWithInteger:idProvidingFile]];
        
        if (!correctQuery) {
            DLog(@"Error delete providing file");
            
        }
        
    }];
    
    return correctQuery;

}

+ (NSArray*) getAllProvidingFilesDto {
    
    __block NSMutableArray *tempArray = [NSMutableArray new];
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, user_id FROM providing_files ORDER BY id DESC"];
        
        while ([rs next]) {
            
            ProvidingFileDto *providerFileTemp = [ProvidingFileDto new];
            
            providerFileTemp.idProvidingFile = [rs intForColumn:@"id"];
            providerFileTemp.filePath = [rs stringForColumn:@"file_path"];
            providerFileTemp.fileName = [rs stringForColumn:@"file_name"];
            providerFileTemp.userId = [rs intForColumn:@"user_id"];
            
            [tempArray addObject:providerFileTemp];
        }
        
        [rs close];
        
    }];
    
    return [NSArray arrayWithArray:tempArray];;
}


+ (ProvidingFileDto *) getProvidingFileDtoByPath:(NSString *)filePath {

    __block ProvidingFileDto *providerFileTemp = nil;
    
    FMDatabaseQueue *queue;
    
#ifdef CONTAINER_APP
    queue = [AppDelegate sharedDatabase];
#elif FILE_PICKER
    queue = [DocumentPickerViewController sharedDatabase];
#else
    queue = [FileProvider sharedDatabase];
#endif
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, user_id FROM providing_files WHERE file_path = ?", filePath];

        while ([rs next]) {
            
            providerFileTemp = [ProvidingFileDto new];
            
            providerFileTemp.idProvidingFile = [rs intForColumn:@"id"];
            providerFileTemp.filePath = [rs stringForColumn:@"file_path"];
            providerFileTemp.fileName = [rs stringForColumn:@"file_name"];
            providerFileTemp.userId = [rs intForColumn:@"user_id"];
            
        }
        
        [rs close];
        
    }];

    
    return providerFileTemp;
    
}


@end
