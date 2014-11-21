//
//  ManageFilesDB.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 6/21/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageFilesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "AppDelegate.h"
#import "FileDto.h"
#import "UtilsDtos.h"
#import "OCSharedDto.h"
#import "ManageUsersDB.h"
#import "FilePreviewViewController.h"
#import "DetailViewController.h"

@implementation ManageFilesDB

+ (NSMutableArray *) getFilesByFileIdForActiveUser:(int) fileId {
    
    __block NSMutableArray *output = [NSMutableArray new];
    DLog(@"getFilesByFileId: %d",fileId);
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, etag, is_favorite, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE file_id = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInt:fileId], [NSNumber numberWithInt:mUser.idUser]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}

///-----------------------------------
/// @name Get Files by idFile
///-----------------------------------

/**
 * Method that return an array of files, this files are sons of fileId
 *
 * @param fileId -> NSInteger
 *
 * @return list of files -> NSMutableArray
 *
 * @warning For filePath and localFolder is necessary the user, but we call this method before to check the user
 */
+ (NSMutableArray *) getFilesByFileId:(NSInteger) fileId {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, etag, is_favorite, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE file_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:fileId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [rs stringForColumn:@"file_path"];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = @"";
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+ (FileDto *) getFileDtoByIdFile:(int) idFile {
    
    __block FileDto *output = nil;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    DLog(@"getFileByIdFile: %d", idFile);
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE id = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInt:idFile], [NSNumber numberWithInt:mUser.idUser]];
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
            output.etag = [rs longLongIntForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
        }
        [rs close];
    }];
    
    return output;
}

+(FileDto *) getFileDtoByFileName:(NSString *) fileName andFilePath:(NSString *) filePath andUser:(UserDto *) user {
    
    __block FileDto *output = nil;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE file_name = ? AND file_path= ? AND user_id = ? ORDER BY file_name ASC",fileName, filePath, [NSNumber numberWithInt:user.idUser]];
        
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:user],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:user];
            output.etag = [rs longLongIntForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
    
        }
        [rs close];
    }];
    
    return output;
}

+(NSMutableArray *) getAllFoldersByBeginFilePath:(NSString *) beginFilePath {
    
    DLog(@"getAllFoldersByBeginFilePath");
    
    //To the like SQL nedd a % charcter in the sintaxis
    beginFilePath = [NSString stringWithFormat:@"%@%%", beginFilePath];
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT DISTINCT file_path, file_name, id FROM files WHERE user_id = ? AND file_path LIKE ? ORDER BY file_name ASC", [NSNumber numberWithInt:mUser.idUser], beginFilePath];
        while ([rs next]) {
            
            FileDto *currentFile = [FileDto new];
            
            currentFile.filePath = [rs stringForColumn:@"file_path"];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.idFile = [rs intForColumn:@"id"];
                       
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}

+(void) setFileIsDownloadState: (int) idFile andState:(enumDownload)downloadState {
    
    DLog(@"setFileIsDownloadState");
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download=? WHERE id = ?", [NSNumber numberWithInt:downloadState], [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFileIsDownloadState");
        }
        
    }];
}


+(void) updateDownloadStateOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withState:(enumDownload)downloadState {
    
    DLog(@"setFileIsDownloadState");
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download=? WHERE file_path = ? AND file_name=? AND user_id = ?", [NSNumber numberWithInt:downloadState], filePath, fileName, [NSNumber numberWithInt:aciveUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in setFileIsDownloadState");
        }
        
    }];
}

+(void) setFilePath: (NSString * ) filePath byIdFile: (int) idFile {
    
    DLog(@"NewFilePath: %@", filePath);
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=? WHERE id = ?", filePath, [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFilePath");
        }
        
    }];
}

