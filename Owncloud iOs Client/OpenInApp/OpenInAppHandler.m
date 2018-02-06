//  Copyright (C) 2018, ownCloud GmbH.
//  This code is covered by the GNU Public License Version 3.
//  For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
//  You should have received a copy of this license along with this program.
//  If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
//
//  @Authors
//      Pablo Carrascal.

#import "OpenInAppHandler.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "ManageFilesDB.h"
#import "UtilsDtos.h"

@implementation OpenInAppHandler

-(id)initWithLink:(NSURL *)linkURL andUser:(UserDto *) user {

    self = [super init];

    if (self) {
        _tappedLinkURL = linkURL;
        _user = user;
    }
    return self;
}

-(void)handleLink:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {

    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {

        if ([redirectedURL isEqualToString:_tappedLinkURL.absoluteString]) {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
            failure(error);
        }

        __block NSArray<NSString *> *urls = [UtilsUrls getArrayOfWebdavUrlWithUrlInWebScheme:redirectedURL forUser:_user];

        __block NSMutableArray *files = [NSMutableArray new];

        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);

        dispatch_group_async(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

                [self getFilesFrom:urls[idx] success:^(NSArray *items) {
                    NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                    files[idx] = directoryList;

                    if (idx == urls.count - 1) {
                        dispatch_group_leave(group);
                    }
                } failure:^(NSError *error) {
                    NSLog(@"LOG ---> error in the request to the url -> %@", urls[idx]);
                    dispatch_group_leave(group);
                    failure(error);

                }];
            }];
        });

        dispatch_group_notify(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            NSMutableArray *filesFromRootToFile = [self syncFilesTreeWithFiles:files andUrls:urls];
            success([filesFromRootToFile copy]);
        });

    } failure:^(NSError *error) {
        failure(error);
    }];

}

-(void)getRedirection:(NSURL *)privateLink success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {

    [[AppDelegate sharedOCCommunication] getFullPathFromPrivateLink:_tappedLinkURL success:^(NSURL *path) {
        success(path.absoluteString);
    } failure:^(NSError *error){
        failure(error);
    }];
}

-(void)syncFolderFilesWithFiles:(NSMutableArray *)folderFiles withParent:(FileDto *)parent {

    NSMutableArray *folderToCache = [NSMutableArray new];
    int numberOfFiles = (int) folderFiles.count;
    for (int i = 0; i < numberOfFiles; i++) {
        FileDto *tmpFileDTO = folderFiles[i];
        tmpFileDTO.filePath = [tmpFileDTO.filePath stringByReplacingOccurrencesOfString:k_url_webdav_server_with_first_slash withString:@""];
        FileDto *fileToCache = [ManageFilesDB getFileDtoByFileName:tmpFileDTO.fileName andFilePath:tmpFileDTO.filePath andUser:_user];

        if (fileToCache == nil) {
            [folderToCache addObject:tmpFileDTO];
        }
    }

    [ManageFilesDB insertManyFiles:folderToCache ofFileId:parent.idFile andUser:APP_DELEGATE.activeUser];
}

-(void)getFilesFrom:(NSString *)folderPath success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    [[AppDelegate sharedOCCommunication] readFolder:folderPath withUserSessionToken:APP_DELEGATE.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        success(items);
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        failure(error);
    }];
}

-(NSString *)getFileNameFromURLWithURL: (NSString *)url {
    NSMutableArray *components = [NSMutableArray arrayWithArray:[url componentsSeparatedByString:@"/"]];
    NSString *name = components.lastObject;
    if (components.count > 1) {
        if ([components.lastObject isEqualToString:@""]) {
            [components removeLastObject];
            name = [components.lastObject stringByAppendingString:@"/"];
        } else {
            name = components.lastObject;
        }
    }

    return name;
}

-(NSString *)getFilePathFromURLWithURL: (NSString *)url andFileName: (NSString *)name {
    NSString *path = [url stringByReplacingOccurrencesOfString:name withString:@""];
    return path;
}

-(NSMutableArray *)syncFilesTreeWithFiles: (NSMutableArray *)filesToSync andUrls: (NSArray<NSString *> *)urls {
    NSMutableArray *filesToReturn = [[NSMutableArray alloc] initWithCapacity:urls.count];
    FileDto *parent = nil;
    for (int i = 1; i < filesToSync.count; i ++) {

        NSString *urlToGetAsParent = urls[i];
        NSString *shortedFileURL = [UtilsUrls getFilePathOnDBByFullPath:urlToGetAsParent andUser:_user];
        NSString *name = [self getFileNameFromURLWithURL:shortedFileURL];

        NSString *path = [self getFilePathFromURLWithURL:shortedFileURL andFileName:name];
        if ([path isEqualToString:k_url_webdav_server_with_first_slash]) {
            path = @"";
        }

        parent = [ManageFilesDB getFileDtoByFileName:name andFilePath:path andUser:_user];
        if (parent != nil) {
            [filesToReturn addObject:parent];
        } else {
            name = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            parent = [ManageFilesDB getFileDtoByFileName:name andFilePath:path andUser:_user];
            if (parent != nil) {
                [filesToReturn addObject:parent];
            }
        }
        [self syncFolderFilesWithFiles:filesToSync[i] withParent:parent];
    }
    return filesToReturn;
}

-(void)handleLink1:(void (^)(FileDto *))success failure:(void (^)(NSError *))failure {
    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {
        NSArray<NSString *> *urls = [UtilsUrls getArrayOfWebdavUrlWithUrlInWebScheme:redirectedURL forUser:_user];

        [self getFilesFrom:urls.lastObject success:^(NSArray *files) {
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray: files];
            success(directoryList[1]);
        } failure:^(NSError *error) {
            failure(error);
        }];
    } failure:^(NSError *error) {
        failure(error);
    }];
}
@end
