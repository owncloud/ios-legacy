//
//  UtilsDtos.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 12/3/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "UserDto.h"
#import "FileDto.h"

@interface UtilsDtos : NSObject

+(NSString *) getLocalFolderByFilePath:(NSString*) filePath andFileName:(NSString*) fileName andUserDto:(UserDto *) mUser;
+(NSString *) getRemovedPartOfFilePathAnd:(UserDto *)mUserDto;
+(NSString *) getDbBFilePathFromFullFilePath:(NSString *) fullFilePath;
+(NSString *) getDbBFolderPathFromFullFolderPath:(NSString *) fullFilePath;
+(NSString *) getDbFolderPathWithoutUTF8FromFilePath:(NSString *) fullFilePath;
+(NSString *) getDbFolderPathFromFilePath:(NSString *) filePath;
+(NSString *) getDbFolderNameFromFilePath:(NSString *) filePath;
+(NSString *) getFilePathOnDBFromFilePathOnFileDto:(NSString *) filePathOnFileDto;
+(NSString *) getFilePathByRemoteURL:(NSString *) remoteUrl andUserDto:(UserDto *) mUser;
+(NSString *) getRemoteUrlByFile:(FileDto *) file andUserDto:(UserDto *) mUser;
+(NSString *) getServerURLWithoutFolderByUserDto:(UserDto *)mUser;

///-----------------------------------
/// @name Pass OCFileDto Array to FileDto Array
///-----------------------------------

/**
 * This method receive a array with OCFileDto objects
 * and return a similar array with FileDto objects
 *
 * OCFileDto object is the object returned for the OCLibrary
 * FileDto object is the object used in the OC iOS app
 * FileDto is based in OCFileDto
 *
 * @param ocFileDtoArray -> NSMutableArray
 *
 * @return NSMutableArray (Array of FileDto objects)
 *
 */
+(NSMutableArray*) passToFileDtoArrayThisOCFileDtoArray:(NSArray*)ocFileDtoArray;

///-----------------------------------
/// @name Get The Parent Path of the Path
///-----------------------------------

/**
 * Get the parent path of the entire path
 *
 * Example 1: path = /home/music/song.mp3
 *         result = /home/music/
 *
 * @param path -> NSString
 * @return -> NSString
 */
+ (NSString*)getTheParentPathOfThePath:(NSString*)path;

///-----------------------------------
/// @name Get DataBase file_path of fileDto.filePath
///-----------------------------------

/**
 * This method get the real data in the database using the data of the FileDto.
 *
 * Ex: /master/owncloud/remote.php/webdav/music/ --> "music"
 *
 * Ex: /master/owncloud/remote.php/webdav/ --> ""
 *
 * @param path -> NSString
 *
 * @param user -> UserDto
 *
 * @return NSString
 *
 
 */
+ (NSString* )getDBFilePathOfFileDtoFilePath:(NSString*)path ofUserDto:(UserDto*)user;


@end