+(void) insertManyFiles:(NSMutableArray *)listOfFiles andFileId:(int)fileId {
    
    NSString *sql = @"";
    NSMutableArray *arrayOfSqlRequests = [NSMutableArray new];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    int numberOfInsertEachTime = 0;
    
    //if count == 1 the file is the current folder so there is nothing to insert
    if([listOfFiles count] > 1) {
        for (int i = 0; i < [listOfFiles count]; i++) {
            if(i > 0) {
                
               //INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date
               FileDto *current = [listOfFiles objectAtIndex:i];
               current.fileId = fileId;
               current.userId = mUser.idUser;
                
                //to jump the first becouse it is not necesary (is the same directory) and the other if is to insert 450 by 450
                if(numberOfInsertEachTime == 0) {
                    sql = [NSString stringWithFormat:@"INSERT INTO files SELECT null as id, '%@' as 'file_path','%@' as 'file_name', %d as 'user_id', %d as 'is_directory',%d as 'is_download', %d as 'file_id', %@ as 'size', %@ as 'date', %d as 'is_favorite',%lld as 'etag', %d as 'is_root_folder', %d as 'is_necessary_update', %d as 'shared_file_source', '%@' as 'permissions', %d as 'task_identifier'",
                           current.filePath,
                           current.fileName,
                           current.userId,
                           current.isDirectory,
                           current.isDownload,
                           current.fileId,
                           [[NSNumber numberWithLong:current.size] stringValue],
                           [[NSNumber numberWithLong:current.date] stringValue],
                           current.isFavorite,
                           current.etag,
                           NO,
                           NO,
                           current.sharedFileSource,
                           current.permissions,
                           current.taskIdentifier];
                    
                    //DLog(@"sql!!!: %@", sql);
                } else {
                    sql = [NSString stringWithFormat:@"%@ UNION SELECT null, '%@','%@',%d,%d,%d,%d,%@,%@,%d,%lld,%d,%d,%d,'%@',%d",
                           sql,
                           current.filePath,
                           current.fileName,
                           current.userId,
                           current.isDirectory,
                           current.isDownload,
                           current.fileId,
                           [[NSNumber numberWithLong:current.size] stringValue],
                           [[NSNumber numberWithLong:current.date] stringValue],
                           current.isFavorite,
                           current.etag,
                           NO,
                           NO,
                           current.sharedFileSource,
                           current.permissions,
                           current.taskIdentifier];
                }
                
                numberOfInsertEachTime++;
                
                //DLog(@"sql: %@", sql);
                
                
                if(numberOfInsertEachTime > 450) {
                    numberOfInsertEachTime = 0;
                    //We add the sql with 450 request to the array
                    [arrayOfSqlRequests addObject:sql];
                }
            }
        }
        
        //We add the sql with less than 450 request to the array
        [arrayOfSqlRequests addObject:sql];
        
       
        FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            BOOL correctQuery=NO;
            
            for (int i = 0 ; i < [arrayOfSqlRequests count] ; i++) {
                correctQuery = [db executeUpdate:[arrayOfSqlRequests objectAtIndex:i]];
            }
            
            if (!correctQuery) {
                DLog(@"Error in insertManyFiles");
            }
            
        }];
        
    }
}


+(void) deleteFileByIdFileOfActiveUser:(int) idFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE id = ? AND user_id = ?",[NSNumber numberWithInt:idFile], [NSNumber numberWithInt:mUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByIdFile");
        }
        
    }];
}

///-----------------------------------
/// @name Delete File by idfile
///-----------------------------------

/**
 * Method that delete a file/folder of the database
 *
 * @param idFile -> NSInteger (Item to delete)
 */
+(void) deleteFileByIdFile:(NSInteger) idFile {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE id = ?",[NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByIdFile");
        }
        
    }];
}

+(void) deleteFilesFromDBBeforeRefreshByFileId: (int) fileId {
    
    DLog(@"deleteFilesFromDBBeforeRefreshByFileId");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE file_id = ? AND user_id = ?", [NSNumber numberWithInt:fileId], [NSNumber numberWithInt:mUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFilesFromDBBeforeRefreshByFileId");
        }
        
    }];
}

+ (void) backupOfTheProcessingFilesAndFoldersByFileId:(int) fileId {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO files_backup SELECT * FROM files WHERE user_id =? and file_id=? and (is_download != 0 or is_directory = 1 or is_favorite = 1 or shared_file_source != 0)", [NSNumber numberWithInt:mUser.idUser], [NSNumber numberWithInt:fileId]];
        
        if (!correctQuery) {
            DLog(@"Error in backupFoldersDownloadedFavoritesByFileId");
        }
    }];
}

+(void) updateRelatedFilesFromBackup {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT files.id, back.file_id, back.etag FROM files, (SELECT DISTINCT files.file_id, files_backup.file_path, files_backup.file_name, files_backup.etag FROM files_backup, files WHERE files.file_id = files_backup.id AND files_backup.is_directory = 1) back WHERE user_id = ? AND files.file_path = back.file_path AND files.file_name = back.file_name ORDER BY id DESC", [NSNumber numberWithInt:mUser.idUser]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            
            DLog(@"currentFile.idFile: %d", currentFile.idFile);
            DLog(@"currentFile.fileId %d", currentFile.fileId);
            DLog(@"currentFile.etag %lld", currentFile.etag);
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {

            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            
            correctQuery = [db executeUpdate:@"UPDATE files SET id = ?, etag = ? WHERE id = ?", [NSNumber numberWithInt:currentFile.fileId], [NSNumber numberWithLongLong: currentFile.etag], [NSNumber numberWithInt:currentFile.idFile]];
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateRelatedFilesFromBackup");
        }
    }];
}


