//
//  OpenInAppHandler.m
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 13/12/2017.
//
//

#import "OpenInAppHandler.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "ManageFilesDB.h"
#import "UtilsDtos.h"

#define FOLDER_PATH 0
#define FILE_PATH 1


#define FOLDER_PATH 0
#define FILE_PATH 1

@implementation OpenInAppHandler

-(id)initWithLink:(NSURL *)linkURL andUser:(UserDto *) user {

    self = [super init];
    
    if (self) {
        _tappedLinkURL = linkURL;
        _user = user;
    }
    return self;
}

<<<<<<< HEAD
=======
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

>>>>>>> b483dc66... fix for open photos and files  inside the app and the root file bug
-(void)getRedirection:(NSURL *)privateLink success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
    
    [[AppDelegate sharedOCCommunication] getFullPathFromPrivateLink:_tappedLinkURL success:^(NSURL *path) {
        success(path.absoluteString);
    } failure:^(NSError *error){
        failure(error);
    }];
}

-(BOOL)isFolder: (NSArray *)queryParameters {
    if (queryParameters.count >= 2) {
        return NO;
    }
    return YES;
}

-(NSMutableArray *)getURlsForFilesWithQueryParameters: (NSMutableArray *)detachedFolderPath andBaseURL: (NSString *)baseURL {
    
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    NSString *tmpURL = baseURL;
    [urls addObject:tmpURL];
    for(int i = 0; i < detachedFolderPath.count; i++) {
        tmpURL = [tmpURL stringByAppendingString:[detachedFolderPath[i] stringByAppendingString: @"/"]];
        [urls addObject:tmpURL];
    }
    
    return urls;
}

-(void)handleLink {
    
    
    
    
}

-(NSMutableArray *)getQueryParameters:(NSString *) url {
    
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params addObject:[elts lastObject]];
    }
    
    return params;
}

-(void)cacheDownloadedFolder:(NSMutableArray *)downloadedFolder withParent:(FileDto *)parent {
    
    NSMutableArray *folderToCache = [NSMutableArray new];
    int numberOfFiles = (int) downloadedFolder.count;
    for (int i = 0; i < numberOfFiles; i++) {
        FileDto *tmpFileDTO = downloadedFolder[i];
        tmpFileDTO.filePath = [tmpFileDTO.filePath stringByReplacingOccurrencesOfString:@"/remote.php/webdav/" withString:@""];
        FileDto *fileToCache = [ManageFilesDB getFileDtoByFileName:tmpFileDTO.fileName andFilePath:tmpFileDTO.filePath andUser:_user];
        
        if (fileToCache == nil) {
            [folderToCache addObject:tmpFileDTO];
        }
    }

    [ManageFilesDB insertManyFiles:folderToCache ofFileId:parent.idFile andUser:APP_DELEGATE.activeUser];
}

-(void)getFilesFrom:(NSString *)folderPath success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    
    [[AppDelegate sharedOCCommunication] readFolder:folderPath withUserSessionToken:APP_DELEGATE.userSessionCurrentToken onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token) {
        
        NSLog(@"LOG ---> items count = %lu",(unsigned long)items.count);
        success(items);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        NSLog(@"LOG ---> error en la request");
        failure(error);
    }];
<<<<<<< HEAD
=======
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
>>>>>>> b483dc66... fix for open photos and files  inside the app and the root file bug
    
}

<<<<<<< HEAD
-(void)handleLink:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    
    [self getRedirection:_tappedLinkURL success:^(NSString *redirectedURL) {
        
        
        NSString *fileRedirectedURL = [UtilsUrls getSharedLinkArgumentsFromWebLink:redirectedURL andUser:_user];
        NSArray *queryParameters = [self getQueryParameters:fileRedirectedURL];
        
        NSMutableArray *detachedFolderPath = [[queryParameters[0] componentsSeparatedByString:@"/"] mutableCopy];
        [detachedFolderPath removeObjectAtIndex:0];
        if (![self isFolder:queryParameters]) {
            [detachedFolderPath addObject:queryParameters[1]];
        } else {
            [detachedFolderPath removeLastObject];
=======
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
>>>>>>> b483dc66... fix for open photos and files  inside the app and the root file bug
        }
        
        __block NSMutableArray *urls = [self getURlsForFilesWithQueryParameters:detachedFolderPath andBaseURL: [UtilsUrls getFullRemoteServerPathWithWebDav:_user]];
        
        __block NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity:urls.count];
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        
        dispatch_group_async(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self getFilesFrom:urls[idx] success:^(NSArray *items) {
                    NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
                    files[idx] = directoryList;
                    NSLog(@"LOG ---> success la request de get files con %@", urls[idx]);
                    
                    if (idx == urls.count - 1) {
                        dispatch_group_leave(group);
                    }
                } failure:^(NSError *error) {
                    NSLog(@"LOG ---> failure la request de get files con %@", urls[idx]);
                    //TODO: stop requests and show error message to user.
                }];
            }];
        });
        
        dispatch_group_notify(group ,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            FileDto *parent = [ManageFilesDB getRootFileDtoByUser: _user];
            for (int i = 1; i < files.count; i ++) {
                
                NSString *urlToGetAsParent = urls[i];
                NSString *shortedFileURL = [UtilsUrls getFilePathOnDBByFullPath:urlToGetAsParent andUser:_user];
                NSString *name = [self getFileNameFromURLWithURL:shortedFileURL];
                NSString *path = [self getFilePathFromURLWithURL:shortedFileURL andFileName:name];
                if ([path isEqualToString:@"/remote.php/webdav/"]) {
                    path = @"";
                }
                
                documents = [ManageFilesDB getFileDtoByFileName:name andFilePath:path andUser:_user];
                if (documents != nil) {
//                    documents.filePath = [documents.filePath stringByReplacingOccurrencesOfString:@"/remote.php/webdav" withString:@""];
                    [filesToReturn addObject:documents];
                }
                [self cacheDownloadedFolder:files[i] withParent:documents];

            }
            NSLog(@"LOG ---> all requests finished %@", files[0][0]);
        });
        
    } failure:^(NSError *error) {
        NSLog(@"LOG ---> failure del handle link");
    }];
    
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
