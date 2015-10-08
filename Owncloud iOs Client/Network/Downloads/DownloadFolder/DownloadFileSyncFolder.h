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

- (void) addFileToDownload:(FileDto *) file;

@end
