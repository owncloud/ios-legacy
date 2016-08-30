//
//  UtilsDtos.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 12/3/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "UserDto.h"
#import "FileDto.h"

@interface UtilsDtos : NSObject

+(NSString *) getDbFolderPathFromFilePath:(NSString *) filePath;
+(NSString *) getDbFolderNameFromFilePath:(NSString *) filePath;

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


@end
