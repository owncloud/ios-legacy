//
//  ManageFilesDB.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 6/21/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "FileDto.h"

@class UserDto;

@interface ManageFilesDB : NSOperation


#pragma mark - Commons methods to work with files
/*
 * Method that give all files from a single folder
 * @fileId -> id of the folder father and we want all his files and folders
 */
+ (NSMutableArray *) getFilesByFileIdForActiveUser:(NSInteger) fileId;

/*
 * Method that give all folders from a single folder
 * @fileId -> id of the folder father and we want all his files and folders
 */
+ (NSMutableArray *) getFoldersByFileIdForActiveUser:(NSInteger) fileId;

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
+ (NSMutableArray *) getFilesByFileId:(NSInteger) fileId;

/*
 * Method that give the file with the idFile 
 * @idFile -> id of tha file that we want
 */
+ (FileDto *) getFileDtoByIdFile:(NSInteger) idFile ;

/*
 * Method that give a file without the idFile but we know the name, the user and where is the file
 * @fileName -> name of the file
 * @filePath -> where is the file
 * @user -> owner of the file
 */
+ (FileDto *) getFileDtoByFileName:(NSString *) fileName andFilePath:(NSString *) filePath andUser:(UserDto *) user;

/*
 * Method that give all the folders and subfolders of a folder
 * @beginFilePath -> file path father of all
 */
+ (NSMutableArray *) getAllFoldersByBeginFilePath:(NSString *) beginFilePath;

/*
 * Method to change the download state of a file
 * @idFile -> id of the file
 * @downloadState -> new state
 */
+(void) setFileIsDownloadState: (NSInteger) idFile andState:(enumDownload)downloadState ;

/*
 * Method to change the download state of a file
 * @FileDto
 * @downloadState -> new state
 */
+(void) updateDownloadStateOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withState:(enumDownload)downloadState;

/*
 * Method to change the filePath of a file
 * @filePath -> new folder
 * @idFile -> id of the file
 */
+(void) setFilePath: (NSString * ) filePath byIdFile: (NSInteger) idFile;

/*
 * Method to insert all the files of a folder
 * @listOfFiles -> List of all the files
 * @fileId -> id of the folder father
 */
+(void) insertManyFiles:(NSMutableArray *)listOfFiles andFileId:(NSInteger)fileId;

/*
 * Method to delete a file
 * @fileId -> id of the file to delete
 */

+(void) deleteFileByIdFileOfActiveUser:(NSInteger) idFile;

///-----------------------------------
/// @name Delete File by idfile
///-----------------------------------

/**
 * Method that delete a file/folder of the database
 *
 * @param idFile -> NSInteger (Item to delete)
 */
+(void) deleteFileByIdFile:(NSInteger) idFile;


#pragma mark - Methods to refresh folder

/*
 * Method to delete all the files and folders from the folder that we want to refresh
 * @fileId -> id of the folder
 */
+(void) deleteFilesFromDBBeforeRefreshByFileId: (NSInteger) fileId;

/*
 * Method to backup the necessary files and folders to make a right refresh and keep the previous information (files downloads, subfolders and favourites)
 * @fileId -> id of the folder
 */
+ (void) backupOfTheProcessingFilesAndFoldersByFileId:(NSInteger) fileId;

/*
 * Method to update the related files from the backup after refresh (related files = subfolders and files from those subfolders)
 */
+ (void) updateRelatedFilesFromBackup;



///-----------------------------------
/// @name updateFilesFromBackup
///-----------------------------------

/**
 * This method update the files DB with the datas located on the files_backup DB
 * 
 * If the file is overwritten we update the fileds: is_download, shared_file_source, providing_file_id and
 * is_overwritten
 *
 * If other case we update the fields: is_download, shared_file_source, providing_file_id and is_overwritten
 * AND etag
 */
+ (void) updateFilesFromBackup;


///-----------------------------------
/// @name setUpdateIsNecessaryFromBackup
///-----------------------------------

/**
 * This method set the field isNecessaryUpdate to YES on the files DB when the file stored etag
 * on the files DB is diferent that the one stored on the files_backup DB
 * The only exception is that the field is not set to YES is the file is overwritten, in this
 * case the etag must be updated on the files DB: check the method updateFilesFromBackup
 *
 * @param idFile -> NSInteger, the file that want to update
 */
+(void) setUpdateIsNecessaryFromBackup:(NSInteger) idFile;


///-----------------------------------
/// @name setIsNecessaryUpdateOfTheFile
///-----------------------------------

/**
 * This method updates the is_necessary_update field of the file
 *
 * @param idFile -> int
 */
+ (void) setIsNecessaryUpdateOfTheFile: (NSInteger) idFile;


