//
//  ExecuteManager.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExecuteManager.h"
#import "ConnectionManager.h"
#import "UserDto.h"
#import "FileDto.h"
#import "constants.h"
#import "UtilsDtos.h"
#import "AppDelegate.h"
#import "UploadsOfflineDto.h"

static sqlite3 *database = nil;
//static sqlite3_stmt *deleteStmt = nil;
static sqlite3_stmt *insertStmt = nil;
static sqlite3_stmt *selectStmt = nil;
static sqlite3_stmt *dropStmt = nil;

@implementation ExecuteManager

+(void) createDataBase {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "CREATE TABLE IF NOT EXISTS 'users' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'url' VARCHAR, 'username' VARCHAR, 'password' VARCHAR, 'ssl' BOOL, 'activeaccount' BOOL, 'storage_occupied' LONG NOT NULL DEFAULT 0, 'storage' LONG NOT NULL DEFAULT 0)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
 
    
    sql = "CREATE TABLE IF NOT EXISTS 'files' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' LONG, 'is_root_folder' BOOL NOT NULL DEFAULT 0)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    
    sql = "CREATE TABLE IF NOT EXISTS 'files_backup' ('id' INTEGER, 'file_path' VARCHAR, 'file_name' VARCHAR, 'user_id' INTEGER, 'is_directory' BOOL, 'is_download' INTEGER, 'file_id' INTEGER, 'size' LONG, 'date' LONG, 'is_favorite' BOOL, 'etag' LONG, 'is_root_folder' BOOL)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    sql = "CREATE TABLE IF NOT EXISTS 'passcode' ('id' INTEGER PRIMARY KEY, 'passcode' VARCHAR)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    
    sql = "CREATE TABLE IF NOT EXISTS 'certificates' ('id' INTEGER PRIMARY KEY, 'certificate_location' VARCHAR)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    
    sql = "CREATE TABLE IF NOT EXISTS 'db_version' ('id' INTEGER PRIMARY KEY, 'version' INTEGER)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    /*sql = "CREATE TABLE IF NOT EXISTS 'uploads_offline' ('id' INTEGER PRIMARY KEY, 'origin_path' VARCHAR, 'destiny_folder' VARCHAR, 'upload_filename' VARCHAR, 'estimate_length' LONG, 'user_id' INTEGER, 'is_last_upload_file_of_this_Array' BOOL, 'is_chunks_upload' BOOL, 'chunk_position' INTEGER, 'chunk_unique_number' INTEGER, 'chunks_length' LONG, 'status' INTEGER, 'uploaded_date' LONG)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
        }
    }
	// reset SQL sentence
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);*/
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(BOOL) isLocalFolerExistOnFiles {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    BOOL output = YES;
    
    const char *sql = "SELECT count(local_folder) FROM files";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        DLog(@"Table local_folder EXIST");
        output = YES;
    } else {
        DLog(@"Table local_folder NOT EXIST");
        output = NO;
    }
    
	// reset query
    sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close DB connection
    [ConnectionManager closeConnection];
    
    return output;
    
}

+ (void) insertVersionToDataBase:(int) version {
    [self clearTableDbVersion];
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO db_version(version) Values(?)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt, 1, version);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) removeTable:(NSString *) table {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    NSString *sqlString = [NSString stringWithFormat:@"drop table if exists %@;", table];
    
    const char *sql = [sqlString UTF8String];
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        
        sqlite3_bind_text(selectStmt, 1, [table UTF8String], -1, SQLITE_TRANSIENT);
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            
        }
    }
    
	// reset query
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close DB connection
    [ConnectionManager closeConnection];
}

+ (void)clearTableDbVersion {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "DELETE FROM db_version";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+ (UserDto *) getActiveUser {
    
    DLog(@"getActiveUser");
    // Open DB Connection
    database = [ConnectionManager openConnection];
    UserDto *output = [[UserDto alloc] init];
    
    @try {
        const char *sql = "SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage FROM users WHERE activeaccount = 1  ORDER BY id ASC LIMIT 1;";
        if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
            while(sqlite3_step(selectStmt) == SQLITE_ROW) {
                
                output.idUser = sqlite3_column_int(selectStmt, 0);
                output.url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
                output.username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
                output.password = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
                output.ssl = sqlite3_column_int(selectStmt, 4);
                output.activeaccount = sqlite3_column_int(selectStmt, 5);
                output.storageOccupied = sqlite3_column_int64(selectStmt, 6);
                output.storage = sqlite3_column_int64(selectStmt, 7);
            }
        }
        
        // reset query
        sqlite3_reset(selectStmt);
        
        // finalize SQL sentence
        //sqlite3_finalize(selectStmt);
        
        // close DB connection
        [ConnectionManager closeConnection];
    }
    @catch (NSException *exception) {
        DLog(@"Exception: %@", [exception description]);
    }
    @finally {
        
    }
    
    
    
    return output;
}

+ (UserDto *) getUserByIdUser:(int) idUser {
    
    DLog(@"getUserByIdUser:(int) idUser");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    UserDto *output = [[UserDto alloc] init];
    
    @try {
        const char *sql = "SELECT id, url, username, password, ssl, activeaccount, storage_occupied, storage FROM users WHERE id = ?;";
        if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(selectStmt, 1, idUser);
            while(sqlite3_step(selectStmt) == SQLITE_ROW) {
                
                output.idUser = sqlite3_column_int(selectStmt, 0);
                output.url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
                output.username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
                output.password = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
                output.ssl = sqlite3_column_int(selectStmt, 4);
                output.activeaccount = sqlite3_column_int(selectStmt, 5);
                output.storageOccupied = sqlite3_column_int64(selectStmt, 6);
                output.storage = sqlite3_column_int64(selectStmt, 7);
            }
        }
        
        // reset query
        sqlite3_reset(selectStmt);
        
        // finalize SQL sentence
        //sqlite3_finalize(selectStmt);
        
        // close DB connection
        [ConnectionManager closeConnection];
    }
    @catch (NSException *exception) {
        DLog(@"Exception: %@", [exception description]);
    }
    @finally {
        
    }
    
    
    
    return output;
}


+ (BOOL) isExistUser: (UserDto *) userDto {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    BOOL output = NO;
    
    /* NSString *sqlString = [NSString stringWithFormat:@"SELECT id, url, username, password, ssl, activeaccount FROM users WHERE username == '%@' AND url == '%@';", userDto.username,userDto.url];*/
    
    
    NSString *sqlString = [NSString stringWithFormat:@"SELECT id, url, username, password, ssl, activeaccount FROM users WHERE UPPER(username) == UPPER('%@') AND url == '%@';", userDto.username,userDto.url];
    
    const char *sql = [sqlString UTF8String];
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            output = YES;
        }
    }
    
	// reset query
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    
    // close DB connection
    [ConnectionManager closeConnection];
    
    return output;
}

+ (NSMutableArray *) getAllUsers {
    
    DLog(@"getAllUsers");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT id, url, username, password, ssl, activeaccount FROM users ORDER BY id ASC;";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            UserDto *current = [[UserDto alloc] init];
            
            current.idUser = sqlite3_column_int(selectStmt, 0);
            current.url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
            current.username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            current.password = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
            current.ssl = sqlite3_column_int(selectStmt, 4);
            current.activeaccount = sqlite3_column_int(selectStmt, 5);
            
            [output addObject:current];
        }
    }
    
	// reset query
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close DB connection
    [ConnectionManager closeConnection];
    
    return output;
}

