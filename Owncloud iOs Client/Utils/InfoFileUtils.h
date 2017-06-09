//
//  InfoFileUtils.h
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 06/03/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@class CustomCellFileAndDirectory;
@class FileDto;

@interface InfoFileUtils : NSObject

///-----------------------------------
/// @name getTheDifferenceBetweenDateOfUploadAndNow
///-----------------------------------

/**
 * This method obtains the difference between the upload date and the received date doing
 * a custom string like a:
 * seconds ago
 * minutes ago
 * hours ago
 * days ago
 * the date of upload (When the days > 30)
 *
 * @param NSDate -> date
 *
 * @return NSString -> The searched date
 */
+ (NSString *)getTheDifferenceBetweenDateOfUploadAndNow:(NSDate *)date;

///-----------------------------------
/// @name setTheStatusIconOntheFile:onTheCell:
///-----------------------------------

/**
 * This method set the status icon of the files and folders
 - The general icons of the icons
 - The general icons of the folder (shared by link, shared with user)
 - The shared icon on the right of the file list
 - The status icon of the files
 *
 * @param fileForSetTheStatusIcon -> FileDto, the file for set the status
 * @param fileCell -> CustomCellFileAndDirectory, the cell where the file is located
 * @param currentFolder -> FileDto, of the folder that contain the fileForSetTheStatusIcon
 * @param isCurrentFolderSonOfFavoriteFolder -> BOOL, indicate if the current cell is from a favorit folder
 * @param user -> UserDto.
 */
+ (CustomCellFileAndDirectory *) getTheStatusIconOntheFile: (FileDto *)fileForSetTheStatusIcon onTheCell: (CustomCellFileAndDirectory *)fileCell andCurrentFolder:(FileDto *)currentFolder andIsSonOfFavoriteFolder:(BOOL)isCurrentFolderSonOfFavoriteFolder ofUser:(UserDto *)user;

+ (void)createAllFoldersInFileSystemByFileDto:(FileDto *)file andUserDto:(UserDto *)user;

+ (NSURLSessionTask *) updateThumbnail:(FileDto *) file andUser:(UserDto *) user tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;


///-----------------------------------
/// @name getFileIdFromOcId
///-----------------------------------

/**
 * This method return de file id of the file from the full ocId
 *
 * @param NSString ocId owncloud file id
 *
 * @return NSString -> file id, first 8 characters without inicial zeros
 *
 *  ex: ocId from server: 00000004ocr2n5bhxjux
 *
 *    00000004 => file id
 *    ocr2n5bhxjux => server instance id
 */
+ (NSString *) getFileIdFromOcId:(NSString *)ocId;

@end
