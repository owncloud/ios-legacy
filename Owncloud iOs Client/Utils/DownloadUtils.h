//
//  DownloadUtils.h
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 29/05/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface DownloadUtils : NSObject

///-----------------------------------
/// @name thereAreDownloadingFilesOnTheFolder
///-----------------------------------

/**
 * This method checks if there are any files on a download process on the selected folder
 *
 * @return thereAreDownloadingFilesOnTheFolder -> BOOL, return YES if there is a file on a download process inside this folder
 */
+ (BOOL) thereAreDownloadingFilesOnTheFolder: (FileDto *) selectedFolder;


///-----------------------------------
/// @name removeDownloadFileWithPath
///-----------------------------------

/**
 * This method removed a downloaded file from the files system.
 *
 * @param path -> local path of the file.
 */
+ (void) removeDownloadFileWithPath:(NSString *)path;

///-----------------------------------
/// @name Update a file with the temporal one
///-----------------------------------

/**
 * This method updates a file because there is a new version in the server
 *
 * @param file > (FileDto) the file to be updated
 * @param temporalFile > (NSString) the path of the temporal file
 */
+ (void) updateFile:(FileDto *)file withTemporalFile:(NSString *)temporalFile;

+ (void) setThePermissionsForFolderPath:(NSString *)folderPath;


///-----------------------------------
/// @name Get if the file is contained by any favorite folder
///-----------------------------------

/**
 * This method check if one of the folders that contains a file is favorite
 *
 * @param file > (FileDto) the file to be checked
 *
 * @return BOOL -> return YES if there is a folder favorite that contains the file
 */
+ (BOOL) isSonOfFavoriteFolder:(FileDto *) file;

///-----------------------------------
/// @name Update all the folders of file contained in a favorite folder
///-----------------------------------

/**
 * This method check if one of the folders that contains a file is favorite
 *
 * @param file > (FileDto) the file son to search the folders
 *
 */
+ (void) setEtagNegativeToAllTheFoldersThatContainsFile:(FileDto *) file;

@end