///-----------------------------------
/// @name updateFilesFromBackup
///-----------------------------------

/**
 * This method update the files DB with the datas located on the files_backup DB
 * 
 * If the file is overwritten we update the fileds: is_download, shared_file_source and
 * is_overwritten
 *
 * If other case we update the fields: is_download, shared_file_source and is_overwritten
 * AND etag
 */
+(void) updateFilesFromBackup {
    
    //1 - Select the files from the files_backup DB that want to be updated on the files DB
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT f.id, f.user_id, b.etag, b.is_necessary_update, b.is_download, b.shared_file_source, b.permissions, b.task_identifier FROM files f, (SELECT id, user_id, file_path, file_name, etag, is_necessary_update, is_download, shared_file_source, permissions, task_identifier FROM files_backup WHERE (files_backup.is_download != 0 or files_backup.shared_file_source != 0)) b WHERE b.file_path = f.file_path AND b.file_name = f.file_name AND b.user_id = f.user_id"];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            currentFile.idFile = [rs intForColumn:@"f.id"];
            currentFile.etag = [rs longLongIntForColumn:@"b.etag"];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"b.is_necessary_update"];
            currentFile.isDownload = [rs intForColumn:@"b.is_download"];
            currentFile.sharedFileSource = [rs intForColumn:@"b.shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"b.permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"b.task_identifier"];
            
            DLog(@"files share source = %d", currentFile.sharedFileSource);
            DLog(@"currentFile.idFile: %d", currentFile.idFile);
            DLog(@"currentFile.idFile: %lld", currentFile.etag);
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    DLog(@"Size list: %d", [listFilesToUpdate count]);
    
    //2 - Update the files DB with the selected datas from the files_backup DB
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
            
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            
            correctQuery = [db executeUpdate:@"UPDATE files SET is_download = ?, etag = ?, shared_file_source = ? WHERE id = ?", [NSNumber numberWithInt:currentFile.isDownload],[NSNumber numberWithLongLong:currentFile.etag] ,[NSNumber numberWithInt:currentFile.sharedFileSource], [NSNumber numberWithInt:currentFile.idFile]];
        }
        if (!correctQuery) {
            DLog(@"Error in updateDownloadedFilesFromBackup");
        }
    }];
}

///-----------------------------------
/// @name setUpdateIsNecessaryFromBackup
///-----------------------------------

/**
 * This method set the field isNecessaryUpdate to YES on the files DB when the file stored etag 
 * on the files DB is diferent that the one stored on the files_backup DB
 * The only exception is that the field is not set to YES is the file is overwritten, in this
 * case the etag must be updated on the files DB: check the method updateFilesFromBackup
 *
 * @param idFile -> int, the file that want to update
 */
+(void) setUpdateIsNecessaryFromBackup:(int) idFile {
    
    //1-Select the files from the files_backup DB
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    NSMutableArray *listFilesFromFiles = [self getFilesByFileIdForActiveUser:idFile];
    NSMutableArray *listFilesFromFilesBackup = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT file_name, etag, is_download FROM files_backup WHERE is_download = 1 OR is_download = 2 OR is_download = 3"];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            
            DLog(@"currentFile.idFile: %d", currentFile.idFile);
            
            [listFilesFromFilesBackup addObject:currentFile];
        }
        [rs close];
    }];
    
    //2-Save the files that have different etag from files_backup DB
    for (FileDto *currentBackup in listFilesFromFilesBackup) {
        for (FileDto *currentFile in listFilesFromFiles) {
            if ((currentBackup.etag != currentFile.etag) && [currentBackup.fileName isEqualToString:currentFile.fileName]) {
                if (currentBackup.etag != 0) {
                    currentFile.isDownload = currentBackup.isDownload;
                    [listFilesToUpdate addObject:currentFile];
                }
            }
        }
    }
    DLog(@"Size list: %d", [listFilesToUpdate count]);
    
    //3-Set all the files that need update less the overwritten ones
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            //Only update the field isNecessary update if it is not an overwritten file
            if (!(currentFile.isDownload == overwriting)) {
                correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update = 1 WHERE id = ?", [NSNumber numberWithInt:currentFile.idFile]];
            }
        }
        if (!correctQuery) {
            DLog(@"Error in setUpdateIsNecessaryFromBackup");
        }
    }];
    
    //Releasing memory
    listFilesToUpdate = nil;
    listFilesFromFiles = nil;
    listFilesFromFilesBackup = nil;
}


///-----------------------------------
/// @name setIsNecessaryUpdateOfTheFile
///-----------------------------------

/**
 * This method updates the is_necessary_update field of the file
 *
 * @param idFile -> int
 */
