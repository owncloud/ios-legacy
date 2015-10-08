//
//  DownloadFileSyncFolder.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 07/10/15.
//
//

#import <Foundation/Foundation.h>

@interface DownloadFileSyncFolder : NSObject

@property (nonatomic, strong) NSString *currentFileEtag;
@property (nonatomic, strong) NSString *tmpUpdatePath;

@property (nonatomic, strong) NSOperation *operation;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

- (void) addFileToDownload:(FileDto *) file;
- (void) cancelDownload;

@end
