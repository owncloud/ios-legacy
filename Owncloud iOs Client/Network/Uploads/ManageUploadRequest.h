//
//  ManageUploadRequest.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 11/11/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <Foundation/Foundation.h>
#import "UtilsNetworkRequest.h"
#import "UtilsNotifications.h"

@class UploadsOfflineDto;
@class UserDto;
@class FileDto;

@protocol ManageUploadRequestDelegate

- (void) uploadCompleted:(NSString*) currentRemoteFolder;
- (void) uploadCanceled:(NSObject*)up;
- (void) uploadFailed:(NSString*)string;
- (void) uploadFailedForLoginError:(NSString*)string;
- (void) uploadLostConnectionWithServer:(NSString*)string;
- (void) uploadAddedContinueWithNext;
- (void) overwriteCompleted;

@end

@interface ManageUploadRequest : NSObject <UtilsNetworkRequestDelegate>

@property(nonatomic, strong) UploadsOfflineDto *currentUpload;
@property(nonatomic, strong) id<ManageUploadRequestDelegate> delegate;
@property(nonatomic, strong) NSString *originPathFile; //*pathOfUpload;
@property(nonatomic, strong) NSString *destinationPath;

@property(nonatomic, strong) UserDto *userUploading;
@property(nonatomic, strong) UtilsNetworkRequest *utilsNetworkRequest;

@property(nonatomic, strong) NSURLSessionUploadTask *uploadTask;

@property(nonatomic) BOOL isFinishTransferLostServer;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *pathOfUpload;
@property(nonatomic, strong) NSString *lenghtOfFile;
@property(nonatomic) float transferProgress;
@property(nonatomic) BOOL isCanceled;
@property(nonatomic) BOOL isUploadBegan;
@property(nonatomic) BOOL isFromBackground;

@property(nonatomic) NSUInteger progressTag;

- (void) addFileToUpload:(UploadsOfflineDto*) currentUpload;

- (void) changeTheStatusToFailForCredentials;
- (void) changeTheStatusToWaitingToServerConnection;
- (void) cancelUpload;
- (void) updateProgressWithPercent:(float)per;
- (void) updateTheEtagOfTheFile: (FileDto *) overwrittenFile;
- (void) refreshPathOfUploadAfterServerChangeUrl;


@end