+ (UserDto *) getUserByFileDto:(FileDto *) file {
    
    DLog(@"getUserByFileDto:(FileDto *) file");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    UserDto *output = [[UserDto alloc] init];
    
    const char *sql = "SELECT id, url, username, password, ssl, activeaccount FROM users WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, file.userId);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            output.idUser = sqlite3_column_bytes(selectStmt, 0);
            output.url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
            output.username = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            output.password = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
            output.ssl = sqlite3_column_bytes(selectStmt, 4);
            output.activeaccount = sqlite3_column_bytes(selectStmt, 5);
            
        }
    }
    
	// reset query
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close DB connection
    [ConnectionManager closeConnection];
    
    return output;
}

+ (NSMutableArray *) getFilesByFileId:(int) fileId {
    DLog(@"getFilesByFileId:(int) fileId");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files WHERE file_id = ? AND user_id = ? ORDER BY file_name ASC";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, fileId);
        sqlite3_bind_int(selectStmt, 2, mUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            //DLog(@"%@", [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]);
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            currentFile.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            currentFile.isDirectory = sqlite3_column_int(selectStmt, 3);
            currentFile.userId = sqlite3_column_int(selectStmt, 4);
            currentFile.isDownload = sqlite3_column_int(selectStmt, 5);
            currentFile.size = sqlite3_column_int64(selectStmt, 6);
            currentFile.fileId = sqlite3_column_int(selectStmt, 7);
            currentFile.date = sqlite3_column_int64(selectStmt, 8);
            currentFile.isFavorite = sqlite3_column_int(selectStmt, 9);
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            
            [output addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    DLog(@"Output :%d", [output count]);
    
    return output;
}

+ (NSMutableArray *) getFoldersByFileId:(int) fileId {
    UserDto *mUser = [self getActiveUser];
    
    DLog(@"getFoldersByFileId:(int) fileId");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files WHERE file_id = ? AND user_id = ? AND is_directory = 1 ORDER BY file_name ASC";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, fileId);
        sqlite3_bind_int(selectStmt, 2, mUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];            currentFile.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            currentFile.isDirectory = sqlite3_column_int(selectStmt, 3);
            currentFile.userId = sqlite3_column_int(selectStmt, 4);
            currentFile.isDownload = sqlite3_column_int(selectStmt, 5);
            currentFile.size = sqlite3_column_int64(selectStmt, 6);
            currentFile.fileId = sqlite3_column_int(selectStmt, 7);
            currentFile.date = sqlite3_column_int64(selectStmt, 8);
            currentFile.isFavorite = sqlite3_column_int(selectStmt, 9);
            //currentFile.localFolder = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            
            [output addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    // finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+ (FileDto *) getFileDtoByIdFile:(int) idFile {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    FileDto *output = nil;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    DLog(@"getFileByIdFile: %d", idFile);
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder FROM files WHERE id = ? AND user_id = ? ORDER BY file_name ASC";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, idFile);
        sqlite3_bind_int(selectStmt, 2, mUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            output = [[FileDto alloc] init];
            
            output.idFile = sqlite3_column_int(selectStmt, 0);
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            output.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            output.isDirectory = sqlite3_column_int(selectStmt, 3);
            output.userId = sqlite3_column_int(selectStmt, 4);
            output.isDownload = sqlite3_column_int(selectStmt, 5);
            output.size = sqlite3_column_int64(selectStmt, 6);
            output.fileId = sqlite3_column_int(selectStmt, 7);
            output.date = sqlite3_column_int64(selectStmt, 8);
            output.isFavorite = sqlite3_column_int(selectStmt, 9);
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
            output.etag = sqlite3_column_int64(selectStmt, 10);
            output.isRootFolder = sqlite3_column_int(selectStmt, 11);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+(NSMutableArray *) getAllFoldersByBeginFilePath:(NSString *) beginFilePath {
    
    DLog(@"getAllFoldersByBeginFilePath");
    
    // Open DB Connection
    //To the like SQL nedd a % charcter in the sintaxis
    beginFilePath = [NSString stringWithFormat:@"%@%%", beginFilePath];
    
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    const char *sql = "SELECT DISTINCT file_path, file_name, id FROM files WHERE user_id = ? AND file_path LIKE ? ORDER BY file_name ASC";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, mUser.idUser);
        sqlite3_bind_text(selectStmt, 2, [beginFilePath UTF8String], -1, SQLITE_TRANSIENT);
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.filePath = [NSString stringWithFormat:@"%@",[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)]];
            
            currentFile.fileName = [NSString stringWithFormat:@"%@",[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            
            currentFile.idFile=sqlite3_column_int(selectStmt, 2);
            
            
            /* currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)]];*/
            
            DLog(@"Current File Path: %@", currentFile.filePath);
            DLog(@"Current File Name: %@", currentFile.fileName);
            
            [output addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);

    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+ (NSMutableArray *) getAllFiles {
    
    DLog(@"getAllFiles");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files ORDER BY file_name ASC";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            currentFile.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            currentFile.isDirectory = sqlite3_column_int(selectStmt, 3);
            currentFile.userId = sqlite3_column_int(selectStmt, 4);
            currentFile.isDownload = sqlite3_column_int(selectStmt, 5);
            currentFile.size = sqlite3_column_int64(selectStmt, 6);
            currentFile.fileId = sqlite3_column_int(selectStmt, 7);
            currentFile.date = sqlite3_column_int64(selectStmt, 8);
            currentFile.isFavorite = sqlite3_column_int(selectStmt, 9);
            currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            
            [output addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}



+(void) insertUser:(UserDto *)userDto {
    
    DLog(@"Insert user: url:%@ / username:%@ / password:%@ / ssl:%d / activeaccount:%d", userDto.url, userDto.username, userDto.password, userDto.ssl, userDto.activeaccount);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO users(url, username, password, ssl, activeaccount) Values(?, ?, ?, ?, ?)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [userDto.url UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insertStmt, 2, [userDto.username UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStmt, 3, [userDto.password UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt, 4, userDto.ssl);
    sqlite3_bind_int(insertStmt, 5, userDto.activeaccount);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) setFileIsDownloadState: (int) idFile andState:(enumDownload)downloadState {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    DLog(@"Update: %d with isDownload: %d", idFile, downloadState);
    
    const char *sql = "UPDATE files SET is_download=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, downloadState);
    sqlite3_bind_int(insertStmt,2, idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) setActiveAccountByIdUser: (int) idUser {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE users SET activeaccount=1 WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) setAllUsersNoActive {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE users SET activeaccount=0";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) setActiveAccountAutomatically {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE users SET activeaccount=1 WHERE id = (SELECT id FROM users ORDER BY id limit 1)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) setFilePath: (NSString * ) filePath byIdFile: (int) idFile {
    
    DLog(@"NewFilePath: %@", filePath);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET file_path=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [filePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,2, idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) insertManyFiles:(NSMutableArray *)listOfFiles andFileId:(int)fileId {
    
    NSString *sql = @"";
    
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
                    sql = [NSString stringWithFormat:@"INSERT INTO files SELECT null as id, '%@' as 'file_path','%@' as 'file_name', %d as 'user_id', %d as 'is_directory',%d as 'is_download', %d as 'file_id', %@ as 'size', %@ as 'date', %d as 'is_favorite',%lld as 'etag', %d as 'id_root_folder'",
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
                           NO];
                    
                    
                    //DLog(@"sql!!!: %@", sql);
                } else {
                    sql = [NSString stringWithFormat:@"%@ UNION SELECT null, '%@','%@',%d,%d,%d,%d,%@,%@,%d,%lld,%d",
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
                           NO];
                }
                
                numberOfInsertEachTime++;
                
                //DLog(@"sql: %@", sql);
                
                
                if(numberOfInsertEachTime > 450) {
                    
                    numberOfInsertEachTime = 0;
                    
                    // Open de th DB connection
                    database = [ConnectionManager openConnection];
                    
                    if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK)
                        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
                    
                    
                    if(SQLITE_DONE != sqlite3_step(insertStmt))
                        NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
                    
                    //Reset the add statement.
                    sqlite3_reset(insertStmt);
                    
                    //finalize SQL sentence
                    //sqlite3_finalize(insertStmt);
                    
                    
                    // Close the DB connection
                    [ConnectionManager closeConnection];
                }
            }
        }
        
        // To insert the last under 450 inserts
        database = [ConnectionManager openConnection];
        
        //const char *sql = "INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        
        
        if(SQLITE_DONE != sqlite3_step(insertStmt))
            NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
        //finalize SQL sentence
        //sqlite3_finalize(insertStmt);
        
        // Close the DB connection
        [ConnectionManager closeConnection];
        
    }
}

+(void) deleteFilesFromDBBeforeRefreshByFileId: (int) fileId {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    DLog(@"deleteFilesFromDBBeforeRefreshByFileId: %d", fileId);
    
    const char *sql = "DELETE FROM files WHERE file_id = ? AND user_id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, fileId);
    sqlite3_bind_int(insertStmt,2, mUser.idUser);
    
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}



+ (void) backupFoldersDownloadedFavoritesByFileId:(int) fileId {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO files_backup SELECT * FROM files WHERE user_id =? and file_id=? and (is_download = 1 or is_directory = 1 or is_favorite = 1)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, mUser.idUser);
    sqlite3_bind_int(insertStmt,2, fileId);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updateRelatedFilesFromBackup {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *listFilesToUpdate = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT files.id, back.file_id, back.etag FROM files, (SELECT DISTINCT files.file_id, files_backup.file_path, files_backup.file_name, files_backup.etag FROM files_backup, files WHERE files.file_id = files_backup.id AND files_backup.is_directory = 1) back WHERE user_id = ? AND files.file_path = back.file_path AND files.file_name = back.file_name ORDER BY id DESC";
    
    //This query was refresh branch
    //const char *sql = "SELECT files.id, back.file_id FROM files, (SELECT DISTINCT files.file_id, files_backup.file_path, files_backup.file_name FROM files_backup, files WHERE files.file_id = files_backup.id AND files_backup.is_directory = 1) back WHERE user_id = ? AND files.file_path = back.file_path AND files.file_name = back.file_name ORDER BY id DESC";

    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, mUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            currentFile.fileId = sqlite3_column_int(selectStmt, 1);
            currentFile.etag = sqlite3_column_int64(selectStmt, 2);
            
            
            [listFilesToUpdate addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
   
    
    for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
        
        FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
        
        NSString *sql = [NSString stringWithFormat: @"UPDATE files SET id = %d, etag = %lld WHERE id = %d", currentFile.fileId, currentFile.etag, currentFile.idFile];
        DLog(@"SQL: %@", sql);
        
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        }
        
        @try {
            if(SQLITE_DONE != sqlite3_step(insertStmt))
                NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        }
        @catch (NSException *exception) {
            DLog(@"Ghost exception updating floder. Same id: %@", exception);
        }
        @finally {
            
        }
        
        
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
       
    }
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}


+(void) updateDownloadedFilesFromBackup {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *listFilesToUpdate = [[NSMutableArray alloc] init];
    
    
    const char *sql = "SELECT f.id FROM files f, (SELECT id, file_path, file_name FROM files_backup WHERE files_backup.is_download = 1) b WHERE b.file_path = f.file_path AND b.file_name = f.file_name";
    /* const char *sql = "SELECT f.id FROM files f, (SELECT id, file_path, user_id FROM files_backup WHERE files_backup.is_download = 1) b WHERE b.file_path = f.file_path AND f.user_id = b.user_id";*/
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            //currentFile.localFolder = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
            
            [listFilesToUpdate addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
  
    
    DLog(@"Size list: %d", [listFilesToUpdate count]);
    
    for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
        
        FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
        
        DLog(@"FileName: %@", currentFile.fileName);
        
        DLog(@"Current file: %d, %d", currentFile.idFile, currentFile.fileId);
        NSString *sql = [NSString stringWithFormat: @"UPDATE files SET is_download = 1 WHERE id = %d", currentFile.idFile];
        
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        }
        
        if(SQLITE_DONE != sqlite3_step(insertStmt))
            NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
        
        
        /*
         sql = [NSString stringWithFormat: @"UPDATE files SET local_folder = '%@' WHERE id = %d", currentFile.localFolder ,currentFile.idFile];
         
         if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
         NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
         }
         
         if(SQLITE_DONE != sqlite3_step(insertStmt))
         NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
         
         //Reset the add statement.
         sqlite3_reset(insertStmt);*/
        
    }
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updateNewEtagWithOldEtagFromBackup {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET etag = (SELECT etag  FROM files_backup WHERE files_backup.user_id = files.user_id AND files.file_path = files_backup.file_path ) WHERE file_name = (SELECT file_name  FROM files_backup) AND user_id = (SELECT user_id  FROM files_backup) AND file_path = (SELECT file_path  FROM files_backup)";
    
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK) {
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    }
    
    if(SQLITE_DONE != sqlite3_step(insertStmt))
        NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
    
    //Reset the add statement.
    sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}



+(void) deleteAllFilesAndFoldersThatNotExistOnServerFromBackup {
    
    DLog(@"deleteAllFilesAndFoldersThatNotExistOnServerFromBackup");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *listFilesToDelete = [[NSMutableArray alloc] init];
    
    
    const char *sql = "SELECT files_backup.id, files_backup.file_path, files_backup.file_name FROM files_backup WHERE files_backup.id NOT IN (SELECT back.id FROM (SELECT id, file_path, file_name FROM files_backup) back, (SELECT id, file_path, file_name FROM files WHERE user_id = ?) files WHERE files.file_path = back.file_path AND files.file_name = back.file_name)";
    /* const char *sql = "SELECT f.id FROM files f, (SELECT id, file_path, user_id FROM files_backup WHERE files_backup.is_download = 1) b WHERE b.file_path = f.file_path AND f.user_id = b.user_id";*/
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, mUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            currentFile.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            //currentFile.localFolder = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
            
            [listFilesToDelete addObject:currentFile];
        }
    }
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    DLog(@"listFilesToDelete: %d", [listFilesToDelete count]);
    
    if([listFilesToDelete count] == 3) {
        DLog(@"Stop");
    }
    
    // Create file manager
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    for(int i = 0 ; i < [listFilesToDelete count] ; i++) {
        
        FileDto *currentFile = [listFilesToDelete objectAtIndex:i];
        
        currentFile.localFolder = [UtilsDtos getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
        
        DLog(@"File download to delete");
        NSError *error;
        
        DLog(@"FileName: %@", currentFile.fileName);
        DLog(@"Delete: %@", currentFile.localFolder);
        
        // Attempt to delete the file at filePath2
        if ([fileMgr removeItemAtPath:currentFile.localFolder error:&error] != YES) {
            DLog(@"Unable to delete file: %@", [error localizedDescription]);
        } else {
            DLog(@"Deleted");
        }
    }
    
    
}

+(void) updateFavoriteFilesFromBackup {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *listFilesToUpdate = [[NSMutableArray alloc] init];
    
    //const char *sql = "SELECT id FROM files WHERE file_path = (SELECT file_path FROM files_backup WHERE files_backup.is_favorite = 1)";
    const char *sql = "SELECT f.id FROM files f, (SELECT id, file_path, user_id FROM files_backup WHERE files_backup.is_favorite = 1) b WHERE b.file_path = f.file_path AND f.user_id = b.user_id";
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = sqlite3_column_int(selectStmt, 0);
            
            [listFilesToUpdate addObject:currentFile];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    
    for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
        
        FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
        
        // DLog(@"%d, %d", currentFile.idFile, currentFile.fileId);
        NSString *sql = [NSString stringWithFormat: @"UPDATE files SET is_favorite = 1 WHERE id = %d", currentFile.idFile];
        
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        }
        
        if(SQLITE_DONE != sqlite3_step(insertStmt))
            NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
        
    }
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+ (void) deleteFilesBackup {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "DELETE FROM files_backup";
    if(sqlite3_prepare_v2(database, sql, -1, &dropStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error mientras se creaba la sentencia DELETE ALL '%s'", sqlite3_errmsg(database));
    
    if(SQLITE_DONE != sqlite3_step(dropStmt))
        NSAssert1(0, @"Error mientras se borraba todo en la DB con '%s'", sqlite3_errmsg(database));
    
    //Reset the add statement.
    sqlite3_reset(dropStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(dropStmt);
    
    
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
}


+(void) deleteFileByIdFile: (int) idFile {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    DLog(@"deleteFileByIdFile: %d", idFile);
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM files WHERE id = %d AND user_id = %d", idFile, mUser.idUser];
    
    DLog(@"sql: %@", sql);
    
    if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &dropStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error mientras se creaba la sentencia DELETE ALL '%s'", sqlite3_errmsg(database));
    
    if(SQLITE_DONE != sqlite3_step(dropStmt))
        NSAssert1(0, @"Error mientras se borraba todo en la DB con '%s'", sqlite3_errmsg(database));
    
    //Reset the add statement.
    sqlite3_reset(dropStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(dropStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
}

+(BOOL)isPasscode {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    int size = 0;
    
    BOOL output = NO;
    
    const char *sql = "SELECT count(*) FROM passcode";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            size = sqlite3_column_int(selectStmt, 0);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}

+(void) insertPasscode: (NSString *) passcode {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO passcode(passcode) Values(?)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [passcode UTF8String], -1, SQLITE_TRANSIENT);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
   
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(NSString *) getPassCode {
    
    DLog(@"getPassCode");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSString *output = [[NSString alloc] init];
    
    const char *sql = "SELECT passcode FROM passcode  ORDER BY id DESC LIMIT 1;";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            output = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
        }
    }
    
	// reset query
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close DB connection
    [ConnectionManager closeConnection];
    
    return output;
}

+(void) removePasscode {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "DELETE FROM passcode";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}


+(void) removeUserAndDataByIdUser:(int)idUser {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    //Delete user
    const char *sql = "DELETE FROM users WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    
    
    //Delete data
    sql = "DELETE FROM files WHERE user_id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    
    //Delete backup data
    sql = "DELETE FROM files_backup WHERE user_id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) insertCertificate: (NSString *) certificateLocation {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO certificates(certificate_location) Values(?)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [certificateLocation UTF8String], -1, SQLITE_TRANSIENT);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(NSMutableArray*) getAllCertificatesLocation {
    
    DLog(@"getAllCertificatesLocation");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *documentsDirectory = [app getDowloadedPathDependingOfVersion];
    
    NSString *localCertificatesFolder = [NSString stringWithFormat:@"%@/Certificates/",documentsDirectory];
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    const char *sql = "SELECT certificate_location FROM certificates";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            [output addObject:[NSString stringWithFormat:@"%@%@",localCertificatesFolder, [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)]]];
        }
    }
    
    //reset SQL sentence
    sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    DLog(@"Number of certificates: %d", [output count]);
    
    return output;
}

+(void) renameFileByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    // DLog(@"Old FilePath: %@", file.filePath);
    
    /* NSString *filePath = [NSString stringWithFormat:@"%@%@",[file.filePath substringToIndex:file.filePath.length - file.fileName.length], mNewName];*/
    
    // NSString *filePath = file.filePath;
    
    /*  UserDto *mUser = [self getActiveUser];
     
     NSString *filePath = [UtilsDtos getLocalFolderByFilePath:file.filePath andFileName:file.fileName andUserDto:mUser];*/
    
    //  DLog(@"New FilePath:%@", filePath);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    //  const char *sql = "UPDATE files SET file_name=?, file_path=? WHERE id = ?";
    const char *sql = "UPDATE files SET file_name=? WHERE id = ?";
    
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [mNewName UTF8String], -1, SQLITE_TRANSIENT);
    // sqlite3_bind_text(insertStmt, 2, [filePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,2, file.idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) renameFolderByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    mNewName=[NSString stringWithFormat:@"%@/", mNewName];
    
    /* NSString *filePath = [NSString stringWithFormat:@"%@%@",[file.filePath substringToIndex:file.filePath.length - file.fileName.length], mNewName];*/
    
    // DLog(@"FilePath:%@", filePath);
    //  DLog(@"local Folder: %@", localFolder);
    //   DLog(@"file name: %@", file.fileName);
    // const char *sql = "UPDATE files SET file_name=?, file_path=? WHERE id = ?";
    const char *sql = "UPDATE files SET file_name=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [mNewName UTF8String], -1, SQLITE_TRANSIENT);
    // sqlite3_bind_text(insertStmt, 2, [filePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt, 2, file.idFile);
    
    if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updatePassword: (UserDto *) user {
    
    if(user.password != nil) {
        // Open DB Connection
        database = [ConnectionManager openConnection];
        
        const char *sql = "UPDATE users SET password=? WHERE id = ?";
        if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(insertStmt, 1, [user.password UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStmt,2, user.idUser);
        
        if(SQLITE_DONE != sqlite3_step(insertStmt))
            NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
        //finalize SQL sentence
        //sqlite3_finalize(insertStmt);
        
        // close SQL connection
        [ConnectionManager closeConnection];
        
        //Set the active user with the new password.
        if (user.activeaccount==YES) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            app.activeUser=user;
            
            [app clearCookiesForURL];
            [app eraseCredentials];
            [app eraseURLCache];
        }
    }
}

+(BOOL) isFileOnDataBase: (FileDto *)fileDto {
    
    DLog(@"isFileOnDataBase: (FileDto *)fileDto");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    int size = 0;
    
    BOOL output = NO;
    
    const char *sql = "SELECT COUNT(*) FROM files WHERE etag = ? AND user_id = ?";
    
    DLog(@"sql: %@", [NSString stringWithUTF8String:sql]);
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(selectStmt, 1, fileDto.etag);
        sqlite3_bind_int(selectStmt, 2, fileDto.userId);
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            size = sqlite3_column_int(selectStmt, 0);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}

+(void) deleteFileByFilePath: (NSString *) filePathToDelete andFileName: (NSString*)fileName {
    
    DLog(@"deleteFileByFilePath: (NSString *) filePathToDelete andFileName: (NSString*)fileName");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    //DLog(@"SELECT * FROM files WHERE file_path = \"%@\" AND user_id = %d", filePathToDelete, currentUser.idUser);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    //const char *sql = "DELETE FROM files WHERE file_path = ? AND user_id = ?";
    const char *sql = "DELETE FROM files WHERE file_path = ? AND file_name = ? AND user_id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [filePathToDelete UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStmt, 2, [fileName UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,3, mUser.idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(FileDto *) getFolderByFilePath: (NSString *) newFilePath andFileName: (NSString *) fileName {
    
    DLog(@"getFolderByFilePath: (NSString *) newFilePath andFileName: (NSString *) fileName");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    FileDto *output = [[FileDto alloc] init];
        
    NSString *sqlString = [NSString stringWithFormat:@"SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files WHERE file_path = '%@' AND file_name = '%@' AND user_id = %d AND is_directory = 1 ORDER BY file_name ASC", newFilePath, fileName, mUser.idUser];
    
    DLog(@"SQL: %@", sqlString);
    
    const char *sql = [sqlString UTF8String];
    
    //const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite FROM files WHERE file_path = ? AND file_name = ? AND user_id = ? AND is_directory = 1 ORDER BY file_name ASC";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        
        /*sqlite3_bind_text(selectStmt, 1, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
         sqlite3_bind_text(selectStmt, 2, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
         sqlite3_bind_int(selectStmt, 3, mUser.idUser);*/
        
        
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            output.idFile = sqlite3_column_int(selectStmt, 0);
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:mUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            output.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            output.isDirectory = sqlite3_column_int(selectStmt, 3);
            output.userId = sqlite3_column_int(selectStmt, 4);
            output.isDownload = sqlite3_column_int(selectStmt, 5);
            output.size = sqlite3_column_int64(selectStmt, 6);
            output.fileId = sqlite3_column_int(selectStmt, 7);
            output.date = sqlite3_column_int64(selectStmt, 8);
            output.isFavorite = sqlite3_column_int(selectStmt, 9);
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+(void) updateFolderOfFileDtoByNewFilePath:(NSString *) newFilePath andDestinationFileDto:(FileDto *) folderDto andFileDto:(FileDto *) selectedFile {
    
    // DLog(@"ExecuteManager newFilePath: %@", newFilePath);
    DLog(@"ExecuteManager folderDto.idFile: %d", folderDto.idFile);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    DLog(@"%@ - %d - %d", newFilePath, folderDto.idFile, selectedFile.idFile);
    
    const char *sql = "UPDATE files SET file_path=?, file_id=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    // sqlite3_bind_text(insertStmt, 1, [[NSString stringWithFormat:@"%@%@",newFilePath,selectedFile.fileName] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStmt, 1, [[NSString stringWithFormat:@"%@",newFilePath] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,2, folderDto.idFile);
    sqlite3_bind_int(insertStmt,3, selectedFile.idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updatePath:(NSString *) oldFilePath withNew:(NSString *) newFilePath andFileId:(int) fileId andSelectedFileId:(int) selectedFileId andChangedFileName:(NSString *) fileName {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    
    /* NSString *sqlString = [NSString stringWithFormat:@"UPDATE files SET file_path='%@', file_id=%d WHERE user_id = %d AND file_path='%@' AND id = %d", newFilePath, fileId, mUser.idUser, oldFilePath, selectedFileId];*/
    
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE files SET file_path='%@', file_id=%d, file_name='%@' WHERE user_id = %d AND id = %d", newFilePath, fileId, fileName, mUser.idUser, selectedFileId];
    
    
    DLog(@"SQL: %@", sqlString);
    
    const char *sql = [sqlString UTF8String];
    
    //const char *sql = "UPDATE files SET file_path=?, file_id=? WHERE user_id = ? AND file_path=? AND id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    /*sqlite3_bind_text(insertStmt, 1, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_int(insertStmt,2, fileId);
     sqlite3_bind_int(insertStmt,3, mUser.idUser);
     sqlite3_bind_text(insertStmt, 4, [oldFilePath UTF8String], -1, SQLITE_TRANSIENT);
     sqlite3_bind_int(insertStmt,5, selectedFileId);
     */
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updatePathwithNewPath:(NSString *) newFilePath andFileDto:(FileDto *) selectedFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET file_path=? WHERE user_id = ? AND id=? ";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,2, mUser.idUser);
    sqlite3_bind_int(insertStmt,3, selectedFile.idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
}
+(void) updatePath:(NSString *) oldFilePath withNew:(NSString *) newFilePath {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET file_path=? WHERE user_id = ? AND file_path=? ";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,2, mUser.idUser);
    sqlite3_bind_text(insertStmt, 3, [oldFilePath UTF8String], -1, SQLITE_TRANSIENT);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updateFolderByNewFilePath:(NSString *) newFilePath andFileDto:(FileDto *) selectedFile {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET file_path=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [newFilePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt,3, selectedFile.idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

#pragma mark - Database version control

+(int) getDatabaseVersion {
    
    DLog(@"getDatabaseVersion");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    int output = -1;
    
    const char *sql = "SELECT version FROM db_version LIMIT 1";
    
    DLog(@"sql: %@", [NSString stringWithUTF8String:sql]);
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            output = sqlite3_column_int(selectStmt, 0);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    
    DLog(@"Version: %d", output);
    
    return output;
}

+(void) updateVersionBetween1and2AddingEtagColumn {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    //Add on files etag
    const char *sql1 = "ALTER TABLE files ADD etag LONG;";
    if(sqlite3_prepare_v2(database, sql1, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);

    
    
    
    //Add on files is_root_folder
    const char *sql2 = "ALTER TABLE files ADD is_root_folder BOOL NOT NULL DEFAULT 0;";
    if(sqlite3_prepare_v2(database, sql2, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
   
        
    //Add on files_backup etag
    const char *sql3 = "ALTER TABLE files_backup ADD etag LONG;";
    if(sqlite3_prepare_v2(database, sql3, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    
    //Add on files_backup is_root_folder
    const char *sql4 = "ALTER TABLE files_backup ADD is_root_folder BOOL DEFAULT 0;";
    if(sqlite3_prepare_v2(database, sql4, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    
    //Add on users storage_occupied
    const char *sql5 = "ALTER TABLE users ADD storage_occupied LONG NOT NULL DEFAULT 0;";
    if(sqlite3_prepare_v2(database, sql5, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    
    //Add on users storage_occupied
    const char *sql6 = "ALTER TABLE users ADD storage LONG NOT NULL DEFAULT 0;";
    if(sqlite3_prepare_v2(database, sql6, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) updateStorageByUserDto:(UserDto *) user {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE users SET storage_occupied=?, storage=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int64(insertStmt,1, user.storageOccupied);
    sqlite3_bind_int64(insertStmt,2, user.storage);
    sqlite3_bind_int(insertStmt,3, user.idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

#pragma martk - Root folder check
+(BOOL) isExistRootFolderByUser:(UserDto *) currentUser {
    
    DLog(@"isExistRootFolderByUser:(UserDto *) currentUser");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    int size = 0;
    
    BOOL output = NO;
    DLog(@"currentUser: %d", currentUser.idUser);
    
    const char *sql = "SELECT COUNT(*) FROM files WHERE user_id = ? AND is_root_folder = 1";
    
    
    DLog(@"sql: %@", [NSString stringWithUTF8String:sql]);
    
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, currentUser.idUser);
        
        
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            size = sqlite3_column_int(selectStmt, 0);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}


+(void) insertFile:(FileDto *)fileDto {
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_text(insertStmt, 1, [fileDto.filePath UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insertStmt, 2, [fileDto.fileName UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insertStmt, 3, fileDto.isDirectory);
    sqlite3_bind_int(insertStmt, 4, fileDto.userId);
    sqlite3_bind_int(insertStmt, 5, downloading);
    sqlite3_bind_int64(insertStmt, 6, fileDto.size);
    sqlite3_bind_int(insertStmt, 7, fileDto.fileId);
    sqlite3_bind_int64(insertStmt, 8, fileDto.date);
    sqlite3_bind_int(insertStmt, 9, fileDto.isFavorite);
    sqlite3_bind_int64(insertStmt, 10, fileDto.etag);
    sqlite3_bind_int(insertStmt, 11, fileDto.isRootFolder);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(FileDto *) getRootFileDtoByUser:(UserDto *) currentUser {
    
    DLog(@"getRootFileDtoByUser:(UserDto *) currentUser");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    FileDto *output = nil;
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder FROM files WHERE user_id = ? AND is_root_folder = 1 ORDER BY file_name ASC";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_int(selectStmt, 1, currentUser.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            output = [[FileDto alloc] init];
            
            output.idFile = sqlite3_column_int(selectStmt, 0);
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:currentUser],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            output.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            output.isDirectory = sqlite3_column_int(selectStmt, 3);
            output.userId = sqlite3_column_int(selectStmt, 4);
            output.isDownload = sqlite3_column_int(selectStmt, 5);
            output.size = sqlite3_column_int64(selectStmt, 6);
            output.fileId = sqlite3_column_int(selectStmt, 7);
            output.date = sqlite3_column_int64(selectStmt, 8);
            output.isFavorite = sqlite3_column_int(selectStmt, 9);
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:currentUser];
            output.etag = sqlite3_column_int64(selectStmt, 10);
            output.isRootFolder = sqlite3_column_int(selectStmt, 11);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+(void) updateEtagOfFileDtoByid:(int) idFile andNewEtag: (long long)etag {
    
    DLog(@"updateEtagOfFileDtoByid: %d, etag: %lld", idFile, etag);
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET etag=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int64(insertStmt,1, etag);
    sqlite3_bind_int(insertStmt,2, idFile);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(FileDto *) getFileDtoByFileName:(NSString *) fileName andFilePath:(NSString *) filePath andUser:(UserDto *) user {
    
    DLog(@"getFileDtoByFileName:(NSString *) fileName andFilePath:(NSString *) filePath andUser:(UserDto *) user");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    FileDto *output = nil;
    
    const char *sql = "SELECT id, file_path, file_name, is_directory, user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder FROM files WHERE file_name = ? AND file_path= ? AND user_id = ? ORDER BY file_name ASC";
    if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectStmt, 1, [fileName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectStmt, 2, [filePath UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(selectStmt, 3, user.idUser);
        while(sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            output = [[FileDto alloc] init];
            
            output.idFile = sqlite3_column_int(selectStmt, 0);
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsDtos getRemovedPartOfFilePathAnd:user],[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)]];
            output.fileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
            output.isDirectory = sqlite3_column_int(selectStmt, 3);
            output.userId = sqlite3_column_int(selectStmt, 4);
            output.isDownload = sqlite3_column_int(selectStmt, 5);
            output.size = sqlite3_column_int64(selectStmt, 6);
            output.fileId = sqlite3_column_int(selectStmt, 7);
            output.date = sqlite3_column_int64(selectStmt, 8);
            output.isFavorite = sqlite3_column_int(selectStmt, 9);
            output.localFolder = [UtilsDtos getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:user];
            output.etag = sqlite3_column_int64(selectStmt, 10);
            output.isRootFolder = sqlite3_column_int(selectStmt, 11);
        }
    }
    
	//reset SQL sentence
	sqlite3_reset(selectStmt);
    
    //finalize SQL sentence
    sqlite3_finalize(selectStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
    
    return output;
}

+(void) updateFilesWithFileId:(int) oldIdFile withNewFileId:(int) idFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserDto *mUser = app.activeUser;
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE files SET file_id=? WHERE file_id = ? AND user_id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, idFile);
    sqlite3_bind_int(insertStmt,2, oldIdFile);
    sqlite3_bind_int(insertStmt,3, mUser.idUser);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

#pragma mark - Uploads
+(void) insertUpload:(UploadsOfflineDto *) upload {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO uploads_offline (origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, is_chunks_upload, chunk_position, chunk_unique_number, chunks_length, status) Values('%@', '%@', '%@',%ld, %d, %d, %d, %d, %d, %ld, %d)", upload.originPath,upload.destinyFolder,upload.uploadFileName, upload.estimateLength, upload.userId, upload.isLastUploadFileOfThisArray, upload.isChunksUpload, upload.chunkPosition, upload.chunkUniqueNumber, upload.chunksLength,upload.status];
    
    DLog(@"sqlString: %@", sqlString);
    
    const char *sql = [sqlString UTF8String];
    
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));

	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(UploadsOfflineDto *) getFirstUpload {
    
    UploadsOfflineDto *output;
    
    return output;
}

+(UploadsOfflineDto *) getLastUpload {
    
    DLog(@"getLastUpload");
    
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    UploadsOfflineDto *output = [[UploadsOfflineDto alloc] init];
    
    @try {
        const char *sql = "SELECT id, origin_path, destiny_folder, upload_filename, estimate_length, user_id, is_last_upload_file_of_this_Array, is_chunks_upload, chunk_position, chunk_unique_number, chunks_length, status FROM uploads_offline ORDER BY id DESC LIMIT 1;";
        if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
            while(sqlite3_step(selectStmt) == SQLITE_ROW) {
                
                output.idUploadsOffline = sqlite3_column_int(selectStmt, 0);
                output.originPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
                output.destinyFolder = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
                output.uploadFileName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
                output.estimateLength = sqlite3_column_int64(selectStmt, 4);
                output.userId = sqlite3_column_int(selectStmt, 5);
                output.isLastUploadFileOfThisArray = sqlite3_column_int(selectStmt, 6);
                output.isChunksUpload = sqlite3_column_int(selectStmt, 7);
                output.chunkPosition = sqlite3_column_int(selectStmt, 8);
                output.chunkUniqueNumber = sqlite3_column_int(selectStmt, 9);
                output.chunksLength = sqlite3_column_int64(selectStmt, 10);
                output.status = sqlite3_column_int(selectStmt, 11);
            }
        }
        
        // reset query
        sqlite3_reset(selectStmt);
        
        // finalize SQL sentence
        //sqlite3_finalize(selectStmt);
        
        // close DB connection
        [ConnectionManager closeConnection];
    }
    @catch (NSException *exception) {
        DLog(@"Excepction: %@", [exception description]);
    }
    @finally {
        
    }
    
    
    
    return output;
}

+(void) updateUploadOfflineStatusByUploadOfflineDto:(UploadsOfflineDto *) upload {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "UPDATE uploads_offline SET status=? WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt, 1, upload.status);
    sqlite3_bind_int(insertStmt,2, upload.idUploadsOffline);
    
	if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) deleteUploadOfflineByUploadOfflineDto:(UploadsOfflineDto *) upload {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "DELETE FROM uploads_offline WHERE id = ?";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    sqlite3_bind_int(insertStmt,1, upload.idUploadsOffline);
    
    if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) cleanTableUploadsOffline {
    // Open DB Connection
    database = [ConnectionManager openConnection];
    
    const char *sql = "DELETE FROM uploads_offline";
    if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
    
    if(SQLITE_DONE != sqlite3_step(insertStmt))
		NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
	
	//Reset the add statement.
	sqlite3_reset(insertStmt);
    
    //finalize SQL sentence
    //sqlite3_finalize(insertStmt);
    
    // close SQL connection
    [ConnectionManager closeConnection];
}

+(void) insertManyUploadsOffline:(NSMutableArray *) listOfUploadOffline {
    
    NSString *sql = @"";
    
    int numberOfInsertEachTime = 0;
    
    //if count == 1 the file is the current folder so there is nothing to insert
    if([listOfUploadOffline count] > 0) {
        for (int i = 0; i < [listOfUploadOffline count]; i++) {
            
            //INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date
            
            UploadsOfflineDto *current = [listOfUploadOffline objectAtIndex:i];
            
            //to jump the first becouse it is not necesary (is the same directory) and the other if is to insert 450 by 450
            if(numberOfInsertEachTime == 0) {
                
                //, , , , , chunkUniqueNumber, chunksLength, status
                
                sql = [NSString stringWithFormat:@"INSERT INTO uploads_offline SELECT null as id, '%@' as 'origin_path','%@' as 'destiny_folder', '%@' as 'upload_filename', %ld as 'estimate_length',%d as 'user_id', %d as 'is_last_upload_file_of_this_Array', %d as 'is_chunks_upload', %d as 'chunk_position', %d as 'chunk_unique_number',%ld as 'chunks_length', %d as 'status',%ld as 'upload_date'",
                       current.originPath,
                       current.destinyFolder,
                       current.uploadFileName,
                       current.estimateLength,
                       current.userId,
                       current.isLastUploadFileOfThisArray,
                       current.isChunksUpload,
                       current.chunkPosition,
                       current.chunkUniqueNumber,
                       current.chunksLength,
                       current.status,
                       current.uploadDate];
                
                
                //DLog(@"sql!!!: %@", sql);
            } else {
                sql = [NSString stringWithFormat:@"%@ UNION SELECT null, '%@','%@','%@',%ld,%d,%d,%d,%d,%d,%ld,%d, %ld",
                       sql,
                       current.originPath,
                       current.destinyFolder,
                       current.uploadFileName,
                       current.estimateLength,
                       current.userId,
                       current.isLastUploadFileOfThisArray,
                       current.isChunksUpload,
                       current.chunkPosition,
                       current.chunkUniqueNumber,
                       current.chunksLength,
                       current.status,
                       current.uploadDate];
            }
            
            numberOfInsertEachTime++;
            
            
            if(numberOfInsertEachTime > 450) {
                
                numberOfInsertEachTime = 0;
                
                // Open de th DB connection
                database = [ConnectionManager openConnection];
                
                if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
                
                
                if(SQLITE_DONE != sqlite3_step(insertStmt))
                    NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
                
                //Reset the add statement.
                sqlite3_reset(insertStmt);
                
                //finalize SQL sentence
                //sqlite3_finalize(insertStmt);
                
                
                // Close the DB connection
                [ConnectionManager closeConnection];
            }
        }
        
        // To insert the last under 450 inserts
        database = [ConnectionManager openConnection];
        
        //const char *sql = "INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
        
        
        if(SQLITE_DONE != sqlite3_step(insertStmt))
            NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
        
        //Reset the add statement.
        sqlite3_reset(insertStmt);
        
        //finalize SQL sentence
        //sqlite3_finalize(insertStmt);
        
        // Close the DB connection
        [ConnectionManager closeConnection];
        
        DLog(@"sql: %@", sql);
        
    }
}

/*
 
 - (void) insertDB:(NSMutableArray *)poi {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 
 const char *sql = "INSERT INTO Poi(idPoi, title, categoria, lat, lon, descripcion, provincia, imagen, puntoinformacion, telefono, web, denominacion) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
 if(sqlite3_prepare_v2(database, sql, -1, &insertStmt, NULL) != SQLITE_OK)
 NSAssert1(0, @"Error while create INSERT sentence '%s'", sqlite3_errmsg(database));
 
 
 POI *poiInsertar = [[[POI alloc] init] autorelease];
 poiInsertar = [poi objectAtIndex:0];
 
 DLog(@"POI a insertar: id:%@ / tipo:%@ / lat:%@ / lon:%@", poiInsertar.idPoi, poiInsertar.categoria, poiInsertar.lat, poiInsertar.lon);
 
 sqlite3_bind_text(insertStmt, 1, [poiInsertar.idPoi UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 2, [poiInsertar.title UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 3, [poiInsertar.categoria UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 4, [poiInsertar.lat UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 5, [poiInsertar.lon UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 6, [poiInsertar.descripcion UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 7, [poiInsertar.provincia UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 8, [poiInsertar.imagen UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 9, [poiInsertar.puntoinformacion UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 10, [poiInsertar.telefono UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 11, [poiInsertar.web UTF8String], -1, SQLITE_TRANSIENT);
 sqlite3_bind_text(insertStmt, 12, [poiInsertar.denominacion UTF8String], -1, SQLITE_TRANSIENT);
 
 if(SQLITE_DONE != sqlite3_step(insertStmt))
 NSAssert1(0, @"Error while insert on the DB '%s'", sqlite3_errmsg(database));
 
 //Reset the add statement.
 sqlite3_reset(insertStmt);
 
 // close SQL connection
 [ConnectionManager closeConnection];
 }
 
 - (void) deleteTable {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 
 const char *sql = "DELETE  FROM Poi";
 if(sqlite3_prepare_v2(database, sql, -1, &dropStmt, NULL) != SQLITE_OK)
 NSAssert1(0, @"Error mientras se creaba la sentencia DELETE ALL '%s'", sqlite3_errmsg(database));
 
 if(SQLITE_DONE != sqlite3_step(dropStmt))
 NSAssert1(0, @"Error mientras se borraba todo en la DB con '%s'", sqlite3_errmsg(database));
 
 //Reset the add statement.
 sqlite3_reset(dropStmt);
 
 // close SQL connection
 [ConnectionManager closeConnection];
 
 }
 
 - (void) updateDB:(NSMutableArray *)poi {
 
 POI *poiInsertar = [[POI alloc] init];
 poiInsertar = [poi objectAtIndex:0];
 
 [self deleteDB:[poiInsertar.idPoi intValue]];
 [self insertDB:poi];
 }
 
 - (void) deleteDB:(int)poi {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 
 const char *sql = "DELETE FROM Poi WHERE idPoi = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL) != SQLITE_OK)
 NSAssert1(0, @"Error al crear la sentencia DELETE con '%s'", sqlite3_errmsg(database));
 
 
 // When binding parameters, index starts from 1 and not zero
 sqlite3_bind_int(deleteStmt, 1, poi);
 
 if (SQLITE_DONE != sqlite3_step(deleteStmt))
 NSAssert1(0, @"Error mientras borrabamos con '%s'", sqlite3_errmsg(database));
 
 sqlite3_reset(deleteStmt);
 
 // close SQL connection
 [ConnectionManager closeConnection];
 }
 
 + (NSString *) selectDBMaxVersion {
 // Open DB Connection
 database = [ConnectionManager openConnection];
 
 NSString *version = nil;
 
 const char *sql = "SELECT MAX(version) FROM Poi";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 version = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 }
 }
 
 //Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return version;
 }
 
 + (void) deleteByDate:(NSString *)date {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 
 const char *sql = "DELETE FROM Poi WHERE datetime(fechafin) < datetime(?)";
 if(sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL) != SQLITE_OK)
 NSAssert1(0, @"Error al crear la sentencia DELETE con '%s'", sqlite3_errmsg(database));
 
 // When binding parameters, index starts from 1 and not zero
 sqlite3_bind_text(deleteStmt, 1, [date UTF8String], -1, SQLITE_TRANSIENT);
 
 if (SQLITE_DONE != sqlite3_step(deleteStmt))
 NSAssert1(0, @"Error mientras borrabamos con '%s'", sqlite3_errmsg(database));
 
 sqlite3_reset(deleteStmt);
 
 // close SQL connection
 [ConnectionManager closeConnection];
 
 }
 
 + (NSMutableArray *) selectDBid:(int)poi {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSMutableArray *poiSelect = [[[NSMutableArray alloc] init] autorelease];
 
 const char *sql = "SELECT * FROM Poi WHERE idPoi = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 sqlite3_bind_int(selectStmt, 1, poi);
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 POI *poiObj = [[POI alloc] init];
 poiObj.idPoi = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 poiObj.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 poiObj.categoria = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
 poiObj.lat = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 poiObj.lon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 5)];
 poiObj.descripcion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 poiObj.provincia = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 7)];
 poiObj.imagen = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 8)];
 poiObj.puntoinformacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 9)];
 poiObj.telefono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
 poiObj.web = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 11)];
 poiObj.denominacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 12)];
 
 [poiSelect addObject:poiObj];
 
 [poiObj release];
 }
 }
 
 //Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return poiSelect;
 }
 
 + (NSMutableArray *) selectDBcat:(int)cat {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSMutableArray *poiSelect = [[[NSMutableArray alloc] init] autorelease];
 
 const char *sql = "SELECT * FROM Poi WHERE categoria = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 sqlite3_bind_int(selectStmt, 1, cat);
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 POI *poiObj = [[POI alloc] init];
 poiObj.idPoi = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 poiObj.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 poiObj.categoria = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
 poiObj.lat = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 poiObj.lon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 5)];
 poiObj.descripcion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 poiObj.provincia = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 7)];
 poiObj.imagen = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 8)];
 poiObj.puntoinformacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 9)];
 poiObj.telefono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
 poiObj.web = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 11)];
 poiObj.denominacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 12)];
 
 // Filtramos por distancia
 if ([PoisVisibles distanciaPOIlat:poiObj.lat distanciaPOIlon:poiObj.lon]) {
 [poiSelect addObject:poiObj];
 }
 
 [poiObj release];
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return poiSelect;
 }
 
 + (NSString *) getNameCat:(int)idCat {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSString *nameCat = @"";
 
 const char *sql = "SELECT * FROM Categoria WHERE rowid = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 sqlite3_bind_int(selectStmt, 1, idCat);
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 NSString *buffer = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 if (![nameCat isEqualToString:@""])
 nameCat = [nameCat stringByAppendingString:@", "];
 nameCat = [nameCat stringByAppendingString:buffer];
 
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return nameCat;
 }
 
 + (Category *) getCat:(int)cat {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 Category *nameCat = [[Category alloc] init];
 
 const char *sql = "SELECT * FROM Categoria WHERE id = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 sqlite3_bind_int(selectStmt, 1, cat);
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 nameCat.nombre = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 nameCat.icono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 2)];
 nameCat.img = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 nameCat.imgpressed = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return nameCat;
 }
 
 + (NSMutableArray *) selectPOIporCat:(NSMutableArray *)cat {
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSMutableArray *poiSelect = [[[NSMutableArray alloc] init] autorelease];
 
 for (int i = 0; i < [cat count]; i++) {
 const char *sql = "SELECT * FROM Poi WHERE categoria = ?";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 sqlite3_bind_text(selectStmt, 1, [[cat objectAtIndex:i] UTF8String], -1, SQLITE_TRANSIENT);
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 POI *poiObj = [[POI alloc] init];
 poiObj.idPoi = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 poiObj.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 poiObj.categoria = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
 poiObj.lat = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 poiObj.lon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 5)];
 poiObj.descripcion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 poiObj.provincia = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 7)];
 poiObj.imagen = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 8)];
 poiObj.puntoinformacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 9)];
 poiObj.telefono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
 poiObj.web = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 11)];
 poiObj.denominacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 12)];
 
 // Filtramos por distancia
 if ([PoisVisibles distanciaPOIlat:poiObj.lat distanciaPOIlon:poiObj.lon]) {
 [poiSelect addObject:poiObj];
 }
 
 [poiObj release];
 }
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return poiSelect;
 }
 
 + (NSMutableArray *) selectDBAllFalseLat:(float)lat selectDBAllFalseLon:(float)lon {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSMutableArray *poiSelect = [[[NSMutableArray alloc] init] autorelease];
 
 const char *sql = "SELECT * FROM Poi";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 POI *poiObj = [[POI alloc] init];
 poiObj.idPoi = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 poiObj.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 poiObj.categoria = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
 poiObj.lat = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 poiObj.lon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 5)];
 poiObj.descripcion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 poiObj.provincia = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 7)];
 poiObj.imagen = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 8)];
 poiObj.puntoinformacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 9)];
 poiObj.telefono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
 poiObj.web = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 11)];
 poiObj.denominacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 12)];
 
 // Filtramos por distancia
 
 if ([PoisVisibles distanciaFalsaPOIlat:poiObj.lat distanciaFalsaPOIlon:poiObj.lon latFalsa:lat lonFalsa:lon]) {
 [poiSelect addObject:poiObj];
 }
 
 [poiObj release];
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return poiSelect;
 }
 
 + (NSMutableArray *) selectDBAll {
 
 // Open DB Connection
 database = [ConnectionManager openConnection];
 NSMutableArray *poiSelect = [[[NSMutableArray alloc] init] autorelease];
 
 const char *sql = "SELECT * FROM Poi";
 if(sqlite3_prepare_v2(database, sql, -1, &selectStmt, NULL) == SQLITE_OK) {
 while(sqlite3_step(selectStmt) == SQLITE_ROW) {
 
 POI *poiObj = [[POI alloc] init];
 poiObj.idPoi = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 0)];
 poiObj.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 1)];
 poiObj.categoria = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 3)];
 poiObj.lat = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 4)];
 poiObj.lon = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 5)];
 poiObj.descripcion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 6)];
 poiObj.provincia = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 7)];
 poiObj.imagen = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 8)];
 poiObj.puntoinformacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 9)];
 poiObj.telefono = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 10)];
 poiObj.web = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 11)];
 poiObj.denominacion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStmt, 12)];
 
 // Filtramos por distancia
 if ([PoisVisibles distanciaPOIlat:poiObj.lat distanciaPOIlon:poiObj.lon]) {
 [poiSelect addObject:poiObj];
 }
 
 [poiObj release];
 }
 }
 
 // Reseteamos la sentencia
 sqlite3_reset(selectStmt);
 
 // Cerramos la conexión
 [ConnectionManager closeConnection];
 
 return poiSelect;
 }
 */

@end