/*
 * Method to delete localy the files that was deleted from other App
 */
+ (void) deleteAllFilesAndFoldersThatNotExistOnServerFromBackup;

/*
 * Method to delete the thumbnails not updated after a refresh
 */
+(void) deleteAllThumbnailsWithDifferentEtagFromBackup;

/*
 * Method to update the Favorite files from the backup after refresh
 */
+ (void) updateFavoriteFilesFromBackup;

/*
 * Method to clean the backup folder before use
 */
+ (void) deleteFilesBackup;

#pragma mark - Rename files and folders

/*
 * Method rename a file
 * @file -> fileDto with the original name
 * @mNewName -> new file name
 */
+ (void) renameFileByFileDto:(FileDto *) file andNewName:(NSString *) mNewName;

/*
 * Method rename a folder
 * @file -> fileDto with the original name
 * @mNewName -> new file name
 */
+ (void) renameFolderByFileDto:(FileDto *) file andNewName:(NSString *) mNewName;

/*
 * Method to check if a file is register on the database
 * @fileDto -> fileDto to check if exist
 */
+ (BOOL) isFileOnDataBase: (FileDto *)fileDto;

#pragma mark - Move files and folders

/*
 * Method to delete a file from the Database
 * @filePathToDelete -> path of the file
 * @fileName -> name of the file to delete
 */
+ (void) deleteFileByFilePath: (NSString *) filePathToDelete andFileName: (NSString*)fileName;

/*
 * Method to get the folder of the file that will contain the file after move
 * @newFilePath -> folder of the file after move
 * @fileName -> name of the file to get
 */
+ (FileDto *) getFolderByFilePath: (NSString *) newFilePath andFileName: (NSString *) fileName;

/*
 * Method to update a file wit the destiny after move
 * @newFilePath -> destiny of the file
 * @folderDto -> fileDto with the folder that contain the file
 * @selectedFile -> fileDto with the file that we want move
 */
+ (void) updateFolderOfFileDtoByNewFilePath:(NSString *) newFilePath andDestinationFileDto:(FileDto *) folderDto andNewFileName:(NSString *)changedFileName andFileDto:(FileDto *) selectedFile;

/*
 * Method to update the related files of a moved folder
 * @oldFilePath -> original filePath
 * @newFilePath -> new filePath
 * @fileId -> original file id
 * @selectedFileId -> idFile of the file moved
 * @fileName -> name of the file moved
 */
+(void) updatePath:(NSString *) oldFilePath withNew:(NSString *) newFilePath andFileId:(NSInteger) fileId andSelectedFileId:(NSInteger) selectedFileId andChangedFileName:(NSString *) fileName;

/*
 * Method to update the related files of a folder
 * @newFilePath -> new filePath
 * @selectedFile -> file moved
 */
+ (void) updatePathwithNewPath:(NSString *) newFilePath andFileDto:(FileDto *) selectedFile;

#pragma mark - Manage Root folder by user

/*
 * Method to check if exist the root folder of a UserDto
 * @currentUser -> user to check if exist the root file
 */
+ (BOOL) isExistRootFolderByUser:(UserDto *) currentUser;

/*
 * Method insert a single file. Used only to insert the root folder
 * @fileDto -> file to insert
 */
+ (void) insertFile:(FileDto *)fileDto;

/*
 * Method to get the root folder of a User
 * @currentUser -> user to search the root folder
 */
+ (FileDto *) getRootFileDtoByUser:(UserDto *) currentUser;

#pragma mark - Manage etag

/*
 * Method to update the etag of a file
 * @idFile -> id of the file to update the etag
 * @etag -> new etag
 */
+ (void) updateEtagOfFileDtoByid:(NSInteger) idFile andNewEtag: (NSString *) etag;

/*
 * Method to update the etag of a file
 * @FileDto
 * @etag -> new etag
 */
+(void) updateEtagOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withNewEtag: (NSString *)etag;

/*
 * Method to update the fileId with a new fileId. We use it to update the files of the root folder
 * @oldFileId -> old fileId (usually 0 to update the root folder)
 * @fileId -> new fileId
 */
+ (void) updateFilesWithFileId:(NSInteger) oldFileId withNewFileId:(NSInteger) fileId;


/*
 * Method to set that this file is necessary update or not
 * @idFile -> file id to identify the file that we need change
 * @isNecessaryUpdate -> Boolean to set if we need to update or not
 */
+ (void) setFile:(NSInteger)idFile isNecessaryUpdate:(BOOL)isNecessaryUpdate;


/*
 * Method that give all files with a concrete download state and by active user
 */
