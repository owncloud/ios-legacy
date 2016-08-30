//
//  FileListDBOperations.h
//  Owncloud iOs Client
//
// This class have the methods to management the files in
// the database and system
//
//
//  Created by Gonzalo Gonzalez on 09/05/13.
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

@interface FileListDBOperations : NSObject

/*
 *  Method to create the directories in the system
 * with the list of files information
 * @listOfFiles --> List of files and folder of a folder
 */
+ (void) createAllFoldersByArrayOfFilesDto: (NSArray *) listOfFiles andLocalFolder:(NSString *)localFolder;

/*
 * Method that create the root folder
 * @FileDto -> FileDto object of root folder
 */
+ (FileDto*)createRootFolderAndGetFileDtoByUser:(UserDto *) user;


/*
 * Method that realice the refresh process
 *
 */
+ (void)makeTheRefreshProcessWith:(NSMutableArray*)arrayFromServer inThisFolder:(NSInteger)idFolder;


/*
 *  Method to create a folder when the user choose delete a folder in the device
 */
+ (void) createAFolder: (NSString *)folderName inLocalFolder:(NSString *)localFolder;

@end
