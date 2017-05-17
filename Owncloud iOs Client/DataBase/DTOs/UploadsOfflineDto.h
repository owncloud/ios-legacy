//
//  UploadsOfflineDto.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 6/7/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, enumUpload){
    waitingAddToUploadList=0,
    waitingForUpload=1,
    uploading=2,
    uploaded=3,
    errorUploading = 4,
    pendingToBeCheck = 5,
    generatedByDocumentProvider = 6
};

typedef NS_ENUM (NSInteger, enumKindOfError){
    notAnError = -1,
    errorCredentials = 0,
    errorDestinyNotExist = 1,
    errorFileExist = 2,
    errorNotPermission = 3,
    errorUploadFileDoesNotExist = 4,
    errorUploadInBackground = 5,
    errorInvalidPath = 6,
    errorInsufficientStorage = 7,
    errorFirewallRuleNotAllowUpload = 8
};

@interface UploadsOfflineDto : NSObject

@property NSInteger idUploadsOffline;
@property (nonatomic, copy) NSString *originPath;
@property (nonatomic, copy) NSString *destinyFolder;
@property (nonatomic, copy) NSString *uploadFileName;
@property long estimateLength;
@property NSInteger userId;
@property BOOL isLastUploadFileOfThisArray;
@property NSInteger chunkPosition;
@property NSInteger chunkUniqueNumber;
@property long chunksLength;
@property NSInteger status;
@property long uploadedDate;
@property NSInteger kindOfError;
@property BOOL isNotNecessaryCheckIfExist;
@property BOOL isInternalUpload;
@property NSInteger taskIdentifier;


@end
