//
//  UtilsUrls.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 16/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@class UserDto;
@class FileDto;

@interface UtilsUrls : NSObject

+ (NSString *) getOwnCloudFilePath;
+ (NSString *) getBundleOfSecurityGroup;
+ (NSString *) bundleSeedID;
+ (NSString *) getFullBundleSecurityGroup;
+ (NSString *) getThumbnailFolderPath;

//Method to skip a file to a iCloud backup
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

//We remove the part of the remote file path that is not necesary
+ (NSString *) getRemovedPartOfFilePathAnd:(UserDto *)mUserDto;

//We generate de local path of the files dinamically
+ (NSString *)getLocalFolderByFilePath:(NSString*) filePath andFileName:(NSString*) fileName andUserDto:(UserDto *) mUser;


//Get the relative path of the document provider using an absolute path
+ (NSString *)getRelativePathForDocumentProviderUsingAboslutePath:(NSString *) abosolutePath;

//Get the path of the temp folder where there are the temp files for the uploads
+ (NSString *) getTempFolderForUploadFiles;

+ (NSString *) getFilePathOnDBByFullPath:(NSString *)filePath andUser:(UserDto *)mUserDto;

+ (NSString *) getFullRemoteServerPath:(UserDto *)mUserDto;

+ (NSString *) getRemoteServerPathWithoutFolders:(UserDto *)mUser;

+ (NSString *) getFullRemoteServerPathWithWebDav:(UserDto *)mUserDto;

+ (NSString *) getPathWithAppNameByDestinyPath:(NSString *)destinyPath andUser:(UserDto *)mUserDto;

+ (NSString *) getFullRemoteServerPathWithoutProtocol:(UserDto *)mUserDto;

+ (NSString *) getUrlServerWithoutHttpOrHttps:(NSString*) url;

//-----------------------------------
/// @name Get a domain by a URL
///-----------------------------------

/**
 * Method used to get only the domain and the protocol (http/https)
 *
 * @param NSString -> url
 *
 * @return NSString
 *
 */
+ (NSString *) getHttpAndDomainByURL:(NSString *) url;

+ (NSString *) getFilePathOnDBByFilePathOnFileDto:(NSString *) filePathOnFileDto andUser:(UserDto *) user;

+ (NSString *) getFilePathOnDBWithFileName:(NSString *)fileName ByFilePathOnFileDto:(NSString *)filePathOnFileDto andUser:(UserDto *) user;

+ (NSString *) getFilePathOnDBwithRootSlashAndWithFileName:(NSString *)fileName ByFilePathOnFileDto:(NSString *)filePathOnFileDto andUser:(UserDto *) user;

+ (NSString *) getFullRemoteServerFilePathByFile:(FileDto *) file andUser:(UserDto *) user;

+ (NSString *) getFullRemoteServerParentPathByFile:(FileDto *) file andUser:(UserDto *) user;

+ (NSString *) getUserAgent;

+ (BOOL) isFileUploadingWithPath:(NSString *)path andUser: (UserDto *) user;

///-----------------------------------
/// @name getKeyByLocalFolder
///-----------------------------------
/**
 * Return the key that identify a file in the dictionary for download a full folder
 *
 * @param localFolder -> /Users/Javi/Library/Developer/CoreSimulator/Devices/3A4FE170-2053-4D9E-9FF0-D2F5FC65C2D4/data/Containers/Shared/AppGroup/8F60BA9F-0A8B-472E-AC05-00A8A66F6CFC/cache_folder/3/Documents/
 *                    -> /Users/Javi/Library/Developer/CoreSimulator/Devices/3A4FE170-2053-4D9E-9FF0-D2F5FC65C2D4/data/Containers/Shared/AppGroup/8F60BA9F-0A8B-472E-AC05-00A8A66F6CFC/cache_folder/3/Documents/File.pdf
 *
 * @return  pathWithAppName -> Documents/
 *                          -> Documents/File.pdf
 */
+ (NSString *) getKeyByLocalFolder:(NSString *) localFolder;

+ (NSString *) getFileLocalSystemPathByFullPath:(NSString *)fullRemotePath andUser:(UserDto *)user;

+ (NSString *) getFileLocalSystemPathByFileDto:(FileDto *)fileDto andUser:(UserDto *)user;

+ (NSString *) getLocalCertificatesPath;

+ (NSString *) getRelatvePathOfFullDestinyPath: (NSString *) fullPath;


+ (BOOL) isNecessaryUpdateToPredefinedUrlByPreviousUrl:(NSString *)oldPredefinedUrl;

+ (NSString *) getFullRemoteServerPathWithoutProtocolBeginningWithUsername:(UserDto *)mUserDto;

@end