+ (void) setIsNecessaryUpdateOfTheFile: (int) idFile {
    DLog(@"setIsNecessaryUpdateOfTheFile");
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update = 1 WHERE id = ?", [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update the field setIsNecessaryUpdateOfTheFile");
        }
    }];
}


///-----------------------------------
/// @name Delete OffSpring of this Folder
///-----------------------------------

/**
 *
 * Recursive method to delete the offspring of a specific folder.
 * This is neccesary when in the server array after a proffind process
 * the folder does not appear.
 *
 * @param folder -> FileDto
 */
+ (void) deleteOffspringOfThisFolder:(FileDto *)folder{
    
    //Get Files of the Folder
    NSArray *files = [ManageFilesDB getFilesByFileId:folder.idFile];
    
    for (FileDto *tempFile in files) {
        //Check if the item is a directory
        if (tempFile.isDirectory) {
            //Recursive called for the next folder
            [self deleteOffspringOfThisFolder:tempFile];
        }else{
            //Delete a file inside the folder
            [ManageFilesDB deleteFileByIdFile:tempFile.idFile];
        }
    }
    //Finally we delete the folder of the database
    [ManageFilesDB deleteFileByIdFile:folder.idFile];
}


+(void) deleteAllFilesAndFoldersThatNotExistOnServerFromBackup {
    
    DLog(@"deleteAllFilesAndFoldersThatNotExistOnServerFromBackup");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    NSMutableArray *listFilesToDelete = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT files_backup.id, files_backup.file_path, files_backup.file_name, files_backup.is_directory FROM files_backup WHERE files_backup.id NOT IN (SELECT back.id FROM (SELECT id, file_path, file_name FROM files_backup) back, (SELECT id, file_path, file_name FROM files WHERE user_id = ?) files WHERE files.file_path = back.file_path AND files.file_name = back.file_name)", [NSNumber numberWithInt:mUser.idUser]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            
            [listFilesToDelete addObject:currentFile];
        }
        [rs close];
    }];
    
    // Create file manager
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    for(int i = 0 ; i < [listFilesToDelete count] ; i++) {
        
        FileDto *currentFile = [listFilesToDelete objectAtIndex:i];
        
        currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
        
        DLog(@"File download to delete");
        NSError *error;
        
        DLog(@"FileName: %@", currentFile.fileName);
        DLog(@"Delete: %@", currentFile.localFolder);
        
        //if file is directory
        if (currentFile.isDirectory) {
            //Delete the offspring of this directory
            [self deleteOffspringOfThisFolder:currentFile];
        }
        
        // Attempt to delete the file at filePath2
        if ([fileMgr removeItemAtPath:currentFile.localFolder error:&error] != YES) {
            DLog(@"Unable to delete file: %@", [error localizedDescription]);
        } else {
            DLog(@"Deleted");
        }
    }
}


+(void) updateFavoriteFilesFromBackup {
    
    
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
   
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT f.id FROM files f, (SELECT id, file_path, user_id, file_name FROM files_backup WHERE files_backup.is_favorite = 1) b WHERE b.file_path = f.file_path AND b.file_name=f.file_name AND f.user_id = b.user_id"];
        
        while ([rs next]) {
                        
            FileDto *currentFile = [FileDto new];
            
            currentFile.idFile = [rs intForColumn:@"f.id"];
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            correctQuery = [db executeUpdate:@"UPDATE files SET is_favorite = 1 WHERE id = ?", [NSNumber numberWithInt:currentFile.idFile]];
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateFavoriteFilesFromBackup");
        }
    }];
}

+ (void) deleteFilesBackup {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files_backup"];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFilesBackup");
        }
        
    }];
}

+(void) renameFileByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_name=? WHERE id = ?", mNewName, [NSNumber numberWithInt:file.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in renameFileByFileDto");
        }
        
    }];
}

+(void) renameFolderByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    mNewName=[NSString stringWithFormat:@"%@/", mNewName];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_name=? WHERE id = ?", mNewName, [NSNumber numberWithInt:file.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in renameFolderByFileDto");
        }
        
    }];
}

+(BOOL) isFileOnDataBase: (FileDto *)fileDto {
    
    __block int size = 0;
    
    BOOL output = NO;
    DLog(@"File path: %@",fileDto.fileName);
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as NUM FROM files WHERE etag = ? AND user_id = ?", [NSNumber numberWithLongLong:fileDto.etag], [NSNumber numberWithInt:fileDto.userId]];
        while ([rs next]) {
            size = [rs intForColumn:@"NUM"];
        }
        [rs close];
    }];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}

+(void) deleteFileByFilePath: (NSString *) filePathToDelete andFileName: (NSString*)fileName {
    
    DLog(@"deleteFileByFilePath: %@ filePathToDelete andFileName: %@", filePathToDelete, fileName);
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE file_path = ? AND file_name = ? AND user_id = ?",filePathToDelete, fileName, [NSNumber numberWithInt:mUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByFilePath");
        }
    }];
}

