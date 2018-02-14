//
//  OpenInAppHandlerNoInternet.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 13/02/2018.
//

#import "OpenInAppHandlerNoInternet.h"
#import "ManageFilesDB.h"

@implementation OpenInAppHandlerNoInternet

-(id)initWithLink:(NSURL *)linkURL andUser:(UserDto *)user {

    self = [super init];

    if (self) {
        _tappedLinkURL = linkURL;
        _user = user;
    }
    return self;
}

- (void)handleLink:(void (^)(NSArray *))success failure:(void (^)(OCPrivateLinkError))failure {

    NSString *ocID = [self getFileIdFromPrivateLinkWithLink:_tappedLinkURL];
    FileDto *item = [ManageFilesDB getFileDtoByOCid:ocID];
    NSMutableArray *files = [[NSMutableArray alloc] init];

    if (item == nil) {
        failure(OCPrivateLinkErrorFileNotExists);
    }

    if (item.isDownload == 1) {
        if (!item.isDirectory) {
            FileDto *parent = [ManageFilesDB getFileDtoByIdFile: item.idFile];
            [files addObject:parent];
        }
        [files addObject:item];
        success([files copy]);
    } else {
        failure(OCPrivateLinkErrorFileNotExists);
    }
}

-(NSString *)getFileIdFromPrivateLinkWithLink: (NSURL *)privateLink {
    NSString *ocID = [privateLink lastPathComponent];
    return ocID;
}

@end
