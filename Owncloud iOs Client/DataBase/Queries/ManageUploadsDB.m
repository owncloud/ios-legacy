//
//  ManageUploadsDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/06/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageUploadsDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UploadsOfflineDto.h"

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

@implementation ManageUploadsDB

/*
 * Method that insert an upload object into uploads_offline table
 * @upload -> upload object
 */
+(void) insertUpload:(UploadsOfflineDto *) upload {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO uploads_offline (origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status,kind_of_error,is_internal_upload,is_not_necessary_check_if_exist, task_identifier) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", upload.originPath,upload.destinyFolder,upload.uploadFileName, [NSNumber numberWithLong:upload.estimateLength], [NSNumber numberWithInteger:upload.userId], [NSNumber numberWithBool:upload.isLastUploadFileOfThisArray], [NSNumber numberWithInteger: upload.chunkPosition], [NSNumber numberWithInteger:upload.chunkUniqueNumber], [NSNumber numberWithLong:upload.chunksLength], [NSNumber numberWithInteger:upload.status], [NSNumber numberWithInteger:upload.kindOfError], [NSNumber numberWithBool:upload.isInternalUpload], [NSNumber numberWithBool:upload.isNotNecessaryCheckIfExist], [NSNumber numberWithInteger:upload.taskIdentifier]];
        
        if (!correctQuery) {
            DLog(@"Error insert upload offline object");
        }
    }];
}

/*
 * Method that update the status of the one upload.
 * @upload --> upload offline object
 */
+(void) updateUploadOfflineStatusByUploadOfflineDto:(UploadsOfflineDto *) upload {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=? WHERE id = ?", [NSNumber numberWithInteger:upload.status], [NSNumber numberWithInteger:upload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error update an upload offline");
        }
    }];
}

/*
 * Method that delete an upload of the uploads table
 * @upload -> upload object
 */
+(void) deleteUploadOfflineByUploadOfflineDto:(UploadsOfflineDto *) upload {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE id = ?", [NSNumber numberWithInteger:upload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error deleting an upload offline");
        }
    }];

}

/*
 * Method that delete al rows of uploads_offline table 
 *
 */
+(void) cleanTableUploadsOfflineTheFinishedUploads {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE status = ?",[NSNumber numberWithInt:uploaded]];
        
        if (!correctQuery) {
            DLog(@"Error deleting uploads_offline table");
        }
    }];

}

/*
 * Method that save only one number the files in the uploads_offline table
 * @uploads -> The number of the first uploads to save
 */
+(void) saveInUploadsOfflineTableTheFirst:(NSUInteger)uploads{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM uploads_offline WHERE status = ? AND id IN (SELECT id FROM uploads_offline WHERE id NOT IN (SELECT id FROM uploads_offline WHERE status = ? ORDER BY id DESC LIMIT ?))", [NSNumber numberWithInt:uploaded], [NSNumber numberWithInt:uploaded], [NSNumber numberWithInteger:uploads]];
        
        if (!correctQuery) {
            DLog(@"Error deleting uploads_offline table");
        }
    }];
    
    
    // DELETE CLIENTES
    //FROM (SELECT TOP 10 * FROM CLIENTES) AS t1
    //WHERE CLIENTE._id = t1.id
    
}


/*
 * Method that insert in uploads_offline a list of uploads objects
 * @listOfUploadOffline -> list of upload objects
 */