+(FileDto *) getFolderByFilePath: (NSString *) newFilePath andFileName: (NSString *) fileName {

    __block FileDto *output = nil;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files WHERE file_path = ? AND file_name = ? AND user_id = ? AND is_directory = 1 ORDER BY file_name ASC", newFilePath, fileName, [NSNumber numberWithInt:mUser.idUser]];
                
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
            
        }
        [rs close];
    }];
    
    return output;
}

+ (void) updateFolderOfFileDtoByNewFilePath:(NSString *) newFilePath andDestinationFileDto:(FileDto *) folderDto andNewFileName:(NSString *)changedFileName andFileDto:(FileDto *) selectedFile {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=?, file_id=?, file_name=? WHERE id = ?", [NSString stringWithFormat:@"%@",newFilePath], [NSNumber numberWithInt:folderDto.idFile], changedFileName, [NSNumber numberWithInt:selectedFile.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updateFolderOfFileDtoByNewFilePath");
        }
        
    }];
}

+(void) updatePath:(NSString *) oldFilePath withNew:(NSString *) newFilePath andFileId:(int) fileId andSelectedFileId:(int) selectedFileId andChangedFileName:(NSString *) fileName {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=?, file_id=?, file_name=? WHERE user_id = ? AND id = ?", newFilePath, [NSNumber numberWithInt:fileId], fileName, [NSNumber numberWithInt:mUser.idUser], [NSNumber numberWithInt:selectedFileId]];
                
        if (!correctQuery) {
            DLog(@"Error in updateFolderOfFileDtoByNewFilePath");
        }
        
    }];
}

+(void) updatePathwithNewPath:(NSString *) newFilePath andFileDto:(FileDto *) selectedFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=? WHERE user_id = ? AND id=?", newFilePath, [NSNumber numberWithInt:mUser.idUser], [NSNumber numberWithInt:selectedFile.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}

+(BOOL) isExistRootFolderByUser:(UserDto *) currentUser {
    
    __block int size = 0;
    
    BOOL output = NO;
    
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) AS NUM FROM files WHERE user_id = ? AND is_root_folder = 1", [NSNumber numberWithInt:currentUser.idUser]];
        while ([rs next]) {
            size = [rs intForColumn:@"NUM"];
        }
        [rs close];
    }];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}

+(void) insertFile:(FileDto *)fileDto {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", fileDto.filePath, fileDto.fileName, [NSNumber numberWithBool:fileDto.isDirectory], [NSNumber numberWithInt:fileDto.userId], [NSNumber numberWithInt:fileDto.isDownload], [NSNumber numberWithLong:fileDto.size], [NSNumber numberWithInt:fileDto.fileId], [NSNumber numberWithLong:fileDto.date], [NSNumber numberWithBool:fileDto.isFavorite], [NSNumber numberWithLongLong:fileDto.etag], [NSNumber numberWithBool:fileDto.isRootFolder], [NSNumber numberWithBool:fileDto.isNecessaryUpdate], [NSNumber numberWithInteger:fileDto.sharedFileSource], fileDto.permissions, [NSNumber numberWithInteger:fileDto.taskIdentifier]];
                        
        if (!correctQuery) {
            DLog(@"Error in insertFile");
        }
        
    }];
}

+(FileDto *) getRootFileDtoByUser:(UserDto *) currentUser {
    
    __block FileDto *output = nil;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE user_id = ? AND is_root_folder = 1 ORDER BY file_name ASC", [NSNumber numberWithInt:currentUser.idUser]];
        
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:currentUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:currentUser];
            output.etag = [rs longLongIntForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
        }
        [rs close];
    }];
    
    return output;
}

+(void) updateEtagOfFileDtoByid:(int) idFile andNewEtag: (long long)etag {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag=? WHERE id = ?", [NSNumber numberWithLongLong:etag], [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}



+(void) updateEtagOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withNewEtag: (long long)etag {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag=? WHERE file_path = ? AND file_name=? AND user_id = ?", [NSNumber numberWithLongLong:etag], filePath, fileName, [NSNumber numberWithInt:aciveUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
    }];
}

+ (void) updateFilesWithFileId:(int) oldFileId withNewFileId:(int) fileId {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_id=? WHERE file_id = ? AND user_id = ?", [NSNumber numberWithInt:fileId], [NSNumber numberWithInt:oldFileId], [NSNumber numberWithInt:mUser.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}

+ (void) setFile:(int)idFile isNecessaryUpdate:(BOOL)isNecessaryUpdate {
    DLog(@"setFileIsDownloadState");
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update=? WHERE id = ?", [NSNumber numberWithInt:isNecessaryUpdate], [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFile:idFile isNecessaryUpdate:isNecessaryUpdate");
        }
        
    }];
}


