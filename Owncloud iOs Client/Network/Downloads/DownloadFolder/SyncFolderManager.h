//
//  SyncFolderManager.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 25/09/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@class FileDto;
@class CWLOrderedDictionary;
@class IndexedForest;

@protocol SyncFolderManagerDelegate

@optional
- (void) releaseSemaphoreToContinueChangingUser;
@end

@interface SyncFolderManager : NSObject

@property (nonatomic, strong) CWLOrderedDictionary *dictOfFoldersToBeCheck;
@property (nonatomic, strong) IndexedForest *forestOfFilesAndFoldersToBeDownloaded;
@property (nonatomic, strong) NSMutableArray *listOfFilesToBeDownloaded;
@property (nonatomic,weak) __weak id<SyncFolderManagerDelegate> delegate;

- (void) setThePermissionsOnDownloadCacheFolder;
- (void) addFolderToBeDownloaded: (FileDto *) folder;
- (void) cancelDownload: (FileDto *) file;
- (void) cancelAllDownloads;
//Method to add the file to the array just to take into account when we come back from background
- (void) simpleDownloadTheFile:(FileDto *) file andTask:(NSURLSessionDownloadTask *) task;
- (void) cancelDownloadsByFolder:(FileDto *) folder;


@end
