//
//  Download.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 09/01/13.
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
#import "UserDto.h"




extern NSString * fileWasDownloadNotification;

@protocol DownloadDelegate

@optional
//Send the downloading percent of a specific file
- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto;
//Send the downloading string of a specific file
- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto;
//Send the download is complete for a specific file
- (void)downloadCompleted:(FileDto*)fileDto;
//Send the download is failed for a specific file with a custom message
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto;
//Send the download is failed for a credentials error
- (void)errorLogin;
//Send question about the updated file after 0 bytes error
- (void)updateOrCancelTheDownload:(id)download;
@end

@interface Download : NSObject


//Download operation
@property(nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

//Current local folder
@property(nonatomic, strong)NSString *currentLocalFolder;

//Current device local path
@property(nonatomic, strong)NSString *deviceLocalPath;

//Boolean to know if the download is cancel or not
@property(nonatomic) BOOL isCancel;

//Boolean to know if the download is complete
@property(nonatomic) BOOL isComplete;

//Boolean to know if the first time that the download get the progress download
@property(nonatomic) BOOL isFirstTime;

//File object of the download
@property(nonatomic,strong) FileDto *fileDto;
//File object to download
@property(nonatomic,strong) FileDto *fileToDownload;

//Temporal updating name
@property (nonatomic, strong) NSString *temporalFileName;

//Size of the download file
@property(nonatomic) long long totalBytesOfFile;

//Delegate
@property(nonatomic,weak) __weak id<DownloadDelegate> delegate;


//etag
@property(nonatomic,strong) NSString *etagToUpdate;

//know if download has started
@property (nonatomic) BOOL isExecuting;

//property to define if the download use the LIFO downloads queue or FIFO downloads queue
@property (nonatomic) BOOL isLIFO;

@property(nonatomic) BOOL isFromBackground;

@property(nonatomic) BOOL isForceCanceling;

//user is needed when we cancel all the downloads in a change of user
@property (nonatomic, strong) UserDto *user;

///-----------------------------------
/// @name File to Download
///-----------------------------------

/**
 * Method that begin the process to download a specific file
 *
 * @param file -> FileDto
*/
- (void)fileToDownload:(FileDto *)file;

- (void) processToDownloadTheFile;

///-----------------------------------
/// @name Cancel Download
///-----------------------------------

/**
 * Method to cancel the download proccess
 *
 */
- (void)cancelDownload;

///-----------------------------------
/// @name Finalize Download
///-----------------------------------

/**
 * Method to finalize download task when download process has finished
 *
 */
- (void)finalizeDownload;

///-----------------------------------
/// @name Update data Download
///-----------------------------------

/**
 * Method that update the data download
 *
 */
- (void)updateDataDownload;

///-----------------------------------
/// @name Set Download Task Identifier
///-----------------------------------

/**
 * Method used to store a value of task identifier
 *
 * @param isValid -> BOOL {if is true, we store the taskidentifier of a download in background,
 * if not, we store invaid task identifier value
 *
 */
- (void) setDownloadTaskIdentifierValid:(BOOL)isValid;

///-----------------------------------
/// @name Failure Downlod Process
///-----------------------------------
- (void) failureDownloadProcess;

@end