+ (BOOL) isGetFilesByDownloadState:(enumDownload)downloadState andByUser:(UserDto *) currentUser andFolder:(NSString *) folder {
    
    __block BOOL *output = NO;
    DLog(@"getFilesByFileId:(int) fileId");
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as NUM FROM files WHERE is_download = ? AND user_id = ? AND file_path LIKE ? ORDER BY file_name ASC", [NSNumber numberWithInt:downloadState], [NSNumber numberWithInt:currentUser.idUser], [NSString stringWithFormat:@"%@%%", folder]];
        while ([rs next]) {
            int numberOfFiles = [rs intForColumn:@"NUM"];
            if(numberOfFiles > 0) {
                output = YES;
            }
        }
        [rs close];
    }];
    
    return output;
}

///-----------------------------------
/// @name File is in the Path?
///-----------------------------------

/**
 * Method that indicate if a specific file is into a specific path
 *
 * @param idFile -> NSInteger of id file
 * @param idUser -> NSInteger of id user
 * @param folder -> Folder path
 *
 * @return YES/NO
 *
 */
+ (BOOL) isThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)idUser intoThisFolder:(NSString *)folder{
    
    DLog(@"ManageFiles -> idFile: %d", idFile);
    DLog(@"ManageFiles -> idUser: %d", idUser);
    DLog(@"ManageFiles -> folder: %@", folder);
    
    __block BOOL *output = NO;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id FROM files WHERE user_id = ? AND file_path LIKE ?", [NSNumber numberWithInt:idUser], [NSString stringWithFormat:@"%@%%", folder]];
       
        
        while ([rs next]) {
            NSInteger tempIdFile = 0;
            tempIdFile = [rs intForColumn:@"id"];
            DLog(@"ManageFiles -> idfile: %d",tempIdFile);
            if (tempIdFile == idFile) {
                output=YES;
            }
        }
        [rs close];
    }];
    
    return output;
    
    
}

+ (void) updateFilesByUser:(UserDto *) currentUser andFolder:(NSString *) folder toDownloadState:(enumDownload)downloadState andIsNecessaryUpdate:(BOOL) isNecessaryUpdate {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download = ?, is_necessary_update = ? WHERE user_id = ? AND file_path LIKE ? ", [NSNumber numberWithInt:downloadState],[NSNumber numberWithInt:isNecessaryUpdate], [NSNumber numberWithInt:currentUser.idUser], [NSString stringWithFormat:@"%@%%", folder]];
        
        if (!correctQuery) {
            DLog(@"Error in updateFilesByUserAndFolder");
        }
        
    }];
}

#pragma mark - Share Querys.


///-----------------------------------
/// @name Update Share File Source
///-----------------------------------

/**
 * Method that update share file source
 *
 *
 * @param value -> NSInteger
 * @param idFile -> NSInteger
 * @param idUser -> NSInteger
 *
 */
+ (void) updateShareFileSource:(NSInteger)value forThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)idUser{
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = ? WHERE id = ? AND user_id= ?", [NSNumber numberWithInt:value], [NSNumber numberWithInt:idFile],[NSNumber numberWithInt:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
        
    }];
}

///-----------------------------------
/// @name setUnShareAllFilesByIdUser
///-----------------------------------

/**
 * Method to unshare all the files of one user
 *
 * @param idUser -> NSInteger
 *
 */
+ (void) setUnShareAllFilesByIdUser:(NSInteger)idUser {
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE user_id= ?", [NSNumber numberWithInt:idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
        
    }];
}

///-----------------------------------
/// @name updateFilesAndSetSharedOfUser
///-----------------------------------

/**
 * This method update the Files table and set the relation with the shared
 *
 * @param userId -> NSInteger
 *
 */
+ (void) updateFilesAndSetSharedOfUser:(NSInteger)userId {
    
    NSMutableArray *listOfFileSource = [NSMutableArray new];
    NSMutableArray *listOfidFile = [NSMutableArray new];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT tmp_shared.file_source AS file_source, tmp_file.id AS id_file FROM (SELECT * FROM shared WHERE share_type=3 AND user_id=?) AS tmp_shared, (SELECT id, shared_file_source , ('/' || file_path || file_name) full_file_path FROM files WHERE user_id=?) AS tmp_file WHERE tmp_shared.path = tmp_file.full_file_path AND tmp_shared.file_source != tmp_file.shared_file_source",[NSNumber numberWithInt:userId], [NSNumber numberWithInt:userId]];
        while ([rs next]) {
            
            [listOfFileSource addObject:[NSNumber numberWithInt:[rs intForColumn:@"file_source"]]];
            [listOfidFile addObject:[NSNumber numberWithInt:[rs intForColumn:@"id_file"]]];
             
        }
        [rs close];
    }];
    
    DLog(@"listOfFileSource: %d", [listOfFileSource count]);
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        //listOfFileSource and listOfidFile have the same size
        for(int i = 0 ; i < [listOfFileSource count] ; i++) {
            
            NSNumber *fileSource = [listOfFileSource objectAtIndex:i];
            NSNumber *idFile = [listOfidFile objectAtIndex:i];
            
            correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = ? WHERE id = ?", fileSource, idFile];
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateDownloadedFilesFromBackup");
        }
        
    }];

}

