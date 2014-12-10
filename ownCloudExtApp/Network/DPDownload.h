//
//  DPDownload.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/12/14.
//
//

#import <Foundation/Foundation.h>
#import "FileDto.h"
#import "UserDto.h"
#import "FFCircularProgressView.h"

@protocol DPDownloadDelegate

@optional
- (void)downloadCompleted:(FileDto*)fileDto;
//Send the download is failed for a specific file with a custom message
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto;
@end


@interface DPDownload : NSObject

@property(nonatomic, strong) NSOperation *operation;
@property(nonatomic, strong) FileDto *file;
@property(nonatomic, strong) UserDto *user;
@property(nonatomic, strong) NSString *currentLocalFolder;
@property (nonatomic) BOOL isLIFO;
@property(nonatomic,weak) __weak id<DPDownloadDelegate> delegate;

- (void) downloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView;
- (void) cancelDownload;

@end
