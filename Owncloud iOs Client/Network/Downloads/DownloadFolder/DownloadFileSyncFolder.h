//
//  DownloadFileSyncFolder.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 07/10/15.
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

@class UserDto;

@interface DownloadFileSyncFolder : NSObject

@property (nonatomic, strong) FileDto *file;

@property (nonatomic, strong) NSString *currentFileEtag;
@property (nonatomic, strong) NSString *tmpUpdatePath;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
//user is needed when we cancel all the downloads in a change of user
@property (nonatomic, strong) UserDto *user;

- (void) addFileToDownload:(FileDto *) file;
- (void) cancelDownload;
- (void) failureDownloadProcess;
- (void) updateDataDownloadSuccess;

@end