///-----------------------------------
/// @name Delete Shared Data of a list of files
///-----------------------------------

/**
 * This method update to 0 {not shared by link} the status of a list of files
 *
 * @param pathItems -> NSArray
 * @param userId -> NSInteger
 */
+ (void) deleteShareDataOfThisFiles:(NSArray*)pathItems ofUser:(NSInteger)userId{
    
    for (FileDto *file in pathItems) {
         //Update shareFileSource to 0
        [self updateShareFileSource:0 forThisFile:file.idFile ofThisUserId:userId];
        
    }
}



///-----------------------------------
/// @name Get files by download status
///-----------------------------------

/**
 * This method get all the file where the download status is equal to status
 *
 * @param int -> The download status
 *
 * @return NSMutableArray -> The array with the files
 */
+ (NSMutableArray *) getFilesByDownloadStatus:(int) status {
    __block NSMutableArray *output = [NSMutableArray new];
    DLog(@"getFilesByDownloadStatus: %d",status);
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, file_path, file_name, is_directory, user_id, size, file_id, date, etag, is_favorite, is_necessary_update, shared_file_source, permissions, task_identifier FROM files WHERE is_download = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInt:status], [NSNumber numberWithInt:mUser.idUser]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}



///-----------------------------------
/// @name setUnShareFilesByListOfOCShared
///-----------------------------------

/**
 * Method to unshare by link the files that are not unshare anymore
 *
 * @param listOfRemoved -> NSArray
 *
 */
+ (void) setUnShareFilesByUser:(UserDto *) user {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE user_id = ?", [NSNumber numberWithInt:user.idUser]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
    }];
    
    /*for (OCSharedDto *current in listOfRemoved) {
        FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL correctQuery=NO;
            
            correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE shared_file_source = ?", [NSNumber numberWithInt:current.fileSource]];
            
            if (!correctQuery) {
                DLog(@"Error in update share file source");
            }
        }];
    }*/
     
}

///-----------------------------------
/// @name Get the filedto equal with the share dto pah
///-----------------------------------

/**
 * This method return a FileDto with equal share dto path, if 
 * is not catched this method return nil
 *
 * @param path -> NSString
 *
 * @return FileDto
 *
 */
+ (FileDto *) getFileEqualWithShareDtoPath:(NSString*)path andByUser:(UserDto *) user {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;

    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    __block FileDto *output = nil;
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE user_id = ?", [NSNumber numberWithInt:user.idUser]];
        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"/%@%@", [rs stringForColumn:@"file_path"], [rs stringForColumn:@"file_name"]];
            
            //DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                //Store the rs file object
                output = [FileDto new];
                
                output.idFile = [rs intForColumn:@"id"];
                output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
                output.fileName = [rs stringForColumn:@"file_name"];
                output.isDirectory = [rs intForColumn:@"is_directory"];
                output.userId = [rs intForColumn:@"user_id"];
                output.isDownload = [rs intForColumn:@"is_download"];
                output.size = [rs longForColumn:@"size"];
                output.fileId = [rs intForColumn:@"file_id"];
                output.date = [rs longForColumn:@"date"];
                output.isFavorite = [rs intForColumn:@"is_favorite"];
                output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
                output.etag = [rs longLongIntForColumn:@"etag"];
                output.isRootFolder = [rs intForColumn:@"is_root_folder"];
                output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
                output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
                output.permissions = [rs stringForColumn:@"permissions"];
                output.taskIdentifier = [rs intForColumn:@"task_identifier"];
                
            }
        }
        [rs close];
    }];
    
    return output;
}

///-----------------------------------
/// @name is Catched in data base this path
///-----------------------------------

/**
 * This method check if a path is inside the DB
 *
 * @param path -> NSString {/folder1/folder1_1}
 *
 * @return YES/NO
 */
