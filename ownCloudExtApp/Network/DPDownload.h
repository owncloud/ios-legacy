//
//  DPDownload.h
//  Owncloud iOs Client
//
// Simple download class based in complex download class of the core app.
// Valid for a document provider in order to download one file at time
//
//  Created by Gonzalo Gonzalez on 10/12/14.
//


#import <Foundation/Foundation.h>
#import "FileDto.h"
#import "UserDto.h"
#import "FFCircularProgressView.h"

@protocol DPDownloadDelegate

@optional
- (void)downloadCompleted:(FileDto*)fileDto;
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto;
- (void)downloadCancelled:(FileDto*)fileDto;
@end


@interface DPDownload : NSObject

@property(nonatomic, strong) NSOperation *operation;
@property(nonatomic, strong) FileDto *file;
@property(nonatomic, strong) UserDto *user;
@property(nonatomic, strong) NSString *currentLocalFolder;
@property(nonatomic, strong) NSString *temporalFileName;
@property(nonatomic, strong) NSString *deviceLocalPath;
@property (nonatomic) BOOL isLIFO;
@property (nonatomic) long long etagToUpdate;
@property(nonatomic,weak) __weak id<DPDownloadDelegate> delegate;


- (void) downloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView;
- (void) cancelDownload;

@end