+(void) insertManyUploadsOffline:(NSMutableArray *) listOfUploadOffline {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL correctQuery=NO;
        
        
        for (int i = 0 ; i < [listOfUploadOffline count]; i++) {
            
            UploadsOfflineDto *current = [listOfUploadOffline objectAtIndex:i];
            
            correctQuery = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO uploads_offline SELECT null as id, '%@' as 'origin_path','%@' as 'destiny_folder', '%@' as 'upload_filename', %ld as 'estimate_length',%ld as 'user_id', %d as 'is_last_upload_file_of_this_Array', %ld as 'chunk_position', %ld as 'chunk_unique_number',%ld as 'chunks_length', %ld as 'status',%ld as 'uploaded_date', %ld as 'kind_of_error', %d as 'is_internal_upload', %d as 'is_not_necessary_check_if_exist', %ld as 'task_identifier'",
                                              current.originPath,
                                              current.destinyFolder,
                                              current.uploadFileName,
                                              current.estimateLength,
                                              (long)current.userId,
                                              current.isLastUploadFileOfThisArray,
                                              (long)current.chunkPosition,
                                              (long)current.chunkUniqueNumber,
                                              current.chunksLength,
                                              (long)current.status,
                                              current.uploadedDate,
                                              (long)current.kindOfError,
                                              current.isInternalUpload,
                                              current.isNotNecessaryCheckIfExist,
                                              (long)current.taskIdentifier]];
        }
        
        if (!correctQuery) {
            DLog(@"Error in insertManyUploadsOffline");
        }
        
    }];
}

/*
 * Method that return the last upload
 */
+(UploadsOfflineDto *) getNextUploadOfflineFileToUpload {
    
    DLog(@"getNextUploadOfflineFileToUpload");
    
    __block UploadsOfflineDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier FROM uploads_offline WHERE status = ? ORDER BY id ASC LIMIT 1", [NSNumber numberWithInt:waitingAddToUploadList]];
        
        while ([rs next]) {
            
            output = [UploadsOfflineDto new];
            
            output.idUploadsOffline = [rs intForColumn:@"id"];
            output.originPath = [rs stringForColumn:@"origin_path"];
            output.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            output.uploadFileName = [rs stringForColumn:@"upload_filename"];
            output.estimateLength = [rs longForColumn:@"estimate_length"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            output.chunkPosition = [rs intForColumn:@"chunk_position"];
            output.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            output.chunksLength = [rs longForColumn:@"chunks_length"];
            output.status = [rs intForColumn:@"status"];
            output.kindOfError = [rs intForColumn:@"kind_of_error"];
            output.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            output.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
        }
        
        [rs close];
        
    }];
    
    return output;
    
}

/*
 * Method that return a upload offline dto by id
 *  @uploadOfflineId -> id of upload offline
 */
+ (UploadsOfflineDto*)getUploadOfflineById:(NSInteger)uploadOfflineId{
    
    DLog(@"getUploadOfflineById: %ld", (long)uploadOfflineId);
    
    __block UploadsOfflineDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier, uploaded_date FROM uploads_offline WHERE id = ?", [NSNumber numberWithInteger:uploadOfflineId]];
        
        while ([rs next]) {
            
            output = [UploadsOfflineDto new];
            
            output.idUploadsOffline = [rs intForColumn:@"id"];
            output.originPath = [rs stringForColumn:@"origin_path"];
            output.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            output.uploadFileName = [rs stringForColumn:@"upload_filename"];
            output.estimateLength = [rs longForColumn:@"estimate_length"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            output.chunkPosition = [rs intForColumn:@"chunk_position"];
            output.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            output.chunksLength = [rs longForColumn:@"chunks_length"];
            output.status = [rs intForColumn:@"status"];
            output.kindOfError = [rs intForColumn:@"kind_of_error"];
            output.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            output.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
            output.uploadedDate = [rs longForColumn:@"uploaded_date"];
        }
        
        [rs close];
        
    }];
    
    return output;

    
}

+(void) setStatus:(NSInteger) status andKindOfError:(NSInteger) kindOfError byUploadOffline:(UploadsOfflineDto *) currentUpload {
    
    DLog(@"setStatus: %ld andKindOfError: %ld currentUpload: %@", (long)status, (long)kindOfError, currentUpload.uploadFileName);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=?, kind_of_error = ? WHERE id = ?", [NSNumber numberWithInteger:status], [NSNumber numberWithInteger:kindOfError], [NSNumber numberWithInteger:currentUpload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}

/*
 * This method set the date of finished upload
 * @currentUpload --> object updated
 */

+ (void) setDatebyUploadOffline:(UploadsOfflineDto *)currentUpload{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        

        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET uploaded_date=? WHERE id = ?", [NSNumber numberWithLong:currentUpload.uploadedDate], [NSNumber numberWithInteger:currentUpload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in set date");
        }
        
    }];
    
}