+ (BOOL) isGetFilesByDownloadState:(enumDownload)downloadState andByUser:(UserDto *) currentUser andFolder:(NSString *) folder;



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
+ (BOOL) isThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)idUser intoThisFolder:(NSString *)folder;


/*
 * Method that update the download state of all files in a folder by active user
 */
+ (void) updateFilesByUser:(UserDto *) currentUser andFolder:(NSString *) folder toDownloadState:(enumDownload)downloadState andIsNecessaryUpdate:(BOOL) isNecessaryUpdate;

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
+ (void) deleteOffspringOfThisFolder:(FileDto *)folder;


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
+ (void) updateShareFileSource:(NSInteger)value forThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)idUser;


///-----------------------------------
/// @name setUnShareAllFilesByIdUser
///-----------------------------------

/**
 * Method to unshare all the files of one user
 *
 * @param idUser -> NSInteger
 *
 */
+ (void) setUnShareAllFilesByIdUser:(NSInteger)idUser;

///-----------------------------------
/// @name updateFilesAndSetSharedOfUser
///-----------------------------------

/**
 * This method update the Files table and set the relation with the shared
 *
 * @param userId -> NSInteger
 *
 */
+ (void) updateFilesAndSetSharedOfUser:(NSInteger)userId;


///-----------------------------------
/// @name Delete Shared Data of a list of files
///-----------------------------------

/**
 * This method update to 0 {not shared by link} the status of a list of files
 *
 * @param pathItems -> NSArray
 * @param userId -> NSInteger
 */
+ (void) deleteShareDataOfThisFiles:(NSArray*)pathItems ofUser:(NSInteger)userId;



///-----------------------------------
/// @name Get files by download status
///-----------------------------------

/**
 * This method get all the file where the download status is equal to status
 *
 * @param NSInteger -> The download status
 * @param UserDto -> user
 *
 * @return NSMutableArray -> The array with the files
 */
+ (NSMutableArray *) getFilesByDownloadStatus:(NSInteger) status andUser:(UserDto *) user;



///-----------------------------------
/// @name setUnShareFilesByListOfOCShared
///-----------------------------------

/**
 * Method to unshare by link the files that are not unshare anymore
 *
 * @param listOfRemoved -> NSArray
 *
 */
+ (void) setUnShareFilesByUser:(UserDto *) user;


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
+ (FileDto *) getFileEqualWithShareDtoPath:(NSString*)path andByUser:(UserDto *) user;


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
+ (BOOL) isCatchedInDataBaseThisPath: (NSString*)path;


///-----------------------------------
/// @name setUnShareFilesOfFolder
///-----------------------------------

/**
 * Method to unshare all the shared of a folder
 *
 * @param folder -> FileDto
 *
 */
+ (void) setUnShareFilesOfFolder:(FileDto *) folder;

#pragma mark - Favorite methods

///-----------------------------------
/// @name updateTheFileID:asFavorite:
///-----------------------------------

/**
 * This method updates the favorite filed of the file
 *
 * @param idFile -> NSInteger
 * @param isFavorite -> BOOL
 */
+ (void) updateTheFileID: (NSInteger)idFile asFavorite: (BOOL) isFavorite;

///-----------------------------------
/// @name getAllFavoritesFilesOfUserId:userId
///-----------------------------------

/**
 * This method returned all favorites files of a specific user
 *
 * @param userId -> NSInterger
 *
 * @return NSArray -> Array of favorites items
 */
+ (NSArray*) getAllFavoritesFilesOfUserId:(NSInteger)userId;

///-----------------------------------
/// @name getAllFavoritesByFolder:userId
///-----------------------------------

/**
 * This method returned all favorites files of a specific user
 *
 * @param folder -> FolderDto
 *
 * @return NSArray -> Array of favorites items
 */
+ (NSArray*) getAllFavoritesByFolder:(FileDto *) folder;

///-----------------------------------
/// @name setNoFavoritesAllFilesOfAFolder
///-----------------------------------

/**
 * This method set all files and folders of a folder as no favorite
 *
 * @param folder -> FolderDto
 *
 */
+ (void) setNoFavoritesAllFilesOfAFolder:(FileDto *) folder;

#pragma mark - TaskIdentifier methods

///-----------------------------------
/// @name update file with task identifier
///-----------------------------------

+ (void) updateFile:(NSInteger)idFile withTaskIdentifier:(NSInteger)taskIdentifier;


+(void) deleteAlleTagOfTheDirectoties;


#pragma mark - Providing Files

+ (void) updateFile:(NSInteger)idFile withProvidingFile:(NSInteger)providingFileId;

+ (FileDto *) getFileDtoRelatedWithProvidingFileId:(NSInteger)providingFileId ofUser:(NSInteger)userId;



@end