+ (BOOL) isCatchedInDataBaseThisPath: (NSString*)path{
    
    //Ex: /folder1/folder1_1/folder1_1_1/folder1_1_1_1
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    __block NSString *comparePath = nil;
    
    __block BOOL isExist = NO;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE user_id = ? AND is_directory = 1", [NSNumber numberWithInt:app.activeUser.idUser]];
        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"%@%@", [rs stringForColumn:@"file_path"], [rs stringForColumn:@"file_name"]];
            
            // DLog(@"path is: %@ - compare path is: %@", path, comparePath);
            
            if ([path isEqualToString:comparePath]) {
                isExist = YES;
            }
            
            
        }
        [rs close];
    }];

    return isExist;
    
}

///-----------------------------------
/// @name setUnShareFilesOfFolder
///-----------------------------------

/**
 * Method to unshare all the shared of a folder
 *
 * @param folder -> FileDto
 *
 */
+ (void) setUnShareFilesOfFolder:(FileDto *) folder {
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE file_id = ?", [NSNumber numberWithInt:folder.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
    }];
}

#pragma mark - Favorites method

///-----------------------------------
/// @name updateTheFileID:asFavorite:
///-----------------------------------

/**
 * This method updates the favorite field of the file
 *
 * @param idFile -> int
 * @param isFavorite -> BOOL
 */
+ (void) updateTheFileID: (int)idFile asFavorite: (BOOL) isFavorite {
    DLog(@"updateTheFavoriteFile");
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_favorite = ? WHERE id = ?", [NSNumber numberWithInt:isFavorite], [NSNumber numberWithInt:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update favorite file source");
        }
    }];
}


///-----------------------------------
/// @name getAllFavoritesOfUserId:userId
///-----------------------------------

/**
 * This method returned all favorites files of a specific user
 *
 * @param userId -> NSInterger
 *
 * @return NSArray -> Array of favorites items
 */
+ (NSArray*) getAllFavoritesOfUserId:(NSInteger)userId {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    NSMutableArray *tempArray = [NSMutableArray new];
    //Get the user
    UserDto *mUser = [ManageUsersDB getUserByIdUser:userId];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_favorite = 1 AND user_id = ?", [NSNumber numberWithInt:userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs longLongIntForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            
            [tempArray addObject:currentFile];

        }
        [rs close];
    }];
    
    NSArray *output = [NSArray arrayWithArray:tempArray];
    tempArray = nil;
    
    return output;

}


///-----------------------------------
/// @name getFavoriteOfPath:path andUserId:userId
///-----------------------------------

/**
 * This method return favorites files of a specific path and user
 *
 * @param path -> NSString
 * @param userId -> NSInteger
 *
 * @return NSArray
 *
 */
+(NSArray*) getFavoritesOfPath:(NSString*)path andUserId:(NSInteger)userId{
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    NSMutableArray *tempArray = [NSMutableArray new];
    
    //Get the user
    UserDto *mUser = [ManageUsersDB getUserByIdUser:userId];
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_favorite = 1 AND user_id = ?", [NSNumber numberWithInt:userId]];
        
        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            
            DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                FileDto *currentFile = [[FileDto alloc] init];
                
                currentFile.idFile = [rs intForColumn:@"id"];
                currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
                currentFile.fileName = [rs stringForColumn:@"file_name"];
                currentFile.isDirectory = [rs intForColumn:@"is_directory"];
                currentFile.userId = [rs intForColumn:@"user_id"];
                currentFile.isDownload = [rs intForColumn:@"is_download"];
                currentFile.size = [rs longForColumn:@"size"];
                currentFile.fileId = [rs intForColumn:@"file_id"];
                currentFile.date = [rs longForColumn:@"date"];
                currentFile.etag = [rs longLongIntForColumn:@"etag"];
                currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
                currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
                currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
                currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
                currentFile.permissions = [rs stringForColumn:@"permissions"];
                currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
                
                [tempArray addObject:currentFile];
                
            }
        }
        [rs close];
    }];
    
    NSArray *output = [NSArray arrayWithArray:tempArray];
    tempArray = nil;
    
    return output;

}


///-----------------------------------
/// @name deleteAlleTagOfTheDirectoties
///-----------------------------------

/**
 * This method is necessary for updateDBVersion7To8. With it the etag are deleted in order to force the refresh of the file list
 */
+(void) deleteAlleTagOfTheDirectoties {
    
    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag = 0 WHERE is_directory = 1"];
        
        if (!correctQuery) {
            DLog(@"Error in deleteAlleTagOfTheDirectoties");
        }
    }];
}

#pragma mark - TaskIdentifier methods

///-----------------------------------
/// @name update file with task identifier
///-----------------------------------

+ (void) updateFile:(NSInteger)idFile withTaskIdentifier:(NSInteger)taskIdentifier {

    FMDatabaseQueue *queue = [AppDelegate sharedDatabase];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET task_identifier = ? WHERE id = ?", [NSNumber numberWithInteger:taskIdentifier], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update task identifier file source");
        }
    }];
}



@end