/*
 *
 */

+ (NSMutableArray *) getUploadsByStatus:(int) status {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier FROM uploads_offline WHERE status = ? ORDER BY id ASC", [NSNumber numberWithInt:status]];
        
        while ([rs next]) {
            
            UploadsOfflineDto *current = [UploadsOfflineDto new];
            
            current.idUploadsOffline = [rs intForColumn:@"id"];
            current.originPath = [rs stringForColumn:@"origin_path"];
            current.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            current.uploadFileName = [rs stringForColumn:@"upload_filename"];
            current.estimateLength = [rs longForColumn:@"estimate_length"];
            current.userId = [rs intForColumn:@"user_id"];
            current.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            current.chunkPosition = [rs intForColumn:@"chunk_position"];
            current.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            current.chunksLength = [rs longForColumn:@"chunks_length"];
            current.status = [rs intForColumn:@"status"];
            current.uploadedDate = [rs longForColumn:@"uploaded_date"];
            current.kindOfError = [rs intForColumn:@"kind_of_error"];
            current.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            current.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            current.taskIdentifier = [rs intForColumn:@"task_identifier"];

            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}

+ (NSMutableArray *) getUploads {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date, kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier FROM uploads_offline ORDER BY id ASC"];
        
        while ([rs next]) {
            
            UploadsOfflineDto *current = [UploadsOfflineDto new];
            
            current.idUploadsOffline = [rs intForColumn:@"id"];
            current.originPath = [rs stringForColumn:@"origin_path"];
            current.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            current.uploadFileName = [rs stringForColumn:@"upload_filename"];
            current.estimateLength = [rs longForColumn:@"estimate_length"];
            current.userId = [rs intForColumn:@"user_id"];
            current.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            current.chunkPosition = [rs intForColumn:@"chunk_position"];
            current.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            current.chunksLength = [rs longForColumn:@"chunks_length"];
            current.status = [rs intForColumn:@"status"];
            current.uploadedDate = [rs longForColumn:@"uploaded_date"];
            current.kindOfError = [rs intForColumn:@"kind_of_error"];
            current.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            current.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            current.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}



/*
 * Method that return if there are files in upload process as a uploading, waiting for upload and error uploading states.
 */
+ (BOOL) isFilesInUploadProcess{
    
    __block BOOL isFiles=NO;
    __block int files=0;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        //count files with uploaded status
        FMResultSet *rs = [db executeQuery:@"SELECT count(*) AS count from uploads_offline where status != ?", [NSNumber numberWithInt:uploaded]];
        
        while ([rs next]) {
            
            files = [rs intForColumn:@"count"];
            if (files>0) 
                isFiles=YES;
            
        }
        
        [rs close];
        
    }];
    
    return isFiles;

}


/*
 * Method that return an array with all uploads of the uploads_offline
 */
+ (NSMutableArray *) getUploadsByInsert {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date, task_identifier FROM uploads_offline ORDER BY id ASC"];
        
        while ([rs next]) {
            
            UploadsOfflineDto *current = [UploadsOfflineDto new];
            
            current.idUploadsOffline = [rs intForColumn:@"id"];
            current.originPath = [rs stringForColumn:@"origin_path"];
            current.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            current.uploadFileName = [rs stringForColumn:@"upload_filename"];
            current.estimateLength = [rs longForColumn:@"estimate_length"];
            current.userId = [rs intForColumn:@"user_id"];
            current.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            current.chunkPosition = [rs intForColumn:@"chunk_position"];
            current.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            current.chunksLength = [rs longForColumn:@"chunks_length"];
            current.status = [rs intForColumn:@"status"];
            current.uploadedDate = [rs longForColumn:@"uploaded_date"];
            current.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}

+ (void)updateAllErrorUploadOfflineWithWaitingAddUploadList {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=? WHERE status = ? AND kind_of_error = ?", [NSNumber numberWithInt:waitingAddToUploadList], [NSNumber numberWithInt:errorUploading], [NSNumber numberWithInt:notAnError]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}

+ (void) updateUploadsGeneratedByDocumentProviertoToWaitingAddUploadList {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=? WHERE status = ?", [NSNumber numberWithInt:waitingAddToUploadList], [NSNumber numberWithInt:generatedByDocumentProvider]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
    
}

+ (void) updateNotFinalizeUploadsBackgroundBy:(NSArray *) uploadsArray {
    
    for (UploadsOfflineDto *current in uploadsArray) {
        
        FMDatabaseQueue *queue = Managers.sharedDatabase;
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL correctQuery=NO;
            
            correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=? WHERE status != ? AND status != ? AND status !=? AND kind_of_error = ? AND id = ?", [NSNumber numberWithInt:errorUploading], [NSNumber numberWithInt:uploaded],[NSNumber numberWithInt:uploading],[NSNumber numberWithInt:waitingForUpload], [NSNumber numberWithInt:notAnError], [NSNumber numberWithInteger:current.idUploadsOffline]];
            
            if (!correctQuery) {
                DLog(@"Error in setState");
            }
            
        }];
    }
}


+ (void) updateNotFinalizeUploadsOfflineBy:(NSArray *) uploadsArray {
    
    for (UploadsOfflineDto *current in uploadsArray) {
        
        FMDatabaseQueue *queue = Managers.sharedDatabase;
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL correctQuery=NO;
            
            correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET status=? WHERE status != ? AND kind_of_error = ? AND id = ?", [NSNumber numberWithInt:errorUploading], [NSNumber numberWithInteger:uploaded], [NSNumber numberWithInt:notAnError], [NSNumber numberWithInteger:current.idUploadsOffline]];
            
            if (!correctQuery) {
                DLog(@"Error in setState");
            }
            
        }];
    }
}




+ (NSMutableArray *) getUploadsByStatus:(int) status andByKindOfError:(int) kindOfError {
    DLog(@"getUploadsByStatus %d andByKindOfError: %d", status, kindOfError);
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date , kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier FROM uploads_offline WHERE status = ? AND kind_of_error = ? ORDER BY id ASC", [NSNumber numberWithInt:status], [NSNumber numberWithInt:kindOfError]];
        
        while ([rs next]) {
            
            UploadsOfflineDto *current = [UploadsOfflineDto new];
            
            current.idUploadsOffline = [rs intForColumn:@"id"];
            current.originPath = [rs stringForColumn:@"origin_path"];
            current.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            current.uploadFileName = [rs stringForColumn:@"upload_filename"];
            current.estimateLength = [rs longForColumn:@"estimate_length"];
            current.userId = [rs intForColumn:@"user_id"];
            current.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            current.chunkPosition = [rs intForColumn:@"chunk_position"];
            current.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            current.chunksLength = [rs longForColumn:@"chunks_length"];
            current.status = [rs intForColumn:@"status"];
            current.uploadedDate = [rs intForColumn:@"uploaded_date"];
            current.kindOfError = [rs intForColumn:@"kind_of_error"];
            current.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            current.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            current.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}



+ (NSMutableArray *) getUploadsWithErrorByStatus:(int) status {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, chunk_position, chunk_unique_number, chunks_length, status, uploaded_date , kind_of_error, is_internal_upload, is_not_necessary_check_if_exist, task_identifier FROM uploads_offline WHERE status = ? AND kind_of_error != -1 ORDER BY id ASC", [NSNumber numberWithInt:status]];
        
        while ([rs next]) {
            
            UploadsOfflineDto *current = [UploadsOfflineDto new];
            
            current.idUploadsOffline = [rs intForColumn:@"id"];
            current.originPath = [rs stringForColumn:@"origin_path"];
            current.destinyFolder = [rs stringForColumn:@"destiny_folder"];
            current.uploadFileName = [rs stringForColumn:@"upload_filename"];
            current.estimateLength = [rs longForColumn:@"estimate_length"];
            current.userId = [rs intForColumn:@"user_id"];
            current.isLastUploadFileOfThisArray = [rs intForColumn:@"is_last_upload_file_of_this_Array"];
            current.chunkPosition = [rs intForColumn:@"chunk_position"];
            current.chunkUniqueNumber = [rs intForColumn:@"chunk_unique_number"];
            current.chunksLength = [rs longForColumn:@"chunks_length"];
            current.status = [rs intForColumn:@"status"];
            current.uploadedDate = [rs intForColumn:@"uploaded_date"];
            current.kindOfError = [rs intForColumn:@"kind_of_error"];
            current.isInternalUpload = [rs boolForColumn:@"is_internal_upload"];
            current.isNotNecessaryCheckIfExist = [rs boolForColumn:@"is_not_necessary_check_if_exist"];
            current.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            
            [output addObject:current];
        }
        
        [rs close];
        
    }];
    
    return output;
}


/*
 * Method that update all the files with error credential that have been corrected by user
 */
+ (void) updateErrorCredentialFiles:(NSInteger) userId {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET kind_of_error=? WHERE kind_of_error = ? AND user_id = ?", [NSNumber numberWithInt:notAnError], [NSNumber numberWithInteger:errorCredentials], [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}


/*
 * Method that update the file with folder doesn't exist error that have been corrected by user
 */
+ (void) updateErrorFolderNotFoundFilesSetNewDestinyFolder:(NSString *) folder forUploadOffline:(UploadsOfflineDto *) selectedUpload  {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET kind_of_error=?, destiny_folder=?  WHERE id = ?", [NSNumber numberWithInteger:notAnError], folder, [NSNumber numberWithInteger:selectedUpload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}


/*
 * Method that update the file with conflict error that have been corrected by user changing the name of the file
 */
+ (void) updateErrorConflictFilesSetNewName:(NSString *) name forUploadOffline:(UploadsOfflineDto *) selectedUpload {
    
    DLog(@"name: %@",name);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET kind_of_error=?, upload_filename = ? WHERE id = ?", [NSNumber numberWithInteger:notAnError], name, [NSNumber numberWithInteger:selectedUpload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}


/*
 * Method that update the file with conflict error that have been corrected by user set overwrite
 */
+ (void) updateErrorConflictFilesSetOverwrite:(BOOL) isNotNecessaryCheckIfExist forUploadOffline:(UploadsOfflineDto *) selectedUpload {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //We do not need set anything on the DB about overwrite only on the UploadOfflineDto
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET kind_of_error=?, is_not_necessary_check_if_exist = ? WHERE id = ?", [NSNumber numberWithInteger:notAnError], [NSNumber numberWithBool:isNotNecessaryCheckIfExist], [NSNumber numberWithInteger:selectedUpload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}

/*
 * Method set all uploads to check if the file exist in order to show overwrite or rename
 */
+ (void) updateAllUploadsWithNotNecessaryCheck {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        //We do not need set anything on the DB about overwrite only on the UploadOfflineDto
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET is_not_necessary_check_if_exist=0"];
        
        if (!correctQuery) {
            DLog(@"Error in setState");
        }
        
    }];
}

///-----------------------------------
/// @name Set task_identifier Number for Upload Offline
///-----------------------------------

/**
 * Method that set a hash of the offline
 *
 * @param hash -> NSInteger
 * @param upload -> UploadsOfflineDto
 */
+ (void) setTaskIdentifier:(NSInteger)taskIdentifier forUploadOffline:(UploadsOfflineDto *)upload{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE uploads_offline SET task_identifier = ? WHERE id = ?", [NSNumber numberWithInteger:taskIdentifier], [NSNumber numberWithInteger:upload.idUploadsOffline]];
        
        if (!correctQuery) {
            DLog(@"Error in set task_identifier");
        }
        
    }];
}
@end
